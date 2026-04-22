// =============================================================================
// server.js — Punto de entrada del backend H3-CoqueGuide
// =============================================================================
// Levanta un servidor Express con los endpoints mínimos:
//   - GET /health  → diagnóstico (servidor vivo + BD conectada)
//
// Más adelante agregaremos:
//   - POST /profile           → guardar perfil de encuesta
//   - POST /events            → registrar evento de uso
//   - POST /chat/message      → proxy a Gemini con persistencia
// =============================================================================

import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import { pool, query } from './db.js';
import { buildSystemPrompt, parseAssistantResponse } from './coquePrompt.js';
import { callGemini } from './geminiClient.js';

const app = express();
const PORT = Number(process.env.PORT) || 8080;

// --- Middlewares ---

// CORS abierto por ahora (en producción restringimos a dominios conocidos).
app.use(cors());

// Parsea JSON entrantes; límite bajo porque no esperamos payloads grandes.
app.use(express.json({ limit: '256kb' }));

// Logger simple de cada request entrante.
app.use((req, _res, next) => {
    console.log(`→ ${req.method} ${req.path}`);
    next();
});

// --- Endpoints ---

/**
 * GET /health
 * Devuelve estado del servidor y verifica que la conexión a Postgres funciona.
 * Útil para:
 *   - Probar local que `npm start` quedó bien.
 *   - Cloud Run usa este endpoint para health checks de readiness.
 */
app.get('/health', async (_req, res) => {
    try {
        const result = await query(
            "SELECT NOW() as now, current_database() as db, current_user as usr"
        );
        res.json({
            ok: true,
            server: 'up',
            db: 'connected',
            now: result.rows[0].now,
            database: result.rows[0].db,
            user: result.rows[0].usr,
        });
    } catch (err) {
        console.error('❌ /health DB check failed:', err.message);
        res.status(503).json({
            ok: false,
            server: 'up',
            db: 'disconnected',
            error: err.message,
        });
    }
});

/**
 * POST /profile
 * Guarda un perfil de visitante (resultado de la encuesta inicial).
 * Espejo del @Model `ExcursionUserProfile` del cliente iOS.
 *
 * Body esperado (JSON):
 * {
 *   "device_id": "...",
 *   "gender": "...",
 *   "age_range": "...",
 *   "planned_time": "...",
 *   "attraction_preference": "...",
 *   "resolved_attraction_preference": "...",
 *   "specific_attraction": "...",
 *   "preferred_language": "...",
 *   "coque_personality": "...",
 *   "ai_description_text": "..."
 * }
 *
 * Respuesta: { ok: true, id: "<uuid>" }
 */
app.post('/profile', async (req, res) => {
    try {
        const {
            device_id,
            gender,
            age_range,
            planned_time,
            attraction_preference,
            resolved_attraction_preference,
            specific_attraction,
            preferred_language,
            coque_personality,
            ai_description_text,
        } = req.body ?? {};

        const result = await query(
            `INSERT INTO coqueguide.visitor_profiles (
                device_id,
                gender,
                age_range,
                planned_time,
                attraction_preference,
                resolved_attraction_preference,
                specific_attraction,
                preferred_language,
                coque_personality,
                ai_description_text
            ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
            RETURNING id, created_at`,
            [
                device_id ?? null,
                gender ?? null,
                age_range ?? null,
                planned_time ?? null,
                attraction_preference ?? null,
                resolved_attraction_preference ?? null,
                specific_attraction ?? null,
                preferred_language ?? null,
                coque_personality ?? null,
                ai_description_text ?? null,
            ]
        );

        res.status(201).json({
            ok: true,
            id: result.rows[0].id,
            created_at: result.rows[0].created_at,
        });
    } catch (err) {
        console.error('❌ POST /profile failed:', err.message);
        res.status(500).json({ ok: false, error: err.message });
    }
});

/**
 * POST /events
 * Registra un evento de uso (analytics). El campo `metadata` es libre (JSONB),
 * así no necesitamos cambiar el schema cada vez que aparece un evento nuevo.
 *
 * Body esperado (JSON):
 * {
 *   "visitor_id": "<uuid>" | null,   // opcional, si ya hay perfil
 *   "device_id": "...",
 *   "event_name": "scanner_opened",  // requerido
 *   "metadata": { ... },             // opcional, JSON libre
 *   "app_version": "1.0.3",
 *   "device_language": "es"
 * }
 *
 * Respuesta: { ok: true, id: <bigint>, occurred_at: "..." }
 */
app.post('/events', async (req, res) => {
    try {
        const {
            visitor_id,
            device_id,
            event_name,
            metadata,
            app_version,
            device_language,
        } = req.body ?? {};

        if (!event_name || typeof event_name !== 'string') {
            return res.status(400).json({
                ok: false,
                error: 'event_name es requerido (string).',
            });
        }

        const result = await query(
            `INSERT INTO coqueguide.usage_events (
                visitor_id,
                device_id,
                event_name,
                metadata,
                app_version,
                device_language
            ) VALUES ($1,$2,$3,$4,$5,$6)
            RETURNING id, occurred_at`,
            [
                visitor_id ?? null,
                device_id ?? null,
                event_name,
                metadata ? JSON.stringify(metadata) : '{}',
                app_version ?? null,
                device_language ?? null,
            ]
        );

        res.status(201).json({
            ok: true,
            id: result.rows[0].id,
            occurred_at: result.rows[0].occurred_at,
        });
    } catch (err) {
        console.error('❌ POST /events failed:', err.message);
        res.status(500).json({ ok: false, error: err.message });
    }
});

/**
 * GET /museum-events/today
 * Devuelve los eventos del museo activos para "hoy" (zona horaria del server).
 * Reemplaza lo que hoy está hardcoded en CGEventService del cliente iOS.
 *
 * Respuesta: { ok: true, events: [ {...}, {...} ] }
 */
app.get('/museum-events/today', async (_req, res) => {
    try {
        const result = await query(
            `SELECT id, name, description, location, icon,
                    starts_at, ends_at
             FROM coqueguide.museum_events
             WHERE active
               AND starts_at::date = CURRENT_DATE
             ORDER BY starts_at ASC`
        );
        res.json({ ok: true, events: result.rows });
    } catch (err) {
        console.error('❌ GET /museum-events/today failed:', err.message);
        res.status(500).json({ ok: false, error: err.message });
    }
});

/**
 * POST /survey/description
 * Genera la descripción del visitante a partir del perfil de la encuesta.
 * Antes vivía en el cliente iOS (SurveyAIService) llamando a Gemini con la
 * API key embebida. Ahora se centraliza aquí para que la key no viva en el
 * binario.
 *
 * Body esperado (JSON):
 * {
 *   "gender": "...",
 *   "age_range": "...",
 *   "planned_time": "...",
 *   "attraction_preference": "...",
 *   "resolved_attraction_preference": "...",
 *   "specific_attraction": "...",
 *   "preferred_language": "Español" | "English" | ...,
 *   "coque_personality": "..."
 * }
 *
 * Respuesta: { ok: true, description: "..." }
 */
app.post('/survey/description', async (req, res) => {
    const {
        gender,
        age_range,
        planned_time,
        attraction_preference,
        resolved_attraction_preference,
        specific_attraction,
        preferred_language,
        coque_personality,
    } = req.body ?? {};

    const outputLanguageName = {
        'Español':   'Spanish',
        'English':   'English',
        'Français':  'French',
        'Português': 'Portuguese',
        'Korean':    'Korean',
        'Arabic':    'Arabic',
    }[preferred_language] || 'Spanish';

    const prompt = `Create one complete paragraph describing this museum visitor using all available data.

Visitor data:
- Gender: ${gender ?? ''}
- Age range: ${age_range ?? ''}
- Planned visit time: ${planned_time ?? ''}
- Attraction preference selected: ${attraction_preference ?? ''}
- Final attraction style to use: ${resolved_attraction_preference ?? ''}
- Specific attraction requested: ${specific_attraction ?? ''}
- Preferred language: ${preferred_language ?? ''}
- Preferred Coque personality: ${coque_personality ?? ''}

Rules:
- Use every visitor data field to build a complete personality and preference description.
- Do not stop mid-sentence or cut off any values.
- End the paragraph with a complete sentence and a final period.
- Write at least 100 words.
- Prefer longer, complete content over short replies; do not shorten the response to save tokens.
- If the selected preference was "Recomendado", use the resolved attraction style naturally.
- If the visitor selected "No" for a specific attraction, do not invent one.
- Keep the result to one paragraph only.
- The paragraph must be written only in this language: ${outputLanguageName}.
- Do not mix languages.`;

    try {
        const description = await callGemini({
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            temperature: 0.2,
            maxOutputTokens: 2048,
        });

        if (!description) {
            return res.status(502).json({
                ok: false,
                error: 'Gemini respondió vacío.',
            });
        }

        res.json({ ok: true, description });
    } catch (err) {
        console.error('❌ POST /survey/description failed:', err.message);
        res.status(500).json({ ok: false, error: err.message });
    }
});

/**
 * POST /chat/message
 * MVP: recibe el texto del usuario, lo guarda, lo manda tal cual a Gemini,
 * guarda la respuesta y la devuelve. Sin lógica de personalidad/idioma todavía
 * (eso se mueve al backend en una segunda iteración).
 *
 * Body esperado (JSON):
 * {
 *   "visitor_id": "<uuid>" | null,
 *   "device_id": "...",
 *   "session_id": "<uuid>" | null,
 *   "text": "Hola Coque",
 *   "language": "es",
 *   "personality": "amigable"
 * }
 *
 * Respuesta:
 * {
 *   ok: true,
 *   user_message_id: <bigint>,
 *   assistant_message_id: <bigint>,
 *   reply: "..."
 * }
 */
app.post('/chat/message', async (req, res) => {
    const {
        visitor_id,
        device_id,
        session_id,
        text,
        language,
        personality,
    } = req.body ?? {};

    if (!text || typeof text !== 'string') {
        return res.status(400).json({
            ok: false,
            error: 'text es requerido (string).',
        });
    }

    try {
        // 1) Cargar perfil (si hay visitor_id), eventos del día e historial.
        const [visitorRows, eventsRows, historyRows] = await Promise.all([
            visitor_id
                ? query(
                    `SELECT gender, age_range, planned_time, attraction_preference,
                            specific_attraction, preferred_language, coque_personality
                     FROM coqueguide.visitor_profiles WHERE id = $1`,
                    [visitor_id]
                )
                : Promise.resolve({ rows: [] }),
            query(
                `SELECT name, description, location, icon
                 FROM coqueguide.museum_events
                 WHERE active AND starts_at::date = CURRENT_DATE
                 ORDER BY starts_at ASC`
            ),
            session_id
                ? query(
                    `SELECT role, text FROM coqueguide.chat_messages
                     WHERE session_id = $1
                     ORDER BY created_at DESC LIMIT 20`,
                    [session_id]
                )
                : Promise.resolve({ rows: [] }),
        ]);

        const visitor = visitorRows.rows[0] || null;
        const todaysEvents = eventsRows.rows;

        // El historial llega DESC por created_at; lo invertimos para mandar
        // en orden cronológico al LLM.
        const history = historyRows.rows.reverse().map((m) => ({
            role: m.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: m.text }],
        }));

        // 2) Construir contents para Gemini: historial + nuevo mensaje del user.
        const contents = [
            ...history,
            { role: 'user', parts: [{ text }] },
        ];

        const systemInstruction = buildSystemPrompt({
            visitor,
            todaysEvents,
            language,
        });

        // 3) Guardar el mensaje del usuario ANTES de llamar a Gemini, para que
        // quede registro aunque el LLM falle.
        const usedPersonality = personality ?? visitor?.coque_personality ?? null;
        const usedLanguage    = language ?? visitor?.preferred_language ?? null;

        const userInsert = await query(
            `INSERT INTO coqueguide.chat_messages
                (visitor_id, device_id, session_id, role, text, language, personality)
             VALUES ($1,$2,$3,'user',$4,$5,$6)
             RETURNING id`,
            [
                visitor_id ?? null,
                device_id ?? null,
                session_id ?? null,
                text,
                usedLanguage,
                usedPersonality,
            ]
        );

        // 4) Llamar a Gemini con system_instruction + contents.
        const reply = await callGemini({
            contents,
            systemInstruction,
            temperature: 0.7,
            maxOutputTokens: 4096,
        });
        const rawReply = reply || '(sin respuesta)';

        // 5) Parsear marcadores [CARD:*] y construir cards estructuradas.
        const { cleanText, cards } = parseAssistantResponse(rawReply, todaysEvents);

        // 6) Guardar la respuesta del asistente (texto limpio + cards en JSONB).
        const assistantInsert = await query(
            `INSERT INTO coqueguide.chat_messages
                (visitor_id, device_id, session_id, role, text, language, personality, cards)
             VALUES ($1,$2,$3,'assistant',$4,$5,$6,$7)
             RETURNING id`,
            [
                visitor_id ?? null,
                device_id ?? null,
                session_id ?? null,
                cleanText,
                usedLanguage,
                usedPersonality,
                cards.length ? JSON.stringify(cards) : null,
            ]
        );

        res.json({
            ok: true,
            user_message_id: userInsert.rows[0].id,
            assistant_message_id: assistantInsert.rows[0].id,
            reply: cleanText,
            cards,
        });
    } catch (err) {
        console.error('❌ POST /chat/message failed:', err.message);
        res.status(500).json({ ok: false, error: err.message });
    }
});

/**
 * Fallback 404 para cualquier ruta no definida.
 */
app.use((req, res) => {
    res.status(404).json({ ok: false, error: `Not found: ${req.method} ${req.path}` });
});

// --- Arranque ---

app.listen(PORT, () => {
    console.log('');
    console.log('🚀 H3-CoqueGuide backend');
    console.log(`   Listening on http://localhost:${PORT}`);
    console.log('');
    console.log('   Prueba:');
    console.log(`     curl http://localhost:${PORT}/health`);
    console.log('');
});

// --- Cierre limpio ---
// Cloud Run manda SIGTERM antes de matar el contenedor; cerramos el pool
// ordenadamente para no dejar conexiones colgadas en Postgres.
process.on('SIGTERM', async () => {
    console.log('⏹  SIGTERM recibido, cerrando pool de Postgres…');
    await pool.end();
    process.exit(0);
});
