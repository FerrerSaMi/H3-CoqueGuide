//
//  SurveyAIService.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//  Refactorizado para usar Apple Intelligence on-device y, como fallback,
//  el backend propio (POST /survey/description). La API key de Gemini ya
//  NO vive en el cliente — queda server-side.
//

import Foundation
import FoundationModels

struct SurveyAIService {
    private let appleModel = SystemLanguageModel.default

    func generateDescription(for profile: ExcursionUserProfile) async throws -> String {
        do {
            return try await generateDescriptionWithAppleModel(for: profile)
        } catch {
            // Fallback: pedirle al backend que la genere con Gemini server-side.
            return try await generateDescriptionViaBackend(for: profile)
        }
    }

    // MARK: - Apple Intelligence (on-device)

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

    // MARK: - Fallback: backend propio

    private func generateDescriptionViaBackend(for profile: ExcursionUserProfile) async throws -> String {
        struct Payload: Encodable {
            let gender, age_range, planned_time: String
            let attraction_preference, resolved_attraction_preference: String
            let specific_attraction, preferred_language: String
            let coque_personality: String
        }
        struct Response: Decodable {
            let ok: Bool
            let description: String?
            let error: String?
        }

        let payload = Payload(
            gender: profile.gender,
            age_range: profile.ageRange,
            planned_time: profile.plannedTime,
            attraction_preference: profile.attractionPreference,
            resolved_attraction_preference: profile.resolvedAttractionPreference,
            specific_attraction: profile.specificAttraction,
            preferred_language: profile.preferredLanguage,
            coque_personality: profile.coquePersonality
        )

        let response: Response = try await BackendHTTPClient.shared.post(
            "survey/description", body: payload
        )

        guard response.ok, let text = response.description, !text.isEmpty else {
            throw SurveyAIError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
    case invalidResponse

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
        case .invalidResponse:
            return "El servidor respondió con un formato inesperado."
        }
    }
}
