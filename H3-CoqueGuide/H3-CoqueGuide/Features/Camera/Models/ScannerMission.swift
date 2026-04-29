//
//  ScannerMission.swift
//  H3-CoqueGuide
//
//  Modelo que representa la misión "Hide and Seek" del escáner.
//  Persiste en UserDefaults la lista de objetos encontrados.
//

import Foundation

struct ScannerMission: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let targetObjectLabels: [String]  // Etiquetas del modelo ML que debe encontrar
    var foundObjectLabels: [String] = []  // Objetos ya encontrados
    
    var progress: (found: Int, total: Int) {
        (foundObjectLabels.count, targetObjectLabels.count)
    }
    
    var isComplete: Bool {
        progress.found == progress.total && progress.total > 0
    }
    
    var progressPercentage: Double {
        let total = targetObjectLabels.count
        guard total > 0 else { return 0 }
        return Double(foundObjectLabels.count) / Double(total)
    }
    
    mutating func markObjectAsFound(_ label: String) {
        if targetObjectLabels.contains(label) && !foundObjectLabels.contains(label) {
            foundObjectLabels.append(label)
        }
    }
    
    func isObjectFound(_ label: String) -> Bool {
        foundObjectLabels.contains(label)
    }
    
    /// Misión predeterminada: encuentra 9 objetos del museo.
    /// `title` y `description` son computed via L10n para reflejar el idioma actual.
    /// Las `targetObjectLabels` son IDs del modelo CoreML — NO se localizan
    /// y deben coincidir exactamente con las claves de `MuseumObjects.json`.
    static var defaultMission: ScannerMission {
        ScannerMission(
            id: UUID(),
            title: L10n.missionTitle,
            description: L10n.missionDescription,
            targetObjectLabels: [
                "Molde de fundición",
                "Carretilla de fundición",
                "Chevrolet 3100",
                "Elevador de Carga",
                "Vagón Torpedo",
                "Maqueta Modelo Horno 3",
                "Reloj Checador",
                "Tenazas de Garra Industrial",
                "Televisor Antiguo"
            ],
            foundObjectLabels: []
        )
    }
}

// MARK: - UserDefaults Manager

final class ScannerMissionManager {
    static let shared = ScannerMissionManager()

    /// Solo persistimos los labels encontrados — el título y la descripción
    /// se reconstruyen via L10n en cada `loadMission()` para que respeten
    /// el idioma actual del dispositivo.
    private let foundObjectsKey = "scannerMission_foundObjects_v1"

    /// Obtiene la misión actual: skeleton localizado + labels encontrados desde UserDefaults.
    func loadMission() -> ScannerMission {
        var mission = ScannerMission.defaultMission
        if let data = UserDefaults.standard.data(forKey: foundObjectsKey),
           let found = try? JSONDecoder().decode([String].self, from: data) {
            mission.foundObjectLabels = found
        }
        return mission
    }

    /// Guarda solo el progreso (labels encontrados).
    func saveMission(_ mission: ScannerMission) {
        if let encoded = try? JSONEncoder().encode(mission.foundObjectLabels) {
            UserDefaults.standard.set(encoded, forKey: foundObjectsKey)
        }
    }

    /// Marca un objeto como encontrado en la misión actual.
    func markObjectAsFound(_ label: String) {
        var mission = loadMission()
        mission.markObjectAsFound(label)
        saveMission(mission)
    }

    /// Reinicia la misión.
    func resetMission() {
        UserDefaults.standard.removeObject(forKey: foundObjectsKey)
    }
}
