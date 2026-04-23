//
//  CGEventService.swift
//  CoqueGuideAI
//
//  Servicio de eventos del museo.
//  — Fuente primaria: backend propio (GET /museum-events/today).
//  — Fallback: datos mock para cuando no hay red.
//  — Cache in-memory válido hasta medianoche del día actual.
//

import Foundation

// MARK: - Modelo de evento

struct CGEvent: Identifiable {
    let id: String
    let name: String
    let location: String
    let description: String
    let icon: String
}

// MARK: - Servicio de eventos

final class CGEventService {

    static let shared = CGEventService()
    private init() {}

    // MARK: - Cache

    private var cachedEvents: [CGEvent] = CGEventService.mockEvents
    private var cacheDate: Date?

    /// `true` si el cache sigue siendo del día de hoy.
    private var cacheIsValid: Bool {
        guard let date = cacheDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    // MARK: - API pública (síncrona, devuelve cache actual)

    /// Devuelve los eventos en cache (mock al inicio, reales tras el primer `refresh()`).
    /// Se llama desde los servicios de CoqueGuide de forma síncrona.
    func todaysEvents() -> [CGEvent] { cachedEvents }

    func nextEvent() -> CGEvent? { cachedEvents.first }

    // MARK: - Refresh desde backend

    /// Descarga los eventos del día desde el backend y actualiza el cache.
    /// Se llama en `LandingView.onAppear`. Fire-and-forget seguro.
    func refresh() async {
        guard !cacheIsValid else { return }

        struct EventDTO: Decodable {
            let id: String
            let name: String
            let description: String?
            let location: String?
            let icon: String?
        }
        struct Response: Decodable {
            let ok: Bool
            let events: [EventDTO]
        }

        do {
            let response: Response = try await BackendHTTPClient.shared.get("museum-events/today")
            guard response.ok else { return }

            let events = response.events.map {
                CGEvent(
                    id: $0.id,
                    name: $0.name,
                    location: $0.location ?? "",
                    description: $0.description ?? "",
                    icon: $0.icon ?? "calendar"
                )
            }

            // Si el servidor no tiene nada para hoy, mantener los mock
            // para que la app no quede con lista vacía.
            if !events.isEmpty {
                cachedEvents = events
            }
            cacheDate = Date()
        } catch {
            print("⚠️ CGEventService: no se pudo refrescar eventos: \(error.localizedDescription)")
            // Fallo silencioso — el cache (mock) sigue activo.
        }
    }

    // MARK: - Mock data (fallback offline)

    private static let mockEvents: [CGEvent] = [
        CGEvent(
            id: "visita-guiada",
            name: "Visita guiada al Horno Alto",
            location: "Nivel 1 – Entrada principal",
            description: "Recorrido guiado por el interior del Horno Alto original.",
            icon: "person.wave.2"
        ),
        CGEvent(
            id: "taller-metalurgia",
            name: "Taller de metalurgia para niños",
            location: "Nivel 1 – Sala de talleres",
            description: "Actividad interactiva para niños de 6 a 12 años.",
            icon: "hammer"
        ),
        CGEvent(
            id: "documental",
            name: "Proyección: Acero y Fuego",
            location: "Nivel 2 – Sala audiovisual",
            description: "Documental sobre la historia de la industria acerera en Monterrey.",
            icon: "film"
        ),
        CGEvent(
            id: "tour-foto",
            name: "Tour fotográfico",
            location: "Nivel 1 – Patio industrial",
            description: "Recorrido para capturar las mejores vistas del museo.",
            icon: "camera"
        ),
    ]
}
