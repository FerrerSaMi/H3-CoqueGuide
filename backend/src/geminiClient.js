// =============================================================================
// geminiClient.js — Cliente unificado para la API de Gemini (generateContent)
// =============================================================================
// Centraliza la llamada HTTP a Gemini para que los endpoints del server no
// dupliquen el bloque de fetch + manejo de errores + extracción del texto.
//
// Uso típico:
//   import { callGemini } from './geminiClient.js';
//   const text = await callGemini({
//       contents: [{ role: 'user', parts: [{ text: prompt }] }],
//       temperature: 0.2,
//       maxOutputTokens: 2048,
//   });
//
// Para el chat se pasa también `systemInstruction`:
//   const reply = await callGemini({
//       contents,
//       systemInstruction,
//       temperature: 0.7,
//       maxOutputTokens: 4096,
//   });
// =============================================================================

import 'dotenv/config';

const DEFAULT_MODEL = 'gemini-2.5-flash';
const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Error específico de las llamadas a Gemini. Permite a los endpoints distinguir
 * entre "falta configuración" (500 puro del server) y "Gemini respondió mal"
 * (que podría mapearse a 502 en el futuro).
 */
export class GeminiError extends Error {
    /**
     * @param {string} message
     * @param {{ kind?: 'config' | 'http', status?: number }} [opts]
     */
    constructor(message, { kind, status } = {}) {
        super(message);
        this.name = 'GeminiError';
        this.kind = kind;
        this.status = status;
    }
}

/**
 * Llama a Gemini `generateContent` y devuelve el texto concatenado de la
 * respuesta (primer candidato). Devuelve `''` si Gemini respondió vacío —
 * corresponde al caller decidir qué hacer en ese caso.
 *
 * @param {object} params
 * @param {Array<{role: string, parts: Array<{text: string}>}>} params.contents
 *        Mensajes de la conversación (al menos uno con role 'user').
 * @param {string} [params.systemInstruction]
 *        Prompt de sistema opcional. Si se omite, Gemini usa su comportamiento por defecto.
 * @param {number} [params.temperature=0.7]
 * @param {number} [params.maxOutputTokens=2048]
 * @param {string} [params.model]
 *        Sobreescribe el modelo (default: env GEMINI_MODEL o `gemini-2.5-flash`).
 * @returns {Promise<string>} Texto plano concatenado de `candidates[0].content.parts`.
 * @throws {GeminiError} Si falta la API key o Gemini devuelve un status !== 2xx.
 */
export async function callGemini({
    contents,
    systemInstruction = null,
    temperature = 0.7,
    maxOutputTokens = 2048,
    model,
}) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new GeminiError(
            'GEMINI_API_KEY no está configurado en el server.',
            { kind: 'config' }
        );
    }

    const resolvedModel = model || process.env.GEMINI_MODEL || DEFAULT_MODEL;
    const url = `${API_BASE}/${resolvedModel}:generateContent?key=${apiKey}`;

    /** @type {Record<string, unknown>} */
    const body = {
        contents,
        generationConfig: { maxOutputTokens, temperature },
    };
    if (systemInstruction) {
        body.system_instruction = { parts: [{ text: systemInstruction }] };
    }

    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const errText = await res.text();
        throw new GeminiError(
            `Gemini ${res.status}: ${errText.slice(0, 200)}`,
            { kind: 'http', status: res.status }
        );
    }

    const json = await res.json();
    const text = (json?.candidates?.[0]?.content?.parts ?? [])
        .map((p) => p.text ?? '')
        .join('')
        .trim();

    return text;
}
