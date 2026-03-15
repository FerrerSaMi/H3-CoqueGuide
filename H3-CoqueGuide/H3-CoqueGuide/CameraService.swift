//
//  Untitled.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import AVFoundation
import Combine

@MainActor
final class CameraService: ObservableObject {

    let session = AVCaptureSession()

    func startSession() {

        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()
        session.startRunning()
    }
}
