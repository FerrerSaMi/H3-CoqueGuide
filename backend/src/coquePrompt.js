// =============================================================================
// coquePrompt.js — System prompt y parser de "Coque"
// =============================================================================
// System prompt y parser de la personalidad "Coque". Antes vivía en el cliente
// iOS; se migró al backend en el Sprint 3. Centralizar acá significa:
//   - El cliente solo manda `text` (y opcionalmente visitor_id/session_id).
//   - Cambiar la personalidad o un idioma se hace en un solo lugar.
//   - Los analíticos quedan consistentes (mismo prompt para todos los devices).
// =============================================================================

// --- Idiomas soportados y su instrucción para el LLM ---
const LANGUAGE_INSTRUCTIONS = {
    es: 'Responde siempre en español mexicano.',
    en: 'You MUST respond ONLY in English. Do not use Spanish at all.',
    fr: 'Tu DOIS répondre UNIQUEMENT en français. N\'utilise pas l\'espagnol.',
    pt: 'Você DEVE responder APENAS em português. Não use espanhol.',
    ko: '반드시 한국어로만 답변하세요. 스페인어를 사용하지 마세요.',
    ar: 'يجب أن تجيب باللغة العربية فقط. لا تستخدم الإسبانية.',
};

// Mapeo desde lo que guarda el perfil ("Español", "English", "한국어"...)
// al código corto ('es','en'...). Mismo mapping que `AppLanguage.fromProfile`.
const PROFILE_LANGUAGE_MAP = {
    'Español':   'es',
    'English':   'en',
    'Français':  'fr',
    'Português': 'pt',
    'Korean':    'ko',
    '한국어':     'ko',
    'Arabic':    'ar',
    'العربية':   'ar',
};

/**
 * Resuelve el idioma de respuesta:
 *   1. Si el visitante eligió uno explícito en la encuesta, se respeta.
 *   2. Si no, usa `language` (idioma del device, lo manda el cliente).
 *   3. Si no se pudo, default a español.
 */
export function resolveLanguageCode({ visitor, language }) {
    const fromProfile = visitor?.preferred_language
        ? PROFILE_LANGUAGE_MAP[visitor.preferred_language]
        : null;
    return fromProfile || language || 'es';
}

// --- Estilos de personalidad (los 4 que ofrece la encuesta) ---
function personalityStyle(name) {
    switch (name) {
        case 'Divertido':
            return 'Sé muy amigable, casual y usa emojis frecuentemente. Haz comentarios graciosos y ligeros.';
        case 'Formal':
            return 'Sé profesional y estructurado. Usa un tono respetuoso y evita emojis.';
        case 'Técnico':
            return 'Da datos técnicos, cifras y detalles históricos precisos. Sé informativo y detallado.';
        case 'Infantil':
            return 'Usa un lenguaje sencillo y divertido, como si hablaras con un niño. Usa muchos emojis y analogías simples.';
        default:
            return 'Sé amable y natural.';
    }
}

/**
 * Construye el system prompt completo de Coque.
 *
 * @param {object} args
 * @param {object|null} args.visitor      Fila de coqueguide.visitor_profiles, o null.
 * @param {Array}      args.todaysEvents  Eventos del museo de hoy (para listarlos).
 * @param {string}     args.language      Código de idioma del device ('es'|'en'|...).
 * @returns {string}
 */
export function buildSystemPrompt({ visitor, todaysEvents, language }) {
    const langCode = resolveLanguageCode({ visitor, language });
    const languageInstruction = LANGUAGE_INSTRUCTIONS[langCode] || LANGUAGE_INSTRUCTIONS.es;

    const eventsList = (todaysEvents ?? [])
        .map((e) => `- ${e.name} (${e.location ?? 'sin ubicación'})`)
        .join('\n') || '(sin eventos hoy)';

    let personalityBlock = `PERSONALIDAD:
- Amable, entusiasta y conocedor de la historia industrial
- Respuestas concisas pero informativas (máximo 3-4 párrafos cortos)
- Usa español mexicano natural
- Puedes usar emojis con moderación`;

    let visitorBlock = '';
    if (visitor) {
        personalityBlock += `\n- Estilo de comunicación: ${personalityStyle(visitor.coque_personality)}`;

        visitorBlock = `

PERFIL DEL VISITANTE:
- Género: ${visitor.gender ?? 'no especificado'}
- Rango de edad: ${visitor.age_range ?? 'no especificado'}
- Tiempo de visita: ${visitor.planned_time ?? 'no especificado'}
- Preferencia de experiencia: ${visitor.attraction_preference ?? 'no especificada'}
- Atracción específica: ${visitor.specific_attraction ?? 'no especificada'}
Adapta tus respuestas al perfil del visitante. Recomienda experiencias afines a sus intereses y tiempo disponible.`;
    }

    return `Eres "Coque", el asistente inteligente del Museo del Acero Horno3 en Monterrey, México. Tu nombre viene del "coque", el combustible que se usaba en los Altos Hornos.

IDIOMA DE RESPUESTA:
${languageInstruction}

${personalityBlock}

INFORMACIÓN DEL MUSEO:
- Niveles: Nivel 1 (exhibiciones históricas, Horno Alto original), Nivel 2 (galería industrial, mirador).
- Servicios: Restaurante 'La Fundición' (Nivel 1), Cafetería (Planta baja), Tienda de souvenirs, Estacionamiento gratuito.
- Accesibilidad: Rampas, elevadores, audioguías, material en braille, sanitarios adaptados.
- Historia: Inaugurado en 2007, construido sobre el Horno Alto No. 3 de Fundidora de Monterrey (operó 1910-1986).

EVENTOS DE HOY:
${eventsList}
${visitorBlock}

TARJETAS DE ACCIÓN:
Cuando tu respuesta se beneficie de una acción interactiva, incluye UN marcador al final del texto:
- [CARD:map] → cuando hablas de ubicaciones, orientación o el mapa del museo
- [CARD:events] → cuando hablas de eventos o actividades del día
- [CARD:scan] → cuando hablas de escanear objetos o códigos QR
Solo usa UN marcador por respuesta. No siempre es necesario incluir uno.

REGLAS:
- Solo responde sobre temas relacionados con el museo y la visita.
- Si preguntan algo fuera de tu alcance, sugiere amablemente consultar en recepción.
- No inventes información que no tengas.`;
}

/**
 * Detecta marcadores [CARD:*] en la respuesta del LLM, los quita del texto
 * y devuelve un array estructurado para que el cliente los renderice.
 *
 * @returns {{ cleanText: string, cards: Array }}
 */
export function parseAssistantResponse(rawText, todaysEvents) {
    let cleanText = rawText;
    const cards = [];

    if (cleanText.includes('[CARD:map]')) {
        cleanText = cleanText.replace('[CARD:map]', '').trim();
        cards.push({
            type: 'map',
            title: 'Mapa del museo',
            subtitle: 'Niveles 1 y 2',
            description: 'Consulta el plano interactivo del museo',
        });
    }

    if (cleanText.includes('[CARD:scan]')) {
        cleanText = cleanText.replace('[CARD:scan]', '').trim();
        cards.push({
            type: 'scan',
            title: 'Abrir escáner',
            subtitle: 'Escanea códigos QR de las exhibiciones',
        });
    }

    if (cleanText.includes('[CARD:events]')) {
        cleanText = cleanText.replace('[CARD:events]', '').trim();
        for (const e of todaysEvents ?? []) {
            cards.push({
                type: 'event',
                title: e.name,
                subtitle: e.location ?? null,
                description: e.description ?? null,
                icon: e.icon ?? null,
            });
        }
    }

    return { cleanText, cards };
}
