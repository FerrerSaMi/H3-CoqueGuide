//
//  Untitled.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import AVFoundation
import Combine
import UIKit
import Vision
import CoreML
import ImageIO
import OSLog

// MARK: - Errors

enum CameraError: LocalizedError, Equatable {
    case permissionDenied
    case deviceUnavailable
    case inputError
    case outputError
    case sessionError(String)
    case configurationError(String)
    case captureError(String)
    case classificationFailed(String)
    case textRecognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:    return "Permiso de cámara denegado."
        case .deviceUnavailable:   return "No se encontró la cámara trasera."
        case .inputError:          return "Error al configurar la entrada de cámara."
        case .outputError:         return "Error al configurar la salida de cámara."
        case .sessionError(let m): return "Error de sesión: \(m)"
        case .configurationError(let m): return "Error de configuración: \(m)"
        case .captureError(let m): return m
        case .classificationFailed(let m): return "Error de clasificación: \(m)"
        case .textRecognitionFailed(let m): return "Error de reconocimiento de texto: \(m)"
        }
    }
}

// MARK: - CameraService

@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: Logger
    private let logger = Logger(subsystem: "com.h3.camera", category: "CameraService")

    // MARK: Published State
    @Published var isPermissionDenied = false
    @Published var cameraError: CameraError?
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var isRunning = false
    @Published var isConfigured = false

    // MARK: Session
    let session = AVCaptureSession()

    // MARK: Private
    private let sessionQueue = DispatchQueue(label: "com.h3.camera.session", qos: .userInitiated)
    private let photoOutput  = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var visionModel: VNCoreMLModel?
    private var isConfiguring = false

    // MARK: - Initialization

    override init() {
        super.init()
        session.delegate = self
        logger.info("CameraService initialized")
    }

    // MARK: - Public API

    func startSession() {
        logger.info("Starting camera session")
        sessionQueue.async { [weak self] in
            guard let self else {
                self?.logger.error("CameraService deallocated during startSession")
                return
            }

            // Evitar inicializaciones duplicadas
            guard !self.isConfiguring else {
                self.logger.warning("Session start already in progress, ignoring duplicate call")
                return
            }

            self.isConfiguring = true
            self.logger.debug("Setting isConfiguring to true")

            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.logger.debug("Camera permission authorized, configuring session")
                self.configureAndStart()
                DispatchQueue.main.async {
                    self.isConfiguring = false
                    self.logger.debug("Session configuration completed successfully")
                }
            case .notDetermined:
                self.logger.info("Camera permission not determined, requesting access")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    self.sessionQueue.async {
                        self.isConfiguring = false
                        if granted {
                            self.logger.info("Camera permission granted, configuring session")
                            self.configureAndStart()
                        } else {
                            self.logger.error("Camera permission denied by user")
                            self.publishError(.permissionDenied)
                        }
                    }
                }
            default:
                self.isConfiguring = false
                self.logger.error("Camera permission denied or restricted")
                self.publishError(.permissionDenied)
            }
        }
    }

    func stopSession() {
        logger.info("Stopping camera session")
        sessionQueue.async { [weak self] in
            guard let self else {
                self?.logger.error("CameraService deallocated during stopSession")
                return
            }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.logger.info("Camera session stopped successfully")
                }
            } else {
                self.logger.debug("Session was already stopped")
            }
        }
    }

    func resetSession() {
        logger.info("Resetting camera session")
        sessionQueue.async { [weak self] in
            guard let self else {
                self?.logger.error("CameraService deallocated during resetSession")
                return
            }

            if self.session.isRunning {
                self.session.stopRunning()
                self.logger.debug("Session stopped during reset")
            }

            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.isConfigured = false
                self.isRunning = false
                self.logger.info("Session reset completed")
            }

            self.photoContinuation?.resume(throwing: CameraError.captureError("La sesión de cámara se ha detenido."))
            self.photoContinuation = nil
            self.visionModel = nil
            self.logger.debug("Session resources cleaned up")
        }
    }

    /// Captura un fotograma estático para análisis. Retorna la imagen en el main thread.
    /// Protege contra llamadas concurrentes: si ya hay una captura en curso, retorna error.
    func capturePhoto() async throws -> UIImage {
        logger.debug("Starting photo capture")
        isCapturing = true
        defer {
            isCapturing = false
            logger.debug("Photo capture process completed")
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    self?.logger.error("CameraService deallocated during photo capture")
                    continuation.resume(throwing: CameraError.captureError("Servicio liberado."))
                    return
                }

                guard self.session.isRunning else {
                    self.logger.error("Attempted to capture photo while session is not running")
                    continuation.resume(throwing: CameraError.captureError("La sesión no está activa."))
                    return
                }

                // Evitar sobrescribir una continuation activa (race condition)
                if self.photoContinuation != nil {
                    self.logger.warning("Photo capture already in progress, rejecting duplicate request")
                    continuation.resume(throwing: CameraError.captureError("Ya hay una captura en curso."))
                    return
                }

                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                self.logger.debug("Initiating photo capture with settings")
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func classifyCurrentFrame() async throws -> (label: String, confidence: Double) {
        logger.debug("Classifying current frame")
        let image = try await capturePhoto()
        return try await classify(image: image)
    }

    /// Extrae texto de la imagen actual usando OCR.
    func extractTextFromCurrentFrame() async throws -> String {
        logger.debug("Extracting text from current frame")
        let image = try await capturePhoto()
        return try await extractText(from: image)
    }

    /// Extrae y traduce texto de la imagen actual.
    func extractAndTranslateTextFromCurrentFrame(to targetLanguage: String, using translator: (String, String) async throws -> String) async throws -> String {
        logger.debug("Extracting and translating text from current frame to \(targetLanguage)")
        let extractedText = try await extractTextFromCurrentFrame()
        guard !extractedText.isEmpty else {
            logger.info("No text to translate")
            return ""
        }
        logger.debug("Translating \(extractedText.count) characters")
        return try await translator(extractedText, targetLanguage)
    }

    /// Limpia el estado de error actual
    func clearError() {
        logger.debug("Clearing camera error state")
        DispatchQueue.main.async { [weak self] in
            self?.cameraError = nil
            self?.isPermissionDenied = false
        }
    }


    // MARK: - Private helpers

    private func configureAndStart() {
        guard !isConfigured else {
            logger.debug("Session already configured, starting if needed")
            startIfNeeded()
            return
        }

        logger.info("Configuring camera session")
        session.beginConfiguration()
        session.sessionPreset = .photo

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                logger.error("No back camera device found")
                session.commitConfiguration()
                publishError(.deviceUnavailable)
                return
            }

            logger.debug("Found back camera device: \(device.localizedName)")

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                logger.error("Cannot add camera input to session")
                session.commitConfiguration()
                publishError(.inputError)
                return
            }

            session.addInput(input)
            logger.debug("Camera input added successfully")

            guard session.canAddOutput(photoOutput) else {
                logger.error("Cannot add photo output to session")
                session.commitConfiguration()
                publishError(.outputError)
                return
            }

            session.addOutput(photoOutput)
            logger.debug("Photo output added successfully")

            if let format = device.activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = format
                logger.debug("Set max photo dimensions: \(format)")
            }

            session.commitConfiguration()
            isConfigured = true
            logger.info("Session configuration completed successfully")
            startIfNeeded()

        } catch {
            logger.error("Failed to create camera input: \(error.localizedDescription)")
            session.commitConfiguration()
            publishError(.inputError)
        }
    }

    private func startIfNeeded() {
        guard !session.isRunning else {
            logger.debug("Session already running")
            return
        }

        logger.info("Starting camera session")
        session.startRunning()
        DispatchQueue.main.async {
            self.isRunning = true
            self.logger.info("Camera session started successfully")
        }
    }

    private func publishError(_ error: CameraError) {
        logger.error("Publishing camera error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.cameraError        = error
            self?.isPermissionDenied = (error == .permissionDenied)
        }
    }

    private func classify(image: UIImage) async throws -> (label: String, confidence: Double) {
        logger.debug("Starting image classification")
        guard let cgImage = image.cgImage else {
            logger.error("Failed to convert UIImage to CGImage for classification")
            throw CameraError.classificationFailed("No se pudo convertir la imagen.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    self?.logger.error("CameraService deallocated during classification")
                    continuation.resume(throwing: CameraError.classificationFailed("Servicio liberado."))
                    return
                }

                do {
                    if self.visionModel == nil {
                        self.logger.debug("Loading ML model for classification")
                        let modelURL = Bundle.main.url(forResource: "ClassificationObjectsH3", withExtension: "mlmodelc")
                            ?? Bundle.main.url(forResource: "ClassificationObjectsH3", withExtension: "mlmodel")

                        guard let modelURL else {
                            self.logger.error("ML model file not found")
                            throw CameraError.classificationFailed("No se encontró el modelo ML.")
                        }

                        let mlModel = try MLModel(contentsOf: modelURL)
                        self.visionModel = try VNCoreMLModel(for: mlModel)
                        self.logger.debug("ML model loaded successfully")
                    }

                    let request = VNCoreMLRequest(model: self.visionModel!) { request, error in
                        if let error {
                            self?.logger.error("ML classification request failed: \(error.localizedDescription)")
                            continuation.resume(throwing: CameraError.classificationFailed(error.localizedDescription))
                            return
                        }

                        guard let observations = request.results as? [VNClassificationObservation], let topResult = observations.first else {
                            self?.logger.error("No classification results obtained")
                            continuation.resume(throwing: CameraError.classificationFailed("No se obtuvieron resultados de clasificación."))
                            return
                        }

                        let confidence = Double(topResult.confidence)
                        self?.logger.info("Classification completed: \(topResult.identifier) (\(String(format: "%.2f", confidence * 100))% confidence)")
                        continuation.resume(returning: (label: topResult.identifier, confidence: confidence))
                    }
                    request.imageCropAndScaleOption = .centerCrop

                    let orientation = CGImagePropertyOrientation(uiImageOrientation: image.imageOrientation)
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                    try handler.perform([request])
                    self.logger.debug("Classification request submitted")

                } catch {
                    self.logger.error("Classification setup failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func extractText(from image: UIImage) async throws -> String {
        logger.debug("Starting text extraction (OCR)")
        guard let cgImage = image.cgImage else {
            logger.error("Failed to convert UIImage to CGImage for OCR")
            throw CameraError.textRecognitionFailed("No se pudo convertir la imagen.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    let request = VNRecognizeTextRequest { request, error in
                        if let error {
                            self.logger.error("OCR request failed: \(error.localizedDescription)")
                            continuation.resume(throwing: CameraError.textRecognitionFailed(error.localizedDescription))
                            return
                        }

                        guard let observations = request.results as? [VNRecognizedTextObservation] else {
                            self.logger.warning("No text recognition results obtained")
                            continuation.resume(throwing: CameraError.textRecognitionFailed("No se obtuvieron resultados de reconocimiento de texto."))
                            return
                        }

                        let recognizedText = observations.compactMap { observation in
                            observation.topCandidates(1).first?.string
                        }.joined(separator: " ")

                        if recognizedText.isEmpty {
                            self.logger.info("No text found in image")
                        } else {
                            self.logger.info("Text extracted successfully: \(recognizedText.count) characters")
                        }

                        continuation.resume(returning: recognizedText)
                    }

                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.recognitionLanguages = ["es-ES", "en-US"] // Priorizar español e inglés

                    let orientation = CGImagePropertyOrientation(uiImageOrientation: image.imageOrientation)
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                    try handler.perform([request])
                    self.logger.debug("OCR request submitted")

                } catch {
                    self.logger.error("OCR setup failed: \(error.localizedDescription)")
                    continuation.resume(throwing: CameraError.textRecognitionFailed(error.localizedDescription))
                }
            }
        }
    }
}

// MARK: - CGImagePropertyOrientation Extension

extension CGImagePropertyOrientation {
    init(uiImageOrientation: UIImage.Orientation) {
        switch uiImageOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            logger.error("Photo capture failed: \(error.localizedDescription)")
            photoContinuation?.resume(throwing: CameraError.captureError("Error al capturar foto: \(error.localizedDescription)"))
            photoContinuation = nil
            return
        }

        guard
            let data  = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            logger.error("Failed to process captured photo data")
            photoContinuation?.resume(throwing: CameraError.captureError("No se pudo procesar la imagen capturada."))
            photoContinuation = nil
            return
        }

        logger.debug("Photo captured successfully")
        capturedImage = image
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}

// MARK: - AVCaptureSessionDelegate

extension CameraService: AVCaptureSessionDelegate {
    func session(_ session: AVCaptureSession, didFailWithError error: Error) {
        logger.error("AVCaptureSession failed with error: \(error.localizedDescription)")
        publishError(.sessionError("La sesión de cámara falló: \(error.localizedDescription)"))
    }

    func sessionWasInterrupted(_ session: AVCaptureSession) {
        logger.warning("AVCaptureSession was interrupted")
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    func sessionInterruptionEnded(_ session: AVCaptureSession) {
        logger.info("AVCaptureSession interruption ended, restarting if needed")
        startIfNeeded()
    }

    func session(_ session: AVCaptureSession, didStopRunningWithError error: Error) {
        logger.error("AVCaptureSession stopped with error: \(error.localizedDescription)")
        publishError(.sessionError("La sesión de cámara se detuvo con error: \(error.localizedDescription)"))
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
}
