//
//  CGMessage.swift
//  CoqueGuideAI
//
//  Modelos de datos para el módulo CoqueGuide.
//  Estos tipos son la fuente de verdad para la capa de UI y el ViewModel.
//

import Foundation

// MARK: - Remitente del mensaje

/// Identifica el origen de cada mensaje en la conversación.
enum CGSender {
    case user        // Mensaje enviado por el visitante
    case coqueGuide  // Respuesta generada por CoqueGuide
}

// MARK: - Mensaje de conversación

/// Representa un mensaje individual dentro del panel de CoqueGuide.
/// Soporta texto plano, tarjetas de acción, o ambos.
struct CGMessage: Identifiable {
    let id: UUID
    let text: String?
    let cards: [CGActionCard]
    let sender: CGSender
    let timestamp: Date

    // MARK: Factories

    static func userMessage(_ text: String) -> CGMessage {
        CGMessage(id: UUID(), text: text, cards: [], sender: .user, timestamp: Date())
    }

    static func guideMessage(_ text: String) -> CGMessage {
        CGMessage(id: UUID(), text: text, cards: [], sender: .coqueGuide, timestamp: Date())
    }

    static func guideMessage(_ text: String?, cards: [CGActionCard]) -> CGMessage {
        CGMessage(id: UUID(), text: text, cards: cards, sender: .coqueGuide, timestamp: Date())
    }
}

// MARK: - Sugerencia proactiva

/// Sugerencia contextual no invasiva que CoqueGuide muestra al visitante
/// sin que este lo haya solicitado explícitamente.
struct CGSuggestion: Identifiable {
    let id: UUID
    let text: String   // Texto mostrado en el banner
    let icon: String   // Nombre del SF Symbol representativo

    init(text: String, icon: String) {
        self.id = UUID()
        self.text = text
        self.icon = icon
    }
}

// MARK: - Acción rápida

/// Chip de acción rápida que el visitante puede tocar para
/// enviar un mensaje predefinido sin tener que escribirlo.
struct CGQuickAction: Identifiable {
    let id: UUID
    let title: String   // Etiqueta visible en el chip
    let icon: String    // SF Symbol del chip
    let message: String // Texto que se enviará como mensaje al seleccionar esta acción

    init(title: String, icon: String, message: String) {
        self.id = UUID()
        self.title = title
        self.icon = icon
        self.message = message
    }
}

// MARK: - Catálogo de acciones rápidas predeterminadas

extension CGQuickAction {
    /// Conjunto predeterminado de acciones rápidas disponibles en el panel.
    static let defaults: [CGQuickAction] = [
        CGQuickAction(
            title: "Ver mapa",
            icon: "map",
            message: "¿Puedes mostrarme el mapa del museo?"
        ),
        CGQuickAction(
            title: "Eventos",
            icon: "calendar",
            message: "¿Qué eventos hay disponibles hoy?"
        ),
        CGQuickAction(
            title: "Escanear objeto",
            icon: "qrcode.viewfinder",
            message: "¿Cómo escaneo un objeto del museo?"
        ),
        CGQuickAction(
            title: "Cambiar idioma",
            icon: "globe",
            message: "¿En qué idiomas está disponible la guía?"
        ),
        CGQuickAction(
            title: "Accesibilidad",
            icon: "figure.roll",
            message: "¿Qué servicios de accesibilidad tiene el museo?"
        ),
    ]
}

// MARK: - Contenido de tarjeta invitadora Home

/// Contenido reutilizable para la tarjeta de invitacion de CoqueGuide en la pantalla de inicio.
struct CGHomeInviteContent {
    let title: String
    let message: String
    let quickActions: [CGQuickAction]

    static let `default` = CGHomeInviteContent(
        title: "CoqueGuide",
        message: "¡Bienvenido! ¿Cómo puedo ayudarte en tu visita?",
        quickActions: [
            CGQuickAction(
                title: "¿Dónde estoy?",
                icon: "location.fill",
                message: "¿Dónde estoy en el museo?"
            ),
            CGQuickAction(
                title: "Ver mapa",
                icon: "map.fill",
                message: "¿Puedes mostrarme el mapa del museo?"
            ),
            CGQuickAction(
                title: "Próximo evento",
                icon: "calendar",
                message: "¿Cuál es el próximo evento?"
            )
        ]
    )
}
