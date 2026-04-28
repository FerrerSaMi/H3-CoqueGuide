# Revisión del proyecto H3-CoqueGuide — Sprint 3

Documento de consulta con el estado completo del proyecto: revisión de seguridad,
inventario de módulos, arquitectura del backend y DDL completo del schema.

Fecha de la revisión: 2026-04-19
Rama analizada: `CoqueGuide` (sincronizada con `origin/CoqueGuide`)

---

## 1. Primera revisión de seguridad / calidad

### 🚨 Crítico — API key de Gemini filtrada en git history (ya resuelto)

El archivo `Secrets.plist` fue eliminado del tracking en el commit `4f48532`, pero
el contenido siguió vivo en la historia y es recuperable con `git show`:

```
commit c4a3075 (Santiago, abril 12)
  H3-CoqueGuide/H3-CoqueGuide/Resources/Secrets.plist
  GEMINI_API_KEY = AIzaSyBl-eNP4TodjpOcMo3Gmm2zOtq0ENMdgF... (TRUNCADA)
commit 1ac1c48 (Angel, abril 13)
  (la modifica)
```

Ambos commits están publicados en `origin/main`, `origin/CoqueGuide` y
`origin/Encuesta` en GitHub (`FerrerSaMi/H3-CoqueGuide`).

**Acciones:**
1. ✅ Rotar la key en Google AI Studio — **HECHO**.
2. (Opcional) Reescribir historia con `git filter-repo` o BFG para borrar la key
   de los commits viejos. Requiere coordinar con los 3 compañeros. Ya no es
   urgente porque la key está rotada.

### ⚠️ Backend sin autenticación

[`backend/src/server.js`](backend/src/server.js) tiene todos los endpoints abiertos:
- `POST /chat/message` — cualquiera puede quemar la cuota de Gemini.
- `POST /profile`, `POST /events` — cualquiera puede meter basura a la BD.
- `POST /survey/description` — mismo problema con la cuota.
- `app.use(cors())` abre CORS a todos los orígenes.

**Antes del deploy a Cloud Run hay que añadir:**
- API key / token compartido en header (`x-app-token`) que el cliente iOS también mande.
- CORS restringido a orígenes conocidos.
- Rate limiting básico (`express-rate-limit`).
- No devolver `err.message` al cliente en los 500 — loggear server-side y responder genérico.

### ⚠️ Release URL aún placeholder

[`AppConfig.swift:25`](H3-CoqueGuide/H3-CoqueGuide/App/AppConfig.swift:25) apunta a
`https://coqueguide-backend.example.com` en Release. Esperado — se reemplaza cuando
tengamos Cloud Run.

### 🧹 Limpiezas menores

- [`CGEventService.swift:44`](H3-CoqueGuide/H3-CoqueGuide/Features/GuideAI/Services/CGEventService.swift:44) — comentario aún menciona `GeminiAIService` (ya no existe).
- [`BackendAIService.swift:10`](H3-CoqueGuide/H3-CoqueGuide/Features/GuideAI/Services/BackendAIService.swift:10) — "Beneficios vs. GeminiAIService" ya no aplica.
- [`backend/src/coquePrompt.js:4`](backend/src/coquePrompt.js:4) — menciona `GeminiAIService.swift` que ya no existe.
- [`server.js:10`](backend/src/server.js:10) — comentario de cabecera lista endpoints "por agregar" que ya están implementados.

### ✅ Lo que está bien

- `.gitignore` cubre correctamente `backend/.env`, `Secrets.plist`, `.DS_Store`, `node_modules/`, `DerivedData/`, `*.xcuserstate`, `build/`.
- No hay secrets hardcoded en el código fuente actual (grep de `AIza`, `sk-`, `Bearer`, `api_key=...` → 0 hits).
- `device_id` usa `identifierForVendor` — scoped al vendor, reseteable desinstalando. Privacy-safe.
- `UserDefaults` solo guarda booleans (`hasSeenOnboarding`, `isDarkModeEnabled`) — sin PII.
- Separación `chat_messages` (contenido) vs `usage_events` (analytics sin PII) es correcta.
- Iteración E removió Gemini del binario iOS; ya no viaja la key en la app compilada.

---

## 2. Verificación de la key rotada

La nueva API key (prefijo `AQ.Ab8RN...`) **no aparece** en:
- Archivos actuales del repo.
- Historia completa de git (`git log --all -S`).
- Ningún ref (`git grep` sobre todos los commits).

**Recordatorios:**
1. La nueva key debe vivir solo en `backend/.env` (ignorado) y en env vars de Cloud Run cuando deployen. Nunca en el binario iOS.
2. No pegar la key en commits, PRs, issues o chats de GitHub — los comentarios también se indexan.
3. Si se te escapa completa en algún lado (incluso chats), rótala otra vez.

---

## 3. Segunda revisión (cosas adicionales encontradas)

### ⚠️ Archivos de Xcode del usuario trackeados

Hay `xcuserdata/` de 4 personas en el repo:
- `davidcantucabello`, `ernesto`, `michelleacosta`, `sroa` — cada uno con su `xcschememanagement.plist`.
- Además `UserInterfaceState.xcuserstate` y breakpoints de algunos.

No tienen secrets, pero:
- Generan merge conflicts constantemente cuando alguien abre el proyecto.
- Falta la línea típica en `.gitignore`:
  ```
  xcuserdata/
  *.xcuserstate
  ```
  (El root `.gitignore` ya tiene `*.xcuserstate`, pero los archivos fueron
  commiteados antes de esa regla y quedaron trackeados — `.gitignore` no retira
  archivos ya trackeados.)

Limpieza con `git rm -r --cached` sobre esas carpetas. No urgente.

### ⚠️ Backend DB con cert sin verificar

[`db.js:26-28`](backend/src/db.js:26):
```js
ssl: process.env.PGSSLMODE === 'require'
    ? { rejectUnauthorized: false }
    : false,
```

Es el workaround estándar para el certificado auto-generado de Cloud SQL, pero
estrictamente desactiva validación del cert (MITM posible entre backend y Cloud
SQL). Patrón común y aceptable en Cloud Run (red de Google). Si van a deployar
en otro sitio, conviene bajar el CA de Cloud SQL o usar Cloud SQL Auth Proxy.

### ℹ️ Info.plist

[`Info.plist:5-9`](H3-CoqueGuide/H3-CoqueGuide/Info.plist:5) tiene
`NSAppTransportSecurity > Allow Local Networking = true`. Permite `localhost:8080`
en DEBUG y viaja también al Release. No es un hueco de seguridad — solo habilita
redes locales/Bonjour, no permite HTTP arbitrario. Mientras el backend en Release
sea HTTPS (Cloud Run lo es), está bien.

---

## 4. Inventario de módulos del proyecto

### Módulos de la app iOS (carpeta `Features/`)

1. **Landing** — home, tabs, carrusel de atracciones.
2. **GuideAI (CoqueGuide chat)** — asistente conversacional.
3. **Camera (Scanner)** — reconocimiento de objetos del museo.
4. **Map** — mapa interactivo por niveles.
5. **Survey** — encuesta inicial para personalizar.
6. **Onboarding** — 3 pantallas de primera apertura.

Capas transversales (no son módulos como tales): `App/AnalyticsService.swift`,
`Services/Backend/BackendHTTPClient.swift`, `Services/AI/SurveyAIService.swift`,
`App/L10n.swift`.

### Componentes del sistema del Sprint 3

1. **Backend Node/Express** (nuevo) — `backend/src/`.
2. **Postgres en GCP Cloud SQL** (nuevo) — schema `coqueguide`.
3. **Analytics / eventos de uso** (nuevo) — `AnalyticsService` + tabla `usage_events`.
4. **App iOS** (ya existía, migró a hablar con backend propio).

Pendientes declarados del Sprint 3:
- Deploy a Cloud Run (backend sigue corriendo local).
- TestFlight (cuenta Apple Developer pendiente).
- Accesibilidad extendida (pospuesta).

### ¿Qué módulos comparten backend + BD?

| Módulo | Backend Node | Postgres | Datos locales |
|---|---|---|---|
| CoqueGuide (chat) | ✅ `/chat/message` | ✅ `chat_messages` | — |
| Encuesta | ✅ `/profile`, `/survey/description` | ✅ `visitor_profiles` | — |
| Eventos del museo | ✅ `/museum-events/today` | ✅ `museum_events` | mock fallback |
| Analytics (todos) | ✅ `/events` | ✅ `usage_events` | — |
| **Mapa** | ❌ | ❌ | `MapLocations.json` |
| **Scanner** | ❌ | ❌ | `MuseumObjects.json` |

Mapa y scanner comparten con CoqueGuide únicamente el canal de analytics. El
catálogo vive en archivos JSON bundled — cualquier cambio requiere nueva release.

---

## 5. Organización interna del backend Node/Express

### Estructura

```
backend/
├── .env                 ← credenciales Postgres + GEMINI_API_KEY (gitignored)
├── .env.example         ← plantilla para el equipo
├── package.json         ← deps mínimas: express, pg, cors, dotenv
├── README.md
├── db/
│   └── schema.sql       ← DDL de las 4 tablas (source of truth del schema)
└── src/
    ├── server.js        (549 líneas)
    ├── db.js            (52 líneas)
    └── coquePrompt.js   (174 líneas)
```

~775 líneas totales.

### Qué hace cada archivo

**`src/server.js`** — punto de entrada. Levanta Express, monta los endpoints:
- `GET /health` — diagnóstico + verifica conexión a Postgres.
- `POST /profile` — guarda perfil de encuesta en `visitor_profiles`.
- `POST /events` — inserta evento analítico en `usage_events`.
- `GET /museum-events/today` — eventos del museo del día.
- `POST /survey/description` — proxy a Gemini para la descripción del visitante.
- `POST /chat/message` — orquesta el chat: carga perfil + eventos + historial,
  construye prompt, llama a Gemini, parsea cards, persiste mensajes.
- Middleware: `cors()`, `express.json({limit:'256kb'})`, logger de requests.
- Handler `SIGTERM` para cerrar el pool limpiamente cuando Cloud Run mande la
  señal de shutdown.

**`src/db.js`** — cliente Postgres. Expone un `Pool` de `pg` (máx 10 conexiones)
y un helper `query(text, params)` que loggea el tiempo de cada query. Lee
credenciales de env.

**`src/coquePrompt.js`** — lógica de prompts del chat:
- `buildSystemPrompt({visitor, todaysEvents, language})` → construye el system
  instruction de Gemini con personalidad, idioma e info del museo.
- `parseAssistantResponse(rawReply, todaysEvents)` → extrae marcadores `[CARD:*]`
  del texto de Gemini y devuelve `{cleanText, cards}` estructurado.

**`db/schema.sql`** — DDL del schema `coqueguide` con las 4 tablas. Es el archivo
que ejecutas una vez contra la BD para crear todo.

### Patrón arquitectónico

Monolito plano tipo "fat server.js". No hay capa de routers / controllers /
services / repositories separada. Justificable:
- Equipo sin experiencia previa con Node.
- Solo 7 endpoints, lógica de negocio acotada.
- Priorizar velocidad de entrega sobre limpieza arquitectónica para un Sprint de 2 semanas.

**Refactor natural si crece:**

```
src/
├── server.js          (solo Express setup)
├── db.js
├── routes/
│   ├── profile.js
│   ├── events.js
│   ├── museumEvents.js
│   └── chat.js
├── services/
│   ├── geminiClient.js     ← extrae las 2 llamadas duplicadas a Gemini
│   └── coquePrompt.js
└── middleware/
    ├── auth.js              ← cuando agreguen token
    └── rateLimit.js
```

### Deuda técnica en esta capa

- Duplicación del bloque "llamar a Gemini" entre `/survey/description` y
  `/chat/message`. Un `geminiClient.js` la eliminaría.
- Sin tests.
- Sin auth / rate-limit / CORS restringido.
- `err.message` en respuestas 500.

---

## 6. DDL completo del schema

Archivo: [`backend/db/schema.sql`](backend/db/schema.sql)

### Preámbulo

```sql
CREATE SCHEMA IF NOT EXISTS coqueguide;
SET search_path TO coqueguide;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- para gen_random_uuid()
```

Todo vive dentro del schema `coqueguide`. Script idempotente (`IF NOT EXISTS` en todo).

### Tabla `visitor_profiles`

Perfil producido por la encuesta. Una fila por visitante que completó el survey.

| Columna | Tipo | Constraints | Default |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY | `gen_random_uuid()` |
| `device_id` | TEXT | — | — |
| `gender` | TEXT | — | — |
| `age_range` | TEXT | — | — |
| `planned_time` | TEXT | — | — |
| `attraction_preference` | TEXT | — | — |
| `resolved_attraction_preference` | TEXT | — | — |
| `specific_attraction` | TEXT | — | — |
| `preferred_language` | TEXT | — | — |
| `coque_personality` | TEXT | — | — |
| `ai_description_text` | TEXT | — | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `NOW()` |

**Índices:**
- `idx_visitor_profiles_device` → `(device_id)`
- `idx_visitor_profiles_created` → `(created_at DESC)`

**Notas:**
- No hay UNIQUE en `device_id` — un mismo dispositivo puede generar varios perfiles si el usuario repite encuesta.
- `updated_at` tiene default pero no se actualiza automáticamente (no hay trigger).

### Tabla `usage_events`

Analytics. Una fila por evento emitido desde el cliente iOS.

| Columna | Tipo | Constraints | Default |
|---|---|---|---|
| `id` | BIGSERIAL | PRIMARY KEY | (auto) |
| `visitor_id` | UUID | FK → `visitor_profiles(id)` ON DELETE SET NULL | — |
| `device_id` | TEXT | — | — |
| `event_name` | TEXT | NOT NULL | — |
| `metadata` | JSONB | NOT NULL | `'{}'::jsonb` |
| `app_version` | TEXT | — | — |
| `device_language` | TEXT | — | — |
| `occurred_at` | TIMESTAMPTZ | NOT NULL | `NOW()` |

**Índices:**
- `idx_usage_events_name` → `(event_name)`
- `idx_usage_events_occurred` → `(occurred_at DESC)`
- `idx_usage_events_visitor` → `(visitor_id)`

**Notas:**
- FK es `ON DELETE SET NULL` — si borran un perfil, los eventos sobreviven como anónimos.
- `metadata JSONB` da flexibilidad para agregar eventos nuevos sin ALTER TABLE.

### Tabla `chat_messages`

Histórico del chat con Coque. Tanto mensajes del usuario como respuestas del asistente.

| Columna | Tipo | Constraints | Default |
|---|---|---|---|
| `id` | BIGSERIAL | PRIMARY KEY | (auto) |
| `visitor_id` | UUID | FK → `visitor_profiles(id)` ON DELETE SET NULL | — |
| `device_id` | TEXT | — | — |
| `session_id` | UUID | — | — |
| `role` | TEXT | NOT NULL, CHECK `IN ('user', 'assistant')` | — |
| `text` | TEXT | NOT NULL | — |
| `language` | TEXT | — | — |
| `personality` | TEXT | — | — |
| `cards` | JSONB | — | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` |

**Índices:**
- `idx_chat_messages_session` → `(session_id)`
- `idx_chat_messages_visitor` → `(visitor_id)`

**Notas:**
- `session_id` agrupa mensajes de una misma conversación — iOS genera un UUID por instancia de `BackendAIService`.
- `cards` guarda la lista estructurada parseada del texto del asistente (marcadores `[CARD:*]`).
- Sin FK sobre `session_id` — es solo un agrupador lógico.

### Tabla `museum_events`

Catálogo de eventos del día. Reemplazó los mocks hardcoded de `CGEventService`.

| Columna | Tipo | Constraints | Default |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY | `gen_random_uuid()` |
| `name` | TEXT | NOT NULL | — |
| `description` | TEXT | — | — |
| `location` | TEXT | — | — |
| `icon` | TEXT | — | — |
| `starts_at` | TIMESTAMPTZ | NOT NULL | — |
| `ends_at` | TIMESTAMPTZ | NOT NULL | — |
| `active` | BOOLEAN | NOT NULL | `TRUE` |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` |

**Índices:**
- `idx_museum_events_active_day` → `(starts_at) WHERE active` (índice parcial — solo indexa filas activas)

**Notas:**
- No hay CHECK de que `ends_at > starts_at`; se confía en quien inserte.
- La query del endpoint filtra `WHERE active AND starts_at::date = CURRENT_DATE`.

### Diagrama de FKs

```
visitor_profiles (id)
        ↑
        │ ON DELETE SET NULL
        ├──── usage_events.visitor_id
        └──── chat_messages.visitor_id

museum_events — tabla independiente, sin FKs
```

### Gaps del schema que podrían importar más adelante

- No hay UNIQUE en `device_id` de `visitor_profiles` — duplicados posibles.
- `updated_at` sin trigger de auto-update.
- `chat_messages` sin índice compuesto `(session_id, created_at)` que sería lo
  óptimo para `ORDER BY created_at DESC LIMIT 20`.
- Sin CHECK en `museum_events` para validar rango de fechas.
- Sin índice en `usage_events(device_id)` — útil si quieren agrupar por
  dispositivo anónimo.

Para el scope del Sprint 3 está bien dimensionado.

---

## 7. Resumen ejecutivo

**Estado del proyecto:** sano. No hay leaks activos. Todo lo que estaba
filtrado ya está rotado.

**Único trabajo bloqueante antes del entregable final:**
- Deploy del backend a Cloud Run (actualmente corre local).
- Añadir auth básica + CORS restringido + rate limit antes de deployar.
- TestFlight (requiere cuenta Apple Developer, trámite aparte).

**Trabajo cosmético (no urgente):**
- Limpiar comentarios huérfanos que mencionan `GeminiAIService`.
- Des-trackear `xcuserdata/` de los 4 colaboradores.
- (Opcional) Reescribir historia para quitar la vieja key rotada.
