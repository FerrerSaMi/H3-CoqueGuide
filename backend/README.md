# H3-CoqueGuide Backend

Backend Node.js intermedio entre la app iOS H3-CoqueGuide y la BD Postgres
en GCP. Maneja perfiles de visitante, analytics y proxy a Gemini.

## Stack

- Node.js ≥ 20 (ESM)
- Express
- pg (driver oficial Postgres)
- dotenv

## Arranque local

### 1. Instalar dependencias

```bash
cd backend
npm install
```

### 2. Crear `.env` con credenciales reales

```bash
cp .env.example .env
```

Edita `.env` y rellena con los valores que dio el socio formador.
**Nunca commitees el `.env`** — está en `.gitignore`.

### 3. Verificar que la BD tenga el schema

Ejecuta `db/schema.sql` contra la BD desde pgAdmin o la extensión de Postgres
de VS Code. Es idempotente (puedes correrlo varias veces sin romper nada).

### 4. Arrancar el servidor

```bash
npm run dev      # con auto-reload al editar (desarrollo)
# o
npm start        # sin auto-reload
```

Deberías ver:

```
🚀 H3-CoqueGuide backend
   Listening on http://localhost:8080
```

### 5. Probar

```bash
curl http://localhost:8080/health
```

Respuesta esperada:

```json
{
  "ok": true,
  "server": "up",
  "db": "connected",
  "now": "2026-04-17T03:14:15.926Z",
  "database": "postgres",
  "user": "postgres"
}
```

Si `db` aparece como `"disconnected"`, revisa el `.env` y que tu IP esté
autorizada en Cloud SQL.

## Estructura

```
backend/
├── db/
│   └── schema.sql          ← schema versionado (fuente de verdad)
├── src/
│   ├── db.js               ← cliente Postgres (Pool)
│   └── server.js           ← Express + endpoints
├── .env.example            ← template (sin credenciales)
├── .env                    ← credenciales reales (gitignored)
├── .gitignore
├── package.json
└── README.md
```

## Endpoints actuales

| Método | Ruta      | Descripción                                     |
|--------|-----------|-------------------------------------------------|
| GET    | `/health` | Diagnóstico del servidor + verificación de BD   |

(Más endpoints próximamente.)
