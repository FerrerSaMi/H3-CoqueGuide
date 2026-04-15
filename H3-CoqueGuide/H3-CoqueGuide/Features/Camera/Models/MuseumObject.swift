//
//  MuseumObject.swift
//  H3-CoqueGuide
//
//  Modelo que representa un objeto detectado por el escáner del museo.
//

import Foundation

struct MuseumObject: Identifiable, Equatable {
    let id          = UUID()
    let title       : String
    let era         : String
    let description : String
    let confidence  : Double

    static let sampleHorno3 = MuseumObject(
        title: "Horno 3",
        era: "CA. 1950s",
        description: "El Horno 3 fue uno de los altos hornos centrales de la Fundidora de Fierro y Acero de Monterrey. Operó durante décadas como corazón siderúrgico del noreste de México, transformando mineral de hierro en acero mediante temperaturas superiores a los 1 500 °C. Su cierre en 1986 marcó el fin de una era industrial y el inicio de su reconversión en parque cultural.",
        confidence: 0.94
    )
}
