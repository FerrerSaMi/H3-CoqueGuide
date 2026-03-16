//
//  CGAIService.swift
//  CoqueGuideAI
//
//  Servicio de IA del módulo CoqueGuide.
//
//  ARQUITECTURA PARA EVOLUCIÓN:
//  ─────────────────────────────────────────────────────────────────────────────
//  El protocolo `CGAIServiceProtocol` desacopla la lógica de IA de la UI.
//  Para conectar una API real (OpenAI, Claude, etc.) basta con:
//    1. Crear una clase que conforme a `CGAIServiceProtocol`.
//    2. Inyectarla en CGViewModel durante la inicialización.
//  No se necesita modificar ninguna vista.
//  ─────────────────────────────────────────────────────────────────────────────

import Foundation

// MARK: - Respuesta estructurada del servicio de IA

/// Respuesta que puede contener texto, tarjetas de acción, o ambos.
struct CGAIResponse {
    let text: String?
    let cards: [CGActionCard]

    static func textOnly(_ text: String) -> CGAIResponse {
        CGAIResponse(text: text, cards: [])
    }

    static func withCards(_ text: String?, cards: [CGActionCard]) -> CGAIResponse {
        CGAIResponse(text: text, cards: cards)
    }
}

// MARK: - Protocolo del servicio de IA

/// Contrato que debe cumplir cualquier implementación del servicio de IA.
/// Permite intercambiar fácilmente la implementación simulada por una real.
protocol CGAIServiceProtocol {
    /// Recibe el texto del usuario y devuelve una respuesta estructurada.
    func processMessage(_ text: String) async -> CGAIResponse
}

// MARK: - Servicio simulado (sin dependencias externas)

/// Implementación simulada que responde mediante coincidencia de palabras clave.
/// Incluye un retraso artificial para representar latencia de red.
final class CGSimulatedAIService: CGAIServiceProtocol {

    // MARK: - Procesamiento de mensajes

    func processMessage(_ text: String) async -> CGAIResponse {
        let delay = Double.random(in: 0.7...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return buildResponse(for: text.lowercased())
    }

    // MARK: - Motor de reglas por palabras clave

    private func buildResponse(for input: String) -> CGAIResponse {
        switch true {

        case input.containsAny(["mapa", "ubicación", "donde", "dónde", "cómo llego",
                                 "orientación", "plano", "ruta", "perdido", "zona"]):
            return orientationResponse()

        case input.containsAny(["evento", "actividad", "show", "visita guiada",
                                 "programa", "agenda", "horario de actividades", "tour"]):
            return eventsResponse()

        case input.containsAny(["escanear", "escaneo", "qr", "código qr",
                                 "código", "objeto", "pieza", "scan", "cámara"]):
            return scanningResponse()

        case input.containsAny(["idioma", "language", "inglés", "english",
                                 "español", "francés", "alemán", "traducción", "traducir"]):
            return .textOnly(languagesResponse())

        case input.containsAny(["accesibilidad", "discapacidad", "silla de ruedas",
                                 "rampa", "audífonos", "braille", "necesidades especiales",
                                 "movilidad reducida"]):
            return .textOnly(accessibilityResponse())

        case input.containsAny(["horario", "hora de apertura", "abre", "cierra",
                                 "entrada", "precio", "costo", "boleto", "tarifa",
                                 "cuánto", "gratis", "gratuito"]):
            return .textOnly(admissionResponse())

        case input.containsAny(["museo", "horno3", "horno 3", "acero", "industrial",
                                 "historia", "fundación", "monterrey", "fundidora"]):
            return .textOnly(museumInfoResponse())

        case input.containsAny(["comer", "comida", "restaurante", "cafetería",
                                 "baño", "sanitario", "tienda", "souvenirs",
                                 "estacionamiento", "parqueo"]):
            return .textOnly(servicesResponse())

        case input.containsAny(["hola", "buenos días", "buenas tardes", "buenas noches",
                                 "buenas", "hi", "hello", "hey", "qué tal"]):
            return .textOnly(greetingResponse())

        case input.containsAny(["gracias", "thanks", "thank you", "perfecto",
                                 "excelente", "de acuerdo", "entendido", "ok"]):
            return .textOnly("¡Con gusto! Estoy aquí si tienes más preguntas durante tu visita. 😊")

        case input.containsAny(["ayuda", "help", "qué puedes", "qué haces",
                                 "funciones", "capacidades"]):
            return .textOnly(helpResponse())

        default:
            return .textOnly(defaultResponse())
        }
    }

    // MARK: - Respuestas con tarjetas de acción

    private func orientationResponse() -> CGAIResponse {
        let text = [
            "El museo Horno3 tiene dos niveles principales. 🗺️\n\n**Nivel 1:** Exhibiciones históricas y el Horno Alto original\n**Nivel 2:** Galería industrial y mirador panorámico",
            "¡Claro! Puedo orientarte. 📍\n\nEl punto de información principal está en la **entrada principal** (Nivel 1). Desde ahí puedes acceder a todos los niveles mediante rampas y elevadores."
        ].randomElement()!

        let mapCard = CGActionCard(
            cardType: .map,
            title: "Mapa del museo",
            subtitle: "Niveles 1 y 2",
            description: "Consulta el plano interactivo del museo",
            action: .navigate(.map)
        )

        return .withCards(text, cards: [mapCard])
    }

    private func eventsResponse() -> CGAIResponse {
        let events = CGEventService.shared.todaysEvents()
        let text = "🗓️ **Actividades de hoy en Horno3:**"

        let cards = events.map { event in
            CGActionCard(
                cardType: .event,
                title: event.name,
                subtitle: event.time + " · " + event.location,
                description: event.description,
                icon: event.icon,
                action: .navigate(.events)
            )
        }

        return .withCards(text, cards: cards)
    }

    private func scanningResponse() -> CGAIResponse {
        let text = "Para escanear un objeto del museo: 📷\n\n1. Apunta la cámara al **código QR** o a la placa informativa\n2. Recibirás información detallada, historia y contenido multimedia"

        let scanCard = CGActionCard(
            cardType: .scan,
            title: "Abrir escáner",
            subtitle: "Escanea códigos QR de las exhibiciones",
            description: "Casi todas las piezas del museo cuentan con código QR.",
            action: .navigate(.scanning)
        )

        return .withCards(text, cards: [scanCard])
    }

    // MARK: - Respuestas de solo texto

    private func languagesResponse() -> String {
        "🌍 **Idiomas disponibles en CoqueGuide:**\n\n• 🇲🇽 Español\n• 🇺🇸 English\n• 🇫🇷 Français\n\nPuedes cambiar el idioma tocando **Cambiar idioma** en las acciones rápidas o en los ajustes de la app.\n\nLas cartelas de las exhibiciones también están en **español e inglés**."
    }

    private func accessibilityResponse() -> String {
        "♿ **Servicios de accesibilidad en Horno3:**\n\n• Rampas y elevadores en todos los niveles\n• Audioguías disponibles en recepción (sin costo adicional)\n• Material en braille en exhibiciones seleccionadas\n• Estacionamiento preferencial en la entrada\n• Personal de apoyo disponible en recepción\n• Sanitarios adaptados en cada nivel\n\n¿Necesitas algún servicio específico? Nuestro equipo puede asistirte en la entrada."
    }

    private func admissionResponse() -> String {
        "🎟️ **Horarios y tarifas de Horno3:**\n\n**Horario:**\n• Martes a Domingo: 10:00 – 18:00 h\n• Lunes: Cerrado\n\n**Precios de entrada:**\n• General: $80 MXN\n• Niños (3–12 años): $40 MXN\n• Adultos mayores: $40 MXN\n• Menores de 3 años: **Gratis**\n• Grupos (+15 personas): Consultar en taquilla\n\n¿Necesitas información sobre visitas especiales o grupos escolares?"
    }

    private func museumInfoResponse() -> String {
        "🏭 **Museo del Acero Horno3**\n\nEspacio cultural único construido sobre el antiguo **Horno Alto Número 3** de la Fundidora de Monterrey. Inaugurado en 2007, combina historia industrial, arte contemporáneo y tecnología interactiva.\n\nEl horno fue operado entre **1910 y 1986**, y es parte fundamental de la identidad industrial de México y de Monterrey."
    }

    private func servicesResponse() -> String {
        "🛎️ **Servicios disponibles en el museo:**\n\n• 🍽️ Restaurante 'La Fundición' – Nivel 1\n• ☕ Cafetería – Planta baja (junto a la entrada)\n• 🛍️ Tienda de souvenirs – Planta baja\n• 🚗 Estacionamiento gratuito para visitantes\n• 🚻 Sanitarios en cada nivel\n• 🔌 Área de carga de dispositivos – Nivel 1\n\n¿Necesitas indicaciones para llegar a alguno de estos espacios?"
    }

    private func greetingResponse() -> String {
        [
            "¡Hola! Soy **CoqueGuide**, tu asistente inteligente en el Museo del Acero Horno3. 👋\n\nPuedo ayudarte con orientación, eventos, escaneo de objetos, accesibilidad y mucho más. ¿En qué te puedo ayudar hoy?",
            "¡Bienvenido al **Museo Horno3**! 🏭\n\nEstoy aquí para hacer tu visita más completa y memorable. Puedo orientarte, contarte sobre las exhibiciones y ayudarte con cualquier duda.\n\n¿Por dónde empezamos?"
        ].randomElement()!
    }

    private func helpResponse() -> String {
        "Puedo ayudarte con: 💡\n\n• 🗺️ **Orientación** dentro del museo\n• 🗓️ **Eventos** y actividades del día\n• 📷 **Escaneo** de objetos y piezas\n• 🌍 **Idiomas** disponibles\n• ♿ **Accesibilidad** y servicios\n• 🎟️ **Horarios** y precios de entrada\n• 🏭 **Historia** del museo\n\nEscribe tu pregunta o usa los botones de acciones rápidas."
    }

    private func defaultResponse() -> String {
        [
            "Entiendo tu pregunta. En este momento puedo ayudarte con orientación, eventos, escaneo de objetos, idiomas y accesibilidad. ¿Quieres explorar alguno de estos temas? 😊",
            "No tengo esa información exacta ahora mismo, pero puedes preguntar en el **punto de información** ubicado en la entrada principal. ¿Hay algo más en lo que pueda ayudarte?",
            "¡Buena pregunta! Te recomiendo consultar con nuestro equipo en recepción para obtener información más detallada. Mientras tanto, puedo ayudarte con el mapa, eventos o accesibilidad. 🙌"
        ].randomElement()!
    }
}

// MARK: - Extensión auxiliar privada

private extension String {
    func containsAny(_ keywords: [String]) -> Bool {
        keywords.contains { self.contains($0) }
    }
}
