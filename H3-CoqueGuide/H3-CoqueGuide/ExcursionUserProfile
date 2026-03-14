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
    var name: String
    var age: Int
    var excursionPreferences: [String]
    var availableTime: String
    var specificSearch: String
    var preferredLanguage: String
    var aiDescriptionText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        age: Int = 0,
        excursionPreferences: [String] = [],
        availableTime: String = "",
        specificSearch: String = "",
        preferredLanguage: String = "",
        aiDescriptionText: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.excursionPreferences = excursionPreferences
        self.availableTime = availableTime
        self.specificSearch = specificSearch
        self.preferredLanguage = preferredLanguage
        self.aiDescriptionText = aiDescriptionText
        self.updatedAt = updatedAt
    }
}
