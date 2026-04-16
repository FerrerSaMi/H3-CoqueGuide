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

    // MARK: - Services
    let camera = CameraService()
    let speech = SpeechService()
    private let geminiService: GeminiAIService?

    // MARK: - Published State
    @Published var detectedObject: MuseumObject? = nil
    @Published var isPanelExpanded = false
    @Published var isScanning = false
    @Published var isFlashOn = false
    @Published var descriptionGenerationError: String? = nil

    // MARK: - Initialization

    init() {
        if let apiKey = GeminiHTTPClient.loadAPIKey() {
            geminiService = GeminiAIService(apiKey: apiKey)
        } else {
            geminiService = nil
        }
    }

    // MARK: - Lifecycle

    func loadVisitorProfile(from context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            if let profile = try context.fetch(descriptor).first,
               !profile.gender.isEmpty {
                geminiService?.visitorProfile = CGVisitorProfile(from: profile)
            }
        } catch {
            print("⚠️ No se pudo cargar el perfil de visitante: \(error)")
        }
    }

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
