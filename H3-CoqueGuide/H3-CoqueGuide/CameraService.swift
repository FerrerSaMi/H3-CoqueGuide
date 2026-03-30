//
//  Untitled.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import AVFoundation
import Combine
import UIKit

// MARK: - Errors

enum CameraError: LocalizedError, Equatable {
    case permissionDenied
    case deviceUnavailable
    case inputError
    case captureError(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:    return "Permiso de cámara denegado."
        case .deviceUnavailable:   return "No se encontró la cámara trasera."
        case .inputError:          return "Error al configurar la entrada de cámara."
        case .captureError(let m): return m
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
                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
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
