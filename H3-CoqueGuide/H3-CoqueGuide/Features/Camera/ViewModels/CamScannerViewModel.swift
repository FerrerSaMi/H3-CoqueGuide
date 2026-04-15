//
//  CamScannerViewModel.swift
//  H3-CoqueGuide
//
//  ViewModel que maneja la lógica de escaneo, flash y detección de objetos.
//

import SwiftUI
import Combine
import AVFoundation

@MainActor
final class CamScannerViewModel: ObservableObject {

    // MARK: - Services
    let camera = CameraService()
    let speech = SpeechService()

    // MARK: - Published State
    @Published var detectedObject: MuseumObject? = nil
    @Published var isPanelExpanded = false
    @Published var isScanning = false
    @Published var isFlashOn = false

    // MARK: - Lifecycle

    func onAppear() {
        camera.startSession()
    }

    func onDisappear() {
        camera.stopSession()
        speech.stop()
        setFlash(false)
    }

    // MARK: - Flash

    func toggleFlash() {
        isFlashOn.toggle()
        setFlash(isFlashOn)
    }

    private func setFlash(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("❌ Flash error: \(error)")
        }
    }

    // MARK: - Scan

    func triggerScan() {
        guard !isScanning else { return }
        speech.stop()
        detectedObject = nil
        isPanelExpanded = false
        isScanning = true

        Task {
            do {
                let result = try await camera.classifyCurrentFrame()
                withAnimation {
                    detectedObject = MuseumObject(
                        title: result.label,
                        era: "Etiquetado ML",
                        description: "No hay información adicional disponible en la base de datos. Esta etiqueta proviene del modelo de clasificación.",
                        confidence: result.confidence
                    )
                }
                isScanning = false
            } catch {
                isScanning = false
                detectedObject = MuseumObject(
                    title: "Desconocido",
                    era: "Etiquetado ML",
                    description: "No se pudo obtener una etiqueta del modelo. Intenta escanear nuevamente.",
                    confidence: 0.0
                )
            }
        }
    }

    // MARK: - Speech

    func toggleSpeech(for text: String) {
        speech.toggle(text)
    }

    func togglePanelExpanded() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPanelExpanded.toggle()
        }
    }
}
