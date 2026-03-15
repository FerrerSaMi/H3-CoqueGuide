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

        let instructions = """
        Eres un asistente que analiza el perfil de un visitante para una excursion al museo Horno3.
        Debes responder con un solo parrafo claro, natural y util.
        Resume exactamente lo que la persona busca para vivir una mejor experiencia.
        Redacta la respuesta en el idioma preferido del usuario.
        """

        let session = LanguageModelSession(instructions: instructions)

        let preferencesText = profile.excursionPreferences.isEmpty
        ? "No especifico preferencias"
        : profile.excursionPreferences.joined(separator: ", ")

        let specificSearchText = profile.specificSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? "No indico algo específico"
        : profile.specificSearch

        let prompt = """
        Haz una descripción de un parrafo mostrando lo que el usuario busca y detallando todo lo que necesita.

        Datos del usuario:
        - Nombre: \(profile.name)
        - Edad: \(profile.age)
        - Tiempo disponible para la excursion: \(profile.availableTime)
        - Preferencias para la excursion: \(preferencesText)
        - Busca algo especifico: \(specificSearchText)
        - Idioma preferido: \(profile.preferredLanguage)

        La respuesta debe integrar todos esos datos de forma natural.
        """

        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
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
            return "Apple Intelligence no está activado en Configuracion."
        case .modelNotReady:
            return "El modelo aun no está listo. Intenta de nuevo en un momento."
        case .unavailable:
            return "La IA no esta disponible en este momento."
        }
    }
}
