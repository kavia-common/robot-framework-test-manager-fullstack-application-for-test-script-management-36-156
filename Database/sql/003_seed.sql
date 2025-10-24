-- 003_seed.sql
-- Seed roles and initial admin user and sample configs

-- Roles
INSERT INTO roles (id, name, description)
VALUES
  (COALESCE(uuid_generate_v4(), gen_random_uuid()), 'admin',  'Full administrative access'),
  (COALESCE(uuid_generate_v4(), gen_random_uuid()), 'tester', 'Create/edit tests, execute, manage runs'),
  (COALESCE(uuid_generate_v4(), gen_random_uuid()), 'viewer', 'Read-only access to tests and results')
ON CONFLICT (name) DO NOTHING;

-- Admin user with a placeholder bcrypt hash (replace in production)
-- bcrypt hash for password 'ChangeMeAdmin123!' generated externally
-- Example hash string below is a placeholder; backend should enforce proper password rotation.
WITH ins AS (
  INSERT INTO users (id, username, email, password_hash, is_active)
  VALUES (
    COALESCE(uuid_generate_v4(), gen_random_uuid()),
    'admin',
    'admin@example.com',
    '$2b$12$CwTycUXWue0Thq9StjUM0u3D6hE/7x1O5m1Qj2DxM7f5k0wQeWlG6', -- placeholder bcrypt
    TRUE
  )
  ON CONFLICT (username) DO NOTHING
  RETURNING id
),
admin_user AS (
  SELECT id AS user_id FROM ins
  UNION ALL
  SELECT id FROM users WHERE username='admin'
),
r_admin AS (
  SELECT id AS role_id FROM roles WHERE name='admin'
),
r_tester AS (
  SELECT id AS role_id FROM roles WHERE name='tester'
),
r_viewer AS (
  SELECT id AS role_id FROM roles WHERE name='viewer'
)
INSERT INTO user_roles (user_id, role_id)
SELECT a.user_id, r.role_id
FROM admin_user a CROSS JOIN r_admin r
ON CONFLICT DO NOTHING;

-- Basic system configs
INSERT INTO configurations (key, value, scope, description)
VALUES
  ('minio.default_bucket', jsonb_build_object('name','robot-artifacts'), 'system', 'Default bucket for run artifacts'),
  ('queue.max_parallel_runs', jsonb_build_object('count', 4), 'system', 'Default max parallel runs'),
  ('security.password_policy', jsonb_build_object('min_length',12,'require_symbols',true,'require_numbers',true), 'system', 'Password policy')
ON CONFLICT (key, scope) DO NOTHING;

-- Audit seed
INSERT INTO audit_log (actor_user_id, action, entity_type, description, metadata)
SELECT u.id, 'create', 'system', 'Initial seed data applied', jsonb_build_object('scripts',['001_init.sql','002_indexes.sql','003_seed.sql'])
FROM users u WHERE u.username='admin'
ON CONFLICT DO NOTHING;
