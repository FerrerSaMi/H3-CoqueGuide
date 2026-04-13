//
//  ExcursionUserProfile.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//

import Foundation
import SwiftData

@Model
final class ExcursionUserProfile {
    var id: UUID
    var gender: String
    var ageRange: String
    var plannedTime: String
    var attractionPreference: String
    var resolvedAttractionPreference: String
    var specificAttraction: String
    var preferredLanguage: String
    var coquePersonality: String
    var aiDescriptionText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        gender: String = "",
        ageRange: String = "",
        plannedTime: String = "",
        attractionPreference: String = "",
        resolvedAttractionPreference: String = "",
        specificAttraction: String = "",
        preferredLanguage: String = "",
        coquePersonality: String = "",
        aiDescriptionText: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.gender = gender
        self.ageRange = ageRange
        self.plannedTime = plannedTime
        self.attractionPreference = attractionPreference
        self.resolvedAttractionPreference = resolvedAttractionPreference
        self.specificAttraction = specificAttraction
        self.preferredLanguage = preferredLanguage
        self.coquePersonality = coquePersonality
        self.aiDescriptionText = aiDescriptionText
        self.updatedAt = updatedAt
    }
}
