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
    
    /// Misión predeterminada: encuentra 5 objetos del museo
    static let defaultMission = ScannerMission(
        id: UUID(),
        title: "Misión: Hide and Seek 🎯",
        description: "Encuentra todos los objetos destacados del museo. Apunta y escanea cada uno para completar tu misión.",
        targetObjectLabels: [
            "Molde de fundición",
            "Carretilla de fundición",
            "Chevrolet 3100",
            "Elevador de Carga",
            "Vagón Torpedo"
        ],
        foundObjectLabels: []
    )
}

// MARK: - UserDefaults Manager

final class ScannerMissionManager {
    static let shared = ScannerMissionManager()
    
    private let userDefaultsKey = "scannerMission_v1"
    private let foundObjectsKey = "scannerMission_foundObjects_v1"
    
    /// Obtiene la misión actual del almacenamiento, o crea una por defecto
    func loadMission() -> ScannerMission {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(ScannerMission.self, from: data) {
            return decoded
        }
        return .defaultMission
    }
    
    /// Guarda la misión en el almacenamiento
    func saveMission(_ mission: ScannerMission) {
        if let encoded = try? JSONEncoder().encode(mission) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// Marca un objeto como encontrado en la misión actual
    func markObjectAsFound(_ label: String) {
        var mission = loadMission()
        mission.markObjectAsFound(label)
        saveMission(mission)
    }
    
    /// Reinicia la misión
    func resetMission() {
        var mission = ScannerMission.defaultMission
        mission.foundObjectLabels = []
        saveMission(mission)
    }
}
