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

// MARK: - Errors

enum CameraError: LocalizedError, Equatable {
    case permissionDenied
    case deviceUnavailable
    case inputError
    case captureError(String)
    case classificationFailed(String)
    case textRecognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:    return "Permiso de cámara denegado."
        case .deviceUnavailable:   return "No se encontró la cámara trasera."
        case .inputError:          return "Error al configurar la entrada de cámara."
        case .captureError(let m): return m
        case .classificationFailed(let m): return "Error de clasificación: \(m)"
        case .textRecognitionFailed(let m): return "Error de reconocimiento de texto: \(m)"
        }
    }
}

// MARK: - CameraService

@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: Published State
    @Published var isPermissionDenied = false
    @Published var cameraError: CameraError?
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false

    // MARK: Session
    let session = AVCaptureSession()

    // MARK: Private
    private let sessionQueue = DispatchQueue(label: "com.h3.camera.session", qos: .userInitiated)
    private let photoOutput  = AVCapturePhotoOutput()
    private var isConfigured = false
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var visionModel: VNCoreMLModel?

    // MARK: - Public API

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.configureAndStart()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.configureAndStart()
                    } else {
                        self.publishError(.permissionDenied)
                    }
                }
            default:
                self.publishError(.permissionDenied)
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Captura un fotograma estático para análisis. Retorna la imagen en el main thread.
    /// Protege contra llamadas concurrentes: si ya hay una captura en curso, retorna error.
    func capturePhoto() async throws -> UIImage {
        isCapturing = true
        defer { isCapturing = false }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.captureError("Servicio liberado."))
                    return
                }
                guard self.session.isRunning else {
                    continuation.resume(throwing: CameraError.captureError("La sesión no está activa."))
                    return
                }
                // Evitar sobrescribir una continuation activa (race condition)
                if self.photoContinuation != nil {
                    continuation.resume(throwing: CameraError.captureError("Ya hay una captura en curso."))
                    return
                }
                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func classifyCurrentFrame() async throws -> (label: String, confidence: Double) {
        let image = try await capturePhoto()
        return try await classify(image: image)
    }

    /// Extrae texto de la imagen actual usando OCR.
    func extractTextFromCurrentFrame() async throws -> String {
        let image = try await capturePhoto()
        return try await extractText(from: image)
    }

    /// Extrae y traduce texto de la imagen actual.
    func extractAndTranslateTextFromCurrentFrame(to targetLanguage: String, using translator: (String, String) async throws -> String) async throws -> String {
        let extractedText = try await extractTextFromCurrentFrame()
        guard !extractedText.isEmpty else { return "" }
        return try await translator(extractedText, targetLanguage)
    }


    // MARK: - Private helpers

    private func configureAndStart() {
        guard !isConfigured else {
            startIfNeeded()
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        session.inputs.forEach { session.removeInput($0) }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            publishError(.deviceUnavailable)
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)

            if let format = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?
                .activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = format
            }
        }

        session.commitConfiguration()
        isConfigured = true
        startIfNeeded()
    }

    private func startIfNeeded() {
        guard !session.isRunning else { return }
        session.startRunning()
    }

    private func publishError(_ error: CameraError) {
        DispatchQueue.main.async { [weak self] in
            self?.cameraError        = error
            self?.isPermissionDenied = (error == .permissionDenied)
        }
    }

    private func classify(image: UIImage) async throws -> (label: String, confidence: Double) {
        guard let cgImage = image.cgImage else {
            throw CameraError.classificationFailed("No se pudo convertir la imagen.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.classificationFailed("Servicio liberado."))
                    return
                }

                do {
                    if self.visionModel == nil {
                        let modelURL = Bundle.main.url(forResource: "ClassificationObjectsH3", withExtension: "mlmodelc")
                            ?? Bundle.main.url(forResource: "ClassificationObjectsH3", withExtension: "mlmodel")

                        guard let modelURL else {
                            throw CameraError.classificationFailed("No se encontró el modelo ML.")
                        }

                        let mlModel = try MLModel(contentsOf: modelURL)
                        self.visionModel = try VNCoreMLModel(for: mlModel)
                    }

                    let request = VNCoreMLRequest(model: self.visionModel!) { request, error in
                        if let error {
                            continuation.resume(throwing: CameraError.classificationFailed(error.localizedDescription))
                            return
                        }
                        guard let observations = request.results as? [VNClassificationObservation], let topResult = observations.first else {
                            continuation.resume(throwing: CameraError.classificationFailed("No se obtuvieron resultados de clasificación."))
                            return
                        }

                        continuation.resume(returning: (label: topResult.identifier, confidence: Double(topResult.confidence)))
                    }
                    request.imageCropAndScaleOption = .centerCrop

                    let orientation = CGImagePropertyOrientation(uiImageOrientation: image.imageOrientation)
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw CameraError.textRecognitionFailed("No se pudo convertir la imagen.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    let request = VNRecognizeTextRequest { request, error in
                        if let error {
                            continuation.resume(throwing: CameraError.textRecognitionFailed(error.localizedDescription))
                            return
                        }

                        guard let observations = request.results as? [VNRecognizedTextObservation] else {
                            continuation.resume(throwing: CameraError.textRecognitionFailed("No se obtuvieron resultados de reconocimiento de texto."))
                            return
                        }

                        let recognizedText = observations.compactMap { observation in
                            observation.topCandidates(1).first?.string
                        }.joined(separator: " ")

                        continuation.resume(returning: recognizedText)
                    }

                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.recognitionLanguages = ["es-ES", "en-US"] // Priorizar español e inglés

                    let orientation = CGImagePropertyOrientation(uiImageOrientation: image.imageOrientation)
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                    try handler.perform([request])
                } catch {
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
            photoContinuation?.resume(throwing: CameraError.captureError(error.localizedDescription))
            photoContinuation = nil
            return
        }
        guard
            let data  = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            photoContinuation?.resume(throwing: CameraError.captureError("No se pudo procesar la imagen."))
            photoContinuation = nil
            return
        }
        capturedImage = image
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
