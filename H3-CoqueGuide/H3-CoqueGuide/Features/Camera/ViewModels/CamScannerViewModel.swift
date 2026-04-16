//
//  CamScannerViewModel.swift
//  H3-CoqueGuide
//
//  ViewModel que maneja la lógica de escaneo, flash y detección de objetos.
//

import SwiftUI
import Combine
import AVFoundation
import SwiftData

@MainActor
final class CamScannerViewModel: ObservableObject {

    // MARK: Services
    let camera = CameraService()
    let speech = SpeechService()
    private let geminiService: GeminiAIService?
    private var visitorProfile: CGVisitorProfile?

    // MARK: - Published State
    @Published var detectedObject: MuseumObject? = nil
    @Published var isPanelExpanded = false
    @Published var isScanning = false
    @Published var isFlashOn = false
    @Published var descriptionGenerationError: String? = nil
    @Published var extractedText: String? = nil
    @Published var translatedText: String? = nil
    @Published var selectedTranslationLanguage: String = "Español"
    @Published var cameraError: String? = nil
    @Published var showFallbackUI = false

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        if let apiKey = GeminiHTTPClient.loadAPIKey() {
            geminiService = GeminiAIService(apiKey: apiKey)
        } else {
            geminiService = nil
        }

        setupCameraErrorObserver()
    }

    private func setupCameraErrorObserver() {
        camera.$cameraError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.cameraError = error.localizedDescription
                    self?.showFallbackUI = true
                    print("📷 Camera error: \(error.localizedDescription)")
                } else {
                    self?.cameraError = nil
                    self?.showFallbackUI = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    func loadVisitorProfile(from context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            if let profile = try context.fetch(descriptor).first,
               !profile.gender.isEmpty {
                let cgProfile = CGVisitorProfile(from: profile)
                geminiService?.visitorProfile = cgProfile
                visitorProfile = cgProfile
                selectedTranslationLanguage = profile.translationLanguage
            }
        } catch {
            print("⚠️ No se pudo cargar el perfil de visitante: \(error)")
        }
    }

    func onAppear() {
        camera.clearError()
        camera.startSession()
    }

    func onDisappear() {
        camera.resetSession()
        speech.stop()
        setFlash(false)
    }

    /// Intenta recuperar de un error de cámara reiniciando la sesión
    func retryCameraSetup() {
        print("🔄 Retrying camera setup")
        camera.clearError()
        camera.resetSession()

        // Pequeño delay antes de reiniciar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.camera.startSession()
        }
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
        descriptionGenerationError = nil

        Task {
            do {
                let result = try await camera.classifyCurrentFrame()
                withAnimation {
                    detectedObject = MuseumObject(
                        title: result.label,
                        era: "Etiquetado ML",
                        description: "Generando descripción automática...",
                        confidence: result.confidence
                    )
                }

                if let generatedDescription = try await generateDescription(for: result.label) {
                    withAnimation {
                        detectedObject = MuseumObject(
                            title: result.label,
                            era: "Etiquetado ML",
                            description: generatedDescription,
                            confidence: result.confidence
                        )
                    }
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

    private func generateDescription(for objectName: String) async throws -> String? {
        guard let service = geminiService else {
            descriptionGenerationError = "No hay clave de Gemini disponible."
            return nil
        }

        do {
            return try await service.generateObjectDescription(for: objectName)
        } catch {
            descriptionGenerationError = "Error generando descripción: \(error.localizedDescription)"
            print("❌ Description generation error: \(error)")
            return nil
        }
    }

    func extractText() async {
        do {
            let text = try await camera.extractTextFromCurrentFrame()
            extractedText = text.isEmpty ? nil : text
            translatedText = nil // Reset translation when new text is extracted
        } catch {
            extractedText = nil
            print("❌ Text extraction error: \(error)")
        }
    }

    func translateExtractedText() async {
        guard let text = extractedText, let service = geminiService else { return }

        do {
            let languageName = languageName(for: selectedTranslationLanguage)
            let translated = try await service.translateText(text, to: languageName)
            translatedText = translated
        } catch {
            translatedText = nil
            print("❌ Translation error: \(error)")
        }
    }

    func saveTranslationLanguagePreference(to context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            if let profile = try context.fetch(descriptor).first {
                profile.translationLanguage = selectedTranslationLanguage
                profile.updatedAt = .now
                try context.save()
            }
        } catch {
            print("❌ Error saving translation language preference: \(error)")
        }
    }

    private func languageName(for code: String) -> String {
        switch code {
        case "English": return "inglés"
        case "Français": return "francés"
        case "Português": return "portugués"
        case "Korean": return "coreano"
        case "Arabic": return "árabe"
        default: return "español"
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
