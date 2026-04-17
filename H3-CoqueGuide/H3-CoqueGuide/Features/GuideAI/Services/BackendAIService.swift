//
//  BackendAIService.swift
//  H3-CoqueGuide
//
//  Implementación de CGAIServiceProtocol que usa el backend propio en vez de
//  llamar a Gemini directamente. Todo lo pesado (system prompt, personalidad,
//  idioma, historial, cards) vive en el server — aquí solo mandamos `text` y
//  parseamos lo que regresa.
//
//  Beneficios vs. GeminiAIService:
//    - La API key de Gemini nunca vive en el binario.
//    - Las conversaciones quedan persistidas en Postgres.
//    - Los cambios al prompt no requieren redeploy del app.
//

import Foundation

final class BackendAIService: CGAIServiceProtocol {

    // MARK: - CGAIServiceProtocol

    /// Perfil del visitante. Se pasa al backend para personalizar respuestas
    /// (cuando tengamos el `backendID` guardado después de la Iteración B).
    var visitorProfile: CGVisitorProfile?

    /// `visitor_id` que devolvió `POST /profile`. Lo setea el flujo de encuesta.
    /// Mientras sea `nil`, el chat funciona pero sin personalización por perfil.
    var visitorID: UUID?

    // MARK: - Estado interno

    private let client: BackendHTTPClient

    /// UUID de sesión — se genera una sola vez por instancia (toda la vida del
    /// app). Agrupa los mensajes de este chat en Postgres y habilita memoria
    /// del asistente entre mensajes.
    private let sessionID: UUID = UUID()

    // MARK: - Init

    init(client: BackendHTTPClient = .shared) {
        self.client = client
    }

    // MARK: - processMessage

    func processMessage(_ text: String) async -> CGAIResponse {
        let body = ChatRequest(
            visitor_id: visitorProfile?.backendID ?? visitorID,
            device_id: AppConfig.deviceID,
            session_id: sessionID,
            text: text,
            language: AppLanguage.device.rawValue,
            personality: visitorProfile?.coquePersonality
        )

        do {
            let response: ChatResponse = try await client.post(
                "chat/message",
                body: body
            )

            guard response.ok else {
                return .textOnly(
                    response.error
                    ?? "Lo siento, no pude procesar tu pregunta en este momento. Intenta de nuevo. 🔄"
                )
            }

            let cards = (response.cards ?? []).compactMap { $0.toActionCard() }
            let text  = response.reply ?? ""

            if cards.isEmpty {
                return .textOnly(text)
            }
            return .withCards(text.isEmpty ? nil : text, cards: cards)
        } catch {
            print("❌ BackendAIService error: \(error.localizedDescription)")
            return .textOnly(
                "Lo siento, no pude procesar tu pregunta en este momento. Intenta de nuevo o usa las acciones rápidas. 🔄"
            )
        }
    }
}

// MARK: - DTOs (wire format con el backend)

/// Request que manda el cliente a `POST /chat/message`.
private struct ChatRequest: Encodable {
    let visitor_id: UUID?
    let device_id: String
    let session_id: UUID
    let text: String
    let language: String
    let personality: String?
}

/// Respuesta de `POST /chat/message`.
private struct ChatResponse: Decodable {
    let ok: Bool
    let reply: String?
    let cards: [ChatCard]?
    let error: String?
}

/// Card devuelta por el backend. Se convierte a `CGActionCard` para la UI.
private struct ChatCard: Decodable {
    let type: String
    let title: String?
    let subtitle: String?
    let description: String?
    let icon: String?

    func toActionCard() -> CGActionCard? {
        switch type {
        case "map":
            return CGActionCard(
                cardType: .map,
                title: title ?? "Mapa del museo",
                subtitle: subtitle ?? "Niveles 1 y 2",
                description: description ?? "Consulta el plano interactivo del museo",
                action: .navigate(.map)
            )
        case "scan":
            return CGActionCard(
                cardType: .scan,
                title: title ?? "Abrir escáner",
                subtitle: subtitle ?? "Escanea códigos QR de las exhibiciones",
                action: .navigate(.scanning)
            )
        case "event":
            return CGActionCard(
                cardType: .event,
                title: title ?? "Evento",
                subtitle: subtitle,
                description: description,
                icon: icon,
                action: .navigate(.events)
            )
        default:
            return nil
        }
    }
}
