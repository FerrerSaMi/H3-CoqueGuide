//
//  SurveyQuestion.swift
//  H3-CoqueGuide
//
//  Created by Santiago on 30/03/26.
//

import Foundation

enum SurveyStep: Int, CaseIterable {
    case gender
    case ageRange
    case plannedTime
    case attractionPreference
    case specificAttraction
    case language
    case coquePersonality

    var title: String {
        switch self {
        case .gender:
            return "¿Cuál es tu género?"
        case .ageRange:
            return "¿En qué rango de edad estás?"
        case .plannedTime:
            return "Tiempo planeado para el recorrido"
        case .attractionPreference:
            return "Preferencias para atracciones"
        case .specificAttraction:
            return "¿Vienes por alguna atracción en específico?"
        case .language:
            return "Lenguaje para tu recorrido"
        case .coquePersonality:
            return "¿Cómo prefieres la personalidad de guía “Coque”?"
        }
    }

    var options: [String] {
        switch self {
        case .gender:
            return [
                "Hombre",
                "Mujer",
                "Prefiero no decir"
            ]
        case .ageRange:
            return [
                "18 o menos",
                "19 - 29",
                "30 - 50",
                "50 o más"
            ]
        case .plannedTime:
            return [
                "1 hora o menos",
                "1 - 2 horas",
                "2 - 3 horas",
                "3 horas o más"
            ]
        case .attractionPreference:
            return [
                "Interacción",
                "Galerías de objetos",
                "Shows",
                "Escuchar historia",
                "Todos",
                "Recomendado"
            ]
        case .specificAttraction:
            return [
                "Galería historia",
                "Acería",
                "Reacción en cadena",
                "Restaurante",
                "Mirador",
                "Shows",
                "Paseo por hornos",
                "No"
            ]
        case .language:
            return [
                "Español",
                "English",
                "Français",
                "Português",
                "Korean",
                "Arabic"
            ]
        case .coquePersonality:
            return [
                "Formal",
                "Neutral",
                "Divertido",
                "Datos curiosos",
                "Para niños",
                "Historiador"
            ]
        }
    }

    var columns: Int {
        switch self {
        case .gender:
            return 1
        case .ageRange:
            return 2
        case .plannedTime:
            return 2
        case .attractionPreference:
            return 2
        case .specificAttraction:
            return 2
        case .language:
            return 2
        case .coquePersonality:
            return 2
        }
    }
}

enum SurveyScreen {
    case home
    case question
    case description
}
