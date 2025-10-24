# Database (PostgreSQL) for Robot Framework Test Manager

This folder contains the PostgreSQL schema, migrations, and startup automation.
It defines metadata for users/RBAC, test scripts, test cases, case versions, execution queue, run history, run artifacts (MinIO references), audit logging, and configurations.

## Contents

- sql/001_init.sql: Base tables, enums, triggers, and constraints
- sql/002_indexes.sql: Performance indexes (btree, GIN)
- sql/003_seed.sql: Seed roles (admin/tester/viewer), admin user (placeholder bcrypt), base configs
- sql/004_views.sql: Convenience views for latest versions and run summaries
- startup.sh: Boots PostgreSQL and applies all migrations automatically
- backup_db.sh, restore_db.sh: Cross-database backup/restore helpers
- db_visualizer/: Lightweight Node.js DB viewer env files

## Schema Overview

- users: accounts with secure password_hash (bcrypt) and timestamps
- roles: admin/tester/viewer
- user_roles: assignments (many-to-many)
- test_scripts: top-level scripts with tags and metadata (JSONB)
- test_cases: cases under scripts, variables and metadata (JSONB)
- test_case_versions: immutable snapshots; version_number unique per case
- execution_queue: queued items with priority, scheduling, retries, and status
- run_history: run records with status, timing, and environment (JSONB)
- run_artifacts: MinIO/S3 object references (bucket + object_key)
- audit_log: security and change events with JSONB metadata
- configurations: scoped key/value JSONB configuration store

All tables include created_at and updated_at (when relevant) with update triggers.

## Indexes

- Trigram GIN on name columns for fast search
- GIN indexes on JSONB and arrays for metadata/variables/tags
- Composite btree indexes over status/priorities and time-based fields
- Uniqueness constraints on key fields (usernames, role names, etc.)

## Seed Data

- Roles: admin, tester, viewer
- Admin user: username "admin", email "admin@example.com"
  - Password hash is a placeholder bcrypt string.
  - IMPORTANT: Replace this user’s password in production and rotate credentials.

## Running Locally

1) Start PostgreSQL and apply migrations:
   ./startup.sh

   The script:
   - Starts PostgreSQL (or connects if running)
   - Ensures database and role exist
   - Applies sql/001_init.sql, 002_indexes.sql, 003_seed.sql, 004_views.sql

2) Connect:
   psql -h localhost -U appuser -d myapp -p 5000

   Or use the saved command in db_connection.txt

3) Environment variables for simple db viewer:
   source db_visualizer/postgres.env
   (Use with ./db_visualizer/server.js if needed.)

## Notes for Backend Integration

- Use env vars:
  - POSTGRES_URL, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_PORT
- All artifacts (logs/reports) are referenced via run_artifacts.bucket and .object_key
- Prefer filtered queries using provided indexes; searching names can leverage trigram

## Security

- Passwords are stored as bcrypt hashes
- Audit logging available via audit_log table
- Do not retain placeholder credentials in production; set strong secrets in .env

## Migrations

Migrations are plain SQL files executed in order by startup.sh. They are designed to be idempotent as much as possible (CREATE IF NOT EXISTS, ON CONFLICT, etc.).

To add a new migration:
- Create a new file: sql/005_description.sql
- Append a run_sql_file call in startup.sh where migrations are applied, maintaining order.

```bash
# Example snippet (already present in startup.sh)
run_sql_file "$MIGRATIONS_DIR/001_init.sql"
run_sql_file "$MIGRATIONS_DIR/002_indexes.sql"
run_sql_file "$MIGRATIONS_DIR/003_seed.sql"
run_sql_file "$MIGRATIONS_DIR/004_views.sql"
# run_sql_file "$MIGRATIONS_DIR/005_description.sql"
```

Ensure new objects have proper constraints, timestamps, and indexes.
