-- 001_init.sql
-- Base schema for Robot Framework Test Manager (PostgreSQL)
-- Creates users/RBAC, test scripts/cases/versions, execution queue, run history,
-- run artifacts (MinIO object references), audit log, and configurations.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid on newer PG

-- Helper: normalized now() default through DB clock
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Users and RBAC
CREATE TABLE IF NOT EXISTS users (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  username         TEXT NOT NULL UNIQUE,
  email            TEXT UNIQUE,
  password_hash    TEXT NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at    TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS roles (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  name             TEXT NOT NULL UNIQUE,
  description      TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_roles (
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id          UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- Tests and Cases
CREATE TABLE IF NOT EXISTS test_scripts (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  name             TEXT NOT NULL,
  description      TEXT,
  tags             TEXT[] DEFAULT '{}',
  metadata         JSONB DEFAULT '{}'::jsonb,
  owner_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(name)
);
CREATE TRIGGER trg_test_scripts_updated_at
BEFORE UPDATE ON test_scripts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS test_cases (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  test_script_id   UUID NOT NULL REFERENCES test_scripts(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  description      TEXT,
  variables        JSONB DEFAULT '{}'::jsonb,
  metadata         JSONB DEFAULT '{}'::jsonb,
  created_by       UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_by       UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(test_script_id, name)
);
CREATE TRIGGER trg_test_cases_updated_at
BEFORE UPDATE ON test_cases
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Versioning for cases (immutable content snapshot)
CREATE TABLE IF NOT EXISTS test_case_versions (
  id                 UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  test_case_id       UUID NOT NULL REFERENCES test_cases(id) ON DELETE CASCADE,
  version_number     INT  NOT NULL,
  change_summary     TEXT,
  content            TEXT, -- optional Robot Framework content or pointer
  variables          JSONB DEFAULT '{}'::jsonb,
  metadata           JSONB DEFAULT '{}'::jsonb,
  created_by         UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(test_case_id, version_number)
);

-- Execution queue
CREATE TYPE execution_status AS ENUM ('queued', 'running', 'completed', 'failed', 'cancelled');
CREATE TABLE IF NOT EXISTS execution_queue (
  id                 UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  test_case_id       UUID NOT NULL REFERENCES test_cases(id) ON DELETE CASCADE,
  requested_version  INT, -- if null, use latest
  priority           INT NOT NULL DEFAULT 100, -- lower is higher priority
  status             execution_status NOT NULL DEFAULT 'queued',
  scheduled_for      TIMESTAMPTZ,
  created_by         UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_worker    TEXT, -- worker id/hostname
  retries            INT NOT NULL DEFAULT 0,
  max_retries        INT NOT NULL DEFAULT 0,
  parameters         JSONB DEFAULT '{}'::jsonb, -- runtime overrides/env
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_execution_queue_updated_at
BEFORE UPDATE ON execution_queue
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Run history
CREATE TYPE run_status AS ENUM ('running', 'passed', 'failed', 'error', 'skipped', 'cancelled');
CREATE TABLE IF NOT EXISTS run_history (
  id                 UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  execution_queue_id UUID REFERENCES execution_queue(id) ON DELETE SET NULL,
  test_case_id       UUID NOT NULL REFERENCES test_cases(id) ON DELETE CASCADE,
  version_number     INT,
  status             run_status NOT NULL DEFAULT 'running',
  started_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at        TIMESTAMPTZ,
  duration_ms        BIGINT,
  triggered_by       UUID REFERENCES users(id) ON DELETE SET NULL,
  environment        JSONB DEFAULT '{}'::jsonb,
  summary            TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_run_history_updated_at
BEFORE UPDATE ON run_history
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Run artifacts (MinIO object references)
CREATE TABLE IF NOT EXISTS run_artifacts (
  id                 UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  run_history_id     UUID NOT NULL REFERENCES run_history(id) ON DELETE CASCADE,
  artifact_type      TEXT NOT NULL, -- e.g., log, report, output, screenshot, archive
  bucket             TEXT NOT NULL,
  object_key         TEXT NOT NULL, -- MinIO/S3 object key
  content_type       TEXT,
  size_bytes         BIGINT,
  metadata           JSONB DEFAULT '{}'::jsonb,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(run_history_id, artifact_type)
);

-- Audit log (security and changes)
CREATE TYPE audit_action AS ENUM ('create','update','delete','login','logout','permission_change','execute','queue','config_change','other');
CREATE TABLE IF NOT EXISTS audit_log (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  actor_user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  action           audit_action NOT NULL,
  entity_type      TEXT NOT NULL,
  entity_id        UUID,
  description      TEXT,
  metadata         JSONB DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Configurations (key/value with scoping)
CREATE TABLE IF NOT EXISTS configurations (
  id               UUID PRIMARY KEY DEFAULT COALESCE(uuid_generate_v4(), gen_random_uuid()),
  key              TEXT NOT NULL,
  value            JSONB NOT NULL,
  scope            TEXT DEFAULT 'system', -- system, user:<id>, project:<id>, etc.
  description      TEXT,
  created_by       UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_by       UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(key, scope)
);
CREATE TRIGGER trg_configurations_updated_at
BEFORE UPDATE ON configurations
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Support table: GIN trigram for fast search (optional, but keep extension for GIN already used below)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
