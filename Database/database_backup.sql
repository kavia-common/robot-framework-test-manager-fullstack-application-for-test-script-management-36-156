--
-- PostgreSQL database dump
--

\restrict CeapDJc1BOvqchFlvIq0IhgT4cnkg0oWbhEyCZJFcj5xcXzfhhNHg98pklbB0Kh

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS myapp;
--
-- Name: myapp; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE myapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE myapp OWNER TO postgres;

\unrestrict CeapDJc1BOvqchFlvIq0IhgT4cnkg0oWbhEyCZJFcj5xcXzfhhNHg98pklbB0Kh
\connect myapp
\restrict CeapDJc1BOvqchFlvIq0IhgT4cnkg0oWbhEyCZJFcj5xcXzfhhNHg98pklbB0Kh

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: audit_action; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_action AS ENUM (
    'create',
    'update',
    'delete',
    'login',
    'logout',
    'permission_change',
    'execute',
    'queue',
    'config_change',
    'other'
);


ALTER TYPE public.audit_action OWNER TO postgres;

--
-- Name: execution_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.execution_status AS ENUM (
    'queued',
    'running',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE public.execution_status OWNER TO postgres;

--
-- Name: run_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.run_status AS ENUM (
    'running',
    'passed',
    'failed',
    'error',
    'skipped',
    'cancelled'
);


ALTER TYPE public.run_status OWNER TO postgres;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    actor_user_id uuid,
    action public.audit_action NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: configurations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configurations (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    key text NOT NULL,
    value jsonb NOT NULL,
    scope text DEFAULT 'system'::text,
    description text,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.configurations OWNER TO postgres;

--
-- Name: execution_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_queue (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    test_case_id uuid NOT NULL,
    requested_version integer,
    priority integer DEFAULT 100 NOT NULL,
    status public.execution_status DEFAULT 'queued'::public.execution_status NOT NULL,
    scheduled_for timestamp with time zone,
    created_by uuid,
    assigned_worker text,
    retries integer DEFAULT 0 NOT NULL,
    max_retries integer DEFAULT 0 NOT NULL,
    parameters jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.execution_queue OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: run_artifacts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.run_artifacts (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    run_history_id uuid NOT NULL,
    artifact_type text NOT NULL,
    bucket text NOT NULL,
    object_key text NOT NULL,
    content_type text,
    size_bytes bigint,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.run_artifacts OWNER TO postgres;

--
-- Name: run_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.run_history (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    execution_queue_id uuid,
    test_case_id uuid NOT NULL,
    version_number integer,
    status public.run_status DEFAULT 'running'::public.run_status NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    duration_ms bigint,
    triggered_by uuid,
    environment jsonb DEFAULT '{}'::jsonb,
    summary text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.run_history OWNER TO postgres;

--
-- Name: test_case_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_case_versions (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    test_case_id uuid NOT NULL,
    version_number integer NOT NULL,
    change_summary text,
    content text,
    variables jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.test_case_versions OWNER TO postgres;

--
-- Name: test_cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_cases (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    test_script_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    variables jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.test_cases OWNER TO postgres;

--
-- Name: test_scripts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_scripts (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    name text NOT NULL,
    description text,
    tags text[] DEFAULT '{}'::text[],
    metadata jsonb DEFAULT '{}'::jsonb,
    owner_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.test_scripts OWNER TO postgres;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT COALESCE(public.uuid_generate_v4(), gen_random_uuid()) NOT NULL,
    username text NOT NULL,
    email text,
    password_hash text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, actor_user_id, action, entity_type, entity_id, description, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configurations (id, key, value, scope, description, created_by, updated_by, created_at, updated_at) FROM stdin;
e1ea479e-42d7-4c07-b747-b25418b16458	minio.default_bucket	{"name": "robot-artifacts"}	system	Default bucket for run artifacts	\N	\N	2025-10-24 04:40:49.065445+00	2025-10-24 04:40:49.065445+00
f3e9021f-da2c-4b9f-b2b5-a64996098ff4	queue.max_parallel_runs	{"count": 4}	system	Default max parallel runs	\N	\N	2025-10-24 04:40:49.065445+00	2025-10-24 04:40:49.065445+00
ecfb6917-8740-4cf2-b194-7b99d004a522	security.password_policy	{"min_length": 12, "require_numbers": true, "require_symbols": true}	system	Password policy	\N	\N	2025-10-24 04:40:49.065445+00	2025-10-24 04:40:49.065445+00
\.


--
-- Data for Name: execution_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_queue (id, test_case_id, requested_version, priority, status, scheduled_for, created_by, assigned_worker, retries, max_retries, parameters, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, description, created_at, updated_at) FROM stdin;
f3fc2074-bbc1-4033-a7c5-ca71df2b6203	admin	Full administrative access	2025-10-24 04:40:49.060547+00	2025-10-24 04:40:49.060547+00
06ec16b4-6479-4074-a83a-6da648e90bc2	tester	Create/edit tests, execute, manage runs	2025-10-24 04:40:49.060547+00	2025-10-24 04:40:49.060547+00
48ba04e0-e9cf-4cfb-b958-7935914bec2e	viewer	Read-only access to tests and results	2025-10-24 04:40:49.060547+00	2025-10-24 04:40:49.060547+00
\.


--
-- Data for Name: run_artifacts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.run_artifacts (id, run_history_id, artifact_type, bucket, object_key, content_type, size_bytes, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: run_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.run_history (id, execution_queue_id, test_case_id, version_number, status, started_at, finished_at, duration_ms, triggered_by, environment, summary, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: test_case_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_case_versions (id, test_case_id, version_number, change_summary, content, variables, metadata, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: test_cases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_cases (id, test_script_id, name, description, variables, metadata, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: test_scripts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_scripts (id, name, description, tags, metadata, owner_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (user_id, role_id, created_at) FROM stdin;
e0462f5d-360e-42c0-ae00-728f5e37a740	f3fc2074-bbc1-4033-a7c5-ca71df2b6203	2025-10-24 04:40:49.062753+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, password_hash, is_active, last_login_at, created_at, updated_at) FROM stdin;
e0462f5d-360e-42c0-ae00-728f5e37a740	admin	admin@example.com	$2b$12$CwTycUXWue0Thq9StjUM0u3D6hE/7x1O5m1Qj2DxM7f5k0wQeWlG6	t	\N	2025-10-24 04:40:49.062753+00	2025-10-24 04:40:49.062753+00
\.


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: configurations configurations_key_scope_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_key_scope_key UNIQUE (key, scope);


--
-- Name: configurations configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: execution_queue execution_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_queue
    ADD CONSTRAINT execution_queue_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: run_artifacts run_artifacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_artifacts
    ADD CONSTRAINT run_artifacts_pkey PRIMARY KEY (id);


--
-- Name: run_artifacts run_artifacts_run_history_id_artifact_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_artifacts
    ADD CONSTRAINT run_artifacts_run_history_id_artifact_type_key UNIQUE (run_history_id, artifact_type);


--
-- Name: run_history run_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_history
    ADD CONSTRAINT run_history_pkey PRIMARY KEY (id);


--
-- Name: test_case_versions test_case_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_versions
    ADD CONSTRAINT test_case_versions_pkey PRIMARY KEY (id);


--
-- Name: test_case_versions test_case_versions_test_case_id_version_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_versions
    ADD CONSTRAINT test_case_versions_test_case_id_version_number_key UNIQUE (test_case_id, version_number);


--
-- Name: test_cases test_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases
    ADD CONSTRAINT test_cases_pkey PRIMARY KEY (id);


--
-- Name: test_cases test_cases_test_script_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases
    ADD CONSTRAINT test_cases_test_script_id_name_key UNIQUE (test_script_id, name);


--
-- Name: test_scripts test_scripts_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_scripts
    ADD CONSTRAINT test_scripts_name_key UNIQUE (name);


--
-- Name: test_scripts test_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_scripts
    ADD CONSTRAINT test_scripts_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_actor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_actor ON public.audit_log USING btree (actor_user_id);


--
-- Name: idx_audit_log_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_entity ON public.audit_log USING btree (entity_type, entity_id);


--
-- Name: idx_audit_log_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_metadata_gin ON public.audit_log USING gin (metadata);


--
-- Name: idx_case_versions_case; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_case_versions_case ON public.test_case_versions USING btree (test_case_id);


--
-- Name: idx_case_versions_case_version; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_case_versions_case_version ON public.test_case_versions USING btree (test_case_id, version_number);


--
-- Name: idx_configurations_key_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_configurations_key_scope ON public.configurations USING btree (key, scope);


--
-- Name: idx_configurations_value_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_configurations_value_gin ON public.configurations USING gin (value);


--
-- Name: idx_exec_queue_case; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exec_queue_case ON public.execution_queue USING btree (test_case_id);


--
-- Name: idx_exec_queue_priority_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exec_queue_priority_status ON public.execution_queue USING btree (status, priority, created_at);


--
-- Name: idx_exec_queue_scheduled_for; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exec_queue_scheduled_for ON public.execution_queue USING btree (scheduled_for);


--
-- Name: idx_exec_queue_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exec_queue_status ON public.execution_queue USING btree (status);


--
-- Name: idx_run_artifacts_bucket_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_artifacts_bucket_key ON public.run_artifacts USING btree (bucket, object_key);


--
-- Name: idx_run_artifacts_run; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_artifacts_run ON public.run_artifacts USING btree (run_history_id);


--
-- Name: idx_run_history_case; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_history_case ON public.run_history USING btree (test_case_id);


--
-- Name: idx_run_history_finished_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_history_finished_at ON public.run_history USING btree (finished_at);


--
-- Name: idx_run_history_started_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_history_started_at ON public.run_history USING btree (started_at);


--
-- Name: idx_run_history_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_run_history_status ON public.run_history USING btree (status);


--
-- Name: idx_test_cases_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_cases_metadata_gin ON public.test_cases USING gin (metadata);


--
-- Name: idx_test_cases_name_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_cases_name_trgm ON public.test_cases USING gin (name public.gin_trgm_ops);


--
-- Name: idx_test_cases_script; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_cases_script ON public.test_cases USING btree (test_script_id);


--
-- Name: idx_test_cases_variables_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_cases_variables_gin ON public.test_cases USING gin (variables);


--
-- Name: idx_test_scripts_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_scripts_metadata_gin ON public.test_scripts USING gin (metadata);


--
-- Name: idx_test_scripts_name_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_scripts_name_trgm ON public.test_scripts USING gin (name public.gin_trgm_ops);


--
-- Name: idx_test_scripts_owner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_scripts_owner ON public.test_scripts USING btree (owner_id);


--
-- Name: idx_test_scripts_tags_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_test_scripts_tags_gin ON public.test_scripts USING gin (tags);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_is_active ON public.users USING btree (is_active);


--
-- Name: configurations trg_configurations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_configurations_updated_at BEFORE UPDATE ON public.configurations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: execution_queue trg_execution_queue_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_execution_queue_updated_at BEFORE UPDATE ON public.execution_queue FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: roles trg_roles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: run_history trg_run_history_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_run_history_updated_at BEFORE UPDATE ON public.run_history FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: test_cases trg_test_cases_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_test_cases_updated_at BEFORE UPDATE ON public.test_cases FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: test_scripts trg_test_scripts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_test_scripts_updated_at BEFORE UPDATE ON public.test_scripts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: audit_log audit_log_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: configurations configurations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: configurations configurations_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: execution_queue execution_queue_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_queue
    ADD CONSTRAINT execution_queue_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: execution_queue execution_queue_test_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_queue
    ADD CONSTRAINT execution_queue_test_case_id_fkey FOREIGN KEY (test_case_id) REFERENCES public.test_cases(id) ON DELETE CASCADE;


--
-- Name: run_artifacts run_artifacts_run_history_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_artifacts
    ADD CONSTRAINT run_artifacts_run_history_id_fkey FOREIGN KEY (run_history_id) REFERENCES public.run_history(id) ON DELETE CASCADE;


--
-- Name: run_history run_history_execution_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_history
    ADD CONSTRAINT run_history_execution_queue_id_fkey FOREIGN KEY (execution_queue_id) REFERENCES public.execution_queue(id) ON DELETE SET NULL;


--
-- Name: run_history run_history_test_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_history
    ADD CONSTRAINT run_history_test_case_id_fkey FOREIGN KEY (test_case_id) REFERENCES public.test_cases(id) ON DELETE CASCADE;


--
-- Name: run_history run_history_triggered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.run_history
    ADD CONSTRAINT run_history_triggered_by_fkey FOREIGN KEY (triggered_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: test_case_versions test_case_versions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_versions
    ADD CONSTRAINT test_case_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: test_case_versions test_case_versions_test_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_versions
    ADD CONSTRAINT test_case_versions_test_case_id_fkey FOREIGN KEY (test_case_id) REFERENCES public.test_cases(id) ON DELETE CASCADE;


--
-- Name: test_cases test_cases_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases
    ADD CONSTRAINT test_cases_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: test_cases test_cases_test_script_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases
    ADD CONSTRAINT test_cases_test_script_id_fkey FOREIGN KEY (test_script_id) REFERENCES public.test_scripts(id) ON DELETE CASCADE;


--
-- Name: test_cases test_cases_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases
    ADD CONSTRAINT test_cases_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: test_scripts test_scripts_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_scripts
    ADD CONSTRAINT test_scripts_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: DATABASE myapp; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE myapp TO appuser;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO appuser;


--
-- Name: TYPE audit_action; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.audit_action TO appuser;


--
-- Name: TYPE execution_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.execution_status TO appuser;


--
-- Name: FUNCTION gtrgm_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO appuser;


--
-- Name: FUNCTION gtrgm_out(public.gtrgm); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO appuser;


--
-- Name: TYPE gtrgm; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.gtrgm TO appuser;


--
-- Name: TYPE run_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.run_status TO appuser;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO appuser;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO appuser;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO appuser;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO appuser;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO appuser;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO appuser;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO appuser;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO appuser;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO appuser;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO appuser;


--
-- Name: FUNCTION gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO appuser;


--
-- Name: FUNCTION gin_extract_value_trgm(text, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO appuser;


--
-- Name: FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO appuser;


--
-- Name: FUNCTION gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_compress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO appuser;


--
-- Name: FUNCTION gtrgm_consistent(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_decompress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO appuser;


--
-- Name: FUNCTION gtrgm_distance(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_options(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO appuser;


--
-- Name: FUNCTION gtrgm_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_picksplit(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_same(public.gtrgm, public.gtrgm, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO appuser;


--
-- Name: FUNCTION gtrgm_union(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO appuser;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO appuser;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION set_limit(real); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_limit(real) TO appuser;


--
-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_updated_at() TO appuser;


--
-- Name: FUNCTION show_limit(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.show_limit() TO appuser;


--
-- Name: FUNCTION show_trgm(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.show_trgm(text) TO appuser;


--
-- Name: FUNCTION similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity(text, text) TO appuser;


--
-- Name: FUNCTION similarity_dist(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO appuser;


--
-- Name: FUNCTION similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity_op(text, text) TO appuser;


--
-- Name: FUNCTION strict_word_similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO appuser;


--
-- Name: FUNCTION strict_word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO appuser;


--
-- Name: FUNCTION strict_word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO appuser;


--
-- Name: FUNCTION strict_word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO appuser;


--
-- Name: FUNCTION strict_word_similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO appuser;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1() TO appuser;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO appuser;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO appuser;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v4() TO appuser;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO appuser;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_nil() TO appuser;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_dns() TO appuser;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_oid() TO appuser;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_url() TO appuser;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_x500() TO appuser;


--
-- Name: FUNCTION word_similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity(text, text) TO appuser;


--
-- Name: FUNCTION word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO appuser;


--
-- Name: FUNCTION word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO appuser;


--
-- Name: FUNCTION word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO appuser;


--
-- Name: FUNCTION word_similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO appuser;


--
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.audit_log TO appuser;


--
-- Name: TABLE configurations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.configurations TO appuser;


--
-- Name: TABLE execution_queue; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.execution_queue TO appuser;


--
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.roles TO appuser;


--
-- Name: TABLE run_artifacts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.run_artifacts TO appuser;


--
-- Name: TABLE run_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.run_history TO appuser;


--
-- Name: TABLE test_case_versions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.test_case_versions TO appuser;


--
-- Name: TABLE test_cases; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.test_cases TO appuser;


--
-- Name: TABLE test_scripts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.test_scripts TO appuser;


--
-- Name: TABLE user_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_roles TO appuser;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TYPES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO appuser;


--
-- PostgreSQL database dump complete
--

\unrestrict CeapDJc1BOvqchFlvIq0IhgT4cnkg0oWbhEyCZJFcj5xcXzfhhNHg98pklbB0Kh

