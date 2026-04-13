//
//  SurveyViewModel.swift
//  H3-CoqueGuide
//
//  Created by Santiago Ferrer on 13/03/26.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var currentScreen: SurveyScreen = .home
    @Published var currentStepIndex: Int = 0

    @Published var gender: String = ""
    @Published var ageRange: String = ""
    @Published var plannedTime: String = ""
    @Published var attractionPreference: String = ""
    @Published var resolvedAttractionPreference: String = ""
    @Published var specificAttraction: String = ""
    @Published var preferredLanguage: String = "Español"
    @Published var selectedCoquePersonality: String = "Neutral"

    @Published var aiDescription: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let aiService = SurveyAIService()

    let steps = SurveyStep.allCases

    var currentStep: SurveyStep {
        steps[currentStepIndex]
    }

    var progressText: String {
        "Pregunta \(currentStepIndex + 1) de \(steps.count)"
    }
    
    var hasCompletedSurvey: Bool {
        !gender.isEmpty &&
        !ageRange.isEmpty &&
        !plannedTime.isEmpty &&
        !attractionPreference.isEmpty &&
        !specificAttraction.isEmpty &&
        !preferredLanguage.isEmpty &&
        !selectedCoquePersonality.isEmpty &&
        !aiDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSendToCoque: Bool {
        hasCompletedSurvey && !isLoading
    }

    func loadExistingProfile(from context: ModelContext) {
        let descriptor = FetchDescriptor<ExcursionUserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let profiles = try context.fetch(descriptor)
            guard let latest = profiles.first else { return }

            gender = latest.gender
            ageRange = latest.ageRange
            plannedTime = latest.plannedTime
            attractionPreference = latest.attractionPreference
            resolvedAttractionPreference = latest.resolvedAttractionPreference
            specificAttraction = latest.specificAttraction
            preferredLanguage = latest.preferredLanguage
            selectedCoquePersonality = latest.coquePersonality
            aiDescription = latest.aiDescriptionText
        } catch {
            errorMessage = "No se pudo cargar la encuesta guardada."
        }
    }

    func startSurvey() {
        resetAnswers()
        currentStepIndex = 0
        errorMessage = nil
        currentScreen = .question
    }

    func openDescription() {
        currentScreen = .description
    }

    func backToHome() {
        currentScreen = .home
    }

    func goBackOneStepOrHome() {
        errorMessage = nil

        if currentStepIndex > 0 {
            currentStepIndex -= 1
        } else {
            currentScreen = .home
        }
    }

    func selectOption(_ option: String, in context: ModelContext) {
        errorMessage = nil

        switch currentStep {
        case .gender:
            gender = option

        case .ageRange:
            ageRange = option

        case .plannedTime:
            plannedTime = option

        case .attractionPreference:
            attractionPreference = option
            resolvedAttractionPreference = option == "Recomendado"
                ? recommendedAttractionPreference()
                : option

        case .specificAttraction:
            specificAttraction = option

        case .language:
            preferredLanguage = option

        case .coquePersonality:
            selectedCoquePersonality = option
        }

        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        } else {
            Task {
                await finishSurvey(in: context)
            }
        }
    }

    func optionIsSelected(_ option: String) -> Bool {
        switch currentStep {
        case .gender:
            return gender == option
        case .ageRange:
            return ageRange == option
        case .plannedTime:
            return plannedTime == option
        case .attractionPreference:
            return attractionPreference == option
        case .specificAttraction:
            return specificAttraction == option
        case .language:
            return preferredLanguage == option
        case .coquePersonality:
            return selectedCoquePersonality == option
        }
    }

    private func finishSurvey(in context: ModelContext) async {
        guard validateAnswers() else { return }

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

            profile.gender = gender
            profile.ageRange = ageRange
            profile.plannedTime = plannedTime
            profile.attractionPreference = attractionPreference
            profile.resolvedAttractionPreference = resolvedAttractionPreference
            profile.specificAttraction = specificAttraction
            profile.preferredLanguage = preferredLanguage
            profile.coquePersonality = selectedCoquePersonality
            profile.updatedAt = .now
            profile.aiDescriptionText = ""

            let generatedDescription = try await aiService.generateDescription(for: profile)
            profile.aiDescriptionText = generatedDescription
            aiDescription = generatedDescription

            try context.save()
            currentScreen = .description
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeCoqueRoutePrompt() -> String {
        let cleanDescription = aiDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let specificGoal = specificAttraction == "No"
            ? "No viene por una atracción específica; puedes priorizar lo más valioso según su perfil."
            : "Quiere incluir especialmente: \(specificAttraction)."

        return """
        Quiero que actúes como Coque, el guía del museo Horno3, y me armes una ruta personalizada basada en la encuesta del visitante.

        Debes responder únicamente en \(routeOutputLanguageInstruction()).

        Quiero un guion narrado por ti, como si fueras acompañando al visitante durante el recorrido.

        Usa este formato:

        **PRIMERO: [nombre del lugar o experiencia]**
        Explica qué verá o hará aquí, cuánto tiempo aproximado puede estar, y por qué este punto conecta con sus gustos.

        **LUEGO: [nombre del lugar o experiencia]**
        Continúa la ruta con el mismo estilo.

        **DESPUÉS: [nombre del lugar o experiencia]**
        Sigue la secuencia del recorrido como si fueras su guía.

        Puedes agregar más paradas si el tiempo lo permite. Termina con una despedida breve.

        Perfil del visitante:
        - Género: \(gender)
        - Edad: \(ageRange)
        - Tiempo disponible: \(plannedTime)
        - Preferencia principal: \(attractionPreference)
        - Preferencia final: \(resolvedAttractionPreference)
        - Idioma preferido: \(preferredLanguage)
        - Personalidad de Coque: \(selectedCoquePersonality)
        - Objetivo específico: \(specificGoal)

        Descripción generada:
        \(cleanDescription)
        """
    }

    private func routeOutputLanguageInstruction() -> String {
        switch preferredLanguage {
        case "Español":
            return "español"
        case "English":
            return "English"
        case "Français":
            return "français"
        case "Português":
            return "português"
        case "Korean":
            return "Korean"
        case "Arabic":
            return "Arabic"
        default:
            return "español"
        }
    }
    
    private func validateAnswers() -> Bool {
        if gender.isEmpty {
            errorMessage = "Falta seleccionar el género."
            return false
        }

        if ageRange.isEmpty {
            errorMessage = "Falta seleccionar el rango de edad."
            return false
        }

        if plannedTime.isEmpty {
            errorMessage = "Falta seleccionar el tiempo del recorrido."
            return false
        }

        if attractionPreference.isEmpty {
            errorMessage = "Falta seleccionar la preferencia de atracciones."
            return false
        }

        if specificAttraction.isEmpty {
            errorMessage = "Falta seleccionar si buscas algo específico."
            return false
        }

        if preferredLanguage.isEmpty {
            errorMessage = "Falta seleccionar el idioma."
            return false
        }

        if selectedCoquePersonality.isEmpty {
            errorMessage = "Falta seleccionar la personalidad de Coque."
            return false
        }

        return true
    }

    private func resetAnswers() {
        gender = ""
        ageRange = ""
        plannedTime = ""
        attractionPreference = ""
        resolvedAttractionPreference = ""
        specificAttraction = ""
        preferredLanguage = "Español"
        selectedCoquePersonality = "Neutral"
    }

    private func recommendedAttractionPreference() -> String {
        if selectedCoquePersonality == "Para niños" || ageRange == "18 o menos" {
            return "Interacción"
        }

        if selectedCoquePersonality == "Historiador" {
            return "Escuchar historia"
        }

        if plannedTime == "1 hora o menos" {
            return "Shows"
        }

        if plannedTime == "3 horas o más" {
            return "Todos"
        }

        if selectedCoquePersonality == "Datos curiosos" {
            return "Galerías de objetos"
        }

        return "Interacción"
    }
}
