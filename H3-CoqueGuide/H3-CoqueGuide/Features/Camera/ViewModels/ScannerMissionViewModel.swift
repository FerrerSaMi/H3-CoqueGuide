//
//  ScannerMissionViewModel.swift
//  H3-CoqueGuide
//
//  ViewModel que gestiona el estado de la misión "Hide and Seek"
//  del escáner.
//

import SwiftUI
import Combine

@MainActor
final class ScannerMissionViewModel: ObservableObject {
    
    @Published var mission: ScannerMission
    
    private let missionManager = ScannerMissionManager.shared
    
    init() {
        self.mission = missionManager.loadMission()
    }
    
    /// Marca un objeto como encontrado y lo guarda
    func markObjectAsFound(_ label: String) {
        mission.markObjectAsFound(label)
        missionManager.saveMission(mission)
        
        AnalyticsService.shared.track("mission_object_found", metadata: [
            "object": label,
            "progress": "\(mission.progress.found)/\(mission.progress.total)"
        ])
        
        // Si misión completada, enviar evento
        if mission.isComplete {
            AnalyticsService.shared.track("mission_completed", metadata: [
                "total_objects": mission.progress.total
            ])
        }
    }
    
    /// Reinicia la misión
    func resetMission() {
        missionManager.resetMission()
        mission = missionManager.loadMission()
        
        AnalyticsService.shared.track("mission_reset")
    }
    
    /// Verifica si un objeto es parte de la misión
    func isPartOfMission(_ label: String) -> Bool {
        mission.targetObjectLabels.contains(label)
    }
    
    /// Verifica si un objeto ya fue encontrado
    func isObjectFound(_ label: String) -> Bool {
        mission.isObjectFound(label)
    }
}
