//
//  SurveyViewModel.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var ageText: String = ""
    @Published var selectedPreferences: Set<String> = []
    @Published var availableTime: String = ""
    @Published var specificSearch: String = ""
    @Published var preferredLanguage: String = "Español"
    @Published var selectedCoquePersonality: String = "Neutral"
    @Published var aiDescription: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let allPreferences = ["Interactuar", "Ver", "Escuchar", "Shows", "Todos"]
    let languageOptions = ["Español", "English", "Français", "Português", "Japanese", "Korean"]
    let coquePersonalityOptions = ["Formal", "Neutral", "Con datos curiosos", "Chistes", "Para niños"]

    private let aiService = SurveyAIService()

    func loadExistingProfile(from context: ModelContext) {
        let descriptor = FetchDescriptor<ExcursionUserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let profiles = try context.fetch(descriptor)
            guard let latest = profiles.first else { return }

            name = latest.name
            ageText = latest.age > 0 ? "\(latest.age)" : ""
            selectedPreferences = Set(latest.excursionPreferences)
            availableTime = latest.availableTime
            specificSearch = latest.specificSearch
            preferredLanguage = latest.preferredLanguage
            selectedCoquePersonality = latest.coquePersonality
            aiDescription = latest.aiDescriptionText
        } catch {
            errorMessage = "No se pudo cargar la encuesta guardada."
        }
    }

    func saveSurvey(in context: ModelContext) async {
        errorMessage = nil

        guard validateFields() else { return }
        guard let age = Int(ageText), age > 0 else {
            errorMessage = "Ingresa una edad valida."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            let profiles = try context.fetch(descriptor)

            let profile: ExcursionUserProfile
            if let existing = profiles.first {
                profile = existing
            } else {
                profile = ExcursionUserProfile()
                context.insert(profile)
            }

            profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.age = age
            profile.excursionPreferences = Array(selectedPreferences)
            profile.availableTime = availableTime.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.specificSearch = specificSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.preferredLanguage = preferredLanguage
            profile.coquePersonality = selectedCoquePersonality
            profile.updatedAt = .now

            let generatedDescription = try await aiService.generateDescription(for: profile)
            profile.aiDescriptionText = generatedDescription
            aiDescription = generatedDescription

            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validateFields() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Escribe tu nombre."
            return false
        }

        if ageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Escribe tu edad."
            return false
        }

        if availableTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Escribe cuanto tiempo tienes para la excursion."
            return false
        }

        if preferredLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Selecciona un idioma."
            return false
        }
        
        if selectedCoquePersonality.isEmpty {
            errorMessage = "Selecciona una personalidad."
            return false
        }

        return true
    }

    func togglePreference(_ preference: String) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }
}
