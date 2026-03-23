//
//  Untitled.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import AVFoundation
import Combine

final class CameraService: ObservableObject {

    @Published var isPermissionDenied = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isConfigured = false

    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStartIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.configureAndStartIfNeeded()
                } else {
                    DispatchQueue.main.async {
                        self.isPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            isPermissionDenied = true
        @unknown default:
            isPermissionDenied = true
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureAndStartIfNeeded() {
        sessionQueue.async {
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                self.session.inputs.forEach { input in
                    self.session.removeInput(input)
                }

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        self.isPermissionDenied = true
                    }
                    return
                }

                self.session.addInput(input)
                self.session.commitConfiguration()
                self.isConfigured = true
            }

            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
}
