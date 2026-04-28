//
//  Untitled.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import Foundation
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

    var errorDescription: String? {
        switch self {
        case .permissionDenied:    return "Permiso de cámara denegado."
        case .deviceUnavailable:   return "No se encontró la cámara trasera."
        case .inputError:          return "Error al configurar la entrada de cámara."
        case .captureError(let m): return m
        case .classificationFailed(let m): return "Error de clasificación: \(m)"
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

    /// Detecta si una imagen contiene texto dominante (> 30%).
    /// Retorna (hasText, textCoveragePercent).
    func detectTextInImage(_ image: UIImage) async throws -> (hasText: Bool, coverage: Int) {
        guard let base64 = imageToBase64(image) else {
            throw CameraError.captureError("No se pudo convertir la imagen a base64.")
        }

        struct DetectTextRequest: Encodable {
            let image_base64: String
            let language: String
        }

        struct DetectTextResponse: Decodable {
            let ok: Bool
            let has_text: Bool
            let text_coverage_percent: Int
            let error: String?
        }

        do {
            let response: DetectTextResponse = try await BackendHTTPClient.shared.post(
                "scanner/detect-text",
                body: DetectTextRequest(image_base64: base64, language: "es")
            )

            guard response.ok else {
                throw CameraError.captureError(response.error ?? "Error al detectar texto.")
            }

            return (response.has_text, response.text_coverage_percent)
        } catch {
            throw CameraError.captureError("Error de red al detectar texto: \(error.localizedDescription)")
        }
    }

    /// Extrae texto de la imagen y lo traduce al idioma especificado.
    /// Retorna (textoOriginal, textoTraducido).
    func extractAndTranslateText(from image: UIImage, targetLanguage: String = "es") async throws -> (original: String, translated: String) {
        guard let base64 = imageToBase64(image) else {
            throw CameraError.captureError("No se pudo convertir la imagen a base64.")
        }

        struct ExtractTextRequest: Encodable {
            let image_base64: String
            let target_language: String
        }

        struct ExtractTextResponse: Decodable {
            let ok: Bool
            let original_text: String
            let translated_text: String
            let error: String?
        }

        do {
            let response: ExtractTextResponse = try await BackendHTTPClient.shared.post(
                "scanner/extract-text",
                body: ExtractTextRequest(image_base64: base64, target_language: targetLanguage)
            )

            guard response.ok else {
                throw CameraError.captureError(response.error ?? "Error al extraer texto.")
            }

            return (response.original_text, response.translated_text)
        } catch {
            throw CameraError.captureError("Error de red al extraer texto: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    /// Convierte UIImage a base64 string.
    private func imageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
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

    func classify(image: UIImage) async throws -> (label: String, confidence: Double) {
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
