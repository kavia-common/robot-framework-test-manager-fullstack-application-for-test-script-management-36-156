-- 004_views.sql
-- Helper views

-- Latest version per test_case
CREATE OR REPLACE VIEW v_test_case_latest_version AS
SELECT
  tc.id            AS test_case_id,
  tc.name          AS test_case_name,
  tc.test_script_id,
  COALESCE((
    SELECT MAX(version_number) FROM test_case_versions v WHERE v.test_case_id = tc.id
  ), 0)            AS latest_version
FROM test_cases tc;

-- Test case with script name
CREATE OR REPLACE VIEW v_test_cases_expanded AS
SELECT
  tc.id,
  ts.name AS script_name,
  tc.name AS case_name,
  tc.description,
  tc.variables,
  tc.metadata,
  tc.created_at,
  tc.updated_at
FROM test_cases tc
JOIN test_scripts ts ON ts.id = tc.test_script_id;

-- Run history summary view
CREATE OR REPLACE VIEW v_run_history_summary AS
SELECT
  rh.id,
  rh.test_case_id,
  tc.name AS case_name,
  ts.name AS script_name,
  rh.status,
  rh.started_at,
  rh.finished_at,
  rh.duration_ms,
  (SELECT object_key FROM run_artifacts ra WHERE ra.run_history_id = rh.id AND ra.artifact_type='log' LIMIT 1) AS log_object_key
FROM run_history rh
JOIN test_cases tc ON tc.id = rh.test_case_id
JOIN test_scripts ts ON ts.id = tc.test_script_id;
