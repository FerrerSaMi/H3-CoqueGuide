//
//  GeminiAIService.swift
//  CoqueGuideAI
//
//  Integración con la API de Google Gemini 2.5 Flash para respuestas reales.
//  Usa GeminiHTTPClient compartido para las llamadas HTTP.
//

import Foundation

final class GeminiAIService: CGAIServiceProtocol {

    private let client: GeminiHTTPClient
    private var conversationHistory: [[String: Any]] = []
    private let maxHistoryMessages = 20 // 10 pares user/assistant

    // MARK: - Perfil del visitante
    var visitorProfile: CGVisitorProfile?

    // MARK: - Inicialización

    init(apiKey: String) {
        self.client = GeminiHTTPClient(apiKey: apiKey)
    }

    /// Intenta crear el servicio leyendo la API key desde Secrets.plist.
    /// Retorna `nil` si no se encuentra la key.
    static func fromSecretsPlist() -> GeminiAIService? {
        guard let key = GeminiHTTPClient.loadAPIKey() else { return nil }
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
            let responseText = try await client.generateContent(
                contents: conversationHistory,
                systemInstruction: Self.systemPrompt(visitor: visitorProfile),
                maxOutputTokens: 2048,
                temperature: 0.7
            )
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

    // MARK: - Generación de descripción de objeto

    func generateObjectDescription(for objectName: String, objectEra: String? = nil) async throws -> String {
        let eraText = objectEra.map { "Está enmarcado en la era de \($0)." } ?? ""
        let message = """
        Genera una descripción breve y accesible para un visitante del museo.
        - Incluye qué es el objeto, qué puede esperar el visitante y por qué vale la pena.
        - Mantén el tono en función de la personalidad de Coque y el idioma preferido del visitante.
        - Usa máximo 3-4 párrafos cortos y evita listas largas.
        - No incluyas etiquetas, solo texto limpio.
        Objeto: \(objectName).
        \(eraText)
        """

        let contents: [[String: Any]] = [
            ["role": "user", "parts": [["text": message]]]
        ]

        return try await client.generateContent(
            contents: contents,
            systemInstruction: Self.systemPrompt(visitor: visitorProfile),
            maxOutputTokens: 280,
            temperature: 0.75
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Historial
        if conversationHistory.count > maxHistoryMessages {
            conversationHistory = Array(conversationHistory.suffix(maxHistoryMessages))
        }
    }

    // MARK: - System Prompt

    private static func systemPrompt(visitor: CGVisitorProfile? = nil) -> String {
        let events = CGEventService.shared.todaysEvents()
        let eventsList = events.map { "- \($0.name) (\($0.location))" }.joined(separator: "\n")

        var personalityBlock = """
        PERSONALIDAD:
        - Amable, entusiasta y conocedor de la historia industrial
        - Respuestas concisas pero informativas (máximo 3-4 párrafos cortos)
        - Usa español mexicano natural
        - Puedes usar emojis con moderación
        """

        var visitorBlock = ""

        if let visitor {
            // Adaptar personalidad según preferencia del visitante
            let personalityStyle: String
            switch visitor.coquePersonality {
            case "Divertido":
                personalityStyle = "Sé muy amigable, casual y usa emojis frecuentemente. Haz comentarios graciosos y ligeros."
            case "Formal":
                personalityStyle = "Sé profesional y estructurado. Usa un tono respetuoso y evita emojis."
            case "Técnico":
                personalityStyle = "Da datos técnicos, cifras y detalles históricos precisos. Sé informativo y detallado."
            case "Infantil":
                personalityStyle = "Usa un lenguaje sencillo y divertido, como si hablaras con un niño. Usa muchos emojis y analogías simples."
            default:
                personalityStyle = "Sé amable y natural."
            }

            personalityBlock += "\n- Estilo de comunicación: \(personalityStyle)"

            // Idioma preferido
            let languageInstruction: String
            switch visitor.preferredLanguage {
            case "English":
                languageInstruction = "You MUST respond ONLY in English. Do not use Spanish at all."
            case "Français":
                languageInstruction = "Tu DOIS répondre UNIQUEMENT en français. N'utilise pas l'espagnol."
            case "Português":
                languageInstruction = "Você DEVE responder APENAS em português. Não use espanhol."
            case "Korean":
                languageInstruction = "반드시 한국어로만 답변하세요. 스페인어를 사용하지 마세요."
            case "Arabic":
                languageInstruction = "يجب أن تجيب باللغة العربية فقط. لا تستخدم الإسبانية."
            default:
                languageInstruction = "Responde siempre en español mexicano."
            }

            visitorBlock = """

            IDIOMA DE RESPUESTA:
            \(languageInstruction)

            PERFIL DEL VISITANTE:
            - Género: \(visitor.gender)
            - Rango de edad: \(visitor.ageRange)
            - Tiempo de visita: \(visitor.plannedTime)
            - Preferencia de experiencia: \(visitor.attractionPreference)
            - Atracción específica: \(visitor.specificAttraction)
            Adapta tus respuestas al perfil del visitante. Recomienda experiencias afines a sus intereses y tiempo disponible.
            """
        }

        return """
        Eres "Coque", el asistente inteligente del Museo del Acero Horno3 en Monterrey, México. \
        Tu nombre viene del "coque", el combustible que se usaba en los Altos Hornos.

        \(personalityBlock)

        INFORMACIÓN DEL MUSEO:
        - Niveles: Nivel 1 (exhibiciones históricas, Horno Alto original), Nivel 2 (galería industrial, mirador).
        - Servicios: Restaurante 'La Fundición' (Nivel 1), Cafetería (Planta baja), Tienda de souvenirs, Estacionamiento gratuito.
        - Accesibilidad: Rampas, elevadores, audioguías, material en braille, sanitarios adaptados.
        - Historia: Inaugurado en 2007, construido sobre el Horno Alto No. 3 de Fundidora de Monterrey (operó 1910-1986).

        EVENTOS DE HOY:
        \(eventsList)
        \(visitorBlock)

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
