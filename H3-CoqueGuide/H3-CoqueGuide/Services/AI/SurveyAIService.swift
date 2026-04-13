//
//  SurveyAIService.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//

import Foundation
import FoundationModels

struct SurveyAIService {
    private let appleModel = SystemLanguageModel.default
    private let geminiModel = "gemini-2.5-flash"

    func generateDescription(for profile: ExcursionUserProfile) async throws -> String {
        do {
            return try await generateDescriptionWithAppleModel(for: profile)
        } catch {
            if let apiKey = loadGeminiAPIKey() {
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

    private func generateDescriptionWithGemini(for profile: ExcursionUserProfile, apiKey: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(geminiModel):generateContent?key=\(apiKey)") else {
            throw SurveyAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [[
                        "text": """
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
                    ]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 220
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SurveyAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let rawBody = String(data: data, encoding: .utf8) ?? "no body"
            print("Survey Gemini HTTP \(httpResponse.statusCode): \(rawBody)")
            throw SurveyAIError.geminiRequestFailed(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw SurveyAIError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadGeminiAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.isEmpty,
              key != "AQUI_VA_LA_API_KEY"
        else { return nil }

        return key
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
