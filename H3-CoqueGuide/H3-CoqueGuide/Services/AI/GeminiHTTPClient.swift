//
//  GeminiHTTPClient.swift
//  H3-CoqueGuide
//
//  Cliente HTTP compartido para llamadas a la API de Google Gemini.
//  Centraliza la carga de API key, construcción de requests y parsing de respuestas.
//

import Foundation

// MARK: - Cliente HTTP de Gemini

final class GeminiHTTPClient {

    private let apiKey: String
    private let model: String

    // MARK: - Inicialización

    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - Carga de API Key

    /// Intenta cargar la API key desde Secrets.plist.
    /// Retorna `nil` si no se encuentra o es un placeholder.
    static func loadAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.isEmpty,
              key != "TU_API_KEY_AQUI",
              key != "AQUI_VA_LA_API_KEY"
        else { return nil }

        return key
    }

    // MARK: - Llamada a la API

    /// Envía un request a Gemini y retorna el texto de respuesta.
    /// - Parameters:
    ///   - contents: Array de mensajes en formato Gemini (role + parts)
    ///   - systemInstruction: Instrucción del sistema (opcional)
    ///   - maxOutputTokens: Límite de tokens de salida (default 1024)
    ///   - temperature: Creatividad de la respuesta (default 0.7)
    /// - Returns: El texto de respuesta de Gemini
    func generateContent(
        contents: [[String: Any]],
        systemInstruction: String? = nil,
        maxOutputTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> String {

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": maxOutputTokens,
                "temperature": temperature
            ]
        ]

        if let systemInstruction {
            body["system_instruction"] = [
                "parts": [["text": systemInstruction]]
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.badResponse(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Gemini HTTP \(httpResponse.statusCode): \(responseBody)")
            throw GeminiError.badResponse(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String
        else {
            throw GeminiError.invalidJSON
        }

        return text
    }
}

// MARK: - Errores

enum GeminiError: LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int)
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "No se pudo construir la URL de Gemini."
        case .badResponse(let statusCode):
            return "Gemini devolvió un error HTTP \(statusCode)."
        case .invalidJSON:
            return "Gemini respondió con un formato inesperado."
        }
    }
}
