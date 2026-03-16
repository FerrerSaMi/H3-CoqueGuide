//
//  CGEventService.swift
//  CoqueGuideAI
//
//  Servicio de eventos del museo con datos mock.
//

import Foundation

// MARK: - Modelo de evento

struct CGEvent: Identifiable {
    let id: String
    let name: String
    let time: String
    let location: String
    let description: String
    let icon: String
}

// MARK: - Servicio de eventos

final class CGEventService {

    static let shared = CGEventService()
    private init() {}

    func todaysEvents() -> [CGEvent] {
        [
            CGEvent(
                id: "visita-guiada",
                name: "Visita guiada al Horno Alto",
                time: "11:00",
                location: "Nivel 1 – Entrada principal",
                description: "Recorrido guiado por el interior del Horno Alto original.",
                icon: "person.wave.2"
            ),
            CGEvent(
                id: "taller-metalurgia",
                name: "Taller de metalurgia para niños",
                time: "13:00",
                location: "Nivel 1 – Sala de talleres",
                description: "Actividad interactiva para niños de 6 a 12 años.",
                icon: "hammer"
            ),
            CGEvent(
                id: "documental",
                name: "Proyección: Acero y Fuego",
                time: "15:30",
                location: "Nivel 2 – Sala audiovisual",
                description: "Documental sobre la historia de la industria acerera en Monterrey.",
                icon: "film"
            ),
            CGEvent(
                id: "tour-foto",
                name: "Tour fotográfico",
                time: "17:00",
                location: "Nivel 1 – Patio industrial",
                description: "Recorrido para capturar las mejores vistas del museo.",
                icon: "camera"
            ),
        ]
    }

    func nextEvent() -> CGEvent? {
        todaysEvents().first
    }
}
