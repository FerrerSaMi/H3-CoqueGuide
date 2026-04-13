//
//  CGViewModel.swift
//  CoqueGuideAI
//
//  ViewModel principal del módulo CoqueGuide.
//  Gestiona el estado de la conversación, las sugerencias proactivas
//  y sirve como punto de coordinación entre la UI y el servicio de IA.
//

import SwiftUI
import Combine

@MainActor
final class CGViewModel: ObservableObject {

    // MARK: - Estado publicado (vinculado a la UI)

    /// Lista de mensajes en la conversación actual.
    @Published private(set) var messages: [CGMessage] = []

    /// Indica si CoqueGuide está procesando una respuesta (muestra indicador de escritura).
    @Published private(set) var isThinking: Bool = false

    /// Controla la presentación del panel de conversación.
    @Published var isPanelOpen: Bool = false

    /// Sugerencia proactiva actualmente visible. `nil` = oculta.
    @Published private(set) var activeSuggestion: CGSuggestion? = nil

    /// Número de sugerencias sin leer (mostrado como badge en el botón flotante).
    @Published private(set) var pendingSuggestionsCount: Int = 0

    /// Mensaje pendiente que se enviará automáticamente al abrir el panel.
    @Published var pendingMessage: String? = nil

    // MARK: - Dependencias

    private let aiService: CGAIServiceProtocol
    private var suggestionTimer: Timer?

    // MARK: - Inicialización

    /// - Parameter aiService: Servicio de IA a usar. Por defecto usa la implementación simulada.
    ///   Para conectar una API real, pasa una instancia que conforme a `CGAIServiceProtocol`.
    init(aiService: CGAIServiceProtocol = CGSimulatedAIService()) {
        self.aiService = aiService
        startProactiveSuggestions()
    }

    deinit {
        suggestionTimer?.invalidate()
    }

    // MARK: - API pública

    /// Abre el panel de conversación.
    /// Muestra el mensaje de bienvenida si la conversación está vacía.
    func openPanel() {
        isPanelOpen = true
        activeSuggestion = nil
        pendingSuggestionsCount = 0

        if messages.isEmpty {
            showWelcomeMessage()
        }
    }

    /// Abre el panel y envía un mensaje automáticamente una vez que esté listo.
    func openPanelWithMessage(_ message: String) {
        pendingMessage = message
        openPanel()
    }

    /// Envía un mensaje del usuario y solicita respuesta al servicio de IA.
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            messages.append(.userMessage(trimmed))
        }
        fetchResponse(for: trimmed)
    }

    /// Envía el mensaje predefinido asociado a una acción rápida.
    func handleQuickAction(_ action: CGQuickAction) {
        sendMessage(action.message)
    }

    /// Descarta la sugerencia proactiva activa sin enviarla como mensaje.
    func dismissSuggestion() {
        withAnimation(.easeOut(duration: 0.25)) {
            activeSuggestion = nil
        }
    }

    /// Acepta la sugerencia proactiva: abre el panel y la envía como mensaje.
    func acceptSuggestion(_ suggestion: CGSuggestion) {
        dismissSuggestion()
        openPanel()
        sendMessage(suggestion.text)
    }

    // MARK: - Internals

    private func showWelcomeMessage() {
        let welcome = CGMessage.guideMessage(
            "¡Hola! Soy **CoqueGuide**, tu asistente en el Museo del Acero Horno3. 🏭\n\n" +
            "Puedo ayudarte con orientación, eventos, escaneo de objetos y accesibilidad.\n\n" +
            "¿En qué te puedo ayudar hoy?"
        )
        // Pequeño retraso para que la apertura del panel sea visible antes del mensaje
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self?.messages.append(welcome)
            }
        }
    }

    private func fetchResponse(for text: String) {
        isThinking = true

        Task {
            let response = await aiService.processMessage(text)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isThinking = false
                messages.append(.guideMessage(response.text, cards: response.cards))
            }
        }
    }

    // MARK: - Sugerencias proactivas

    /// Catálogo de sugerencias contextuales que CoqueGuide puede mostrar al visitante.
    private let proactiveSuggestions: [CGSuggestion] = [
        CGSuggestion(
            text: "¿Quieres ver el mapa del museo?",
            icon: "map"
        ),
        CGSuggestion(
            text: "¿Sabías que hay una visita guiada disponible hoy?",
            icon: "person.wave.2"
        ),
        CGSuggestion(
            text: "¿Necesitas información sobre accesibilidad?",
            icon: "figure.roll"
        ),
        CGSuggestion(
            text: "Puedes escanear cualquier pieza del museo para saber más.",
            icon: "qrcode.viewfinder"
        ),
        CGSuggestion(
            text: "¿Quieres conocer los horarios y precios de entrada?",
            icon: "ticket"
        ),
        CGSuggestion(
            text: "¿Hay algo en lo que pueda ayudarte durante tu visita?",
            icon: "sparkles"
        ),
    ]

    /// Inicia el ciclo de sugerencias proactivas con temporizador.
    private func startProactiveSuggestions() {
        // Primera sugerencia después de 10 segundos (cuando el usuario ya conoce la app)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.showNextSuggestion()
        }

        // Sugerencias adicionales cada 35 segundos, solo si el panel está cerrado
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: 35, repeats: true) { [weak self] _ in
            guard let self, !self.isPanelOpen else { return }
            self.showNextSuggestion()
        }
    }

    private func showNextSuggestion() {
        // No muestra si el panel está abierto o hay una sugerencia visible
        guard !isPanelOpen, activeSuggestion == nil else { return }

        let suggestion = proactiveSuggestions.randomElement()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            activeSuggestion = suggestion
            pendingSuggestionsCount += 1
        }

        // Auto-descarta después de 7 segundos para no ser invasiva
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.activeSuggestion = nil
            }
        }
    }
}
