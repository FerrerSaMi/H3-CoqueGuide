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
                // 1) Capturar imagen
                let image = try await camera.capturePhoto()

                // 2) Detectar si hay texto predominante
                let (hasText, textCoverage) = try await camera.detectTextInImage(image)

                // 3) Si hay texto dominante (> 30%), extraer y traducir
                if hasText && textCoverage > 30 {
                    do {
                        let (original, translated) = try await camera.extractAndTranslateText(
                            from: image,
                            targetLanguage: "es"
                        )

                        withAnimation {
                            // Mostrar texto extraído como "objeto"
                            detectedObject = MuseumObject(
                                title: "📝 Texto detectado",
                                era: "OCR",
                                description: translated.isEmpty
                                    ? original
                                    : "\(translated)",
                                confidence: Double(textCoverage) / 100.0
                            )
                        }
                        isScanning = false
                    } catch {
                        // Fallback: mostrar error pero mantener UI
                        print("❌ OCR error: \(error)")
                        withAnimation {
                            detectedObject = MuseumObject(
                                title: "Error en OCR",
                                era: "REINTENTA",
                                description: "No se pudo extraer el texto. Intenta de nuevo con mejor iluminación.",
                                confidence: 0.0
                            )
                        }
                        isScanning = false
                    }
                } else {
                    // 4) Si no hay texto, usar CoreML normal
                    do {
                        let result = try await camera.classify(image: image)
                        withAnimation {
                            detectedObject = catalog.museumObject(
                                forLabel: result.label,
                                confidence: result.confidence
                            )
                        }
                        isScanning = false
                    } catch {
                        withAnimation {
                            detectedObject = MuseumObject(
                                title: catalog.unknown.title,
                                era: catalog.unknown.era,
                                description: "No se pudo completar el escaneo. Intenta acercarte al objeto, mejorar la iluminación o encuadrarlo dentro del marco del escáner.",
                                confidence: 0.0
                            )
                        }
                        isScanning = false
                    }
                }
            } catch {
                // Error en detección de texto o captura
                print("❌ Scan error: \(error)")
                isScanning = false
                withAnimation {
                    detectedObject = MuseumObject(
                        title: "Error al escanear",
                        era: "REINTENTA",
                        description: "No se pudo procesar la imagen. Verifica tu conexión a internet y vuelve a intentar.",
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

    /// Cierra el panel de información y detiene cualquier lectura activa.
    func dismissInfoPanel() {
        speech.stop()
        withAnimation(.easeInOut(duration: 0.25)) {
            detectedObject = nil
            isPanelExpanded = false
        }
    }
}
