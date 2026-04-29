//
//  CamScannerViewModel.swift
//  H3-CoqueGuide
//
//  ViewModel que maneja la lógica de escaneo, flash y detección de objetos.
//

import SwiftUI
import Combine
import AVFoundation

/// Modo del escáner. El usuario lo elige antes de disparar.
enum ScannerMode {
    case object   // Identificar pieza del museo (CoreML)
    case text     // Extraer y traducir texto (OCR + Gemini)
}

/// Resultado de OCR + traducción para mostrar en el panel dedicado.
struct OCRResult: Identifiable {
    let id = UUID()
    let original: String
    let translated: String
    let targetLanguage: String   // Código ISO del idioma destino (en, fr, etc.)
}

@MainActor
final class CamScannerViewModel: ObservableObject {

    // MARK: - Services
    let camera = CameraService()
    let speech = SpeechService()
    let missionViewModel = ScannerMissionViewModel()

    // MARK: - Catalog
    private let catalog = MuseumObjectsCatalog.load()

    // MARK: - Published State
    @Published var detectedObject: MuseumObject? = nil
    @Published var ocrResult: OCRResult? = nil
    @Published var isPanelExpanded = false
    @Published var isScanning = false
    @Published var isFlashOn = false
    @Published var scannerMode: ScannerMode = .object
    
    // MARK: - Onboarding
    @AppStorage("hasSeenScannerOnboarding") private var hasSeenScannerOnboarding = false
    @Published var showScannerOnboarding = false
    
    // MARK: - Mission UI
    @Published var showMissionSheet = false

    // MARK: - Lifecycle

    func onAppear() {
        camera.startSession()
        
        // Mostrar onboarding si es la primera vez
        if !hasSeenScannerOnboarding {
            showScannerOnboarding = true
        }
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
        ocrResult = nil
        isPanelExpanded = false
        isScanning = true

        Task {
            do {
                let image = try await camera.capturePhoto()
                switch scannerMode {
                case .object:
                    await scanAsObject(image: image)
                case .text:
                    await scanAsText(image: image)
                }
            } catch {
                print("❌ Capture error: \(error)")
                isScanning = false
                withAnimation {
                    detectedObject = MuseumObject(
                        title: L10n.scannerGenericErrorTitle,
                        era: L10n.scannerRetryTag,
                        description: L10n.scannerGenericErrorDescription,
                        confidence: 0.0
                    )
                }
            }
        }
    }

    // MARK: - Modo Objeto (CoreML + traducción de catálogo)

    private func scanAsObject(image: UIImage) async {
        do {
            let result = try await camera.classify(image: image)

            // Verificar si es parte de la misión
            if missionViewModel.isPartOfMission(result.label) && !missionViewModel.isObjectFound(result.label) {
                missionViewModel.markObjectAsFound(result.label)
            }

            // Mostrar inmediato en español
            let original = catalog.museumObject(
                forLabel: result.label,
                confidence: result.confidence
            )
            withAnimation {
                detectedObject = original
            }
            isScanning = false

            // Traducir descripción en background si el idioma no es español
            if AppLanguage.device != .spanish && !original.isUnknown {
                Task { [weak self] in
                    guard let self else { return }
                    let translated = await MuseumTranslationService.shared.translateForDevice(
                        label: result.label,
                        title: original.title,
                        era: original.era,
                        description: original.description
                    )
                    guard let current = self.detectedObject, current.id == original.id else { return }
                    withAnimation {
                        self.detectedObject = MuseumObject(
                            title: translated.title,
                            era: translated.era,
                            description: translated.description,
                            confidence: original.confidence
                        )
                    }
                }
            }
        } catch {
            withAnimation {
                detectedObject = MuseumObject(
                    title: catalog.unknown.title,
                    era: catalog.unknown.era,
                    description: L10n.scannerScanFailedDescription,
                    confidence: 0.0
                )
            }
            isScanning = false
        }
    }

    // MARK: - Modo Texto (OCR + traducción server-side)

    private func scanAsText(image: UIImage) async {
        do {
            let targetLang = AppLanguage.device.rawValue
            let (original, translated) = try await camera.extractAndTranslateText(
                from: image,
                targetLanguage: targetLang
            )

            // Si Gemini no extrajo nada legible, mostrar mensaje claro
            guard !original.isEmpty else {
                withAnimation {
                    detectedObject = MuseumObject(
                        title: L10n.scannerOcrErrorTitle,
                        era: L10n.scannerRetryTag,
                        description: L10n.scannerOcrErrorDescription,
                        confidence: 0.0
                    )
                }
                isScanning = false
                return
            }

            withAnimation {
                ocrResult = OCRResult(
                    original: original,
                    translated: translated.isEmpty ? original : translated,
                    targetLanguage: targetLang
                )
            }
            isScanning = false
        } catch {
            print("❌ OCR error: \(error)")
            withAnimation {
                detectedObject = MuseumObject(
                    title: L10n.scannerOcrErrorTitle,
                    era: L10n.scannerRetryTag,
                    description: L10n.scannerOcrErrorDescription,
                    confidence: 0.0
                )
            }
            isScanning = false
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
            ocrResult = nil
            isPanelExpanded = false
        }
    }
}
