//
//  NavigationState.swift
//  H3-CoqueGuide
//
//  Estado compartido para navegación entre vistas.
//

import Foundation

@Observable
final class NavigationState {
    /// ID de ubicación en el mapa a mostrar cuando se navega desde el carrusel
    var selectedMapLocationID: Int? = nil
    
    /// Mapeo de índice de galería a ID de ubicación en el mapa
    static let galleryToMapLocation: [Int: (locationID: Int, level: Int)] = [
        0: (locationID: 16, level: 2),  // Galeria1 - Show del Horno → Salón Show del horno (Nivel 2)
        1: (locationID: 1, level: 1),   // Galeria2 - Lab Innovación → Laboratorio de Innovación (Nivel 1)
        2: (locationID: 17, level: 2),  // Galeria3 - Planeta Tierra → Planeta Tierra (Nivel 2)
        3: (locationID: 6, level: 1),   // Galeria4 - Reacción Cadena → Núcleo Científico (Nivel 1)
        4: (locationID: 4, level: 1),   // Galeria5 - Historia → Vestíbulo Galería Historia (Nivel 1)
        5: (locationID: 2, level: 1),   // Galeria6 - Ventana Ciencia → Lab Ventana a Ciencia (Nivel 1)
        6: (locationID: 15, level: 2),  // Galeria7 - Cima → Terraza verde (Nivel 2)
        7: (locationID: 5, level: 1)    // Galeria8 - Acero → Vestíbulo Galería Acero (Nivel 1)
    ]
    
    /// Navega a una ubicación específica del mapa desde el carrusel
    func navigateToGalleryLocation(galleryIndex: Int) {
        if let mapping = Self.galleryToMapLocation[galleryIndex] {
            selectedMapLocationID = mapping.locationID
        }
    }
}
