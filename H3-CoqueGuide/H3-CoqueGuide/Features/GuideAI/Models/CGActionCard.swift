//
//  CGActionCard.swift
//  CoqueGuideAI
//
//  Modelos para tarjetas de acción interactivas y navegación.
//

import SwiftUI

// MARK: - Destinos de navegación de la app

enum CGAppDestination: Hashable {
    case map
    case events
    case scanning
    case survey
    case chatbot
}

// MARK: - Acción al tocar una tarjeta

enum CGCardAction {
    case navigate(CGAppDestination)
    case sendMessage(String)
}

// MARK: - Tipo visual de tarjeta

enum CGCardType {
    case event
    case map
    case scan
    case info

    var actionLabel: String {
        switch self {
        case .event: return "Ver evento"
        case .map:   return "Ir al mapa"
        case .scan:  return "Abrir escáner"
        case .info:  return "Más información"
        }
    }

    var defaultIcon: String {
        switch self {
        case .event: return "calendar"
        case .map:   return "map"
        case .scan:  return "qrcode.viewfinder"
        case .info:  return "info.circle"
        }
    }
}

// MARK: - Tarjeta de acción

struct CGActionCard: Identifiable {
    let id: UUID
    let cardType: CGCardType
    let title: String
    let subtitle: String?
    let description: String?
    let icon: String
    let action: CGCardAction?

    init(
        cardType: CGCardType,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        action: CGCardAction? = nil
    ) {
        self.id = UUID()
        self.cardType = cardType
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.icon = icon ?? cardType.defaultIcon
        self.action = action
    }
}
