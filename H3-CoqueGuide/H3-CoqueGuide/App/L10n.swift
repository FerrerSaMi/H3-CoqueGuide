//
//  L10n.swift
//  H3-CoqueGuide
//
//  Helper centralizado de localización. Cada propiedad devuelve el texto
//  correspondiente al idioma detectado del iPhone (AppLanguage.device).
//
//  POR QUÉ ASÍ Y NO CON STRING CATALOGS (.xcstrings):
//  - Funciona sin necesidad de configurar Localizations en el proyecto Xcode.
//  - Los textos están junto al código, fáciles de revisar en PR.
//  - Para el Sprint 2 es el camino más rápido con cero riesgo de romper el build.
//
//  CÓMO AÑADIR NUEVOS STRINGS:
//  1. Agregar una propiedad estática en L10n con el nombre semántico (p. ej. L10n.scannerTitle).
//  2. Cubrir todos los idiomas dentro de `localize(...)` usando el closure por idioma.
//  3. Llamar `L10n.scannerTitle` desde cualquier View o ViewModel.
//

import Foundation

enum L10n {

    // MARK: - Tabs

    static var tabHome:    String { localize(es: "Inicio",  en: "Home",     fr: "Accueil",  pt: "Início",  ko: "홈",     ar: "الرئيسية") }
    static var tabScan:    String { localize(es: "Escaneo", en: "Scan",     fr: "Scanner",  pt: "Escanear", ko: "스캔",   ar: "مسح") }
    static var tabMap:     String { localize(es: "Mapa",    en: "Map",      fr: "Carte",    pt: "Mapa",    ko: "지도",   ar: "خريطة") }
    static var tabProfile: String { localize(es: "Perfil",  en: "Profile",  fr: "Profil",   pt: "Perfil",  ko: "프로필", ar: "الملف الشخصي") }

    // MARK: - Saludos

    static var greetingMorning:   String { localize(es: "Buenos días",  en: "Good morning",   fr: "Bonjour",     pt: "Bom dia",    ko: "좋은 아침",  ar: "صباح الخير") }
    static var greetingAfternoon: String { localize(es: "Buenas tardes", en: "Good afternoon", fr: "Bon après-midi", pt: "Boa tarde",  ko: "좋은 오후",  ar: "مساء الخير") }
    static var greetingEvening:   String { localize(es: "Buenas noches", en: "Good evening",   fr: "Bonsoir",     pt: "Boa noite",  ko: "좋은 저녁",  ar: "مساء الخير") }

    // MARK: - CoqueGuide chat

    static var cgHeaderStatus: String {
        localize(
            es: "Asistente activo",
            en: "Assistant active",
            fr: "Assistant actif",
            pt: "Assistente ativo",
            ko: "어시스턴트 활성",
            ar: "المساعد نشط"
        )
    }

    static var cgHeaderSubtitle: String {
        localize(
            es: "Tu asistente inteligente",
            en: "Your smart assistant",
            fr: "Votre assistant intelligent",
            pt: "Seu assistente inteligente",
            ko: "당신의 스마트 어시스턴트",
            ar: "مساعدك الذكي"
        )
    }

    static var cgStatusBadge: String {
        localize(es: "Activo", en: "Active", fr: "Actif", pt: "Ativo", ko: "활성", ar: "نشط")
    }

    static var cgInputPlaceholder: String {
        localize(
            es: "Escribe tu pregunta…",
            en: "Type your question…",
            fr: "Tapez votre question…",
            pt: "Digite sua pergunta…",
            ko: "질문을 입력하세요…",
            ar: "اكتب سؤالك…"
        )
    }

    static var cgWelcome: String {
        localize(
            es: "¡Hola! Soy **CoqueGuide**, tu asistente en el Museo del Acero Horno3. 🏭\n\nPuedo ayudarte con orientación, eventos, escaneo de objetos y accesibilidad.\n\n¿En qué te puedo ayudar hoy?",
            en: "Hi! I'm **CoqueGuide**, your assistant at the Horno3 Steel Museum. 🏭\n\nI can help you with navigation, events, object scanning, and accessibility.\n\nHow can I help you today?",
            fr: "Salut ! Je suis **CoqueGuide**, votre assistant au Musée de l'Acier Horno3. 🏭\n\nJe peux vous aider avec la navigation, les événements, le scan d'objets et l'accessibilité.\n\nComment puis-je vous aider aujourd'hui ?",
            pt: "Olá! Sou o **CoqueGuide**, seu assistente no Museu do Aço Horno3. 🏭\n\nPosso ajudá-lo com navegação, eventos, escaneamento de objetos e acessibilidade.\n\nComo posso ajudá-lo hoje?",
            ko: "안녕하세요! 저는 Horno3 철강 박물관의 어시스턴트 **CoqueGuide**입니다. 🏭\n\n길 안내, 이벤트, 물건 스캔, 접근성에 대해 도와드릴 수 있습니다.\n\n오늘 무엇을 도와드릴까요?",
            ar: "مرحبًا! أنا **CoqueGuide**، مساعدك في متحف الصلب Horno3. 🏭\n\nيمكنني مساعدتك في التنقل والفعاليات ومسح الأشياء وإمكانية الوصول.\n\nكيف يمكنني مساعدتك اليوم؟"
        )
    }

    // MARK: - Home card de CoqueGuide

    static var cgHomeTitle: String { "CoqueGuide" }

    static var cgHomeMessage: String {
        localize(
            es: "¡Bienvenido! ¿Cómo puedo ayudarte en tu visita?",
            en: "Welcome! How can I help you with your visit?",
            fr: "Bienvenue ! Comment puis-je vous aider lors de votre visite ?",
            pt: "Bem-vindo! Como posso ajudá-lo em sua visita?",
            ko: "환영합니다! 방문에 어떻게 도움을 드릴까요?",
            ar: "مرحبًا! كيف يمكنني مساعدتك في زيارتك؟"
        )
    }

    static var cgHomeCTA: String {
        localize(
            es: "Abrir chat con Coque →",
            en: "Open chat with Coque →",
            fr: "Ouvrir le chat avec Coque →",
            pt: "Abrir chat com Coque →",
            ko: "Coque와 채팅 열기 →",
            ar: "افتح الدردشة مع Coque ←"
        )
    }

    static var cgQuickActionsLabel: String {
        localize(
            es: "Preguntas rápidas",
            en: "Quick questions",
            fr: "Questions rapides",
            pt: "Perguntas rápidas",
            ko: "빠른 질문",
            ar: "أسئلة سريعة"
        )
    }

    // MARK: - Quick actions (home card)

    static var qaWhereTitle: String {
        localize(es: "¿Dónde estoy?", en: "Where am I?", fr: "Où suis-je ?", pt: "Onde estou?", ko: "여기 어디예요?", ar: "أين أنا؟")
    }

    static var qaWhereMessage: String {
        localize(
            es: "¿Dónde estoy en el museo?",
            en: "Where am I in the museum?",
            fr: "Où suis-je dans le musée ?",
            pt: "Onde estou no museu?",
            ko: "박물관 안 어디에 있나요?",
            ar: "أين أنا في المتحف؟"
        )
    }

    static var qaMapTitle: String {
        localize(es: "Ver mapa", en: "See map", fr: "Voir la carte", pt: "Ver mapa", ko: "지도 보기", ar: "اعرض الخريطة")
    }

    static var qaMapMessage: String {
        localize(
            es: "¿Puedes mostrarme el mapa del museo?",
            en: "Can you show me the museum map?",
            fr: "Pouvez-vous me montrer la carte du musée ?",
            pt: "Você pode me mostrar o mapa do museu?",
            ko: "박물관 지도를 보여줄 수 있나요?",
            ar: "هل يمكنك أن تريني خريطة المتحف؟"
        )
    }

    static var qaNextEventTitle: String {
        localize(es: "Próximo evento", en: "Next event", fr: "Prochain événement", pt: "Próximo evento", ko: "다음 이벤트", ar: "الفعالية القادمة")
    }

    static var qaNextEventMessage: String {
        localize(
            es: "¿Cuál es el próximo evento?",
            en: "What is the next event?",
            fr: "Quel est le prochain événement ?",
            pt: "Qual é o próximo evento?",
            ko: "다음 이벤트는 무엇인가요?",
            ar: "ما هي الفعالية القادمة؟"
        )
    }

    // MARK: - Quick actions (chat panel)

    static var qaEventsTitle: String {
        localize(es: "Eventos", en: "Events", fr: "Événements", pt: "Eventos", ko: "이벤트", ar: "الفعاليات")
    }

    static var qaEventsMessage: String {
        localize(
            es: "¿Qué eventos hay disponibles hoy?",
            en: "What events are available today?",
            fr: "Quels événements sont disponibles aujourd'hui ?",
            pt: "Quais eventos estão disponíveis hoje?",
            ko: "오늘 어떤 이벤트가 있나요?",
            ar: "ما هي الفعاليات المتاحة اليوم؟"
        )
    }

    static var qaScanTitle: String {
        localize(es: "Escanear objeto", en: "Scan object", fr: "Scanner un objet", pt: "Escanear objeto", ko: "물체 스캔", ar: "مسح عنصر")
    }

    static var qaScanMessage: String {
        localize(
            es: "¿Cómo escaneo un objeto del museo?",
            en: "How do I scan a museum object?",
            fr: "Comment scanner un objet du musée ?",
            pt: "Como eu escaneio um objeto do museu?",
            ko: "박물관 물체를 어떻게 스캔하나요?",
            ar: "كيف أمسح عنصرًا من المتحف؟"
        )
    }

    static var qaLanguageTitle: String {
        localize(es: "Cambiar idioma", en: "Change language", fr: "Changer de langue", pt: "Mudar idioma", ko: "언어 변경", ar: "تغيير اللغة")
    }

    static var qaLanguageMessage: String {
        localize(
            es: "¿En qué idiomas está disponible la guía?",
            en: "What languages is the guide available in?",
            fr: "Dans quelles langues le guide est-il disponible ?",
            pt: "Em quais idiomas o guia está disponível?",
            ko: "가이드는 어떤 언어로 제공되나요?",
            ar: "ما هي اللغات المتوفرة للدليل؟"
        )
    }

    static var qaAccessibilityTitle: String {
        localize(es: "Accesibilidad", en: "Accessibility", fr: "Accessibilité", pt: "Acessibilidade", ko: "접근성", ar: "إمكانية الوصول")
    }

    static var qaAccessibilityMessage: String {
        localize(
            es: "¿Qué servicios de accesibilidad tiene el museo?",
            en: "What accessibility services does the museum have?",
            fr: "Quels services d'accessibilité le musée propose-t-il ?",
            pt: "Quais serviços de acessibilidade o museu oferece?",
            ko: "박물관에는 어떤 접근성 서비스가 있나요?",
            ar: "ما هي خدمات إمكانية الوصول المتوفرة في المتحف؟"
        )
    }

    // MARK: - Scanner

    static var scannerTitle: String { localize(es: "Escaneo", en: "Scan", fr: "Scanner", pt: "Escanear", ko: "스캔", ar: "مسح") }

    static var scannerAskCoque: String {
        localize(
            es: "Pregúntale a Coque",
            en: "Ask Coque",
            fr: "Demander à Coque",
            pt: "Pergunte ao Coque",
            ko: "Coque에게 물어보기",
            ar: "اسأل Coque"
        )
    }

    /// Prompt que se envía al chat al pulsar "Pregúntale a Coque" en el scanner.
    static func scannerAskPrompt(objectTitle: String) -> String {
        localize(
            es: "Cuéntame más sobre \(objectTitle).",
            en: "Tell me more about \(objectTitle).",
            fr: "Parlez-moi davantage de \(objectTitle).",
            pt: "Conte-me mais sobre \(objectTitle).",
            ko: "\(objectTitle)에 대해 더 알려주세요.",
            ar: "أخبرني المزيد عن \(objectTitle)."
        )
    }

    // MARK: - Landing

    static var landingGreetingSubtitle: String {
        localize(
            es: "Explora todo lo que el museo tiene para ti",
            en: "Explore everything the museum has to offer",
            fr: "Découvrez tout ce que le musée vous offre",
            pt: "Explore tudo o que o museu tem para oferecer",
            ko: "박물관이 제공하는 모든 것을 둘러보세요",
            ar: "اكتشف كل ما يقدمه المتحف"
        )
    }

    static var landingDarkModeToLight: String {
        localize(
            es: "Cambiar a modo claro",
            en: "Switch to light mode",
            fr: "Passer en mode clair",
            pt: "Mudar para modo claro",
            ko: "라이트 모드로 전환",
            ar: "التبديل إلى الوضع الفاتح"
        )
    }

    static var landingDarkModeToDark: String {
        localize(
            es: "Cambiar a modo oscuro",
            en: "Switch to dark mode",
            fr: "Passer en mode sombre",
            pt: "Mudar para modo escuro",
            ko: "다크 모드로 전환",
            ar: "التبديل إلى الوضع الداكن"
        )
    }

    static var landingHowToUseTitle: String {
        localize(
            es: "Cómo funciona",
            en: "How it works",
            fr: "Comment ça marche",
            pt: "Como funciona",
            ko: "사용 방법",
            ar: "كيف يعمل"
        )
    }

    static var landingStepScanTitle: String {
        localize(es: "Escanea", en: "Scan", fr: "Scanner", pt: "Escaneie", ko: "스캔", ar: "امسح")
    }

    static var landingStepScanSubtitle: String {
        localize(
            es: "Apunta a un objeto del museo",
            en: "Point at a museum object",
            fr: "Pointez vers un objet du musée",
            pt: "Aponte para um objeto do museu",
            ko: "박물관 물체를 겨누세요",
            ar: "وجّه نحو قطعة في المتحف"
        )
    }

    static var landingStepAskTitle: String {
        localize(es: "Pregunta", en: "Ask", fr: "Demandez", pt: "Pergunte", ko: "질문", ar: "اسأل")
    }

    static var landingStepAskSubtitle: String {
        localize(
            es: "CoqueGuide te responde",
            en: "CoqueGuide answers you",
            fr: "CoqueGuide vous répond",
            pt: "O CoqueGuide te responde",
            ko: "CoqueGuide가 답해드려요",
            ar: "CoqueGuide يجيبك"
        )
    }

    static var landingStepExploreTitle: String {
        localize(es: "Explora", en: "Explore", fr: "Explorez", pt: "Explore", ko: "탐험", ar: "استكشف")
    }

    static var landingStepExploreSubtitle: String {
        localize(
            es: "Navega por el museo",
            en: "Navigate the museum",
            fr: "Naviguez dans le musée",
            pt: "Navegue pelo museu",
            ko: "박물관을 둘러보세요",
            ar: "تصفّح المتحف"
        )
    }

    static var landingAttractionsTitle: String {
        localize(
            es: "Explora el museo",
            en: "Explore the museum",
            fr: "Explorez le musée",
            pt: "Explore o museu",
            ko: "박물관 둘러보기",
            ar: "استكشف المتحف"
        )
    }

    static var landingCGAccessibilityLabel: String {
        localize(
            es: "CoqueGuide, tu asistente inteligente del museo",
            en: "CoqueGuide, your smart museum assistant",
            fr: "CoqueGuide, votre assistant intelligent du musée",
            pt: "CoqueGuide, seu assistente inteligente do museu",
            ko: "CoqueGuide, 당신의 스마트 박물관 어시스턴트",
            ar: "CoqueGuide، مساعدك الذكي في المتحف"
        )
    }

    static var landingPlaceholderAttractions: String {
        localize(es: "Atracciones", en: "Attractions", fr: "Attractions", pt: "Atrações", ko: "명소", ar: "المعالم")
    }

    static var landingPlaceholderChatbot: String {
        localize(es: "Chatbot", en: "Chatbot", fr: "Chatbot", pt: "Chatbot", ko: "챗봇", ar: "روبوت دردشة")
    }

    static var landingPlaceholderComingSoon: String {
        localize(
            es: "Próximamente",
            en: "Coming soon",
            fr: "Bientôt disponible",
            pt: "Em breve",
            ko: "곧 공개됩니다",
            ar: "قريبًا"
        )
    }

    // MARK: - Museum Location Card

    static var locationFindUs: String {
        localize(
            es: "Encuéntranos",
            en: "Find us",
            fr: "Trouvez-nous",
            pt: "Encontre-nos",
            ko: "찾아오는 길",
            ar: "اعثر علينا"
        )
    }

    static var locationHowToGetThere: String {
        localize(
            es: "Cómo llegar",
            en: "How to get there",
            fr: "Comment y aller",
            pt: "Como chegar",
            ko: "가는 방법",
            ar: "كيف تصل"
        )
    }

    static var locationOpenInMapsA11y: String {
        localize(
            es: "Abrir indicaciones en Apple Maps",
            en: "Open directions in Apple Maps",
            fr: "Ouvrir l'itinéraire dans Apple Plans",
            pt: "Abrir rotas no Apple Maps",
            ko: "Apple Maps에서 길찾기 열기",
            ar: "فتح الاتجاهات في Apple Maps"
        )
    }

    // MARK: - Carousel (galería del landing)

    static var galleryMuseumTitle: String {
        localize(
            es: "Museo del Acero",
            en: "Steel Museum",
            fr: "Musée de l'Acier",
            pt: "Museu do Aço",
            ko: "철강 박물관",
            ar: "متحف الصلب"
        )
    }

    static var galleryMuseumSubtitle: String {
        localize(
            es: "Horno3 - Monterrey, NL",
            en: "Horno3 - Monterrey, NL",
            fr: "Horno3 - Monterrey, NL",
            pt: "Horno3 - Monterrey, NL",
            ko: "Horno3 - 몬테레이, NL",
            ar: "Horno3 - مونتيري، NL"
        )
    }

    static var galleryHistoryTitle: String {
        localize(
            es: "Historia Industrial",
            en: "Industrial History",
            fr: "Histoire industrielle",
            pt: "História Industrial",
            ko: "산업의 역사",
            ar: "التاريخ الصناعي"
        )
    }

    static var galleryHistorySubtitle: String {
        localize(
            es: "Conoce el legado siderúrgico",
            en: "Discover the steelmaking legacy",
            fr: "Découvrez l'héritage sidérurgique",
            pt: "Conheça o legado siderúrgico",
            ko: "제철의 유산을 알아보세요",
            ar: "اكتشف إرث صناعة الصلب"
        )
    }

    static var galleryExhibitionsTitle: String {
        localize(
            es: "Exhibiciones",
            en: "Exhibitions",
            fr: "Expositions",
            pt: "Exposições",
            ko: "전시",
            ar: "المعارض"
        )
    }

    static var galleryExhibitionsSubtitle: String {
        localize(
            es: "Ciencia, arte y tecnología",
            en: "Science, art and technology",
            fr: "Science, art et technologie",
            pt: "Ciência, arte e tecnologia",
            ko: "과학, 예술, 기술",
            ar: "العلم والفن والتكنولوجيا"
        )
    }

    static var galleryExperiencesTitle: String {
        localize(
            es: "Experiencias",
            en: "Experiences",
            fr: "Expériences",
            pt: "Experiências",
            ko: "체험",
            ar: "التجارب"
        )
    }

    static var galleryExperiencesSubtitle: String {
        localize(
            es: "Recorridos interactivos",
            en: "Interactive tours",
            fr: "Visites interactives",
            pt: "Tours interativos",
            ko: "인터랙티브 투어",
            ar: "جولات تفاعلية"
        )
    }

    static var galleryCultureTitle: String {
        localize(
            es: "Cultura y Aprendizaje",
            en: "Culture and Learning",
            fr: "Culture et apprentissage",
            pt: "Cultura e Aprendizagem",
            ko: "문화와 배움",
            ar: "الثقافة والتعلّم"
        )
    }

    static var galleryCultureSubtitle: String {
        localize(
            es: "Un mundo por descubrir",
            en: "A world to discover",
            fr: "Un monde à découvrir",
            pt: "Um mundo para descobrir",
            ko: "발견할 세상",
            ar: "عالم جدير بالاكتشاف"
        )
    }

    // MARK: - Attractions (tarjetas horizontales)

    static var attrHornoAltoName: String {
        localize(es: "Horno Alto", en: "Blast Furnace", fr: "Haut-Fourneau", pt: "Alto-Forno", ko: "고로", ar: "الفرن العالي")
    }

    static var attrHornoAltoSubtitle: String {
        localize(
            es: "Paseo por el ícono del museo",
            en: "A tour through the museum's icon",
            fr: "Visite de l'icône du musée",
            pt: "Passeio pelo ícone do museu",
            ko: "박물관의 상징을 둘러보기",
            ar: "جولة في أيقونة المتحف"
        )
    }

    static var attrHornoAltoMessage: String {
        localize(
            es: "Cuéntame sobre el Horno Alto del museo",
            en: "Tell me about the museum's Blast Furnace",
            fr: "Parlez-moi du Haut-Fourneau du musée",
            pt: "Me conte sobre o Alto-Forno do museu",
            ko: "박물관의 고로에 대해 알려주세요",
            ar: "أخبرني عن الفرن العالي في المتحف"
        )
    }

    static var attrGalleryName: String {
        localize(
            es: "Galería del Acero",
            en: "Steel Gallery",
            fr: "Galerie de l'Acier",
            pt: "Galeria do Aço",
            ko: "철강 갤러리",
            ar: "معرض الصلب"
        )
    }

    static var attrGallerySubtitle: String {
        localize(
            es: "Historia de la siderurgia",
            en: "History of steelmaking",
            fr: "Histoire de la sidérurgie",
            pt: "História da siderurgia",
            ko: "제철의 역사",
            ar: "تاريخ صناعة الصلب"
        )
    }

    static var attrGalleryMessage: String {
        localize(
            es: "¿Qué puedo encontrar en la Galería del Acero?",
            en: "What can I find in the Steel Gallery?",
            fr: "Que puis-je trouver dans la Galerie de l'Acier ?",
            pt: "O que posso encontrar na Galeria do Aço?",
            ko: "철강 갤러리에서 무엇을 볼 수 있나요?",
            ar: "ماذا أجد في معرض الصلب؟"
        )
    }

    static var attrSteelShowName: String {
        localize(
            es: "Show del Acero",
            en: "Steel Show",
            fr: "Spectacle de l'Acier",
            pt: "Show do Aço",
            ko: "철강 쇼",
            ar: "عرض الصلب"
        )
    }

    static var attrSteelShowSubtitle: String {
        localize(
            es: "Espectáculo en vivo",
            en: "Live show",
            fr: "Spectacle en direct",
            pt: "Espetáculo ao vivo",
            ko: "라이브 쇼",
            ar: "عرض حيّ"
        )
    }

    static var attrSteelShowMessage: String {
        localize(
            es: "¿De qué trata el Show del Acero?",
            en: "What is the Steel Show about?",
            fr: "De quoi parle le Spectacle de l'Acier ?",
            pt: "Do que se trata o Show do Aço?",
            ko: "철강 쇼는 무엇에 관한 것인가요?",
            ar: "عمّ يتحدث عرض الصلب؟"
        )
    }

    static var attrLabName: String {
        localize(
            es: "Laboratorio",
            en: "Laboratory",
            fr: "Laboratoire",
            pt: "Laboratório",
            ko: "실험실",
            ar: "المختبر"
        )
    }

    static var attrLabSubtitle: String {
        localize(
            es: "Ciencia interactiva",
            en: "Interactive science",
            fr: "Science interactive",
            pt: "Ciência interativa",
            ko: "체험형 과학",
            ar: "علوم تفاعلية"
        )
    }

    static var attrLabMessage: String {
        localize(
            es: "¿Qué actividades hay en el Laboratorio?",
            en: "What activities are there in the Laboratory?",
            fr: "Quelles activités y a-t-il au Laboratoire ?",
            pt: "Quais atividades há no Laboratório?",
            ko: "실험실에는 어떤 활동이 있나요?",
            ar: "ما الأنشطة المتوفرة في المختبر؟"
        )
    }

    static var attrViewpointName: String {
        localize(
            es: "Mirador",
            en: "Viewpoint",
            fr: "Belvédère",
            pt: "Mirante",
            ko: "전망대",
            ar: "نقطة المراقبة"
        )
    }

    static var attrViewpointSubtitle: String {
        localize(
            es: "Vista panorámica",
            en: "Panoramic view",
            fr: "Vue panoramique",
            pt: "Vista panorâmica",
            ko: "파노라마 전망",
            ar: "إطلالة بانورامية"
        )
    }

    static var attrViewpointMessage: String {
        localize(
            es: "Cuéntame sobre el Mirador del museo",
            en: "Tell me about the museum's Viewpoint",
            fr: "Parlez-moi du Belvédère du musée",
            pt: "Me conte sobre o Mirante do museu",
            ko: "박물관의 전망대에 대해 알려주세요",
            ar: "أخبرني عن نقطة المراقبة في المتحف"
        )
    }

    static var attrSteelMillName: String {
        localize(
            es: "Acería",
            en: "Steel Mill",
            fr: "Aciérie",
            pt: "Aciaria",
            ko: "제철소",
            ar: "مصنع الصلب"
        )
    }

    static var attrSteelMillSubtitle: String {
        localize(
            es: "Proceso del acero",
            en: "The steel process",
            fr: "Le processus de l'acier",
            pt: "Processo do aço",
            ko: "제강 과정",
            ar: "عملية صناعة الصلب"
        )
    }

    static var attrSteelMillMessage: String {
        localize(
            es: "¿Qué puedo aprender en la Acería?",
            en: "What can I learn at the Steel Mill?",
            fr: "Que puis-je apprendre à l'Aciérie ?",
            pt: "O que posso aprender na Aciaria?",
            ko: "제철소에서 무엇을 배울 수 있나요?",
            ar: "ماذا يمكنني أن أتعلم في مصنع الصلب؟"
        )
    }

    static func attractionOpenHint(_ name: String) -> String {
        localize(
            es: "Abre CoqueGuide con información sobre \(name)",
            en: "Opens CoqueGuide with information about \(name)",
            fr: "Ouvre CoqueGuide avec des informations sur \(name)",
            pt: "Abre o CoqueGuide com informações sobre \(name)",
            ko: "\(name)에 대한 정보와 함께 CoqueGuide를 엽니다",
            ar: "يفتح CoqueGuide بمعلومات عن \(name)"
        )
    }

    // MARK: - Proactive suggestions

    static var suggestShowMap: String {
        localize(
            es: "¿Quieres ver el mapa del museo?",
            en: "Want to see the museum map?",
            fr: "Voulez-vous voir la carte du musée ?",
            pt: "Quer ver o mapa do museu?",
            ko: "박물관 지도를 볼까요?",
            ar: "هل تريد رؤية خريطة المتحف؟"
        )
    }

    static var suggestGuidedTour: String {
        localize(
            es: "¿Sabías que hay una visita guiada disponible hoy?",
            en: "Did you know there's a guided tour available today?",
            fr: "Saviez-vous qu'il y a une visite guidée disponible aujourd'hui ?",
            pt: "Sabia que há um tour guiado disponível hoje?",
            ko: "오늘 가이드 투어가 있다는 사실을 아셨나요?",
            ar: "هل تعلم أن هناك جولة إرشادية متاحة اليوم؟"
        )
    }

    static var suggestAccessibility: String {
        localize(
            es: "¿Necesitas información sobre accesibilidad?",
            en: "Need accessibility information?",
            fr: "Avez-vous besoin d'informations sur l'accessibilité ?",
            pt: "Precisa de informações sobre acessibilidade?",
            ko: "접근성 정보가 필요하신가요?",
            ar: "هل تحتاج إلى معلومات عن إمكانية الوصول؟"
        )
    }

    static var suggestScan: String {
        localize(
            es: "Puedes escanear cualquier pieza del museo para saber más.",
            en: "You can scan any museum piece to learn more.",
            fr: "Vous pouvez scanner n'importe quelle pièce du musée pour en savoir plus.",
            pt: "Você pode escanear qualquer peça do museu para saber mais.",
            ko: "박물관의 어떤 작품이든 스캔하여 더 알아볼 수 있어요.",
            ar: "يمكنك مسح أي قطعة في المتحف لمعرفة المزيد."
        )
    }

    static var suggestTickets: String {
        localize(
            es: "¿Quieres conocer los horarios y precios de entrada?",
            en: "Want to know the opening hours and ticket prices?",
            fr: "Voulez-vous connaître les horaires et les tarifs ?",
            pt: "Quer saber os horários e preços dos ingressos?",
            ko: "운영 시간과 입장료를 알려드릴까요?",
            ar: "هل تريد معرفة مواعيد العمل وأسعار التذاكر؟"
        )
    }

    static var suggestHelp: String {
        localize(
            es: "¿Hay algo en lo que pueda ayudarte durante tu visita?",
            en: "Is there something I can help you with during your visit?",
            fr: "Puis-je vous aider pour quelque chose pendant votre visite ?",
            pt: "Há algo em que eu possa ajudar durante sua visita?",
            ko: "방문하시는 동안 도와드릴 게 있을까요?",
            ar: "هل هناك ما يمكنني مساعدتك به خلال زيارتك؟"
        )
    }

    static var suggestHistoryAudio: String {
        localize(
            es: "🎧 Escucha la **narración de la Galería de Historia** en Soundcloud — una introducción magistral al legado del acero.",
            en: "🎧 Listen to the **History Gallery narration** on Soundcloud — a masterful introduction to the steel legacy.",
            fr: "🎧 Écoutez la **narration de la Galerie d'Histoire** sur Soundcloud — une introduction magistrale à l'héritage de l'acier.",
            pt: "🎧 Ouça a **narração da Galeria de História** no Soundcloud — uma introdução magistral ao legado do aço.",
            ko: "🎧 Soundcloud에서 **역사 갤러리 해설**을 들어보세요 — 철강 유산에 대한 훌륭한 소개입니다.",
            ar: "🎧 استمع إلى **سرد معرض التاريخ** على Soundcloud — مقدمة رائعة لإرث الصلب."
        )
    }

    // MARK: - Map

    static var mapTitle: String {
        localize(
            es: "Mapa del Museo",
            en: "Museum Map",
            fr: "Carte du musée",
            pt: "Mapa do Museu",
            ko: "박물관 지도",
            ar: "خريطة المتحف"
        )
    }

    static var mapLevel1: String { localize(es: "Nivel 1", en: "Level 1", fr: "Niveau 1", pt: "Nível 1", ko: "1층", ar: "المستوى 1") }
    static var mapLevel2: String { localize(es: "Nivel 2", en: "Level 2", fr: "Niveau 2", pt: "Nível 2", ko: "2층", ar: "المستوى 2") }

    static var mapServices: String {
        localize(es: "Servicios", en: "Services", fr: "Services", pt: "Serviços", ko: "시설", ar: "الخدمات")
    }

    static var mapShowServices: String {
        localize(es: "Mostrar servicios", en: "Show services", fr: "Afficher les services", pt: "Mostrar serviços", ko: "시설 표시", ar: "إظهار الخدمات")
    }

    static var mapHideServices: String {
        localize(es: "Ocultar servicios", en: "Hide services", fr: "Masquer les services", pt: "Ocultar serviços", ko: "시설 숨기기", ar: "إخفاء الخدمات")
    }

    static var mapEmptyPinsTitle: String {
        localize(
            es: "Sin puntos de interés",
            en: "No points of interest",
            fr: "Aucun point d'intérêt",
            pt: "Sem pontos de interesse",
            ko: "관심 지점 없음",
            ar: "لا توجد نقاط اهتمام"
        )
    }

    static var mapEmptyPinsMessage: String {
        localize(
            es: "No pudimos cargar la información de este nivel. Intenta recargar o consulta en recepción.",
            en: "We couldn't load information for this level. Try reloading or ask at reception.",
            fr: "Impossible de charger les informations de ce niveau. Essayez de recharger ou demandez à l'accueil.",
            pt: "Não foi possível carregar as informações deste nível. Tente recarregar ou pergunte na recepção.",
            ko: "이 층의 정보를 불러올 수 없습니다. 다시 시도하거나 안내데스크에 문의하세요.",
            ar: "تعذر تحميل معلومات هذا المستوى. حاول إعادة التحميل أو استفسر في الاستقبال."
        )
    }

    static var mapEmptyPinsReload: String {
        localize(
            es: "Recargar",
            en: "Reload",
            fr: "Recharger",
            pt: "Recarregar",
            ko: "다시 불러오기",
            ar: "إعادة التحميل"
        )
    }

    static var carouselImageUnavailable: String {
        localize(
            es: "Imagen no disponible",
            en: "Image unavailable",
            fr: "Image indisponible",
            pt: "Imagem indisponível",
            ko: "이미지를 사용할 수 없음",
            ar: "الصورة غير متاحة"
        )
    }

    static var mapPinchToZoom: String {
        localize(es: "Pellizca para zoom", en: "Pinch to zoom", fr: "Pincez pour zoomer", pt: "Pince para dar zoom", ko: "확대하려면 핀치", ar: "اضغط للتكبير")
    }

    static var mapReset: String {
        localize(es: "Reset", en: "Reset", fr: "Réinitialiser", pt: "Redefinir", ko: "리셋", ar: "إعادة تعيين")
    }

    static var mapCloseInfo: String {
        localize(es: "Cerrar información", en: "Close info", fr: "Fermer les infos", pt: "Fechar informações", ko: "정보 닫기", ar: "إغلاق المعلومات")
    }

    static var mapService: String {
        localize(es: "Servicio", en: "Service", fr: "Service", pt: "Serviço", ko: "시설", ar: "خدمة")
    }

    static func mapPoint(_ id: Int) -> String {
        localize(
            es: "Punto \(id)",
            en: "Point \(id)",
            fr: "Point \(id)",
            pt: "Ponto \(id)",
            ko: "지점 \(id)",
            ar: "نقطة \(id)"
        )
    }

    static func mapServiceNamed(_ name: String) -> String {
        localize(
            es: "Servicio: \(name)",
            en: "Service: \(name)",
            fr: "Service : \(name)",
            pt: "Serviço: \(name)",
            ko: "시설: \(name)",
            ar: "خدمة: \(name)"
        )
    }

    // MARK: - Survey

    static var surveyTitle: String {
        localize(es: "Encuesta", en: "Survey", fr: "Enquête", pt: "Pesquisa", ko: "설문", ar: "استبيان")
    }

    static var surveyHomeTitle: String {
        localize(
            es: "Encuesta para mejor experiencia",
            en: "Survey for a better experience",
            fr: "Enquête pour une meilleure expérience",
            pt: "Pesquisa para uma experiência melhor",
            ko: "더 나은 경험을 위한 설문",
            ar: "استبيان لتجربة أفضل"
        )
    }

    static var surveyHomeSubtitle: String {
        localize(
            es: "Elige una opción para comenzar",
            en: "Choose an option to begin",
            fr: "Choisissez une option pour commencer",
            pt: "Escolha uma opção para começar",
            ko: "시작할 옵션을 선택하세요",
            ar: "اختر خيارًا للبدء"
        )
    }

    static var surveyStart: String {
        localize(es: "Hacer encuesta", en: "Take survey", fr: "Faire l'enquête", pt: "Fazer pesquisa", ko: "설문 시작", ar: "ابدأ الاستبيان")
    }

    static var surveyViewDescription: String {
        localize(
            es: "Ver descripción del usuario",
            en: "View user description",
            fr: "Voir la description de l'utilisateur",
            pt: "Ver descrição do usuário",
            ko: "사용자 설명 보기",
            ar: "عرض وصف المستخدم"
        )
    }

    static var surveyDescriptionTitle: String {
        localize(
            es: "Descripción del usuario",
            en: "User description",
            fr: "Description de l'utilisateur",
            pt: "Descrição do usuário",
            ko: "사용자 설명",
            ar: "وصف المستخدم"
        )
    }

    static var surveyDescriptionEmpty: String {
        localize(
            es: "Todavía no hay una descripción generada. Primero realiza la encuesta.",
            en: "No description yet. Please take the survey first.",
            fr: "Aucune description pour le moment. Veuillez d'abord faire l'enquête.",
            pt: "Ainda não há descrição. Faça a pesquisa primeiro.",
            ko: "아직 생성된 설명이 없습니다. 먼저 설문을 완료하세요.",
            ar: "لا يوجد وصف بعد. يرجى إجراء الاستبيان أولاً."
        )
    }

    static var surveyShowDescription: String {
        localize(
            es: "Ver descripción generada",
            en: "View generated description",
            fr: "Voir la description générée",
            pt: "Ver descrição gerada",
            ko: "생성된 설명 보기",
            ar: "عرض الوصف الذي تم إنشاؤه"
        )
    }

    static var surveyHideDescription: String {
        localize(
            es: "Ocultar descripción",
            en: "Hide description",
            fr: "Masquer la description",
            pt: "Ocultar descrição",
            ko: "설명 숨기기",
            ar: "إخفاء الوصف"
        )
    }

    static var surveySendToCoque: String {
        localize(
            es: "Mandársela a Coque",
            en: "Send it to Coque",
            fr: "Envoyer à Coque",
            pt: "Enviar para o Coque",
            ko: "Coque에게 보내기",
            ar: "أرسلها إلى Coque"
        )
    }

    static var surveySendReady: String {
        localize(
            es: "Abrirá el chat con tu ruta personalizada",
            en: "It will open the chat with your personalized route",
            fr: "Cela ouvrira le chat avec votre itinéraire personnalisé",
            pt: "Abrirá o chat com sua rota personalizada",
            ko: "맞춤 경로와 함께 채팅이 열립니다",
            ar: "سيفتح الدردشة مع مسارك المخصص"
        )
    }

    static var surveySendNotReady: String {
        localize(
            es: "Primero necesitas contestar la encuesta",
            en: "You need to complete the survey first",
            fr: "Vous devez d'abord remplir l'enquête",
            pt: "Você precisa responder à pesquisa primeiro",
            ko: "먼저 설문을 완료해야 합니다",
            ar: "عليك إكمال الاستبيان أولاً"
        )
    }

    static var surveyBack: String {
        localize(es: "Volver", en: "Back", fr: "Retour", pt: "Voltar", ko: "돌아가기", ar: "رجوع")
    }

    static var surveyLoading: String {
        localize(
            es: "Generando descripción...",
            en: "Generating description…",
            fr: "Génération de la description…",
            pt: "Gerando descrição…",
            ko: "설명 생성 중…",
            ar: "جارٍ إنشاء الوصف…"
        )
    }

    static var surveyRecommendHint: String {
        localize(
            es: "Si eliges “Recomendado”, se elegirá una opción según tus respuestas.",
            en: "If you pick “Recommended”, an option will be chosen based on your answers.",
            fr: "Si vous choisissez « Recommandé », une option sera choisie selon vos réponses.",
            pt: "Se você escolher “Recomendado”, será selecionada uma opção com base nas suas respostas.",
            ko: "“추천”을 선택하면 답변을 바탕으로 옵션이 선택됩니다.",
            ar: "إذا اخترت ”موصى به“، فسيتم اختيار خيار بناءً على إجاباتك."
        )
    }

    static var surveyAlertTitle: String {
        localize(
            es: "Primero cuéntame de ti ✨",
            en: "Tell me about you first ✨",
            fr: "Parlez-moi d'abord de vous ✨",
            pt: "Primeiro me conte sobre você ✨",
            ko: "먼저 자신에 대해 알려주세요 ✨",
            ar: "أخبرني عن نفسك أولاً ✨"
        )
    }

    static var surveyAlertMessage: String {
        localize(
            es: "Contesta la encuesta para que Coque pueda crear una ruta personalizada con tus gustos, tu tiempo y tu estilo de visita.",
            en: "Complete the survey so Coque can create a personalized route based on your tastes, time, and visit style.",
            fr: "Remplissez l'enquête pour que Coque puisse créer un itinéraire personnalisé selon vos goûts, votre temps et votre style de visite.",
            pt: "Preencha a pesquisa para que o Coque crie uma rota personalizada com seus gostos, tempo e estilo de visita.",
            ko: "Coque가 취향, 시간, 방문 스타일에 맞춘 맞춤 경로를 만들 수 있도록 설문을 완료하세요.",
            ar: "أكمل الاستبيان لكي يتمكن Coque من إنشاء مسار مخصص يتناسب مع ذوقك ووقتك ونمط زيارتك."
        )
    }

    static var surveyAlertLater: String {
        localize(es: "Después", en: "Later", fr: "Plus tard", pt: "Depois", ko: "나중에", ar: "لاحقًا")
    }

    static var surveyLoadError: String {
        localize(
            es: "No se pudo cargar la encuesta guardada.",
            en: "Could not load the saved survey.",
            fr: "Impossible de charger l'enquête enregistrée.",
            pt: "Não foi possível carregar a pesquisa salva.",
            ko: "저장된 설문을 불러올 수 없습니다.",
            ar: "تعذّر تحميل الاستبيان المحفوظ."
        )
    }

    static func surveyProgress(current: Int, total: Int) -> String {
        localize(
            es: "Pregunta \(current) de \(total)",
            en: "Question \(current) of \(total)",
            fr: "Question \(current) sur \(total)",
            pt: "Pergunta \(current) de \(total)",
            ko: "\(total)개 중 \(current)번 질문",
            ar: "سؤال \(current) من \(total)"
        )
    }

    // MARK: - Survey validation errors

    static var sqValidateGender: String {
        localize(
            es: "Falta seleccionar el género.",
            en: "Please select your gender.",
            fr: "Veuillez sélectionner votre genre.",
            pt: "Por favor, selecione seu gênero.",
            ko: "성별을 선택해 주세요.",
            ar: "يرجى اختيار الجنس."
        )
    }

    static var sqValidateAge: String {
        localize(
            es: "Falta seleccionar el rango de edad.",
            en: "Please select your age range.",
            fr: "Veuillez sélectionner votre tranche d'âge.",
            pt: "Por favor, selecione sua faixa etária.",
            ko: "나이 범위를 선택해 주세요.",
            ar: "يرجى اختيار الفئة العمرية."
        )
    }

    static var sqValidateTime: String {
        localize(
            es: "Falta seleccionar el tiempo del recorrido.",
            en: "Please select your tour duration.",
            fr: "Veuillez sélectionner la durée de votre visite.",
            pt: "Por favor, selecione a duração do seu tour.",
            ko: "투어 시간을 선택해 주세요.",
            ar: "يرجى اختيار مدة الجولة."
        )
    }

    static var sqValidateAttraction: String {
        localize(
            es: "Falta seleccionar la preferencia de atracciones.",
            en: "Please select your attraction preference.",
            fr: "Veuillez sélectionner vos préférences d'attractions.",
            pt: "Por favor, selecione sua preferência de atrações.",
            ko: "명소 선호도를 선택해 주세요.",
            ar: "يرجى اختيار تفضيل الأماكن."
        )
    }

    static var sqValidateSpecific: String {
        localize(
            es: "Falta seleccionar si buscas algo específico.",
            en: "Please select a specific attraction if any.",
            fr: "Veuillez indiquer si vous avez une attraction spécifique.",
            pt: "Por favor, indique se você tem alguma atração específica.",
            ko: "특정 관광지 여부를 선택해 주세요.",
            ar: "يرجى تحديد ما إذا كنت تبحث عن شيء محدد."
        )
    }

    static var sqValidateLanguage: String {
        localize(
            es: "Falta seleccionar el idioma.",
            en: "Please select a language.",
            fr: "Veuillez sélectionner une langue.",
            pt: "Por favor, selecione um idioma.",
            ko: "언어를 선택해 주세요.",
            ar: "يرجى اختيار اللغة."
        )
    }

    static var sqValidatePersonality: String {
        localize(
            es: "Falta seleccionar la personalidad de Coque.",
            en: "Please select Coque's personality.",
            fr: "Veuillez sélectionner la personnalité de Coque.",
            pt: "Por favor, selecione a personalidade do Coque.",
            ko: "Coque의 성격을 선택해 주세요.",
            ar: "يرجى اختيار شخصية Coque."
        )
    }

    // MARK: - Onboarding

    static var onboardingSkip: String {
        localize(es: "Saltar", en: "Skip", fr: "Passer", pt: "Pular", ko: "건너뛰기", ar: "تخطي")
    }

    static var onboardingSkipHint: String {
        localize(
            es: "Cierra la introducción y entra al museo.",
            en: "Dismiss the intro and enter the museum.",
            fr: "Ferme l'introduction et entre au musée.",
            pt: "Fecha a introdução e entra no museu.",
            ko: "소개를 닫고 박물관에 입장합니다.",
            ar: "إغلاق المقدمة والدخول إلى المتحف."
        )
    }

    static var onboardingNext: String {
        localize(es: "Siguiente", en: "Next", fr: "Suivant", pt: "Próximo", ko: "다음", ar: "التالي")
    }

    static func onboardingStepLabel(current: Int, total: Int) -> String {
        localize(
            es: "Paso \(current) de \(total)",
            en: "Step \(current) of \(total)",
            fr: "Étape \(current) sur \(total)",
            pt: "Passo \(current) de \(total)",
            ko: "\(total)단계 중 \(current)단계",
            ar: "الخطوة \(current) من \(total)"
        )
    }

    // Página 1: Bienvenida
    static var onboardingWelcomeTitle: String {
        localize(
            es: "Bienvenido al Museo del Acero Horno3",
            en: "Welcome to the Horno3 Steel Museum",
            fr: "Bienvenue au Musée de l'Acier Horno3",
            pt: "Bem-vindo ao Museu do Aço Horno3",
            ko: "Horno3 철강 박물관에 오신 것을 환영합니다",
            ar: "مرحبًا بك في متحف هورنو3 للصلب"
        )
    }

    static var onboardingWelcomeSubtitle: String {
        localize(
            es: "Coque te acompaña durante toda tu visita para hacerla inolvidable.",
            en: "Coque will guide you throughout your visit to make it unforgettable.",
            fr: "Coque t'accompagne tout au long de ta visite pour la rendre inoubliable.",
            pt: "Coque te acompanha durante toda a visita para torná-la inesquecível.",
            ko: "Coque가 방문 내내 함께하며 잊을 수 없는 경험을 선사합니다.",
            ar: "سيرافقك Coque طوال زيارتك ليجعلها لا تُنسى."
        )
    }

    // Página 2: Capacidades
    static var onboardingCapabilitiesTitle: String {
        localize(
            es: "Qué puedes hacer",
            en: "What you can do",
            fr: "Ce que tu peux faire",
            pt: "O que você pode fazer",
            ko: "할 수 있는 것",
            ar: "ما يمكنك فعله"
        )
    }

    static var onboardingCapabilitiesSubtitle: String {
        localize(
            es: "Tres herramientas para aprovechar tu visita al máximo.",
            en: "Three tools to make the most of your visit.",
            fr: "Trois outils pour profiter au maximum de ta visite.",
            pt: "Três ferramentas para aproveitar ao máximo sua visita.",
            ko: "방문을 최대한 활용할 수 있는 세 가지 도구입니다.",
            ar: "ثلاث أدوات للاستفادة القصوى من زيارتك."
        )
    }

    static var onboardingCapScanTitle: String {
        localize(
            es: "Escanea objetos del museo",
            en: "Scan museum objects",
            fr: "Scanne les objets du musée",
            pt: "Escaneia objetos do museu",
            ko: "박물관 물품 스캔",
            ar: "امسح قطع المتحف"
        )
    }

    static var onboardingCapScanSubtitle: String {
        localize(
            es: "Apunta la cámara a una pieza y conoce su historia.",
            en: "Point the camera at a piece to learn its story.",
            fr: "Pointe la caméra vers une pièce pour connaître son histoire.",
            pt: "Aponte a câmera para uma peça e conheça sua história.",
            ko: "카메라를 유물에 가져다 대어 이야기를 알아보세요.",
            ar: "وجّه الكاميرا إلى القطعة لمعرفة قصتها."
        )
    }

    static var onboardingCapAskTitle: String {
        localize(
            es: "Pregúntale a Coque",
            en: "Ask Coque",
            fr: "Demande à Coque",
            pt: "Pergunta ao Coque",
            ko: "Coque에게 물어보기",
            ar: "اسأل Coque"
        )
    }

    static var onboardingCapAskSubtitle: String {
        localize(
            es: "Resuelve dudas o pide recomendaciones en cualquier momento.",
            en: "Get answers or recommendations anytime.",
            fr: "Obtiens des réponses ou des recommandations à tout moment.",
            pt: "Tire dúvidas ou peça recomendações a qualquer momento.",
            ko: "언제든지 질문하거나 추천을 받아보세요.",
            ar: "احصل على إجابات أو توصيات في أي وقت."
        )
    }

    static var onboardingCapMapTitle: String {
        localize(
            es: "Explora el mapa",
            en: "Explore the map",
            fr: "Explore la carte",
            pt: "Explore o mapa",
            ko: "지도 살펴보기",
            ar: "استكشف الخريطة"
        )
    }

    static var onboardingCapMapSubtitle: String {
        localize(
            es: "Ubica atracciones, servicios y rutas sugeridas.",
            en: "Find attractions, services and suggested routes.",
            fr: "Trouve les attractions, services et itinéraires suggérés.",
            pt: "Encontre atrações, serviços e rotas sugeridas.",
            ko: "명소, 시설, 추천 경로를 찾아보세요.",
            ar: "اعثر على المعالم والخدمات والمسارات المقترحة."
        )
    }

    // Página 3: Encuesta
    static var onboardingSurveyTitle: String {
        localize(
            es: "Responde una encuesta rápida",
            en: "Answer a quick survey",
            fr: "Réponds à un rapide questionnaire",
            pt: "Responda a uma pesquisa rápida",
            ko: "간단한 설문 조사에 답해 주세요",
            ar: "أجب عن استبيان سريع"
        )
    }

    static var onboardingSurveySubtitle: String {
        localize(
            es: "Coque personalizará tu recorrido según tus preferencias. Solo toma un minuto.",
            en: "Coque will personalize your tour based on your preferences. It only takes a minute.",
            fr: "Coque personnalisera ta visite selon tes préférences. Cela ne prend qu'une minute.",
            pt: "O Coque personalizará seu passeio de acordo com suas preferências. Leva apenas um minuto.",
            ko: "Coque가 취향에 맞게 투어를 맞춤 설정합니다. 1분이면 충분합니다.",
            ar: "سيخصص Coque جولتك وفقًا لتفضيلاتك. الأمر يستغرق دقيقة فقط."
        )
    }

    static var onboardingStartSurvey: String {
        localize(
            es: "Comenzar encuesta",
            en: "Start survey",
            fr: "Commencer le questionnaire",
            pt: "Iniciar pesquisa",
            ko: "설문 조사 시작",
            ar: "بدء الاستبيان"
        )
    }

    static var onboardingSkipSurvey: String {
        localize(
            es: "Ahora no, gracias",
            en: "Not now, thanks",
            fr: "Pas maintenant, merci",
            pt: "Agora não, obrigado",
            ko: "지금은 괜찮습니다",
            ar: "ليس الآن، شكرًا"
        )
    }

    // MARK: - Helper privado

    /// Devuelve la variante correspondiente al idioma del dispositivo.
    /// Si el idioma no está cubierto, cae a español.
    private static func localize(
        es: String,
        en: String,
        fr: String,
        pt: String,
        ko: String,
        ar: String
    ) -> String {
        switch AppLanguage.device {
        case .spanish:    return es
        case .english:    return en
        case .french:     return fr
        case .portuguese: return pt
        case .korean:     return ko
        case .arabic:     return ar
        }
    }
}
