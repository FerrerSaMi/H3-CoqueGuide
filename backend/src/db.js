// =============================================================================
// db.js — Cliente Postgres
// =============================================================================
// Crea un Pool de conexiones reutilizable contra la BD de GCP Cloud SQL.
// Lee las credenciales de variables de entorno (definidas en .env localmente,
// o inyectadas por Cloud Run en producción).
//
// Por qué un Pool y no conexiones sueltas:
//   Postgres tarda ~30-100ms en abrir cada conexión nueva. Un Pool mantiene
//   conexiones abiertas listas para reusarse, así cada request es ~1ms.
// =============================================================================

import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

export const pool = new Pool({
    host:     process.env.PGHOST,
    port:     Number(process.env.PGPORT) || 5432,
    user:     process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    // Cloud SQL exige SSL. `rejectUnauthorized: false` acepta el certificado
    // auto-generado de Cloud SQL sin necesidad de bajar el CA explícitamente.
    ssl: process.env.PGSSLMODE === 'require'
        ? { rejectUnauthorized: false }
        : false,
    // Tuneado para serverless (Vercel Functions):
    //   - max:1     → cada instancia caliente abre como máximo 1 conexión.
    //                 Vercel puede levantar muchas instancias en paralelo, así
    //                 que mantenerlo bajo evita reventar el límite de
    //                 conexiones de Cloud SQL Postgres.
    //   - idleTimeout corto → la conexión se cierra rápido cuando la función
    //                 deja de recibir tráfico, liberando slots en Postgres.
    //   - connectionTimeout 5s → si la BD tarda más en aceptar, fallamos rápido
    //                 antes de chocar con el timeout total de la función.
    max: 1,
    idleTimeoutMillis: 10000,
    connectionTimeoutMillis: 5000,
});

// Si una conexión del pool muere por sí sola, lo logueamos para no quedarnos
// debugueando en silencio.
pool.on('error', (err) => {
    console.error('❌ Pool error inesperado:', err);
});

/**
 * Helper para ejecutar queries con logging de tiempo.
 * Uso:
 *   const { rows } = await query('SELECT * FROM coqueguide.visitor_profiles WHERE id = $1', [id]);
 */
export async function query(text, params) {
    const start = Date.now();
    const result = await pool.query(text, params);
    const ms = Date.now() - start;
    const preview = text.split('\n').map(l => l.trim()).filter(Boolean)[0]?.slice(0, 80);
    console.log(`📊 SQL [${ms}ms]: ${preview}`);
    return result;
}
