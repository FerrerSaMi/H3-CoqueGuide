//
//  Attraction.swift
//  H3-CoqueGuide
//
//  Modelo que representa una atracción del museo.
//
//  Los textos (name, subtitle, message) se localizan vía L10n para que
//  reflejen el idioma del iPhone al instante.
//

import SwiftUI

struct Attraction: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let message: String

    /// Catálogo de atracciones del museo.
    /// Es una `static var` computada para que las claves de L10n se resuelvan
    /// en tiempo de acceso (si el idioma del dispositivo cambia, los textos se actualizan).
    static var museumAttractions: [Attraction] {
        [
            Attraction(
                name: L10n.attrHornoAltoName,
                subtitle: L10n.attrHornoAltoSubtitle,
                icon: "flame.fill",
                color: Color(red: 0.93, green: 0.45, blue: 0.15),
                message: L10n.attrHornoAltoMessage
            ),
            Attraction(
                name: L10n.attrGalleryName,
                subtitle: L10n.attrGallerySubtitle,
                icon: "building.columns.fill",
                color: Color(red: 0.30, green: 0.50, blue: 0.75),
                message: L10n.attrGalleryMessage
            ),
            Attraction(
                name: L10n.attrSteelShowName,
                subtitle: L10n.attrSteelShowSubtitle,
                icon: "sparkles",
                color: Color(red: 0.85, green: 0.30, blue: 0.30),
                message: L10n.attrSteelShowMessage
            ),
            Attraction(
                name: L10n.attrLabName,
                subtitle: L10n.attrLabSubtitle,
                icon: "flask.fill",
                color: Color(red: 0.35, green: 0.70, blue: 0.50),
                message: L10n.attrLabMessage
            ),
            Attraction(
                name: L10n.attrViewpointName,
                subtitle: L10n.attrViewpointSubtitle,
                icon: "binoculars.fill",
                color: Color(red: 0.55, green: 0.45, blue: 0.75),
                message: L10n.attrViewpointMessage
            ),
            Attraction(
                name: L10n.attrSteelMillName,
                subtitle: L10n.attrSteelMillSubtitle,
                icon: "gearshape.2.fill",
                color: Color(red: 0.50, green: 0.55, blue: 0.60),
                message: L10n.attrSteelMillMessage
            ),
        ]
    }

    /// Mapea un ID retornado por el servicio de IA/backend a una `Attraction`.
    /// IDs soportados: HORNO_ALTO, GALLERY, STEEL_SHOW, LAB, VIEWPOINT, STEEL_MILL
    static func attraction(for id: String) -> Attraction? {
        switch id.uppercased() {
        case "HORNO_ALTO":
            return museumAttractions.indices.contains(0) ? museumAttractions[0] : nil
        case "GALLERY":
            return museumAttractions.indices.contains(1) ? museumAttractions[1] : nil
        case "STEEL_SHOW":
            return museumAttractions.indices.contains(2) ? museumAttractions[2] : nil
        case "LAB":
            return museumAttractions.indices.contains(3) ? museumAttractions[3] : nil
        case "VIEWPOINT":
            return museumAttractions.indices.contains(4) ? museumAttractions[4] : nil
        case "STEEL_MILL":
            return museumAttractions.indices.contains(5) ? museumAttractions[5] : nil
        default:
            return nil
        }
    }
}
