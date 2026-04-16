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
    private let translationService = GoogleTranslationService()
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
    @Published var isDownloadingTranslationModel = false
    @Published var translationDownloadProgress: Float = 0.0
    @Published var translationError: String? = nil
    @Published var showScanResults = false

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Accessors
    var googleTranslationService: GoogleTranslationService {
        return translationService
    }

    // MARK: - Public Accessors
    var translationService: GoogleTranslationService {
        return translationService
    }

    // MARK: - Initialization

    init() {
        if let apiKey = GeminiHTTPClient.loadAPIKey() {
            geminiService = GeminiAIService(apiKey: apiKey)
        } else {
            geminiService = nil
        }

        setupCameraErrorObserver()
        setupTranslationObservers()
    }

    private func setupTranslationObservers() {
        translationService.$isDownloadingModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDownloading in
                self?.isDownloadingTranslationModel = isDownloading
            }
            .store(in: &cancellables)

        translationService.$downloadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.translationDownloadProgress = progress
            }
            .store(in: &cancellables)

        translationService.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.translationError = error
            }
            .store(in: &cancellables)
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
        showScanResults = false
        isScanning = true
        descriptionGenerationError = nil

        Task {
            do {
                let result = try await camera.classifyCurrentFrame()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    detectedObject = MuseumObject(
                        title: result.label,
                        era: "Etiquetado ML",
                        description: "Generando descripción automática...",
                        confidence: result.confidence
                    )
                    showScanResults = true
                }

                if let generatedDescription = try await generateDescription(for: result.label) {
                    withAnimation(.easeInOut(duration: 0.3)) {
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    detectedObject = MuseumObject(
                        title: "Desconocido",
                        era: "Etiquetado ML",
                        description: "No se pudo obtener una etiqueta del modelo. Intenta escanear nuevamente.",
                        confidence: 0.0
                    )
                    showScanResults = true
                }
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
        guard let text = extractedText else { return }

        // Limpiar errores previos
        translationError = nil

        do {
            // Verificar si el modelo está descargado
            if !translationService.isModelDownloaded(for: selectedTranslationLanguage) {
                print("📥 Model not downloaded for \(selectedTranslationLanguage), downloading...")
                try await translationService.downloadModel(for: selectedTranslationLanguage)
            }

            // Realizar traducción
            let translated = try await translationService.translateText(text, to: selectedTranslationLanguage)
            translatedText = translated
            print("✅ Translation completed successfully")

        } catch {
            translatedText = nil
            translationError = error.localizedDescription
            print("❌ Translation error: \(error.localizedDescription)")
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

    // MARK: - Speech

    func toggleSpeech(for text: String) {
        speech.toggle(text)
    }

    func togglePanelExpanded() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPanelExpanded.toggle()
        }
    }
}
