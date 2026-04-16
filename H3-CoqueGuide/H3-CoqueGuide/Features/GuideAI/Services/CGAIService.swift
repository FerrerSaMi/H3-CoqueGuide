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

/// Datos relevantes del perfil del visitante para personalizar respuestas.
struct CGVisitorProfile {
    let gender: String
    let ageRange: String
    let plannedTime: String
    let attractionPreference: String
    let specificAttraction: String
    let preferredLanguage: String
    let translationLanguage: String
    let coquePersonality: String

    /// Crea un perfil desde un ExcursionUserProfile de SwiftData.
    init(from profile: ExcursionUserProfile) {
        self.gender = profile.gender
        self.ageRange = profile.ageRange
        self.plannedTime = profile.plannedTime
        self.attractionPreference = profile.resolvedAttractionPreference
        self.specificAttraction = profile.specificAttraction
        self.preferredLanguage = profile.preferredLanguage
        self.translationLanguage = profile.translationLanguage
        self.coquePersonality = profile.coquePersonality
    }
}

/// Contrato que debe cumplir cualquier implementación del servicio de IA.
/// Permite intercambiar fácilmente la implementación simulada por una real.
protocol CGAIServiceProtocol {
    /// Perfil del visitante actual. Se usa para personalizar respuestas.
    var visitorProfile: CGVisitorProfile? { get set }

    /// Recibe el texto del usuario y devuelve una respuesta estructurada.
    func processMessage(_ text: String) async -> CGAIResponse
}

// MARK: - Servicio simulado (sin dependencias externas)

/// Implementación simulada que responde mediante sistema de puntaje por palabras clave.
/// Incluye: puntaje por coincidencias, memoria de conversación, detección de idioma,
/// tolerancia a typos, saludos por hora y default inteligente.
final class CGSimulatedAIService: CGAIServiceProtocol {

    // MARK: - Perfil del visitante
    var visitorProfile: CGVisitorProfile?

    // MARK: - Estado de conversación (memoria)

    private var lastCategory: Category?
    private var conversationCount: Int = 0

    // MARK: - Categorías del motor de reglas

    private enum Category: CaseIterable {
        case greeting
        case thanks
        case help
        case orientation
        case events
        case scanning
        case exhibits
        case languages
        case accessibility
        case museumInfo
        case services
        case suggestions
    }

    // Nombres legibles por categoría (para el default inteligente)
    private let categoryNames: [Category: String] = [
        .orientation: "orientación y mapa",
        .events: "eventos y actividades",
        .scanning: "escaneo de piezas",
        .exhibits: "exhibiciones y salas",
        .languages: "idiomas",
        .accessibility: "accesibilidad",
        .museumInfo: "historia del museo",
        .services: "servicios (baños, comida, tienda)",
        .suggestions: "recomendaciones"
    ]

    // Keywords por categoría — incluye variantes sin acentos y typos comunes
    private let categoryKeywords: [Category: [String]] = [
        .greeting: ["hola", "buenos días", "buenos dias", "buenas tardes", "buenas noches",
                     "buenas", "hi", "hello", "hey", "qué tal", "que tal", "saludos",
                     "good morning", "good afternoon"],
        .thanks: ["gracias", "thanks", "thank you", "perfecto",
                   "excelente", "de acuerdo", "entendido", "genial", "vale", "ok"],
        .help: ["ayuda", "help", "qué puedes", "que puedes", "qué haces", "que haces",
                 "funciones", "capacidades", "cómo funciona", "como funciona",
                 "what can you do"],
        .orientation: ["mapa", "ubicación", "ubicacion", "cómo llego", "como llego",
                        "orientación", "orientacion", "plano", "ruta", "perdido", "zona",
                        "nivel", "piso", "entrada", "salida", "elevador", "rampa",
                        "where is", "how do i get", "map", "location"],
        .events: ["evento", "actividad", "show", "visita guiada",
                   "programa", "agenda", "tour", "taller",
                   "demostración", "demostracion", "espectáculo", "espectaculo",
                   "función", "funcion", "events", "activities", "what's on"],
        .scanning: ["escanear", "escaneo", "escaner", "qr", "código qr", "codigo qr",
                     "scan", "escanea", "leer código", "leer codigo",
                     "scanner"],
        .exhibits: ["exhibición", "exhibicion", "exhibiciones", "exposición", "exposicion",
                     "exposiciones", "sala", "salas", "galería", "galeria",
                     "qué ver", "que ver", "qué hay", "que hay",
                     "qué puedo ver", "que puedo ver", "recorrido", "atracción", "atraccion",
                     "atracciones", "horno alto", "mirador", "muestra", "colección", "coleccion",
                     "exhibits", "what to see", "gallery"],
        .languages: ["idioma", "language", "inglés", "ingles", "english",
                      "español", "espanol", "francés", "frances", "alemán", "aleman",
                      "traducción", "traduccion", "traducir", "translate"],
        .accessibility: ["accesibilidad", "discapacidad", "silla de ruedas",
                          "rampa accesible", "audífonos", "audifonos", "braille",
                          "necesidades especiales", "movilidad reducida",
                          "wheelchair", "accessible", "disability"],
        .museumInfo: ["museo", "horno3", "horno 3", "acero", "industrial",
                       "historia", "fundación", "fundacion", "monterrey", "fundidora",
                       "cuándo se fundó", "cuando se fundo", "inauguración", "inauguracion",
                       "origen", "history", "about the museum"],
        .services: ["comer", "comida", "restaurante", "restoran", "cafetería", "cafeteria",
                     "café", "cafe", "baño", "bano", "sanitario", "tienda", "souvenirs",
                     "regalo", "estacionamiento", "parqueo", "wifi", "cargar celular",
                     "bathroom", "restroom", "food", "restaurant", "shop", "parking"],
        .suggestions: ["no sé", "no se", "recomienda", "recomendación", "recomendacion",
                        "sugerencia", "qué hago", "que hago", "aburrido", "sugiéreme",
                        "sugiereme", "qué me recomiendas", "que me recomiendas",
                        "por dónde empiezo", "por donde empiezo", "qué es lo mejor",
                        "que es lo mejor", "recommend", "what should i do"]
    ]

    // Keywords de follow-up que activan la memoria
    private let followUpKeywords = ["cuéntame más", "cuentame mas", "más info", "mas info",
                                     "dime más", "dime mas", "el primero", "el segundo",
                                     "el tercero", "sí", "si", "claro", "dale",
                                     "tell me more", "more info", "yes"]

    // Keywords en inglés para detección de idioma
    private let englishIndicators = ["where", "what", "how", "when", "can you", "is there",
                                      "do you", "tell me", "show me", "i want", "i need",
                                      "please", "the", "bathroom", "museum", "events",
                                      "map", "help", "thanks", "hello", "hi"]

    // MARK: - Procesamiento de mensajes

    func processMessage(_ text: String) async -> CGAIResponse {
        let delay = Double.random(in: 0.7...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        conversationCount += 1
        let input = text.lowercased()

        // Detectar idioma
        let isEnglish = detectEnglish(input)

        // Checar si es follow-up
        if followUpKeywords.contains(where: { input.contains($0) }), let lastCat = lastCategory {
            return responseFor(category: lastCat, english: isEnglish)
        }

        return buildResponse(for: input, english: isEnglish)
    }

    // MARK: - Detección de idioma

    private func detectEnglish(_ input: String) -> Bool {
        let englishScore = englishIndicators.filter { input.contains($0) }.count
        return englishScore >= 2
    }

    // MARK: - Motor de reglas por puntaje

    private func buildResponse(for input: String, english: Bool) -> CGAIResponse {
        // Calcular puntaje para cada categoría
        var scores: [(Category, Int)] = []
        for category in Category.allCases {
            guard let keywords = categoryKeywords[category] else { continue }
            let score = keywords.filter { input.contains($0) }.count
            if score > 0 {
                scores.append((category, score))
            }
        }

        // Ordenar por puntaje descendente y tomar la mejor
        scores.sort { $0.1 > $1.1 }

        guard let bestMatch = scores.first else {
            // Default inteligente: sugerir la categoría más cercana si hay algo parcial
            if let closestCategory = findClosestCategory(for: input) {
                return .textOnly(smartDefaultResponse(suggesting: closestCategory, english: english))
            }
            return .textOnly(defaultResponse(english: english))
        }

        lastCategory = bestMatch.0
        return responseFor(category: bestMatch.0, english: english)
    }

    // MARK: - Default inteligente: buscar categoría parcialmente cercana

    private func findClosestCategory(for input: String) -> Category? {
        // Busca si alguna keyword tiene al menos 4 caracteres en común con alguna palabra del input
        let inputWords = input.split(separator: " ").map(String.init)
        var bestCategory: Category?
        var bestOverlap = 0

        for (category, keywords) in categoryKeywords {
            // Ignorar greeting, thanks, help para sugerencias
            if [.greeting, .thanks, .help].contains(category) { continue }

            for keyword in keywords {
                for word in inputWords where word.count >= 4 {
                    let common = commonPrefixLength(word, keyword)
                    if common >= 4 && common > bestOverlap {
                        bestOverlap = common
                        bestCategory = category
                    }
                }
            }
        }

        return bestCategory
    }

    private func commonPrefixLength(_ a: String, _ b: String) -> Int {
        zip(a, b).prefix(while: { $0 == $1 }).count
    }

    // MARK: - Dispatch de respuestas

    private func responseFor(category: Category, english: Bool = false) -> CGAIResponse {
        if english {
            return responseForEnglish(category: category)
        }

        switch category {
        case .greeting:     return .textOnly(greetingResponse())
        case .thanks:       return .textOnly(thanksResponse())
        case .help:         return .textOnly(helpResponse())
        case .orientation:  return orientationResponse()
        case .events:       return eventsResponse()
        case .scanning:     return scanningResponse()
        case .exhibits:     return exhibitsResponse()
        case .languages:    return .textOnly(languagesResponse())
        case .accessibility: return .textOnly(accessibilityResponse())
        case .museumInfo:   return .textOnly(museumInfoResponse())
        case .services:     return .textOnly(servicesResponse())
        case .suggestions:  return .textOnly(suggestionsResponse())
        }
    }

    // MARK: - Respuestas en inglés

    private func responseForEnglish(category: Category) -> CGAIResponse {
        switch category {
        case .greeting:
            return .textOnly("Hi! I'm **CoqueGuide**, your digital assistant at the Horno3 Steel Museum. 👋\n\nI can help you with navigation, events, exhibits, scanning and more. How can I help you?")
        case .thanks:
            return .textOnly("You're welcome! I'm here if you need anything else during your visit. 😊")
        case .help:
            return .textOnly("I can help you with: 💡\n\n• 🗺️ **Navigation** around the museum\n• 🗓️ **Events** and activities\n• 🏛️ **Exhibits** and galleries\n• 📷 **Scanning** QR codes\n• 🌍 **Languages**\n• ♿ **Accessibility**\n• 🏭 **Museum history**\n\nJust ask!")
        case .orientation:
            let mapCard = CGActionCard(cardType: .map, title: "Museum map", subtitle: "Levels 1 & 2", description: "View the interactive museum map", action: .navigate(.map))
            return .withCards("The museum has two main levels. 🗺️\n\n**Level 1:** Historical exhibits and the original Blast Furnace\n**Level 2:** Industrial gallery and panoramic viewpoint", cards: [mapCard])
        case .events:
            let events = CGEventService.shared.todaysEvents()
            let cards = events.map { event in CGActionCard(cardType: .event, title: event.name, subtitle: event.location, description: event.description, icon: event.icon, action: .navigate(.events)) }
            return .withCards("🗓️ **Today's activities at Horno3:**", cards: cards)
        case .scanning:
            let scanCard = CGActionCard(cardType: .scan, title: "Open scanner", subtitle: "Scan exhibit QR codes", description: "Most exhibits have QR codes.", action: .navigate(.scanning))
            return .withCards("Point your camera at a **QR code** next to any exhibit to learn more about it! 📷", cards: [scanCard])
        case .exhibits:
            let mapCard = CGActionCard(cardType: .map, title: "See exhibits on map", subtitle: "Find each gallery", description: "Plan your visit with the interactive map", action: .navigate(.map))
            return .withCards("🏛️ **Featured exhibits:**\n\n• **Original Blast Furnace** — The centerpiece, a 70-meter industrial colossus\n• **Steel Gallery** — The steelmaking process\n• **Interactive Room** — Science experiments\n• **Panoramic Viewpoint** — Level 2 city views\n\nStart with the Blast Furnace!", cards: [mapCard])
        case .languages:
            return .textOnly("🌍 **Available languages:**\n\n• 🇲🇽 Español\n• 🇺🇸 English\n• 🇫🇷 Français\n\nExhibit signs are available in **Spanish and English**.")
        case .accessibility:
            return .textOnly("♿ **Accessibility at Horno3:**\n\n• Ramps and elevators on all levels\n• Free audio guides at reception\n• Braille materials at select exhibits\n• Adapted restrooms on every level\n• Preferential parking\n\nNeed help? Our staff at the entrance can assist you.")
        case .museumInfo:
            return .textOnly("🏭 **Horno3 Steel Museum**\n\nBuilt inside the original **Blast Furnace No. 3** of Fundidora Monterrey. The furnace operated from **1910 to 1986**.\n\nReopened as a museum in 2007, it combines industrial history, contemporary art, and interactive technology.")
        case .services:
            return .textOnly("🛎️ **Available services:**\n\n• 🍽️ Restaurant 'La Fundición' — Level 1\n• ☕ Cafeteria — Ground floor\n• 🛍️ Souvenir shop — Ground floor\n• 🚗 Free parking\n• 🚻 Restrooms on every level\n\nNeed directions to any of these?")
        case .suggestions:
            return .textOnly("🌟 **My top recommendations:**\n\n1. Visit the **Blast Furnace** — the museum's centerpiece\n2. Go up to the **viewpoint** on Level 2 for city views\n3. Check today's **events** for workshops or guided tours\n\nWould you like to see the map?")
        }
    }

    // MARK: - Respuestas con tarjetas de acción

    private func orientationResponse() -> CGAIResponse {
        let text = [
            "El museo Horno3 tiene dos niveles principales. 🗺️\n\n**Nivel 1:** Exhibiciones históricas y el Horno Alto original\n**Nivel 2:** Galería industrial y mirador panorámico",
            "¡Claro! Puedo orientarte. 📍\n\nEl punto de información principal está en la **entrada principal** (Nivel 1). Desde ahí puedes acceder a todos los niveles mediante rampas y elevadores.",
            "¡Te ubico! 🧭\n\nEl museo se organiza en dos niveles conectados por rampas y elevadores. La mayoría de las exhibiciones principales están en el **Nivel 1**, y el **mirador** está en el Nivel 2."
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
        let text = [
            "🗓️ **Actividades de hoy en Horno3:**",
            "🎉 **Esto es lo que tenemos preparado para hoy:**",
            "📋 **Aquí están las actividades disponibles hoy:**"
        ].randomElement()!

        let cards = events.map { event in
            CGActionCard(
                cardType: .event,
                title: event.name,
                subtitle: event.location,
                description: event.description,
                icon: event.icon,
                action: .navigate(.events)
            )
        }

        return .withCards(text, cards: cards)
    }

    private func scanningResponse() -> CGAIResponse {
        let text = [
            "Para escanear un objeto del museo: 📷\n\n1. Apunta la cámara al **código QR** o a la placa informativa\n2. Recibirás información detallada, historia y contenido multimedia",
            "¡Buena idea! 📱 El escáner te permite conocer a fondo cada pieza del museo.\n\nSolo apunta tu cámara al **código QR** que encontrarás junto a las exhibiciones.",
            "¿Quieres saber más sobre una pieza? 🔍\n\nUsa el escáner para leer los **códigos QR** de las exhibiciones y acceder a información detallada, fotos y datos históricos."
        ].randomElement()!

        let scanCard = CGActionCard(
            cardType: .scan,
            title: "Abrir escáner",
            subtitle: "Escanea códigos QR de las exhibiciones",
            description: "Casi todas las piezas del museo cuentan con código QR.",
            action: .navigate(.scanning)
        )

        return .withCards(text, cards: [scanCard])
    }

    private func exhibitsResponse() -> CGAIResponse {
        let text = [
            "🏛️ **Exhibiciones destacadas de Horno3:**\n\n• **Horno Alto original** — La pieza central del museo, un coloso industrial de 70 metros\n• **Galería del Acero** — Historia del proceso siderúrgico\n• **Sala interactiva** — Experimentos de ciencia y tecnología\n• **Mirador panorámico** — Vista de Monterrey desde el Nivel 2\n\n¡Te recomiendo empezar por el Horno Alto!",
            "¡Hay mucho que ver! 🔥\n\n**Nivel 1:**\n• Horno Alto original (¡imperdible!)\n• Galería del Acero\n• Sala de historia industrial\n\n**Nivel 2:**\n• Galería interactiva\n• Mirador panorámico\n\n¿Quieres que te muestre el mapa para planear tu recorrido?",
            "El museo tiene exhibiciones increíbles. 🌟\n\nLo más popular es el **Horno Alto original** — un gigante de acero que operó desde 1910. También puedes explorar la **Galería del Acero**, las **salas interactivas** y subir al **mirador** en el Nivel 2.\n\n¿Te interesa alguna en particular?"
        ].randomElement()!

        let mapCard = CGActionCard(
            cardType: .map,
            title: "Ver exhibiciones en el mapa",
            subtitle: "Ubica cada sala y exhibición",
            description: "Planea tu recorrido con el mapa interactivo",
            action: .navigate(.map)
        )

        return .withCards(text, cards: [mapCard])
    }

    // MARK: - Respuestas de solo texto

    private func languagesResponse() -> String {
        [
            "🌍 **Idiomas disponibles en CoqueGuide:**\n\n• 🇲🇽 Español\n• 🇺🇸 English\n• 🇫🇷 Français\n\nPuedes cambiar el idioma en los ajustes de la app.\n\nLas cartelas de las exhibiciones también están en **español e inglés**.",
            "🗣️ CoqueGuide habla **español, inglés y francés**.\n\nDentro del museo, la señalización y las cartelas están disponibles en **español e inglés**. Si necesitas asistencia en otro idioma, el personal de recepción puede ayudarte.",
            "🌎 **¡Hablamos tu idioma!**\n\n• Español 🇲🇽\n• English 🇺🇸\n• Français 🇫🇷\n\nLas audioguías también están disponibles en estos idiomas. Pregunta en recepción."
        ].randomElement()!
    }

    private func accessibilityResponse() -> String {
        [
            "♿ **Servicios de accesibilidad en Horno3:**\n\n• Rampas y elevadores en todos los niveles\n• Audioguías disponibles en recepción (sin costo adicional)\n• Material en braille en exhibiciones seleccionadas\n• Estacionamiento preferencial en la entrada\n• Personal de apoyo disponible en recepción\n• Sanitarios adaptados en cada nivel\n\n¿Necesitas algún servicio específico?",
            "En Horno3 nos importa que **todos** disfruten la visita. ♿\n\n✅ Rampas y elevadores\n✅ Audioguías gratuitas\n✅ Material en braille\n✅ Sanitarios adaptados\n✅ Estacionamiento preferencial\n\nNuestro equipo en recepción puede asistirte con cualquier necesidad adicional.",
            "🤝 **Accesibilidad total en el museo:**\n\nTodos los niveles están conectados con **rampas y elevadores**. Tenemos **audioguías**, material en **braille** y **sanitarios adaptados** en cada piso.\n\nSi necesitas apoyo personalizado, avisa en la entrada y te asignamos un acompañante."
        ].randomElement()!
    }

    private func museumInfoResponse() -> String {
        [
            "🏭 **Museo del Acero Horno3**\n\nEspacio cultural único construido sobre el antiguo **Horno Alto Número 3** de la Fundidora de Monterrey. Inaugurado en 2007, combina historia industrial, arte contemporáneo y tecnología interactiva.\n\nEl horno fue operado entre **1910 y 1986**, y es parte fundamental de la identidad industrial de México.",
            "🔥 **¿Sabías esto?**\n\nEl Horno Alto No. 3 fue uno de los más grandes de Latinoamérica. Operó durante **76 años** (1910-1986) produciendo acero para todo México.\n\nEn 2007 se transformó en este museo, conservando la estructura original. ¡Estás literalmente dentro de un horno industrial!",
            "🏗️ **Historia del Horno3:**\n\nLa Fundidora de Monterrey fue la primera **siderúrgica integrada** de Latinoamérica (1900). El Horno Alto No. 3 operó desde 1910 hasta 1986.\n\nHoy es un museo interactivo que honra el legado industrial de Monterrey. Inaugurado en **2007**, recibe miles de visitantes cada año."
        ].randomElement()!
    }

    private func servicesResponse() -> String {
        [
            "🛎️ **Servicios disponibles en el museo:**\n\n• 🍽️ Restaurante 'La Fundición' – Nivel 1\n• ☕ Cafetería – Planta baja (junto a la entrada)\n• 🛍️ Tienda de souvenirs – Planta baja\n• 🚗 Estacionamiento gratuito para visitantes\n• 🚻 Sanitarios en cada nivel\n• 🔌 Área de carga de dispositivos – Nivel 1\n\n¿Necesitas indicaciones para llegar a alguno?",
            "¡Claro! Aquí tienes lo que necesitas: 📍\n\n• 🚻 **Baños** — En cada nivel del museo\n• 🍽️ **Restaurante** 'La Fundición' — Nivel 1\n• ☕ **Cafetería** — Planta baja, junto a la entrada\n• 🛍️ **Tienda** de souvenirs — Planta baja\n• 🚗 **Estacionamiento** — Gratuito\n\n¿Quieres ver el mapa para ubicarlos?",
            "🏪 **Todo lo que necesitas está aquí:**\n\n¿Hambre? → Restaurante 'La Fundición' (Nivel 1) o Cafetería (Planta baja)\n¿Recuerdos? → Tienda de souvenirs (Planta baja)\n¿Baños? → Disponibles en cada nivel\n¿Estacionamiento? → Gratuito para visitantes\n\nSi no encuentras algo, pregunta a cualquier miembro del equipo."
        ].randomElement()!
    }

    private func greetingResponse() -> String {
        let timeGreeting: String = {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<12: return "¡Buenos días!"
            case 12..<19: return "¡Buenas tardes!"
            default: return "¡Buenas noches!"
            }
        }()

        return [
            "\(timeGreeting) Soy **CoqueGuide**, tu asistente inteligente en el Museo del Acero Horno3. 👋\n\nPuedo ayudarte con orientación, eventos, escaneo de objetos, accesibilidad y mucho más. ¿En qué te puedo ayudar hoy?",
            "\(timeGreeting) ¡Bienvenido al **Museo Horno3**! 🏭\n\nEstoy aquí para hacer tu visita más completa y memorable. Puedo orientarte, contarte sobre las exhibiciones y ayudarte con cualquier duda.\n\n¿Por dónde empezamos?",
            "\(timeGreeting) 🔥 Me llamo **Coque** y soy tu guía digital en el Museo del Acero.\n\nPuedo ayudarte con:\n• 🗺️ Orientación\n• 🗓️ Eventos\n• 🏛️ Exhibiciones\n• 📷 Escaneo de piezas\n\n¿Qué te gustaría saber?"
        ].randomElement()!
    }

    private func thanksResponse() -> String {
        [
            "¡Con gusto! Estoy aquí si tienes más preguntas durante tu visita. 😊",
            "¡De nada! 🙌 Disfruta el museo y no dudes en escribirme si necesitas algo.",
            "¡Para eso estoy! 😄 Que disfrutes tu recorrido por Horno3. Si necesitas algo más, aquí ando."
        ].randomElement()!
    }

    private func helpResponse() -> String {
        [
            "Puedo ayudarte con: 💡\n\n• 🗺️ **Orientación** dentro del museo\n• 🗓️ **Eventos** y actividades del día\n• 🏛️ **Exhibiciones** y salas\n• 📷 **Escaneo** de objetos y piezas\n• 🌍 **Idiomas** disponibles\n• ♿ **Accesibilidad** y servicios\n• 🏭 **Historia** del museo\n\nEscribe tu pregunta o usa los botones de acciones rápidas.",
            "¡Soy tu guía digital! 🤖 Esto es lo que puedo hacer:\n\n• Orientarte dentro del museo 🗺️\n• Contarte sobre las exhibiciones 🏛️\n• Informarte de los eventos del día 🗓️\n• Ayudarte a escanear piezas 📷\n• Darte info de servicios (baños, comida, tienda) 🛎️\n\n¡Pregunta lo que quieras!",
            "¡Estoy para ayudarte! 💪\n\nPrueba preguntar cosas como:\n• *\"¿Qué exhibiciones hay?\"*\n• *\"¿Dónde está el baño?\"*\n• *\"¿Qué eventos hay hoy?\"*\n• *\"¿Dónde queda el restaurante?\"*\n\nO usa los botones rápidos de abajo. 👇"
        ].randomElement()!
    }

    private func suggestionsResponse() -> String {
        [
            "🌟 **¡Te recomiendo esto para empezar!**\n\n1. Visita el **Horno Alto original** — es la pieza central y lo más impresionante del museo\n2. Sube al **mirador** del Nivel 2 para una vista panorámica de Monterrey\n3. Revisa los **eventos del día** — puede haber talleres o visitas guiadas\n\n¿Te interesa alguna de estas opciones?",
            "🤔 ¡Déjame ayudarte!\n\nSi es tu **primera visita**, te sugiero:\n• Empieza por el **Nivel 1** con el Horno Alto\n• Luego sube al **Nivel 2** para la galería y el mirador\n• No te pierdas los **talleres interactivos** si hay alguno hoy\n\n¿Quieres ver el mapa para planear tu recorrido?",
            "¡Hay mucho que hacer! 🎉\n\nMis favoritos:\n• 🔥 **Horno Alto** — La estrella del museo\n• 🔭 **Mirador** — Vistas increíbles de la ciudad\n• 🧪 **Sala interactiva** — Experimentos de ciencia\n• 📷 **Escanea piezas** — Descubre datos ocultos con el QR\n\n¿Qué suena mejor?"
        ].randomElement()!
    }

    // MARK: - Respuestas default

    private func smartDefaultResponse(suggesting category: Category, english: Bool) -> String {
        let name = categoryNames[category] ?? "eso"
        if english {
            return "I'm not sure about that, but maybe you're asking about **\(name)**? 🤔\n\nTry rephrasing or use the quick action buttons below."
        }
        return "No estoy seguro de entender tu pregunta, pero quizás te refieres a **\(name)**. 🤔\n\n¿Es eso lo que buscas? También puedes usar los botones de acciones rápidas."
    }

    private func defaultResponse(english: Bool) -> String {
        if english {
            return [
                "I'm not sure about that. 🤔 I can help you with **exhibits**, **events**, **navigation**, **services** or **accessibility**. What interests you?",
                "I don't have that information, but you can ask at the **information desk** at the main entrance. 📍\n\nCan I help with something else?",
                "Great question! Our team at **reception** can help with that. 🙌\n\nMeanwhile, I can help with the map, exhibits or events."
            ].randomElement()!
        }
        return [
            "Hmm, no estoy seguro de eso. 🤔 Pero puedo ayudarte con **exhibiciones**, **eventos**, **orientación**, **servicios** o **accesibilidad**. ¿Qué te interesa?",
            "No tengo esa información exacta, pero puedes preguntar en el **punto de información** en la entrada principal. 📍\n\nMientras tanto, ¿te gustaría saber sobre las exhibiciones o los eventos de hoy?",
            "¡Buena pregunta! No tengo la respuesta, pero nuestro equipo en **recepción** seguro puede ayudarte. 🙌\n\n¿Puedo ayudarte con algo más? Prueba preguntarme sobre el mapa, exhibiciones o eventos."
        ].randomElement()!
    }
}
