//
//  Attraction.swift
//  H3-CoqueGuide
//
//  Modelo que representa una atracción del museo.
//

import SwiftUI

struct Attraction: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let message: String

    static let museumAttractions: [Attraction] = [
        Attraction(
            name: "Horno Alto",
            subtitle: "Paseo por el ícono del museo",
            icon: "flame.fill",
            color: Color(red: 0.93, green: 0.45, blue: 0.15),
            message: "Cuéntame sobre el Horno Alto del museo"
        ),
        Attraction(
            name: "Galería del Acero",
            subtitle: "Historia de la siderurgia",
            icon: "building.columns.fill",
            color: Color(red: 0.30, green: 0.50, blue: 0.75),
            message: "¿Qué puedo encontrar en la Galería del Acero?"
        ),
        Attraction(
            name: "Show del Acero",
            subtitle: "Espectáculo en vivo",
            icon: "sparkles",
            color: Color(red: 0.85, green: 0.30, blue: 0.30),
            message: "¿De qué trata el Show del Acero?"
        ),
        Attraction(
            name: "Laboratorio",
            subtitle: "Ciencia interactiva",
            icon: "flask.fill",
            color: Color(red: 0.35, green: 0.70, blue: 0.50),
            message: "¿Qué actividades hay en el Laboratorio?"
        ),
        Attraction(
            name: "Mirador",
            subtitle: "Vista panorámica",
            icon: "binoculars.fill",
            color: Color(red: 0.55, green: 0.45, blue: 0.75),
            message: "Cuéntame sobre el Mirador del museo"
        ),
        Attraction(
            name: "Acería",
            subtitle: "Proceso del acero",
            icon: "gearshape.2.fill",
            color: Color(red: 0.50, green: 0.55, blue: 0.60),
            message: "¿Qué puedo aprender en la Acería?"
        ),
    ]
}
