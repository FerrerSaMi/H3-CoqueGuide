-- =============================================================================
-- SCHEMA INICIAL — H3-CoqueGuide
-- =============================================================================
-- Ejecutar UNA SOLA VEZ contra la database `postgres` en la instancia de
-- Cloud SQL del socio formador.
--
-- Es idempotente: usa `IF NOT EXISTS` en todas las creaciones, así que
-- correrlo dos veces no rompe nada.
--
-- Todas las tablas viven en el schema `coqueguide` para no mezclarse
-- con objetos de sistema de Postgres.
-- =============================================================================

-- 1) Schema propio
CREATE SCHEMA IF NOT EXISTS coqueguide;
SET search_path TO coqueguide;

-- 2) Extensión para generar UUIDs automáticos
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- visitor_profiles
-- Perfil del visitante que completó la encuesta inicial.
-- Espejo server-side del @Model ExcursionUserProfile que ya tienes en iOS.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS visitor_profiles (
    id                                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id                         TEXT,
    gender                            TEXT,
    age_range                         TEXT,
    planned_time                      TEXT,
    attraction_preference             TEXT,
    resolved_attraction_preference    TEXT,
    specific_attraction               TEXT,
    preferred_language                TEXT,
    coque_personality                 TEXT,
    ai_description_text               TEXT,
    created_at                        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_visitor_profiles_device
    ON visitor_profiles(device_id);

CREATE INDEX IF NOT EXISTS idx_visitor_profiles_created
    ON visitor_profiles(created_at DESC);

-- -----------------------------------------------------------------------------
-- usage_events
-- Cada interacción del visitante con la app. Flexible vía `metadata` JSONB
-- para no crear una columna por cada evento distinto.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usage_events (
    id              BIGSERIAL PRIMARY KEY,
    visitor_id      UUID REFERENCES visitor_profiles(id) ON DELETE SET NULL,
    device_id       TEXT,
    event_name      TEXT NOT NULL,
    metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
    app_version     TEXT,
    device_language TEXT,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usage_events_name
    ON usage_events(event_name);

CREATE INDEX IF NOT EXISTS idx_usage_events_occurred
    ON usage_events(occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_usage_events_visitor
    ON usage_events(visitor_id);

-- -----------------------------------------------------------------------------
-- chat_messages
-- Histórico de mensajes con Coque. Útil para analytics y para mejorar prompts.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
    id            BIGSERIAL PRIMARY KEY,
    visitor_id    UUID REFERENCES visitor_profiles(id) ON DELETE SET NULL,
    device_id     TEXT,
    session_id    UUID,
    role          TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    text          TEXT NOT NULL,
    language      TEXT,
    personality   TEXT,
    cards         JSONB,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session
    ON chat_messages(session_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_visitor
    ON chat_messages(visitor_id);

-- -----------------------------------------------------------------------------
-- museum_events
-- Eventos del museo del día (reemplaza lo que hoy está hardcoded en
-- CGEventService en el cliente iOS).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS museum_events (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    description   TEXT,
    location      TEXT,
    icon          TEXT,
    starts_at     TIMESTAMPTZ NOT NULL,
    ends_at       TIMESTAMPTZ NOT NULL,
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_museum_events_active_day
    ON museum_events(starts_at) WHERE active;
