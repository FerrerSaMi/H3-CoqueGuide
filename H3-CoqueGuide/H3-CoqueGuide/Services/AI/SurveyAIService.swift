//
//  SurveyAIService.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//  Refactorizado para usar GeminiHTTPClient compartido.
//

import Foundation
import FoundationModels

struct SurveyAIService {
    private let appleModel = SystemLanguageModel.default

    func generateDescription(for profile: ExcursionUserProfile) async throws -> String {
        do {
            return try await generateDescriptionWithAppleModel(for: profile)
        } catch {
            if let apiKey = GeminiHTTPClient.loadAPIKey() {
                return try await generateDescriptionWithGemini(for: profile, apiKey: apiKey)
            } else {
                throw error
            }
        }
    }

    private func generateDescriptionWithAppleModel(for profile: ExcursionUserProfile) async throws -> String {
        switch appleModel.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw SurveyAIError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            throw SurveyAIError.appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            throw SurveyAIError.modelNotReady
        case .unavailable:
            throw SurveyAIError.unavailable
        }

        let languageInstruction = outputLanguageInstruction(for: profile.preferredLanguage)

        let instructions = """
        You are an assistant that creates a visitor profile summary for a museum experience at Horno3.
        Write exactly one complete paragraph of at least 100 words.
        Make it natural, attractive, and useful.
        Mention the type of experience they would probably enjoy, the pace of visit, and the kind of guidance style they prefer.
        Use every item of visitor data to describe the user and their interests.
        Prefer longer, complete content over short replies; do not shorten the response to save tokens.
        End the paragraph with a complete sentence and a final period.
        \(languageInstruction)
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = buildPrompt(for: profile)

        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateDescriptionWithGemini(for profile: ExcursionUserProfile, apiKey: String) async throws -> String {
        let client = GeminiHTTPClient(apiKey: apiKey)

        let prompt = buildPrompt(for: profile)

        let contents: [[String: Any]] = [
            [
                "role": "user",
                "parts": [["text": prompt]]
            ]
        ]

        do {
            let text = try await client.generateContent(
                contents: contents,
                maxOutputTokens: 2048,
                temperature: 0.2
            )
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let error as GeminiError {
            switch error {
            case .invalidURL:
                throw SurveyAIError.invalidURL
            case .badResponse(let statusCode):
                throw SurveyAIError.geminiRequestFailed(statusCode: statusCode)
            case .invalidJSON:
                throw SurveyAIError.invalidResponse
            }
        }
    }

    // MARK: - Prompt compartido

    private func buildPrompt(for profile: ExcursionUserProfile) -> String {
        """
        Create one complete paragraph describing this museum visitor using all available data.

        Visitor data:
        - Gender: \(profile.gender)
        - Age range: \(profile.ageRange)
        - Planned visit time: \(profile.plannedTime)
        - Attraction preference selected: \(profile.attractionPreference)
        - Final attraction style to use: \(profile.resolvedAttractionPreference)
        - Specific attraction requested: \(profile.specificAttraction)
        - Preferred language: \(profile.preferredLanguage)
        - Preferred Coque personality: \(profile.coquePersonality)

        Rules:
        - Use every visitor data field to build a complete personality and preference description.
        - Do not stop mid-sentence or cut off any values.
        - End the paragraph with a complete sentence and a final period.
        - Write at least 100 words.
        - Prefer longer, complete content over short replies; do not shorten the response to save tokens.
        - If the selected preference was "Recomendado", use the resolved attraction style naturally.
        - If the visitor selected "No" for a specific attraction, do not invent one.
        - Keep the result to one paragraph only.
        - The paragraph must be written only in this language: \(outputLanguageName(for: profile.preferredLanguage)).
        - Do not mix languages.
        """
    }

    // MARK: - Helpers de idioma

    private func outputLanguageInstruction(for language: String) -> String {
        switch language {
        case "Español":
            return "Write the entire paragraph only in Spanish."
        case "English":
            return "Write the entire paragraph only in English."
        case "Français":
            return "Write the entire paragraph only in French."
        case "Português":
            return "Write the entire paragraph only in Portuguese."
        case "Korean":
            return "Write the entire paragraph only in Korean."
        case "Arabic":
            return "Write the entire paragraph only in Arabic."
        default:
            return "Write the entire paragraph only in Spanish."
        }
    }

    private func outputLanguageName(for language: String) -> String {
        switch language {
        case "Español":
            return "Spanish"
        case "English":
            return "English"
        case "Français":
            return "French"
        case "Português":
            return "Portuguese"
        case "Korean":
            return "Korean"
        case "Arabic":
            return "Arabic"
        default:
            return "Spanish"
        }
    }
}

enum SurveyAIError: LocalizedError {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unavailable
    case invalidURL
    case invalidResponse
    case geminiRequestFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .deviceNotEligible:
            return "Este dispositivo no es compatible con Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence no está activado en Configuración."
        case .modelNotReady:
            return "El modelo aún no está listo. Intenta de nuevo en un momento."
        case .unavailable:
            return "La IA no está disponible en este momento."
        case .invalidURL:
            return "No se pudo construir la URL de Gemini."
        case .invalidResponse:
            return "Gemini respondió con un formato inesperado."
        case .geminiRequestFailed(let statusCode):
            return "Gemini devolvió un error HTTP \(statusCode)."
        }
    }
}
