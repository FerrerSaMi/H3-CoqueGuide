//
//  GoogleTranslationService.swift
//  H3-CoqueGuide
//
//  Servicio de traducción usando Google ML Kit Translate.
//  Proporciona traducción offline/online con descarga automática de modelos.
//

import Foundation
import MLKitTranslate
import Combine
import OSLog

@MainActor
final class GoogleTranslationService: ObservableObject {

    // MARK: Logger
    private let logger = Logger(subsystem: "com.h3.translation", category: "GoogleTranslationService")

    // MARK: Published State
    @Published var isDownloadingModel = false
    @Published var downloadProgress: Float = 0.0
    @Published var lastError: String?

    // MARK: Private Properties
    private var translators: [String: Translator] = [:]
    private var modelDownloads: [String: ModelDownloadConditions] = [:]

    // MARK: Supported Languages
    private let supportedLanguages: [String: TranslateLanguage] = [
        "Español": .spanish,
        "English": .english,
        "Français": .french,
        "Português": .portuguese,
        "Korean": .korean,
        "Arabic": .arabic
    ]

    // MARK: - Initialization

    init() {
        logger.info("GoogleTranslationService initialized")
    }

    // MARK: - Public API

    /// Traduce texto al idioma especificado
    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }

        guard let targetLang = supportedLanguages[targetLanguage] else {
            throw TranslationError.unsupportedLanguage(targetLanguage)
        }

        logger.debug("Starting translation to \(targetLanguage)")

        // Asegurar que el modelo esté disponible
        try await ensureModelDownloaded(for: targetLang)

        // Obtener o crear traductor
        let translator = try await getTranslator(for: targetLang)

        // Realizar traducción
        return try await withCheckedThrowingContinuation { continuation in
            translator.translate(text) { result, error in
                if let error = error {
                    self.logger.error("Translation failed: \(error.localizedDescription)")
                    continuation.resume(throwing: TranslationError.translationFailed(error.localizedDescription))
                    return
                }

                guard let translatedText = result else {
                    self.logger.error("Translation returned nil result")
                    continuation.resume(throwing: TranslationError.translationFailed("Traducción falló"))
                    return
                }

                self.logger.info("Translation completed successfully")
                continuation.resume(returning: translatedText)
            }
        }
    }

    /// Verifica si un modelo de idioma está descargado
    func isModelDownloaded(for languageName: String) -> Bool {
        guard let language = supportedLanguages[languageName] else { return false }

        let conditions = ModelDownloadConditions(
            requiresWifi: false,
            requiresCharging: false
        )

        return TranslateRemoteModel.translateRemoteModel(language).isModelOnDevice
    }

    /// Descarga un modelo de idioma si no está disponible
    func downloadModel(for languageName: String) async throws {
        guard let language = supportedLanguages[languageName] else {
            throw TranslationError.unsupportedLanguage(languageName)
        }

        guard !isModelDownloaded(for: languageName) else {
            logger.debug("Model for \(languageName) already downloaded")
            return
        }

        logger.info("Starting model download for \(languageName)")

        isDownloadingModel = true
        downloadProgress = 0.0
        lastError = nil

        defer {
            isDownloadingModel = false
            downloadProgress = 0.0
        }

        let model = TranslateRemoteModel.translateRemoteModel(language)
        let conditions = ModelDownloadConditions(
            requiresWifi: false,
            requiresCharging: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            model.download(conditions) { error in
                if let error = error {
                    self.logger.error("Model download failed: \(error.localizedDescription)")
                    self.lastError = error.localizedDescription
                    continuation.resume(throwing: TranslationError.downloadFailed(error.localizedDescription))
                    return
                }

                self.logger.info("Model download completed for \(languageName)")
                continuation.resume(returning: ())
            }

            // Monitorear progreso (ML Kit no proporciona progreso directo)
            // Simulamos progreso básico
            Task {
                for progress in stride(from: 0.0, to: 1.0, by: 0.1) {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    await MainActor.run {
                        self.downloadProgress = progress
                    }
                }
                await MainActor.run {
                    self.downloadProgress = 1.0
                }
            }
        }
    }

    /// Obtiene la lista de idiomas soportados
    func getSupportedLanguages() -> [String] {
        return Array(supportedLanguages.keys).sorted()
    }

    // MARK: - Private Methods

    private func ensureModelDownloaded(for language: TranslateLanguage) async throws {
        guard !TranslateRemoteModel.translateRemoteModel(language).isModelOnDevice else {
            return
        }

        logger.debug("Model not available locally, downloading...")
        try await downloadModel(for: language.displayName)
    }

    private func getTranslator(for language: TranslateLanguage) async throws -> Translator {
        let languageKey = language.rawValue

        if let existingTranslator = translators[languageKey] {
            return existingTranslator
        }

        logger.debug("Creating new translator for \(language.displayName)")

        let options = TranslatorOptions(sourceLanguage: .english, targetLanguage: language)
        let translator = Translator.translator(options: options)

        translators[languageKey] = translator
        return translator
    }
}

// MARK: - Translation Errors

enum TranslationError: LocalizedError {
    case unsupportedLanguage(String)
    case downloadFailed(String)
    case translationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage(let lang):
            return "Idioma no soportado: \(lang)"
        case .downloadFailed(let reason):
            return "Error al descargar modelo: \(reason)"
        case .translationFailed(let reason):
            return "Error de traducción: \(reason)"
        }
    }
}

// MARK: - TranslateLanguage Extension

extension TranslateLanguage {
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        case .french: return "Français"
        case .portuguese: return "Português"
        case .korean: return "Korean"
        case .arabic: return "Arabic"
        default: return rawValue
        }
    }
}