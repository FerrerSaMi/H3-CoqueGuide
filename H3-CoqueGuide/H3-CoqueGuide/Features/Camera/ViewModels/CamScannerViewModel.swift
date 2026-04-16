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

    // MARK: - Catalog
    private let catalog = MuseumObjectsCatalog.load()

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
                    detectedObject = catalog.museumObject(
                        forLabel: result.label,
                        confidence: result.confidence
                    )
                }
                isScanning = false
            } catch {
                isScanning = false
                withAnimation {
                    detectedObject = MuseumObject(
                        title: catalog.unknown.title,
                        era: catalog.unknown.era,
                        description: "No se pudo completar el escaneo. Intenta acercarte al objeto, mejorar la iluminación o encuadrarlo dentro del marco del escáner.",
                        confidence: 0.0
                    )
                }
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
