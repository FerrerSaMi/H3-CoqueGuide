// =============================================================================
// api/index.js — Entry point para Vercel Serverless Functions
// =============================================================================
// Vercel detecta automáticamente cualquier archivo dentro de `api/` y lo expone
// como una función serverless. Aquí re-exportamos el `app` de Express que vive
// en `src/server.js`. El routing real (a `/health`, `/profile`, etc.) lo hace
// `vercel.json` mandando TODAS las rutas a este único handler.
//
// Por qué un solo handler en lugar de un archivo por endpoint:
//   - Reusamos el `app` de Express tal cual (mismos middlewares, mismo logging).
//   - Una sola "function" en Vercel → un solo cold start y un solo pool de
//     conexiones a Postgres compartido entre invocaciones calientes.
// =============================================================================

export { default } from '../src/server.js';
