-- 002_indexes.sql
-- Indexes for performance tuning

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users (is_active);

-- Roles
-- name is already unique

-- User roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

-- Test scripts
CREATE INDEX IF NOT EXISTS idx_test_scripts_name_trgm ON test_scripts USING GIN (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_test_scripts_tags_gin ON test_scripts USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_test_scripts_metadata_gin ON test_scripts USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_test_scripts_owner ON test_scripts (owner_id);

-- Test cases
CREATE INDEX IF NOT EXISTS idx_test_cases_script ON test_cases (test_script_id);
CREATE INDEX IF NOT EXISTS idx_test_cases_name_trgm ON test_cases USING GIN (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_test_cases_metadata_gin ON test_cases USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_test_cases_variables_gin ON test_cases USING GIN (variables);

-- Test case versions
CREATE INDEX IF NOT EXISTS idx_case_versions_case ON test_case_versions (test_case_id);
CREATE INDEX IF NOT EXISTS idx_case_versions_case_version ON test_case_versions (test_case_id, version_number);

-- Execution queue
CREATE INDEX IF NOT EXISTS idx_exec_queue_case ON execution_queue (test_case_id);
CREATE INDEX IF NOT EXISTS idx_exec_queue_status ON execution_queue (status);
CREATE INDEX IF NOT EXISTS idx_exec_queue_priority_status ON execution_queue (status, priority, created_at);
CREATE INDEX IF NOT EXISTS idx_exec_queue_scheduled_for ON execution_queue (scheduled_for);

-- Run history
CREATE INDEX IF NOT EXISTS idx_run_history_case ON run_history (test_case_id);
CREATE INDEX IF NOT EXISTS idx_run_history_status ON run_history (status);
CREATE INDEX IF NOT EXISTS idx_run_history_started_at ON run_history (started_at);
CREATE INDEX IF NOT EXISTS idx_run_history_finished_at ON run_history (finished_at);

-- Run artifacts
CREATE INDEX IF NOT EXISTS idx_run_artifacts_run ON run_artifacts (run_history_id);
CREATE INDEX IF NOT EXISTS idx_run_artifacts_bucket_key ON run_artifacts (bucket, object_key);

-- Audit log
CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log (created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_metadata_gin ON audit_log USING GIN (metadata);

-- Configurations
CREATE INDEX IF NOT EXISTS idx_configurations_key_scope ON configurations (key, scope);
CREATE INDEX IF NOT EXISTS idx_configurations_value_gin ON configurations USING GIN (value);
