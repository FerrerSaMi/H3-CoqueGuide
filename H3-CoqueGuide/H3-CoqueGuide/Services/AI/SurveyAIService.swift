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

    // MARK: - Atracción ideal (Apple Intelligence + backend fallback)

    /// Devuelve un ID único para la atracción ideal entre un conjunto acotado.
    /// Intenta usar Apple Intelligence on-device; si no está disponible lanza el error correspondiente.
    func generateIdealAttractionID(for profile: ExcursionUserProfile) async throws -> String {
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

        let instructions = """
        You are Coque, the museum guide assistant. Given visitor data, choose exactly one of the following IDs as the best single attraction recommendation for this visitor: HORNO_ALTO, GALLERY, STEEL_SHOW, LAB, VIEWPOINT, STEEL_MILL.
        Output must be only the chosen ID in UPPERCASE and nothing else.
        """

        let session = LanguageModelSession(instructions: instructions)
        let prompt = buildPrompt(for: profile) + "\n\nWhich ID is best? Reply with only the ID token."

        let response = try await session.respond(to: prompt)
        let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        let allowed = ["HORNO_ALTO","GALLERY","STEEL_SHOW","LAB","VIEWPOINT","STEEL_MILL"]
        for id in allowed {
            if raw.localizedCaseInsensitiveContains(id) {
                return id
            }
        }

        // Heurísticas simples si el modelo devolviera un nombre en lugar del ID
        let lower = raw.lowercased()
        if lower.contains("horno") || lower.contains("alto") { return "HORNO_ALTO" }
        if lower.contains("galer") || lower.contains("gallery") { return "GALLERY" }
        if lower.contains("show") || lower.contains("espectac") { return "STEEL_SHOW" }
        if lower.contains("lab") || lower.contains("labor") { return "LAB" }
        if lower.contains("mirador") || lower.contains("view") || lower.contains("binocular") { return "VIEWPOINT" }
        if lower.contains("acero") || lower.contains("mill") || lower.contains("steel") { return "STEEL_MILL" }

        throw SurveyAIError.invalidResponse
    }

    /// Fallback que pide al backend generar el ID de la atracción ideal.
    func generateIdealAttractionViaBackend(for profile: ExcursionUserProfile) async throws -> String {
        struct Payload: Encodable {
            let gender, age_range, planned_time: String
            let attraction_preference, resolved_attraction_preference: String
            let specific_attraction, preferred_language: String
            let coque_personality: String
        }
        struct Response: Decodable {
            let ok: Bool
            let id: String?
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

        let response: Response = try await BackendHTTPClient.shared.post("survey/ideal", body: payload)
        guard response.ok, let id = response.id, !id.isEmpty else {
            throw SurveyAIError.invalidResponse
        }
        return id
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
