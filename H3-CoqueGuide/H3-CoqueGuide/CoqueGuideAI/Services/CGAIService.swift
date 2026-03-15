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

// MARK: - Protocolo del servicio de IA

/// Contrato que debe cumplir cualquier implementación del servicio de IA.
/// Permite intercambiar fácilmente la implementación simulada por una real.
protocol CGAIServiceProtocol {
    /// Recibe el texto del usuario y devuelve la respuesta generada.
    func processMessage(_ text: String) async -> String
}

// MARK: - Servicio simulado (sin dependencias externas)

/// Implementación simulada que responde mediante coincidencia de palabras clave.
/// Incluye un retraso artificial para representar latencia de red.
///
/// Para conectar una API real, crea una nueva clase que conforme a
/// `CGAIServiceProtocol` e inyéctala en `CGViewModel`.
final class CGSimulatedAIService: CGAIServiceProtocol {

    // MARK: - Procesamiento de mensajes

    func processMessage(_ text: String) async -> String {
        // Simula latencia de red entre 0.7 y 1.5 segundos
        let delay = Double.random(in: 0.7...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return buildResponse(for: text.lowercased())
    }

    // MARK: - Motor de reglas por palabras clave

    private func buildResponse(for input: String) -> String {
        switch true {

        // Orientación y mapa
        case input.containsAny(["mapa", "ubicación", "donde", "dónde", "cómo llego",
                                 "orientación", "plano", "ruta", "perdido", "zona"]):
            return orientationResponse()

        // Eventos y actividades
        case input.containsAny(["evento", "actividad", "show", "visita guiada",
                                 "programa", "agenda", "horario de actividades", "tour"]):
            return eventsResponse()

        // Escaneo de objetos
        case input.containsAny(["escanear", "escaneo", "qr", "código qr",
                                 "código", "objeto", "pieza", "scan", "cámara"]):
            return scanningResponse()

        // Idiomas
        case input.containsAny(["idioma", "language", "inglés", "english",
                                 "español", "francés", "alemán", "traducción", "traducir"]):
            return languagesResponse()

        // Accesibilidad
        case input.containsAny(["accesibilidad", "discapacidad", "silla de ruedas",
                                 "rampa", "audífonos", "braille", "necesidades especiales",
                                 "movilidad reducida"]):
            return accessibilityResponse()

        // Horarios y precios de entrada
        case input.containsAny(["horario", "hora de apertura", "abre", "cierra",
                                 "entrada", "precio", "costo", "boleto", "tarifa",
                                 "cuánto", "gratis", "gratuito"]):
            return admissionResponse()

        // Información general del museo
        case input.containsAny(["museo", "horno3", "horno 3", "acero", "industrial",
                                 "historia", "fundación", "monterrey", "fundidora"]):
            return museumInfoResponse()

        // Restaurante y servicios
        case input.containsAny(["comer", "comida", "restaurante", "cafetería",
                                 "baño", "sanitario", "tienda", "souvenirs",
                                 "estacionamiento", "parqueo"]):
            return servicesResponse()

        // Saludo inicial
        case input.containsAny(["hola", "buenos días", "buenas tardes", "buenas noches",
                                 "buenas", "hi", "hello", "hey", "qué tal"]):
            return greetingResponse()

        // Agradecimiento
        case input.containsAny(["gracias", "thanks", "thank you", "perfecto",
                                 "excelente", "de acuerdo", "entendido", "ok"]):
            return "¡Con gusto! Estoy aquí si tienes más preguntas durante tu visita. 😊"

        // Ayuda general
        case input.containsAny(["ayuda", "help", "qué puedes", "qué haces",
                                 "funciones", "capacidades"]):
            return helpResponse()

        // Respuesta por defecto
        default:
            return defaultResponse()
        }
    }

    // MARK: - Respuestas por categoría

    private func orientationResponse() -> String {
        [
            "El museo Horno3 tiene dos niveles principales. 🗺️\n\n**Nivel 1:** Exhibiciones históricas y el Horno Alto original\n**Nivel 2:** Galería industrial y mirador panorámico\n\nPuedes ver el mapa interactivo tocando el ícono de mapa en la pantalla principal.",

            "¡Claro! Puedo orientarte. 📍\n\nEl punto de información principal está en la **entrada principal** (Nivel 1). Desde ahí puedes acceder a todos los niveles mediante rampas y elevadores.\n\nToca 'Ver mapa' en las acciones rápidas para ver el plano detallado."
        ].randomElement()!
    }

    private func eventsResponse() -> String {
        [
            "🗓️ **Actividades de hoy:**\n\n• 11:00 – Visita guiada al Horno Alto\n• 13:00 – Taller de metalurgia para niños\n• 15:30 – Proyección documental 'Acero y Fuego'\n• 17:00 – Tour fotográfico\n\nPuedes ver el calendario completo en la sección **Atracciones**.",

            "Hoy hay varias actividades disponibles. 🎯\n\nLa próxima **visita guiada** sale en 45 minutos desde la entrada principal. Cupo limitado, ¡te recomiendo registrarte pronto!\n\n¿Te interesa alguna actividad en particular?"
        ].randomElement()!
    }

    private func scanningResponse() -> String {
        "Para escanear un objeto del museo: 📷\n\n1. Toca el ícono **Escanear** en la pantalla principal\n2. Apunta la cámara al **código QR** o a la placa informativa del objeto\n3. Recibirás información detallada, historia y contenido multimedia\n\nCasi todas las piezas del museo cuentan con código QR. ¿Necesitas más ayuda con el escaneo?"
    }

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
    /// Devuelve `true` si la cadena contiene alguna de las palabras clave indicadas.
    func containsAny(_ keywords: [String]) -> Bool {
        keywords.contains { self.contains($0) }
    }
}
