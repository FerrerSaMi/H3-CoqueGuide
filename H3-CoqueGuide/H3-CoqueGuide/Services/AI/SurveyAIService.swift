//
//  SurveyAIService.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//

import Foundation
import FoundationModels

struct SurveyAIService {
    private let model = SystemLanguageModel.default

    func generateDescription(for profile: ExcursionUserProfile) async throws -> String {
        switch model.availability {
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
        Write exactly one paragraph.
        Make it natural, attractive, and useful.
        Mention the type of experience they would probably enjoy, the pace of visit, and the kind of guidance style they prefer.
        \(languageInstruction)
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
        Create one paragraph describing this museum visitor.

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
        - If the selected preference was "Recomendado", use the resolved attraction style naturally.
        - If the visitor selected "No" for a specific attraction, do not invent one.
        - Keep the result to one paragraph only.
        - The paragraph must be written only in this language: \(outputLanguageName(for: profile.preferredLanguage)).
        - Do not mix languages.
        """

        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
        }
    }
}
