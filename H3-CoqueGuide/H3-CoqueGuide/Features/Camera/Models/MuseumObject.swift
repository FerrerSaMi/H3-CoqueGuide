//
//  MuseumObject.swift
//  H3-CoqueGuide
//
//  Modelo que representa un objeto detectado por el escáner del museo,
//  y el catálogo que mapea etiquetas del modelo ML a información real.
//

import Foundation

struct MuseumObject: Identifiable, Equatable {
    let id          = UUID()
    let title       : String
    let era         : String
    let description : String
    let confidence  : Double

    /// Indica si el objeto no pudo ser reconocido por el modelo.
    var isUnknown: Bool {
        confidence < 0.01 || title.lowercased().contains("no identificada")
    }

    static let sampleHorno3 = MuseumObject(
        title: "Horno 3",
        era: "CA. 1950s",
        description: "El Horno 3 fue uno de los altos hornos centrales de la Fundidora de Fierro y Acero de Monterrey. Operó durante décadas como corazón siderúrgico del noreste de México, transformando mineral de hierro en acero mediante temperaturas superiores a los 1 500 °C. Su cierre en 1986 marcó el fin de una era industrial y el inicio de su reconversión en parque cultural.",
        confidence: 0.94
    )
}

// MARK: - Catálogo cargado desde JSON

/// Entrada del catálogo de piezas del museo (sin `confidence`, se aporta en runtime).
struct MuseumObjectEntry: Decodable {
    let title: String
    let era: String
    let description: String
}

/// Catálogo que mapea las etiquetas del modelo ML a información real del museo.
/// Carga `MuseumObjects.json` desde el bundle con fallback seguro si no existe.
struct MuseumObjectsCatalog: Decodable {
    let objects: [String: MuseumObjectEntry]
    let unknown: MuseumObjectEntry

    /// Construye un `MuseumObject` completo dado una etiqueta del modelo ML.
    /// Si la etiqueta no existe en el catálogo, devuelve la entrada `unknown` con confianza 0.
    func museumObject(forLabel label: String, confidence: Double) -> MuseumObject {
        if let entry = objects[label] {
            return MuseumObject(
                title: entry.title,
                era: entry.era,
                description: entry.description,
                confidence: confidence
            )
        }
        return MuseumObject(
            title: unknown.title,
            era: unknown.era,
            description: unknown.description,
            confidence: 0.0
        )
    }

    static func load() -> MuseumObjectsCatalog {
        guard let url = Bundle.main.url(forResource: "MuseumObjects", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(MuseumObjectsCatalog.self, from: data) else {
            return .fallback
        }
        return decoded
    }

    /// Fallback usado si el JSON no se encuentra o falla el decode.
    static let fallback = MuseumObjectsCatalog(
        objects: [:],
        unknown: MuseumObjectEntry(
            title: "Pieza no identificada",
            era: "SIN RECONOCER",
            description: "No logré reconocer esta pieza. Prueba acercarte más, mejorar la iluminación o encuadrarla dentro del marco del escáner."
        )
    )
}
