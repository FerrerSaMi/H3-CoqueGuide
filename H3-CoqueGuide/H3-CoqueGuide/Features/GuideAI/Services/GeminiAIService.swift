//
//  GeminiAIService.swift
//  CoqueGuideAI
//
//  Integración con la API de Google Gemini 2.5 Flash para respuestas reales.
//

import Foundation

final class GeminiAIService: CGAIServiceProtocol {

    private let apiKey: String
    private let model = "gemini-2.5-flash"
    private var conversationHistory: [[String: Any]] = []
    private let maxHistoryMessages = 20 // 10 pares user/assistant

    // MARK: - Inicialización

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Intenta crear el servicio leyendo la API key desde Secrets.plist.
    /// Retorna `nil` si no se encuentra la key.
    static func fromSecretsPlist() -> GeminiAIService? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.isEmpty,
              key != "TU_API_KEY_AQUI"
        else { return nil }

        return GeminiAIService(apiKey: key)
    }

    // MARK: - CGAIServiceProtocol

    func processMessage(_ text: String) async -> CGAIResponse {
        conversationHistory.append([
            "role": "user",
            "parts": [["text": text]]
        ])
        trimHistory()

        do {
            let responseText = try await callGeminiAPI()
            conversationHistory.append([
                "role": "model",
                "parts": [["text": responseText]]
            ])
            return parseResponse(responseText)
        } catch {
            print("❌ GeminiAIService error: \(error)")
            conversationHistory.removeLast() // Quita el mensaje del usuario si falló
            return .textOnly("Lo siento, no pude procesar tu pregunta en este momento. Intenta de nuevo o usa las acciones rápidas. 🔄")
        }
    }

    // MARK: - Llamada a la API

    private func callGeminiAPI() async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": Self.systemPrompt()]]
            ],
            "contents": conversationHistory,
            "generationConfig": [
                "maxOutputTokens": 1024,
                "temperature": 0.7
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Gemini HTTP \(statusCode): \(body)")
            throw GeminiAPIError.badResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String
        else {
            throw GeminiAPIError.invalidJSON
        }

        return text
    }

    // MARK: - Parsing de respuesta con marcadores de tarjetas

    private func parseResponse(_ text: String) -> CGAIResponse {
        var cleanText = text
        var cards: [CGActionCard] = []

        // [CARD:map]
        if cleanText.contains("[CARD:map]") {
            cleanText = cleanText.replacingOccurrences(of: "[CARD:map]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cards.append(CGActionCard(
                cardType: .map,
                title: "Mapa del museo",
                subtitle: "Niveles 1 y 2",
                description: "Consulta el plano interactivo del museo",
                action: .navigate(.map)
            ))
        }

        // [CARD:scan]
        if cleanText.contains("[CARD:scan]") {
            cleanText = cleanText.replacingOccurrences(of: "[CARD:scan]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cards.append(CGActionCard(
                cardType: .scan,
                title: "Abrir escáner",
                subtitle: "Escanea códigos QR de las exhibiciones",
                action: .navigate(.scanning)
            ))
        }

        // [CARD:events]
        if cleanText.contains("[CARD:events]") {
            cleanText = cleanText.replacingOccurrences(of: "[CARD:events]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let events = CGEventService.shared.todaysEvents()
            cards.append(contentsOf: events.map { event in
                CGActionCard(
                    cardType: .event,
                    title: event.name,
                    subtitle: event.location,
                    description: event.description,
                    icon: event.icon,
                    action: .navigate(.events)
                )
            })
        }

        if cards.isEmpty {
            return .textOnly(cleanText)
        }
        return .withCards(cleanText.isEmpty ? nil : cleanText, cards: cards)
    }

    // MARK: - Historial

    private func trimHistory() {
        if conversationHistory.count > maxHistoryMessages {
            conversationHistory = Array(conversationHistory.suffix(maxHistoryMessages))
        }
    }

    // MARK: - System Prompt

    private static func systemPrompt() -> String {
        let events = CGEventService.shared.todaysEvents()
        let eventsList = events.map { "- \($0.name) (\($0.location))" }.joined(separator: "\n")

        return """
        Eres "Coque", el asistente inteligente del Museo del Acero Horno3 en Monterrey, México. \
        Tu nombre viene del "coque", el combustible que se usaba en los Altos Hornos.

        PERSONALIDAD:
        - Amable, entusiasta y conocedor de la historia industrial
        - Respuestas concisas pero informativas (máximo 3-4 párrafos cortos)
        - Usa español mexicano natural
        - Puedes usar emojis con moderación

        INFORMACIÓN DEL MUSEO:
        - Niveles: Nivel 1 (exhibiciones históricas, Horno Alto original), Nivel 2 (galería industrial, mirador).
        - Servicios: Restaurante 'La Fundición' (Nivel 1), Cafetería (Planta baja), Tienda de souvenirs, Estacionamiento gratuito.
        - Accesibilidad: Rampas, elevadores, audioguías, material en braille, sanitarios adaptados.
        - Historia: Inaugurado en 2007, construido sobre el Horno Alto No. 3 de Fundidora de Monterrey (operó 1910-1986).

        EVENTOS DE HOY:
        \(eventsList)

        TARJETAS DE ACCIÓN:
        Cuando tu respuesta se beneficie de una acción interactiva, incluye UN marcador al final del texto:
        - [CARD:map] → cuando hablas de ubicaciones, orientación o el mapa del museo
        - [CARD:events] → cuando hablas de eventos o actividades del día
        - [CARD:scan] → cuando hablas de escanear objetos o códigos QR
        Solo usa UN marcador por respuesta. No siempre es necesario incluir uno.

        REGLAS:
        - Solo responde sobre temas relacionados con el museo y la visita.
        - Si preguntan algo fuera de tu alcance, sugiere amablemente consultar en recepción.
        - No inventes información que no tengas.
        """
    }
}

// MARK: - Errores

private enum GeminiAPIError: Error {
    case invalidURL
    case badResponse
    case invalidJSON
}
