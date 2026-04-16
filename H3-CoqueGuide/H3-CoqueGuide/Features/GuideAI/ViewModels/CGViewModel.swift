//
//  CGViewModel.swift
//  CoqueGuideAI
//
//  ViewModel principal del módulo CoqueGuide.
//  Gestiona el estado de la conversación, las sugerencias proactivas
//  y sirve como punto de coordinación entre la UI y el servicio de IA.
//

import SwiftUI
import SwiftData
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

    private var aiService: CGAIServiceProtocol
    private var suggestionTimer: Timer?

    // MARK: - Inicialización

    /// - Parameter aiService: Servicio de IA a usar. Por defecto usa la implementación simulada.
    ///   Para conectar una API real, pasa una instancia que conforme a `CGAIServiceProtocol`.
    init(aiService: CGAIServiceProtocol = CGSimulatedAIService()) {
        self.aiService = aiService
        startProactiveSuggestions()
    }

    // MARK: - Perfil del visitante

    /// Carga el perfil más reciente de SwiftData y lo pasa al servicio de IA.
    func loadVisitorProfile(from context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            if let profile = try context.fetch(descriptor).first,
               !profile.gender.isEmpty {
                aiService.visitorProfile = CGVisitorProfile(from: profile)
            }
        } catch {
            print("⚠️ No se pudo cargar el perfil del visitante: \(error)")
        }
    }

    deinit {
        suggestionTimer?.invalidate()
    }

    // MARK: - API pública

    /// Abre el panel de conversación.
    /// Muestra el mensaje de bienvenida si la conversación está vacía y no hay mensaje pendiente.
    func openPanel(initialMessage: String? = nil) {
        isPanelOpen = true
        activeSuggestion = nil
        pendingSuggestionsCount = 0

        if let initialMessage {
            sendMessage(initialMessage)
            return
        }

        // Si hay un mensaje pendiente, no mostramos welcome para evitar ruido visual
        if messages.isEmpty && pendingMessage == nil {
            showWelcomeMessage()
        }
    }

    /// Abre el panel y envía un mensaje automáticamente una vez que esté listo.
    func openPanelWithMessage(_ message: String) {
        if isPanelOpen {
            // El panel ya está abierto, enviar directamente
            sendMessage(message)
        } else {
            // Primero marcamos el mensaje pendiente, luego abrimos el panel
            // (el orden importa: openPanel chequea pendingMessage para decidir el welcome).
            pendingMessage = message
            openPanel()
        }
    }

    /// Abre el panel y envía un prompt silencioso al servicio de IA:
    /// solicita respuesta pero **no** muestra el prompt como mensaje del usuario.
    /// Útil para contextos largos (p. ej. el prompt de ruta generado tras la encuesta).
    func openPanelWithSilentPrompt(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isPanelOpen = true
        activeSuggestion = nil
        pendingSuggestionsCount = 0

        // Evita colisionar con otro mensaje pendiente que abriría el chat duplicado.
        pendingMessage = nil

        // Si ya está pensando (otra petición en vuelo), dejamos pasar la actual.
        guard !isThinking else { return }

        fetchResponse(for: trimmed)
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
        // Usa el idioma detectado del iPhone (L10n.cgWelcome lo resuelve).
        let welcome = CGMessage.guideMessage(L10n.cgWelcome)
        // Lo insertamos de forma síncrona para que ya esté visible cuando el sheet
        // termine de animarse; así evitamos el "trabón" perceptible de un delay +
        // animación encadenada al primer frame.
        messages.append(welcome)
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
    /// Es `var` computada para que los textos se resuelvan con el idioma actual del dispositivo.
    private var proactiveSuggestions: [CGSuggestion] {
        [
            CGSuggestion(text: L10n.suggestShowMap,      icon: "map"),
            CGSuggestion(text: L10n.suggestGuidedTour,   icon: "person.wave.2"),
            CGSuggestion(text: L10n.suggestAccessibility, icon: "figure.roll"),
            CGSuggestion(text: L10n.suggestScan,         icon: "qrcode.viewfinder"),
            CGSuggestion(text: L10n.suggestTickets,      icon: "ticket"),
            CGSuggestion(text: L10n.suggestHelp,         icon: "sparkles"),
        ]
    }

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
