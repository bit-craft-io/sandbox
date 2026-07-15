--
-- PostgreSQL database dump
--

\restrict xbtAtDWuSUrBeX874UkwksAfDksiaywSC6yqJWoLarJrYDNICObo1TgPtqiB7ux

-- Dumped from database version 15.18
-- Dumped by pg_dump version 15.18

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: uuidv7(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.uuidv7() RETURNS uuid
    LANGUAGE sql PARALLEL SAFE
    AS $$
            -- Replace the first 48 bits of a uuidv4 with the current
            -- number of milliseconds since 1970-01-01 UTC
            -- and set the "ver" field to 7 by setting additional bits
        SELECT encode(
                       set_bit(
                               set_bit(
                                       overlay(uuid_send(gen_random_uuid()) placing
                                               substring(int8send((extract(epoch from clock_timestamp()) * 1000)::bigint) from
                                                         3)
                                               from 1 for 6),
                                       52, 1),
                               53, 1), 'hex')::uuid;
        $$;


ALTER FUNCTION public.uuidv7() OWNER TO postgres;

--
-- Name: FUNCTION uuidv7(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.uuidv7() IS 'Generate a uuid-v7 value with a 48-bit timestamp (millisecond precision) and 74 bits of randomness';


--
-- Name: uuidv7_boundary(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.uuidv7_boundary(timestamp with time zone) RETURNS uuid
    LANGUAGE sql STABLE STRICT PARALLEL SAFE
    AS $_$
    /* uuid fields: version=0b0111, variant=0b10 */
SELECT encode(
               overlay('\x00000000000070008000000000000000'::bytea
                       placing substring(int8send(floor(extract(epoch from $1) * 1000)::bigint) from 3)
                       from 1 for 6),
               'hex')::uuid;
$_$;


ALTER FUNCTION public.uuidv7_boundary(timestamp with time zone) OWNER TO postgres;

--
-- Name: FUNCTION uuidv7_boundary(timestamp with time zone); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.uuidv7_boundary(timestamp with time zone) IS 'Generate a non-random uuidv7 with the given timestamp (first 48 bits) and all random bits to 0. As the smallest possible uuidv7 for that timestamp, it may be used as a boundary for partitions.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_integrates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_integrates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    provider character varying(16) NOT NULL,
    open_id character varying(255) NOT NULL,
    encrypted_token character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.account_integrates OWNER TO postgres;

--
-- Name: account_plugin_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_plugin_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    install_permission character varying(16) DEFAULT 'everyone'::character varying NOT NULL,
    debug_permission character varying(16) DEFAULT 'noone'::character varying NOT NULL
);


ALTER TABLE public.account_plugin_permissions OWNER TO postgres;

--
-- Name: account_trial_app_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_trial_app_records (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    app_id uuid NOT NULL,
    count integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.account_trial_app_records OWNER TO postgres;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255),
    password_salt character varying(255),
    avatar character varying(255),
    interface_language character varying(255),
    interface_theme character varying(255),
    timezone character varying(255),
    last_login_at timestamp without time zone,
    last_login_ip character varying(255),
    status character varying(16) DEFAULT 'active'::character varying NOT NULL,
    initialized_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    last_active_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: agent_config_drafts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_config_drafts (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    draft_type character varying(32) NOT NULL,
    account_id uuid,
    draft_owner_key character varying(255) NOT NULL,
    base_snapshot_id uuid,
    config_snapshot text NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.agent_config_drafts OWNER TO postgres;

--
-- Name: agent_config_revisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_config_revisions (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    previous_snapshot_id uuid,
    current_snapshot_id uuid NOT NULL,
    revision integer NOT NULL,
    operation character varying(64) NOT NULL,
    summary text,
    version_note text,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.agent_config_revisions OWNER TO postgres;

--
-- Name: agent_config_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_config_snapshots (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    version integer NOT NULL,
    config_snapshot text NOT NULL,
    summary text,
    version_note text,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.agent_config_snapshots OWNER TO postgres;

--
-- Name: COLUMN agent_config_snapshots.config_snapshot; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_config_snapshots.config_snapshot IS 'Serialized services.entities.agent_entities.AgentSoulConfig JSON.';


--
-- Name: agent_debug_conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_debug_conversations (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    app_id uuid NOT NULL,
    account_id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.agent_debug_conversations OWNER TO postgres;

--
-- Name: agent_drive_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_drive_files (
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    key character varying(512) NOT NULL,
    file_kind character varying(32) NOT NULL,
    file_id uuid NOT NULL,
    value_owned_by_drive boolean DEFAULT false NOT NULL,
    size bigint,
    hash character varying(255),
    mime_type character varying(255),
    created_by uuid,
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_skill boolean DEFAULT false NOT NULL,
    skill_metadata text
);


ALTER TABLE public.agent_drive_files OWNER TO postgres;

--
-- Name: agent_runtime_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_runtime_sessions (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    owner_type character varying(32) NOT NULL,
    agent_id uuid NOT NULL,
    backend_run_id character varying(255),
    session_snapshot text NOT NULL,
    workflow_id uuid,
    workflow_run_id uuid,
    node_id character varying(255),
    node_execution_id character varying(255),
    binding_id uuid,
    agent_config_snapshot_id uuid,
    composition_layer_specs text NOT NULL,
    conversation_id uuid,
    status character varying(32) DEFAULT 'active'::character varying NOT NULL,
    cleaned_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pending_form_id uuid,
    pending_tool_call_id character varying(255)
);


ALTER TABLE public.agent_runtime_sessions OWNER TO postgres;

--
-- Name: agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    icon_type character varying(32),
    icon character varying(255),
    icon_background character varying(255),
    agent_kind character varying(32) DEFAULT 'dify_agent'::character varying NOT NULL,
    scope character varying(32) NOT NULL,
    source character varying(32) NOT NULL,
    app_id uuid,
    workflow_id uuid,
    workflow_node_id character varying(255),
    active_config_snapshot_id uuid,
    status character varying(32) DEFAULT 'active'::character varying NOT NULL,
    roster_unique_name character varying(255) GENERATED ALWAYS AS (
CASE
    WHEN (((scope)::text = 'roster'::text) AND ((status)::text = 'active'::text)) THEN name
    ELSE NULL::character varying
END) STORED,
    created_by uuid,
    updated_by uuid,
    archived_by uuid,
    archived_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    role character varying(255) NOT NULL,
    active_config_has_model boolean DEFAULT false NOT NULL,
    backing_app_id uuid,
    active_config_is_published boolean DEFAULT false NOT NULL
);


ALTER TABLE public.agents OWNER TO postgres;

--
-- Name: COLUMN agents.icon; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.icon IS 'Icon payload interpreted by icon_type: emoji character, image file id, or external URL.';


--
-- Name: COLUMN agents.active_config_is_published; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.active_config_is_published IS 'Whether the normal shared Agent draft has been published into the active config snapshot. User-scoped debug drafts do not affect this flag.';


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: api_based_extensions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_based_extensions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    api_endpoint character varying(255) NOT NULL,
    api_key text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.api_based_extensions OWNER TO postgres;

--
-- Name: api_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    api_token_id uuid NOT NULL,
    path character varying(255) NOT NULL,
    request text,
    response text,
    ip character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.api_requests OWNER TO postgres;

--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid,
    type character varying(16) NOT NULL,
    token character varying(255) NOT NULL,
    last_used_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    tenant_id uuid
);


ALTER TABLE public.api_tokens OWNER TO postgres;

--
-- Name: app_annotation_hit_histories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_annotation_hit_histories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    annotation_id uuid NOT NULL,
    source text NOT NULL,
    question text NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    score double precision DEFAULT 0 NOT NULL,
    message_id uuid NOT NULL,
    annotation_question text NOT NULL,
    annotation_content text NOT NULL
);


ALTER TABLE public.app_annotation_hit_histories OWNER TO postgres;

--
-- Name: app_annotation_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_annotation_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    score_threshold double precision DEFAULT 0 NOT NULL,
    collection_binding_id uuid NOT NULL,
    created_user_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_user_id uuid NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.app_annotation_settings OWNER TO postgres;

--
-- Name: app_dataset_joins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_dataset_joins (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.app_dataset_joins OWNER TO postgres;

--
-- Name: app_mcp_servers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_mcp_servers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    server_code character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    parameters text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.app_mcp_servers OWNER TO postgres;

--
-- Name: app_model_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_model_configs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    provider character varying(255),
    model_id character varying(255),
    configs json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    opening_statement text,
    suggested_questions text,
    suggested_questions_after_answer text,
    more_like_this text,
    model text,
    user_input_form text,
    pre_prompt text,
    agent_mode text,
    speech_to_text text,
    sensitive_word_avoidance text,
    retriever_resource text,
    dataset_query_variable character varying(255),
    prompt_type character varying(255) DEFAULT 'simple'::character varying NOT NULL,
    chat_prompt_config text,
    completion_prompt_config text,
    dataset_configs text,
    external_data_tools text,
    file_upload text,
    text_to_speech text,
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.app_model_configs OWNER TO postgres;

--
-- Name: app_stars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_stars (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.app_stars OWNER TO postgres;

--
-- Name: app_triggers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_triggers (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    node_id character varying(64) NOT NULL,
    trigger_type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    provider_name character varying(255) DEFAULT ''::character varying,
    status character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.app_triggers OWNER TO postgres;

--
-- Name: apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.apps (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    mode character varying(255) NOT NULL,
    icon character varying(255),
    icon_background character varying(255),
    app_model_config_id uuid,
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    enable_site boolean NOT NULL,
    enable_api boolean NOT NULL,
    api_rpm integer DEFAULT 0 NOT NULL,
    api_rph integer DEFAULT 0 NOT NULL,
    is_demo boolean DEFAULT false NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    is_universal boolean DEFAULT false NOT NULL,
    workflow_id uuid,
    description text DEFAULT ''::character varying NOT NULL,
    tracing text,
    max_active_requests integer,
    icon_type character varying(255),
    created_by uuid,
    updated_by uuid,
    use_icon_as_answer_icon boolean DEFAULT false NOT NULL,
    maintainer uuid
);


ALTER TABLE public.apps OWNER TO postgres;

--
-- Name: task_id_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_id_sequence OWNER TO postgres;

--
-- Name: celery_taskmeta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.celery_taskmeta (
    id integer DEFAULT nextval('public.task_id_sequence'::regclass) NOT NULL,
    task_id character varying(155) NOT NULL,
    status character varying(50) NOT NULL,
    result bytea,
    date_done timestamp without time zone,
    traceback text,
    name character varying(155),
    args bytea,
    kwargs bytea,
    worker character varying(155),
    retries integer,
    queue character varying(155)
);


ALTER TABLE public.celery_taskmeta OWNER TO postgres;

--
-- Name: taskset_id_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.taskset_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.taskset_id_sequence OWNER TO postgres;

--
-- Name: celery_tasksetmeta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.celery_tasksetmeta (
    id integer DEFAULT nextval('public.taskset_id_sequence'::regclass) NOT NULL,
    taskset_id character varying(155) NOT NULL,
    result bytea,
    date_done timestamp without time zone
);


ALTER TABLE public.celery_tasksetmeta OWNER TO postgres;

--
-- Name: child_chunks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.child_chunks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    document_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    "position" integer NOT NULL,
    content text NOT NULL,
    word_count integer NOT NULL,
    index_node_id character varying(255),
    index_node_hash character varying(255),
    type character varying(255) DEFAULT 'automatic'::character varying NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    indexing_at timestamp without time zone,
    completed_at timestamp without time zone,
    error text
);


ALTER TABLE public.child_chunks OWNER TO postgres;

--
-- Name: conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    app_model_config_id uuid,
    model_provider character varying(255),
    override_model_configs text,
    model_id character varying(255),
    mode character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    summary text,
    inputs json NOT NULL,
    introduction text,
    system_instruction text,
    system_instruction_tokens integer DEFAULT 0 NOT NULL,
    status character varying(255) NOT NULL,
    from_source character varying(255) NOT NULL,
    from_end_user_id uuid,
    from_account_id uuid,
    read_at timestamp without time zone,
    read_account_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    invoke_from character varying(255),
    dialogue_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.conversations OWNER TO postgres;

--
-- Name: credential_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credential_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    credential_id uuid NOT NULL,
    credential_type character varying(40) NOT NULL,
    account_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    has_permission boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.credential_permissions OWNER TO postgres;

--
-- Name: customized_snippets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customized_snippets (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    type character varying(50) DEFAULT 'node'::character varying NOT NULL,
    workflow_id uuid,
    is_published boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    use_count integer DEFAULT 0 NOT NULL,
    icon_info jsonb,
    input_fields text,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.customized_snippets OWNER TO postgres;

--
-- Name: data_source_api_key_auth_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_source_api_key_auth_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    category character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    credentials text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    disabled boolean DEFAULT false
);


ALTER TABLE public.data_source_api_key_auth_bindings OWNER TO postgres;

--
-- Name: data_source_oauth_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_source_oauth_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    access_token character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    source_info jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    disabled boolean DEFAULT false
);


ALTER TABLE public.data_source_oauth_bindings OWNER TO postgres;

--
-- Name: dataset_auto_disable_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_auto_disable_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    document_id uuid NOT NULL,
    notified boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.dataset_auto_disable_logs OWNER TO postgres;

--
-- Name: dataset_collection_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_collection_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    collection_name character varying(64) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    type character varying(40) DEFAULT 'dataset'::character varying NOT NULL
);


ALTER TABLE public.dataset_collection_bindings OWNER TO postgres;

--
-- Name: dataset_keyword_tables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_keyword_tables (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dataset_id uuid NOT NULL,
    keyword_table text NOT NULL,
    data_source_type character varying(255) DEFAULT 'database'::character varying NOT NULL
);


ALTER TABLE public.dataset_keyword_tables OWNER TO postgres;

--
-- Name: dataset_metadata_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_metadata_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    metadata_id uuid NOT NULL,
    document_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid NOT NULL
);


ALTER TABLE public.dataset_metadata_bindings OWNER TO postgres;

--
-- Name: dataset_metadatas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_metadatas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    created_by uuid NOT NULL,
    updated_by uuid
);


ALTER TABLE public.dataset_metadatas OWNER TO postgres;

--
-- Name: dataset_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dataset_id uuid NOT NULL,
    account_id uuid NOT NULL,
    has_permission boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    tenant_id uuid NOT NULL
);


ALTER TABLE public.dataset_permissions OWNER TO postgres;

--
-- Name: dataset_process_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_process_rules (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dataset_id uuid NOT NULL,
    mode character varying(255) DEFAULT 'automatic'::character varying NOT NULL,
    rules text,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.dataset_process_rules OWNER TO postgres;

--
-- Name: dataset_queries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_queries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dataset_id uuid NOT NULL,
    content text NOT NULL,
    source character varying(255) NOT NULL,
    source_app_id uuid,
    created_by_role character varying NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.dataset_queries OWNER TO postgres;

--
-- Name: dataset_retriever_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dataset_retriever_resources (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    "position" integer NOT NULL,
    dataset_id uuid NOT NULL,
    dataset_name text NOT NULL,
    document_id uuid,
    document_name text NOT NULL,
    data_source_type text,
    segment_id uuid,
    score double precision,
    content text NOT NULL,
    hit_count integer,
    word_count integer,
    segment_position integer,
    index_node_hash text,
    retriever_from text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.dataset_retriever_resources OWNER TO postgres;

--
-- Name: datasets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datasets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    provider character varying(255) DEFAULT 'vendor'::character varying NOT NULL,
    permission character varying(255) DEFAULT 'only_me'::character varying NOT NULL,
    data_source_type character varying(255),
    indexing_technique character varying(255),
    index_struct text,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    embedding_model character varying(255) DEFAULT 'text-embedding-ada-002'::character varying,
    embedding_model_provider character varying(255) DEFAULT 'openai'::character varying,
    collection_binding_id uuid,
    retrieval_model jsonb,
    built_in_field_enabled boolean DEFAULT false NOT NULL,
    keyword_number integer DEFAULT 10,
    icon_info jsonb,
    runtime_mode character varying(255) DEFAULT 'general'::character varying,
    pipeline_id uuid,
    chunk_structure character varying(255),
    enable_api boolean DEFAULT true NOT NULL,
    is_multimodal boolean DEFAULT false NOT NULL,
    summary_index_setting jsonb,
    maintainer uuid
);


ALTER TABLE public.datasets OWNER TO postgres;

--
-- Name: datasource_oauth_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datasource_oauth_params (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    plugin_id character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    system_credentials jsonb NOT NULL
);


ALTER TABLE public.datasource_oauth_params OWNER TO postgres;

--
-- Name: datasource_oauth_tenant_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datasource_oauth_tenant_params (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    provider character varying(255) NOT NULL,
    plugin_id character varying(255) NOT NULL,
    client_params jsonb NOT NULL,
    enabled boolean NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.datasource_oauth_tenant_params OWNER TO postgres;

--
-- Name: datasource_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datasource_providers (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    provider character varying(128) NOT NULL,
    plugin_id character varying(255) NOT NULL,
    auth_type character varying(255) NOT NULL,
    encrypted_credentials jsonb NOT NULL,
    avatar_url text,
    is_default boolean DEFAULT false NOT NULL,
    expires_at integer DEFAULT '-1'::integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id uuid,
    visibility character varying(40) DEFAULT 'all_team_members'::character varying NOT NULL
);


ALTER TABLE public.datasource_providers OWNER TO postgres;

--
-- Name: dify_setups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dify_setups (
    version character varying(255) NOT NULL,
    setup_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.dify_setups OWNER TO postgres;

--
-- Name: document_pipeline_execution_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_pipeline_execution_logs (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    pipeline_id uuid NOT NULL,
    document_id uuid NOT NULL,
    datasource_type character varying(255) NOT NULL,
    datasource_info text NOT NULL,
    datasource_node_id character varying(255) NOT NULL,
    input_data json NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.document_pipeline_execution_logs OWNER TO postgres;

--
-- Name: document_segment_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_segment_summaries (
    id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    document_id uuid NOT NULL,
    chunk_id uuid NOT NULL,
    summary_content text,
    summary_index_node_id character varying(255),
    summary_index_node_hash character varying(255),
    tokens integer,
    status character varying(32) DEFAULT 'generating'::character varying NOT NULL,
    error text,
    enabled boolean DEFAULT true NOT NULL,
    disabled_at timestamp without time zone,
    disabled_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.document_segment_summaries OWNER TO postgres;

--
-- Name: document_segments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_segments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    document_id uuid NOT NULL,
    "position" integer NOT NULL,
    content text NOT NULL,
    word_count integer NOT NULL,
    tokens integer NOT NULL,
    keywords json,
    index_node_id character varying(255),
    index_node_hash character varying(255),
    hit_count integer NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    disabled_at timestamp without time zone,
    disabled_by uuid,
    status character varying(255) DEFAULT 'waiting'::character varying NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    indexing_at timestamp without time zone,
    completed_at timestamp without time zone,
    error text,
    stopped_at timestamp without time zone,
    answer text,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.document_segments OWNER TO postgres;

--
-- Name: documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    "position" integer NOT NULL,
    data_source_type character varying(255) NOT NULL,
    data_source_info text,
    dataset_process_rule_id uuid,
    batch character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_from character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    created_api_request_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    processing_started_at timestamp without time zone,
    file_id text,
    word_count integer,
    parsing_completed_at timestamp without time zone,
    cleaning_completed_at timestamp without time zone,
    splitting_completed_at timestamp without time zone,
    tokens integer,
    indexing_latency double precision,
    completed_at timestamp without time zone,
    is_paused boolean DEFAULT false,
    paused_by uuid,
    paused_at timestamp without time zone,
    error text,
    stopped_at timestamp without time zone,
    indexing_status character varying(255) DEFAULT 'waiting'::character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    disabled_at timestamp without time zone,
    disabled_by uuid,
    archived boolean DEFAULT false NOT NULL,
    archived_reason character varying(255),
    archived_by uuid,
    archived_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    doc_type character varying(40),
    doc_metadata jsonb,
    doc_form character varying(255) DEFAULT 'text_model'::character varying NOT NULL,
    doc_language character varying(255),
    need_summary boolean DEFAULT false NOT NULL
);


ALTER TABLE public.documents OWNER TO postgres;

--
-- Name: embeddings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    hash character varying(64) NOT NULL,
    embedding bytea NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    model_name character varying(255) DEFAULT 'text-embedding-ada-002'::character varying NOT NULL,
    provider_name character varying(255) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.embeddings OWNER TO postgres;

--
-- Name: end_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.end_users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid,
    type character varying(255) NOT NULL,
    external_user_id character varying(255),
    name character varying(255),
    is_anonymous boolean DEFAULT true NOT NULL,
    session_id character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.end_users OWNER TO postgres;

--
-- Name: execution_extra_contents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_extra_contents (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type character varying(30) NOT NULL,
    workflow_run_id uuid NOT NULL,
    message_id uuid,
    form_id uuid
);


ALTER TABLE public.execution_extra_contents OWNER TO postgres;

--
-- Name: exporle_banners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exporle_banners (
    id uuid NOT NULL,
    content json NOT NULL,
    link character varying(255) NOT NULL,
    sort integer NOT NULL,
    status character varying(255) DEFAULT 'enabled'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    language character varying(255) DEFAULT 'en-US'::character varying NOT NULL
);


ALTER TABLE public.exporle_banners OWNER TO postgres;

--
-- Name: external_knowledge_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.external_knowledge_apis (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    tenant_id uuid NOT NULL,
    settings text,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.external_knowledge_apis OWNER TO postgres;

--
-- Name: external_knowledge_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.external_knowledge_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    external_knowledge_api_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    external_knowledge_id character varying(512) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.external_knowledge_bindings OWNER TO postgres;

--
-- Name: human_input_form_deliveries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.human_input_form_deliveries (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    form_id uuid NOT NULL,
    delivery_method_type character varying(20) NOT NULL,
    delivery_config_id uuid,
    channel_payload text NOT NULL
);


ALTER TABLE public.human_input_form_deliveries OWNER TO postgres;

--
-- Name: human_input_form_recipients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.human_input_form_recipients (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    form_id uuid NOT NULL,
    delivery_id uuid NOT NULL,
    recipient_type character varying(20) NOT NULL,
    recipient_payload text NOT NULL,
    access_token character varying(32) NOT NULL
);


ALTER TABLE public.human_input_form_recipients OWNER TO postgres;

--
-- Name: human_input_form_upload_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.human_input_form_upload_files (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    form_id uuid NOT NULL,
    upload_file_id uuid NOT NULL,
    upload_token_id uuid NOT NULL
);


ALTER TABLE public.human_input_form_upload_files OWNER TO postgres;

--
-- Name: human_input_form_upload_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.human_input_form_upload_tokens (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    form_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    token character varying(255) NOT NULL
);


ALTER TABLE public.human_input_form_upload_tokens OWNER TO postgres;

--
-- Name: human_input_forms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.human_input_forms (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_run_id uuid,
    form_kind character varying(20) NOT NULL,
    node_id character varying(60) NOT NULL,
    form_definition text NOT NULL,
    rendered_content text NOT NULL,
    status character varying(20) NOT NULL,
    expiration_time timestamp without time zone NOT NULL,
    selected_action_id character varying(200),
    submitted_data text,
    submitted_at timestamp without time zone,
    submission_user_id uuid,
    submission_end_user_id uuid,
    completed_by_recipient_id uuid,
    conversation_id uuid
);


ALTER TABLE public.human_input_forms OWNER TO postgres;

--
-- Name: installed_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.installed_apps (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    app_owner_tenant_id uuid NOT NULL,
    "position" integer NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL,
    last_used_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.installed_apps OWNER TO postgres;

--
-- Name: invitation_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invitation_codes (
    id integer NOT NULL,
    batch character varying(255) NOT NULL,
    code character varying(32) NOT NULL,
    status character varying(16) DEFAULT 'unused'::character varying NOT NULL,
    used_at timestamp without time zone,
    used_by_tenant_id uuid,
    used_by_account_id uuid,
    deprecated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.invitation_codes OWNER TO postgres;

--
-- Name: invitation_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invitation_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invitation_codes_id_seq OWNER TO postgres;

--
-- Name: invitation_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invitation_codes_id_seq OWNED BY public.invitation_codes.id;


--
-- Name: load_balancing_model_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.load_balancing_model_configs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    model_type character varying(40) NOT NULL,
    name character varying(255) NOT NULL,
    encrypted_config text,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    credential_id uuid,
    credential_source_type character varying(40)
);


ALTER TABLE public.load_balancing_model_configs OWNER TO postgres;

--
-- Name: message_agent_thoughts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_agent_thoughts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    message_chain_id uuid,
    "position" integer NOT NULL,
    thought text,
    tool text,
    tool_input text,
    observation text,
    tool_process_data text,
    message text,
    message_token integer,
    message_unit_price numeric,
    answer text,
    answer_token integer,
    answer_unit_price numeric,
    tokens integer,
    total_price numeric,
    currency character varying,
    latency double precision,
    created_by_role character varying NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message_price_unit numeric(10,7) DEFAULT 0.001 NOT NULL,
    answer_price_unit numeric(10,7) DEFAULT 0.001 NOT NULL,
    message_files text,
    tool_labels_str text DEFAULT '{}'::text NOT NULL,
    tool_meta_str text DEFAULT '{}'::text NOT NULL
);


ALTER TABLE public.message_agent_thoughts OWNER TO postgres;

--
-- Name: message_annotations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_annotations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    conversation_id uuid,
    message_id uuid,
    content text NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    question text NOT NULL,
    hit_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.message_annotations OWNER TO postgres;

--
-- Name: message_chains; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_chains (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    input text,
    output text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.message_chains OWNER TO postgres;

--
-- Name: message_feedbacks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_feedbacks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    message_id uuid NOT NULL,
    rating character varying(255) NOT NULL,
    content text,
    from_source character varying(255) NOT NULL,
    from_end_user_id uuid,
    from_account_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.message_feedbacks OWNER TO postgres;

--
-- Name: message_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_files (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    transfer_method character varying(255) NOT NULL,
    url text,
    upload_file_id uuid,
    created_by_role character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    belongs_to character varying(255)
);


ALTER TABLE public.message_files OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    model_provider character varying(255),
    model_id character varying(255),
    override_model_configs text,
    conversation_id uuid NOT NULL,
    inputs json NOT NULL,
    query text NOT NULL,
    message json NOT NULL,
    message_tokens integer DEFAULT 0 NOT NULL,
    message_unit_price numeric(10,4) NOT NULL,
    answer text NOT NULL,
    answer_tokens integer DEFAULT 0 NOT NULL,
    answer_unit_price numeric(10,4) NOT NULL,
    provider_response_latency double precision DEFAULT 0 NOT NULL,
    total_price numeric(10,7),
    currency character varying(255) NOT NULL,
    from_source character varying(255) NOT NULL,
    from_end_user_id uuid,
    from_account_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    agent_based boolean DEFAULT false NOT NULL,
    message_price_unit numeric(10,7) DEFAULT 0.001 NOT NULL,
    answer_price_unit numeric(10,7) DEFAULT 0.001 NOT NULL,
    workflow_run_id uuid,
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    error text,
    message_metadata text,
    invoke_from character varying(255),
    parent_message_id uuid,
    app_mode character varying(255)
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_access_tokens (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    subject_email character varying(255) NOT NULL,
    subject_issuer character varying(255),
    account_id uuid,
    client_id character varying(64) NOT NULL,
    device_label character varying(255) NOT NULL,
    prefix character varying(8) NOT NULL,
    token_hash character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone
);


ALTER TABLE public.oauth_access_tokens OWNER TO postgres;

--
-- Name: oauth_provider_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_provider_apps (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    app_icon character varying(255) NOT NULL,
    app_label json DEFAULT '{}'::json NOT NULL,
    client_id character varying(255) NOT NULL,
    client_secret character varying(255) NOT NULL,
    redirect_uris json DEFAULT '[]'::json NOT NULL,
    scope character varying(255) DEFAULT 'read:name read:email read:avatar read:interface_language read:timezone'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.oauth_provider_apps OWNER TO postgres;

--
-- Name: operation_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operation_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    account_id uuid NOT NULL,
    action character varying(255) NOT NULL,
    content json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    created_ip character varying(255) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.operation_logs OWNER TO postgres;

--
-- Name: pinned_conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pinned_conversations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    created_by_role character varying(255) DEFAULT 'end_user'::character varying NOT NULL
);


ALTER TABLE public.pinned_conversations OWNER TO postgres;

--
-- Name: pipeline_built_in_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_built_in_templates (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    chunk_structure character varying(255) NOT NULL,
    icon json NOT NULL,
    yaml_content text NOT NULL,
    copyright character varying(255) NOT NULL,
    privacy_policy character varying(255) NOT NULL,
    "position" integer NOT NULL,
    install_count integer NOT NULL,
    language character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pipeline_built_in_templates OWNER TO postgres;

--
-- Name: pipeline_customized_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_customized_templates (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    chunk_structure character varying(255) NOT NULL,
    icon json NOT NULL,
    "position" integer NOT NULL,
    yaml_content text NOT NULL,
    install_count integer NOT NULL,
    language character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pipeline_customized_templates OWNER TO postgres;

--
-- Name: pipeline_recommended_plugins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_recommended_plugins (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    plugin_id text NOT NULL,
    provider_name text NOT NULL,
    "position" integer NOT NULL,
    active boolean NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type character varying(50) DEFAULT 'tool'::character varying NOT NULL
);


ALTER TABLE public.pipeline_recommended_plugins OWNER TO postgres;

--
-- Name: pipelines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipelines (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text DEFAULT ''::character varying NOT NULL,
    workflow_id uuid,
    is_public boolean DEFAULT false NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pipelines OWNER TO postgres;

--
-- Name: provider_credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provider_credentials (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    credential_name character varying(255) NOT NULL,
    encrypted_config text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id uuid,
    visibility character varying(40) DEFAULT 'all_team_members'::character varying NOT NULL
);


ALTER TABLE public.provider_credentials OWNER TO postgres;

--
-- Name: provider_model_credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provider_model_credentials (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    model_type character varying(40) NOT NULL,
    credential_name character varying(255) NOT NULL,
    encrypted_config text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.provider_model_credentials OWNER TO postgres;

--
-- Name: provider_model_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provider_model_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    model_type character varying(40) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    load_balancing_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.provider_model_settings OWNER TO postgres;

--
-- Name: provider_models; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provider_models (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    model_type character varying(40) NOT NULL,
    is_valid boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    credential_id uuid
);


ALTER TABLE public.provider_models OWNER TO postgres;

--
-- Name: provider_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provider_orders (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    account_id uuid NOT NULL,
    payment_product_id character varying(191) NOT NULL,
    payment_id character varying(191),
    transaction_id character varying(191),
    quantity integer DEFAULT 1 NOT NULL,
    currency character varying(40),
    total_amount integer,
    payment_status character varying(40) DEFAULT 'wait_pay'::character varying NOT NULL,
    paid_at timestamp without time zone,
    pay_failed_at timestamp without time zone,
    refunded_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.provider_orders OWNER TO postgres;

--
-- Name: providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    provider_type character varying(40) DEFAULT 'custom'::character varying NOT NULL,
    is_valid boolean DEFAULT false NOT NULL,
    last_used timestamp without time zone,
    quota_type character varying(40) DEFAULT ''::character varying,
    quota_limit bigint,
    quota_used bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    credential_id uuid
);


ALTER TABLE public.providers OWNER TO postgres;

--
-- Name: rate_limit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rate_limit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    subscription_plan character varying(255) NOT NULL,
    operation character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.rate_limit_logs OWNER TO postgres;

--
-- Name: recommended_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recommended_apps (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    description json NOT NULL,
    copyright character varying(255) NOT NULL,
    privacy_policy character varying(255) NOT NULL,
    category character varying(255) NOT NULL,
    "position" integer NOT NULL,
    is_listed boolean NOT NULL,
    install_count integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    language character varying(255) DEFAULT 'en-US'::character varying NOT NULL,
    custom_disclaimer text NOT NULL,
    categories json,
    is_learn_dify boolean DEFAULT false NOT NULL,
    is_cloud_only boolean DEFAULT false NOT NULL
);


ALTER TABLE public.recommended_apps OWNER TO postgres;

--
-- Name: saved_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.saved_messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    message_id uuid NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    created_by_role character varying(255) DEFAULT 'end_user'::character varying NOT NULL
);


ALTER TABLE public.saved_messages OWNER TO postgres;

--
-- Name: segment_attachment_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.segment_attachment_bindings (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    dataset_id uuid NOT NULL,
    document_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    attachment_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.segment_attachment_bindings OWNER TO postgres;

--
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sites (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    icon character varying(255),
    icon_background character varying(255),
    description text,
    default_language character varying(255) NOT NULL,
    copyright character varying(255),
    privacy_policy character varying(255),
    customize_domain character varying(255),
    customize_token_strategy character varying(255) NOT NULL,
    prompt_public boolean DEFAULT false NOT NULL,
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    code character varying(255),
    custom_disclaimer text NOT NULL,
    show_workflow_steps boolean DEFAULT true NOT NULL,
    chat_color_theme character varying(255),
    chat_color_theme_inverted boolean DEFAULT false NOT NULL,
    icon_type character varying(255),
    created_by uuid,
    updated_by uuid,
    use_icon_as_answer_icon boolean DEFAULT false NOT NULL,
    input_placeholder character varying(255)
);


ALTER TABLE public.sites OWNER TO postgres;

--
-- Name: tag_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tag_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid,
    tag_id uuid,
    target_id uuid,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tag_bindings OWNER TO postgres;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid,
    type character varying(16) NOT NULL,
    name character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- Name: tenant_account_joins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_account_joins (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    account_id uuid NOT NULL,
    role character varying(16) DEFAULT 'normal'::character varying NOT NULL,
    invited_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    current boolean DEFAULT false NOT NULL,
    last_opened_at timestamp without time zone
);


ALTER TABLE public.tenant_account_joins OWNER TO postgres;

--
-- Name: tenant_credit_pools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_credit_pools (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    pool_type character varying(40) DEFAULT 'trial'::character varying NOT NULL,
    quota_limit bigint NOT NULL,
    quota_used bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.tenant_credit_pools OWNER TO postgres;

--
-- Name: tenant_default_models; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_default_models (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    model_name character varying(255) NOT NULL,
    model_type character varying(40) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tenant_default_models OWNER TO postgres;

--
-- Name: tenant_plugin_auto_upgrade_strategies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_plugin_auto_upgrade_strategies (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    strategy_setting character varying(16) DEFAULT 'fix_only'::character varying NOT NULL,
    upgrade_time_of_day integer NOT NULL,
    upgrade_mode character varying(16) DEFAULT 'exclude'::character varying NOT NULL,
    exclude_plugins json NOT NULL,
    include_plugins json NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    category character varying(32) DEFAULT 'tool'::character varying NOT NULL
);


ALTER TABLE public.tenant_plugin_auto_upgrade_strategies OWNER TO postgres;

--
-- Name: tenant_preferred_model_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_preferred_model_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    provider_name character varying(255) NOT NULL,
    preferred_provider_type character varying(40) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tenant_preferred_model_providers OWNER TO postgres;

--
-- Name: tenants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenants (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    encrypt_public_key text,
    plan character varying(255) DEFAULT 'basic'::character varying NOT NULL,
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    custom_config text
);


ALTER TABLE public.tenants OWNER TO postgres;

--
-- Name: tidb_auth_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tidb_auth_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid,
    cluster_id character varying(255) NOT NULL,
    cluster_name character varying(255) NOT NULL,
    active boolean DEFAULT false NOT NULL,
    status character varying(255) DEFAULT 'CREATING'::character varying NOT NULL,
    account character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    qdrant_endpoint character varying(512)
);


ALTER TABLE public.tidb_auth_bindings OWNER TO postgres;

--
-- Name: tool_api_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_api_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    schema text NOT NULL,
    schema_type_str character varying(40) NOT NULL,
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tools_str text NOT NULL,
    icon character varying(255) NOT NULL,
    credentials_str text NOT NULL,
    description text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    privacy_policy character varying(255),
    custom_disclaimer text NOT NULL
);


ALTER TABLE public.tool_api_providers OWNER TO postgres;

--
-- Name: tool_builtin_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_builtin_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid,
    user_id uuid NOT NULL,
    provider character varying(256) NOT NULL,
    encrypted_credentials text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    name character varying(256) DEFAULT 'API KEY 1'::character varying NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    credential_type character varying(32) DEFAULT 'api-key'::character varying NOT NULL,
    expires_at bigint DEFAULT '-1'::integer NOT NULL,
    visibility character varying(40) DEFAULT 'all_team_members'::character varying NOT NULL
);


ALTER TABLE public.tool_builtin_providers OWNER TO postgres;

--
-- Name: tool_conversation_variables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_conversation_variables (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    variables_str text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tool_conversation_variables OWNER TO postgres;

--
-- Name: tool_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_files (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    conversation_id uuid,
    file_key character varying(255) NOT NULL,
    mimetype character varying(255) NOT NULL,
    original_url character varying(2048),
    name character varying NOT NULL,
    size integer NOT NULL
);


ALTER TABLE public.tool_files OWNER TO postgres;

--
-- Name: tool_label_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_label_bindings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tool_id character varying(64) NOT NULL,
    tool_type character varying(40) NOT NULL,
    label_name character varying(40) NOT NULL
);


ALTER TABLE public.tool_label_bindings OWNER TO postgres;

--
-- Name: tool_mcp_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_mcp_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(40) NOT NULL,
    server_identifier character varying(64) NOT NULL,
    server_url text NOT NULL,
    server_url_hash character varying(64) NOT NULL,
    icon character varying(255),
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    encrypted_credentials text,
    authed boolean NOT NULL,
    tools text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    timeout double precision DEFAULT 30 NOT NULL,
    sse_read_timeout double precision DEFAULT 300 NOT NULL,
    encrypted_headers text,
    identity_mode character varying(32) DEFAULT 'off'::character varying NOT NULL
);


ALTER TABLE public.tool_mcp_providers OWNER TO postgres;

--
-- Name: tool_model_invokes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_model_invokes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    provider character varying(255) NOT NULL,
    tool_type character varying(40) NOT NULL,
    tool_name character varying(128) NOT NULL,
    model_parameters text NOT NULL,
    prompt_messages text NOT NULL,
    model_response text NOT NULL,
    prompt_tokens integer DEFAULT 0 NOT NULL,
    answer_tokens integer DEFAULT 0 NOT NULL,
    answer_unit_price numeric(10,4) NOT NULL,
    answer_price_unit numeric(10,7) DEFAULT 0.001 NOT NULL,
    provider_response_latency double precision DEFAULT 0 NOT NULL,
    total_price numeric(10,7),
    currency character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tool_model_invokes OWNER TO postgres;

--
-- Name: tool_oauth_system_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_oauth_system_clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    plugin_id character varying(512) NOT NULL,
    provider character varying(255) NOT NULL,
    encrypted_oauth_params text NOT NULL
);


ALTER TABLE public.tool_oauth_system_clients OWNER TO postgres;

--
-- Name: tool_oauth_tenant_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_oauth_tenant_clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    plugin_id character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    encrypted_oauth_params text NOT NULL
);


ALTER TABLE public.tool_oauth_tenant_clients OWNER TO postgres;

--
-- Name: tool_published_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_published_apps (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    user_id uuid NOT NULL,
    description text NOT NULL,
    llm_description text NOT NULL,
    query_description text NOT NULL,
    query_name character varying(40) NOT NULL,
    tool_name character varying(40) NOT NULL,
    author character varying(40) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.tool_published_apps OWNER TO postgres;

--
-- Name: tool_workflow_providers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tool_workflow_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(255) NOT NULL,
    app_id uuid NOT NULL,
    user_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    description text NOT NULL,
    parameter_configuration text DEFAULT '[]'::text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    privacy_policy character varying(255) DEFAULT ''::character varying,
    version character varying(255) DEFAULT ''::character varying NOT NULL,
    label character varying(255) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.tool_workflow_providers OWNER TO postgres;

--
-- Name: trace_app_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trace_app_config (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    tracing_provider character varying(255),
    tracing_config json,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.trace_app_config OWNER TO postgres;

--
-- Name: trial_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trial_apps (
    id uuid NOT NULL,
    app_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    trial_limit integer NOT NULL
);


ALTER TABLE public.trial_apps OWNER TO postgres;

--
-- Name: trigger_oauth_system_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trigger_oauth_system_clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    plugin_id character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    encrypted_oauth_params text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.trigger_oauth_system_clients OWNER TO postgres;

--
-- Name: trigger_oauth_tenant_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trigger_oauth_tenant_clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    plugin_id character varying(255) NOT NULL,
    provider character varying(255) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    encrypted_oauth_params text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.trigger_oauth_tenant_clients OWNER TO postgres;

--
-- Name: trigger_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trigger_subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider_id character varying(255) NOT NULL,
    endpoint_id character varying(255) NOT NULL,
    parameters json NOT NULL,
    properties json NOT NULL,
    credentials json NOT NULL,
    credential_type character varying(50) NOT NULL,
    credential_expires_at integer NOT NULL,
    expires_at integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    visibility character varying(40) DEFAULT 'all_team_members'::character varying NOT NULL
);


ALTER TABLE public.trigger_subscriptions OWNER TO postgres;

--
-- Name: COLUMN trigger_subscriptions.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.name IS 'Subscription instance name';


--
-- Name: COLUMN trigger_subscriptions.provider_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.provider_id IS 'Provider identifier (e.g., plugin_id/provider_name)';


--
-- Name: COLUMN trigger_subscriptions.endpoint_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.endpoint_id IS 'Subscription endpoint';


--
-- Name: COLUMN trigger_subscriptions.parameters; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.parameters IS 'Subscription parameters JSON';


--
-- Name: COLUMN trigger_subscriptions.properties; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.properties IS 'Subscription properties JSON';


--
-- Name: COLUMN trigger_subscriptions.credentials; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.credentials IS 'Subscription credentials JSON';


--
-- Name: COLUMN trigger_subscriptions.credential_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.credential_type IS 'oauth or api_key';


--
-- Name: COLUMN trigger_subscriptions.credential_expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.credential_expires_at IS 'OAuth token expiration timestamp, -1 for never';


--
-- Name: COLUMN trigger_subscriptions.expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.trigger_subscriptions.expires_at IS 'Subscription instance expiration timestamp, -1 for never';


--
-- Name: upload_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.upload_files (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    storage_type character varying(255) NOT NULL,
    key character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    size integer NOT NULL,
    extension character varying(255) NOT NULL,
    mime_type character varying(255),
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    used boolean DEFAULT false NOT NULL,
    used_by uuid,
    used_at timestamp without time zone,
    hash character varying(255),
    created_by_role character varying(255) DEFAULT 'account'::character varying NOT NULL,
    source_url text DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.upload_files OWNER TO postgres;

--
-- Name: whitelists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.whitelists (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid,
    category character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.whitelists OWNER TO postgres;

--
-- Name: workflow_agent_node_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_agent_node_bindings (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    node_id character varying(255) NOT NULL,
    binding_type character varying(32) NOT NULL,
    agent_id uuid,
    current_snapshot_id uuid,
    node_job_config text NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    workflow_version character varying(255) NOT NULL
);


ALTER TABLE public.workflow_agent_node_bindings OWNER TO postgres;

--
-- Name: workflow_app_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_app_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    created_from character varying(255) NOT NULL,
    created_by_role character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


ALTER TABLE public.workflow_app_logs OWNER TO postgres;

--
-- Name: workflow_archive_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_archive_logs (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    log_id uuid,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    created_by_role character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    log_created_at timestamp without time zone,
    log_created_from character varying(255),
    run_version character varying(255) NOT NULL,
    run_status character varying(255) NOT NULL,
    run_triggered_from character varying(255) NOT NULL,
    run_error text,
    run_elapsed_time double precision DEFAULT 0 NOT NULL,
    run_total_tokens bigint DEFAULT 0 NOT NULL,
    run_total_steps integer DEFAULT 0,
    run_created_at timestamp without time zone NOT NULL,
    run_finished_at timestamp without time zone,
    run_exceptions_count integer DEFAULT 0,
    trigger_metadata text,
    archived_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_archive_logs OWNER TO postgres;

--
-- Name: workflow_comment_mentions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_comment_mentions (
    id uuid NOT NULL,
    comment_id uuid NOT NULL,
    reply_id uuid,
    mentioned_user_id uuid NOT NULL
);


ALTER TABLE public.workflow_comment_mentions OWNER TO postgres;

--
-- Name: workflow_comment_replies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_comment_replies (
    id uuid NOT NULL,
    comment_id uuid NOT NULL,
    content text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_comment_replies OWNER TO postgres;

--
-- Name: workflow_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_comments (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    position_x double precision NOT NULL,
    position_y double precision NOT NULL,
    content text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    resolved boolean DEFAULT false NOT NULL,
    resolved_at timestamp without time zone,
    resolved_by uuid
);


ALTER TABLE public.workflow_comments OWNER TO postgres;

--
-- Name: workflow_conversation_variables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_conversation_variables (
    id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    app_id uuid NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_conversation_variables OWNER TO postgres;

--
-- Name: workflow_draft_variable_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_draft_variable_files (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    user_id uuid NOT NULL,
    upload_file_id uuid NOT NULL,
    size bigint NOT NULL,
    length integer,
    value_type character varying(20) NOT NULL
);


ALTER TABLE public.workflow_draft_variable_files OWNER TO postgres;

--
-- Name: COLUMN workflow_draft_variable_files.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.tenant_id IS 'The tenant to which the WorkflowDraftVariableFile belongs, referencing Tenant.id';


--
-- Name: COLUMN workflow_draft_variable_files.app_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.app_id IS 'The application to which the WorkflowDraftVariableFile belongs, referencing App.id';


--
-- Name: COLUMN workflow_draft_variable_files.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.user_id IS 'The owner to of the WorkflowDraftVariableFile, referencing Account.id';


--
-- Name: COLUMN workflow_draft_variable_files.upload_file_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.upload_file_id IS 'Reference to UploadFile containing the large variable data';


--
-- Name: COLUMN workflow_draft_variable_files.size; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.size IS 'Size of the original variable content in bytes';


--
-- Name: COLUMN workflow_draft_variable_files.length; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variable_files.length IS 'Length of the original variable content. For array and array-like types, this represents the number of elements. For object types, it indicates the number of keys. For other types, the value is NULL.';


--
-- Name: workflow_draft_variables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_draft_variables (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    app_id uuid NOT NULL,
    last_edited_at timestamp without time zone,
    node_id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    selector character varying(255) NOT NULL,
    value_type character varying(20) NOT NULL,
    value text NOT NULL,
    visible boolean NOT NULL,
    editable boolean NOT NULL,
    node_execution_id uuid,
    file_id uuid,
    is_default_value boolean DEFAULT false NOT NULL,
    user_id uuid
);


ALTER TABLE public.workflow_draft_variables OWNER TO postgres;

--
-- Name: COLUMN workflow_draft_variables.file_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variables.file_id IS 'Reference to WorkflowDraftVariableFile if variable is offloaded to external storage';


--
-- Name: COLUMN workflow_draft_variables.is_default_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_draft_variables.is_default_value IS 'Indicates whether the current value is the default for a conversation variable. Always `FALSE` for other types of variables.';


--
-- Name: workflow_node_execution_offload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_node_execution_offload (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    node_execution_id uuid,
    type character varying(20) NOT NULL,
    file_id uuid NOT NULL
);


ALTER TABLE public.workflow_node_execution_offload OWNER TO postgres;

--
-- Name: workflow_node_executions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_node_executions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    triggered_from character varying(255) NOT NULL,
    workflow_run_id uuid,
    index integer NOT NULL,
    predecessor_node_id character varying(255),
    node_id character varying(255) NOT NULL,
    node_type character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    inputs text,
    process_data text,
    outputs text,
    status character varying(255) NOT NULL,
    error text,
    elapsed_time double precision DEFAULT 0 NOT NULL,
    execution_metadata text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    created_by_role character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    finished_at timestamp without time zone,
    node_execution_id character varying(255)
);


ALTER TABLE public.workflow_node_executions OWNER TO postgres;

--
-- Name: workflow_pause_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_pause_reasons (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pause_id uuid NOT NULL,
    type_ character varying(20) NOT NULL,
    form_id character varying(36) NOT NULL,
    node_id character varying(255) NOT NULL,
    message character varying(255) NOT NULL
);


ALTER TABLE public.workflow_pause_reasons OWNER TO postgres;

--
-- Name: workflow_pauses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_pauses (
    workflow_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    resumed_at timestamp without time zone,
    state_object_key character varying(255) NOT NULL,
    id uuid DEFAULT public.uuidv7() NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_pauses OWNER TO postgres;

--
-- Name: workflow_plugin_triggers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_plugin_triggers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    node_id character varying(64) NOT NULL,
    tenant_id uuid NOT NULL,
    provider_id character varying(512) NOT NULL,
    event_name character varying(255) NOT NULL,
    subscription_id character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_plugin_triggers OWNER TO postgres;

--
-- Name: workflow_runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_runs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    triggered_from character varying(255) NOT NULL,
    version character varying(255) NOT NULL,
    graph text,
    inputs text,
    status character varying(255) NOT NULL,
    outputs text,
    error text,
    elapsed_time double precision DEFAULT 0 NOT NULL,
    total_tokens bigint DEFAULT 0 NOT NULL,
    total_steps integer DEFAULT 0,
    created_by_role character varying(255) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    finished_at timestamp without time zone,
    exceptions_count integer DEFAULT 0
);


ALTER TABLE public.workflow_runs OWNER TO postgres;

--
-- Name: workflow_schedule_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_schedule_plans (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    app_id uuid NOT NULL,
    node_id character varying(64) NOT NULL,
    tenant_id uuid NOT NULL,
    cron_expression character varying(255) NOT NULL,
    timezone character varying(64) NOT NULL,
    next_run_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_schedule_plans OWNER TO postgres;

--
-- Name: workflow_trigger_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_trigger_logs (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    workflow_run_id uuid,
    root_node_id character varying(255),
    trigger_metadata text NOT NULL,
    trigger_type character varying(50) NOT NULL,
    trigger_data text NOT NULL,
    inputs text NOT NULL,
    outputs text,
    status character varying(50) NOT NULL,
    error text,
    queue_name character varying(100) NOT NULL,
    celery_task_id character varying(255),
    retry_count integer NOT NULL,
    elapsed_time double precision,
    total_tokens integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by_role character varying(255) NOT NULL,
    created_by character varying(255) NOT NULL,
    triggered_at timestamp without time zone,
    finished_at timestamp without time zone
);


ALTER TABLE public.workflow_trigger_logs OWNER TO postgres;

--
-- Name: workflow_webhook_triggers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_webhook_triggers (
    id uuid DEFAULT public.uuidv7() NOT NULL,
    app_id uuid NOT NULL,
    node_id character varying(64) NOT NULL,
    tenant_id uuid NOT NULL,
    webhook_id character varying(24) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.workflow_webhook_triggers OWNER TO postgres;

--
-- Name: workflows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflows (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    app_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    version character varying(255) NOT NULL,
    graph text NOT NULL,
    features text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone NOT NULL,
    environment_variables text DEFAULT '{}'::text NOT NULL,
    conversation_variables text DEFAULT '{}'::text NOT NULL,
    marked_name character varying DEFAULT ''::character varying NOT NULL,
    marked_comment character varying DEFAULT ''::character varying NOT NULL,
    rag_pipeline_variables text DEFAULT '{}'::text NOT NULL,
    kind character varying(255)
);


ALTER TABLE public.workflows OWNER TO postgres;

--
-- Name: invitation_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invitation_codes ALTER COLUMN id SET DEFAULT nextval('public.invitation_codes_id_seq'::regclass);


--
-- Data for Name: account_integrates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_integrates (id, account_id, provider, open_id, encrypted_token, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: account_plugin_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_plugin_permissions (id, tenant_id, install_permission, debug_permission) FROM stdin;
\.


--
-- Data for Name: account_trial_app_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_trial_app_records (id, account_id, app_id, count, created_at) FROM stdin;
\.


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts (id, name, email, password, password_salt, avatar, interface_language, interface_theme, timezone, last_login_at, last_login_ip, status, initialized_at, created_at, updated_at, last_active_at) FROM stdin;
28805f49-a5f3-48bf-a39c-ef203d1557d3	admin	samurai.dance@gmail.com	OTdiMTgzOGUwMzYyY2FlYTNlYTQ2NzgwZDhiNWI3NTAwZTkyNmE0YTk1OTMwNmUzOTdlODYzY2I5MjA2NmVlOA==	sKFXyp0tmB8rVKhXdcdusg==	\N	ja-JP	light	Asia/Tokyo	2026-07-14 03:27:22.780104	172.19.0.1	active	2026-07-14 03:27:22.485957	2026-07-14 03:27:22	2026-07-14 05:53:34.444216	2026-07-14 05:53:34.466141
\.


--
-- Data for Name: agent_config_drafts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_config_drafts (id, tenant_id, agent_id, draft_type, account_id, draft_owner_key, base_snapshot_id, config_snapshot, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: agent_config_revisions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_config_revisions (id, tenant_id, agent_id, previous_snapshot_id, current_snapshot_id, revision, operation, summary, version_note, created_by, created_at) FROM stdin;
019f5eaa-7d05-748c-937a-1220c64aa3b5	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	019f5eaa-7cfc-730c-8b3a-518dc1685dbe	\N	019f5eaa-7d01-79b1-81d4-eef0b7b03279	1	create_version	\N	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:27:39.269152
\.


--
-- Data for Name: agent_config_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_config_snapshots (id, tenant_id, agent_id, version, config_snapshot, summary, version_note, created_by, created_at, updated_at) FROM stdin;
019f5eaa-7d01-79b1-81d4-eef0b7b03279	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	019f5eaa-7cfc-730c-8b3a-518dc1685dbe	1	{"app_features":{"file_upload":{"allowed_file_extensions":["JPG","JPEG","PNG","GIF","WEBP","SVG"],"allowed_file_types":["document","image","audio","video"],"allowed_file_upload_methods":["local_file","remote_url"],"enabled":true,"image":{"enabled":true},"number_limits":3},"opening_statement":null,"retriever_resource":null,"sensitive_word_avoidance":null,"speech_to_text":null,"suggested_questions":null,"suggested_questions_after_answer":null,"text_to_speech":null},"app_variables":[],"config_files":[],"config_note":"","config_skills":[],"env":{"secret_refs":[],"variables":[]},"files":{"files":[],"skills":[]},"human":{"contacts":[],"tools":[]},"knowledge":{"sets":[]},"memory":{"artifacts":[],"budget":null,"scope":null},"misc_legacy":{"file_upload":{"allowed_file_extensions":["JPG","JPEG","PNG","GIF","WEBP","SVG"],"allowed_file_types":["document","image","audio","video"],"allowed_file_upload_methods":["local_file","remote_url"],"enabled":true,"image":{"enabled":true},"number_limits":3},"opening_statement":null,"retriever_resource":null,"sensitive_word_avoidance":null,"speech_to_text":null,"suggested_questions":null,"suggested_questions_after_answer":null,"text_to_speech":null},"model":null,"prompt":{"system_prompt":""},"sandbox":{"config":{"cpu":null,"env":[],"image":null,"working_dir":null},"provider":null},"schema_version":1,"tools":{"cli_tools":[],"dify_tools":[]}}	\N	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:27:39.265159	2026-07-14 03:27:39.265165
\.


--
-- Data for Name: agent_debug_conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_debug_conversations (id, tenant_id, agent_id, app_id, account_id, conversation_id, created_at, updated_at) FROM stdin;
019f5eaa-7d0d-7ce0-bd74-b876a6664950	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	019f5eaa-7cfc-730c-8b3a-518dc1685dbe	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	28805f49-a5f3-48bf-a39c-ef203d1557d3	7b19f31e-7ce7-4f60-bbb0-ca26222d5402	2026-07-14 03:27:39.277878	2026-07-14 03:27:39.277887
\.


--
-- Data for Name: agent_drive_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_drive_files (tenant_id, agent_id, key, file_kind, file_id, value_owned_by_drive, size, hash, mime_type, created_by, id, created_at, updated_at, is_skill, skill_metadata) FROM stdin;
\.


--
-- Data for Name: agent_runtime_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_runtime_sessions (id, tenant_id, app_id, owner_type, agent_id, backend_run_id, session_snapshot, workflow_id, workflow_run_id, node_id, node_execution_id, binding_id, agent_config_snapshot_id, composition_layer_specs, conversation_id, status, cleaned_at, created_at, updated_at, pending_form_id, pending_tool_call_id) FROM stdin;
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents (id, tenant_id, name, description, icon_type, icon, icon_background, agent_kind, scope, source, app_id, workflow_id, workflow_node_id, active_config_snapshot_id, status, created_by, updated_by, archived_by, archived_at, created_at, updated_at, role, active_config_has_model, backing_app_id, active_config_is_published) FROM stdin;
019f5eaa-7cfc-730c-8b3a-518dc1685dbe	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	LocalLLM		emoji	🧸	#F5F3FF	dify_agent	roster	agent_app	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	\N	\N	019f5eaa-7d01-79b1-81d4-eef0b7b03279	active	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3	\N	\N	2026-07-14 03:27:39.260893	2026-07-14 03:27:39.254162		f	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	f
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
c3d4e5f6a7b8
\.


--
-- Data for Name: api_based_extensions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_based_extensions (id, tenant_id, name, api_endpoint, api_key, created_at) FROM stdin;
\.


--
-- Data for Name: api_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_requests (id, tenant_id, api_token_id, path, request, response, ip, created_at) FROM stdin;
\.


--
-- Data for Name: api_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_tokens (id, app_id, type, token, last_used_at, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: app_annotation_hit_histories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_annotation_hit_histories (id, app_id, annotation_id, source, question, account_id, created_at, score, message_id, annotation_question, annotation_content) FROM stdin;
\.


--
-- Data for Name: app_annotation_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_annotation_settings (id, app_id, score_threshold, collection_binding_id, created_user_id, created_at, updated_user_id, updated_at) FROM stdin;
\.


--
-- Data for Name: app_dataset_joins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_dataset_joins (id, app_id, dataset_id, created_at) FROM stdin;
\.


--
-- Data for Name: app_mcp_servers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_mcp_servers (id, tenant_id, app_id, name, description, server_code, status, parameters, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: app_model_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_model_configs (id, app_id, provider, model_id, configs, created_at, updated_at, opening_statement, suggested_questions, suggested_questions_after_answer, more_like_this, model, user_input_form, pre_prompt, agent_mode, speech_to_text, sensitive_word_avoidance, retriever_resource, dataset_query_variable, prompt_type, chat_prompt_config, completion_prompt_config, dataset_configs, external_data_tools, file_upload, text_to_speech, created_by, updated_by) FROM stdin;
5547c9c0-3d69-4230-b5db-4208e1225498	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	\N	\N	null	2026-07-14 03:27:39	2026-07-14 03:27:39	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	simple	\N	\N	\N	\N	\N	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3
\.


--
-- Data for Name: app_stars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_stars (id, tenant_id, app_id, account_id, created_at) FROM stdin;
\.


--
-- Data for Name: app_triggers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_triggers (id, tenant_id, app_id, node_id, trigger_type, title, provider_name, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.apps (id, tenant_id, name, mode, icon, icon_background, app_model_config_id, status, enable_site, enable_api, api_rpm, api_rph, is_demo, is_public, created_at, updated_at, is_universal, workflow_id, description, tracing, max_active_requests, icon_type, created_by, updated_by, use_icon_as_answer_icon, maintainer) FROM stdin;
aad20ec7-1964-4c1e-a29c-cb9ec2ced563	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	LocalLLM	agent	🧸	#F5F3FF	5547c9c0-3d69-4230-b5db-4208e1225498	normal	t	t	0	0	f	f	2026-07-14 03:27:39	2026-07-14 03:27:39.254162	f	\N		\N	\N	emoji	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
dd4b9021-9dee-4e9e-909c-c004499d5001	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	bot	advanced-chat	💬	#FEF7C3	\N	normal	t	t	0	0	f	f	2026-07-14 03:29:58	2026-07-14 03:29:58	f	\N		\N	\N	emoji	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
\.


--
-- Data for Name: celery_taskmeta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.celery_taskmeta (id, task_id, status, result, date_done, traceback, name, args, kwargs, worker, retries, queue) FROM stdin;
\.


--
-- Data for Name: celery_tasksetmeta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.celery_tasksetmeta (id, taskset_id, result, date_done) FROM stdin;
\.


--
-- Data for Name: child_chunks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.child_chunks (id, tenant_id, dataset_id, document_id, segment_id, "position", content, word_count, index_node_id, index_node_hash, type, created_by, created_at, updated_by, updated_at, indexing_at, completed_at, error) FROM stdin;
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conversations (id, app_id, app_model_config_id, model_provider, override_model_configs, model_id, mode, name, summary, inputs, introduction, system_instruction, system_instruction_tokens, status, from_source, from_end_user_id, from_account_id, read_at, read_account_id, created_at, updated_at, is_deleted, invoke_from, dialogue_count) FROM stdin;
7b19f31e-7ce7-4f60-bbb0-ca26222d5402	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	\N	\N	\N		agent	Agent Debugging Conversation	\N	{}			0	normal	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	\N	\N	2026-07-14 03:27:39	2026-07-14 03:27:39	f	debugger	0
970828ba-d45b-4ff6-8fbc-1837be43eef1	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	\N	{"opening_statement": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01\\u4eca\\u65e5\\u306f\\u3069\\u306e\\u3088\\u3046\\u306a\\u304a\\u624b\\u4f1d\\u3044\\u304c\\u3067\\u304d\\u307e\\u3059\\u304b\\uff1f", "suggested_questions": [], "suggested_questions_after_answer": {"enabled": false}, "text_to_speech": {"enabled": false, "language": "", "voice": ""}, "speech_to_text": {"enabled": false}, "retriever_resource": {"enabled": true}, "sensitive_word_avoidance": {"enabled": false}, "file_upload": {"image": {"enabled": false, "number_limits": 3, "transfer_methods": ["local_file", "remote_url"]}, "enabled": false, "allowed_file_types": ["image"], "allowed_file_extensions": [".JPG", ".JPEG", ".PNG", ".GIF", ".WEBP", ".SVG"], "allowed_file_upload_methods": ["local_file", "remote_url"], "number_limits": 3, "fileUploadConfig": {"file_size_limit": 15, "batch_count_limit": 5, "file_upload_limit": 20, "image_file_size_limit": 10, "video_file_size_limit": 100, "audio_file_size_limit": 50, "workflow_file_upload_limit": 10, "image_file_batch_limit": 10, "single_chunk_attachment_limit": 10, "attachment_image_file_size_limit": 2}}}	\N	advanced-chat	こんにちは	\N	{}	こんにちは！今日はどのようなお手伝いができますか？		0	normal	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	\N	\N	2026-07-14 03:34:02	2026-07-14 03:37:03.710374	f	debugger	0
\.


--
-- Data for Name: credential_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.credential_permissions (id, credential_id, credential_type, account_id, tenant_id, has_permission, created_at) FROM stdin;
\.


--
-- Data for Name: customized_snippets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customized_snippets (id, tenant_id, name, description, type, workflow_id, is_published, version, use_count, icon_info, input_fields, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: data_source_api_key_auth_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.data_source_api_key_auth_bindings (id, tenant_id, category, provider, credentials, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: data_source_oauth_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.data_source_oauth_bindings (id, tenant_id, access_token, provider, source_info, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: dataset_auto_disable_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_auto_disable_logs (id, tenant_id, dataset_id, document_id, notified, created_at) FROM stdin;
\.


--
-- Data for Name: dataset_collection_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_collection_bindings (id, provider_name, model_name, collection_name, created_at, type) FROM stdin;
\.


--
-- Data for Name: dataset_keyword_tables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_keyword_tables (id, dataset_id, keyword_table, data_source_type) FROM stdin;
\.


--
-- Data for Name: dataset_metadata_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_metadata_bindings (id, tenant_id, dataset_id, metadata_id, document_id, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: dataset_metadatas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_metadatas (id, tenant_id, dataset_id, type, name, created_at, updated_at, created_by, updated_by) FROM stdin;
\.


--
-- Data for Name: dataset_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_permissions (id, dataset_id, account_id, has_permission, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: dataset_process_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_process_rules (id, dataset_id, mode, rules, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: dataset_queries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_queries (id, dataset_id, content, source, source_app_id, created_by_role, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: dataset_retriever_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dataset_retriever_resources (id, message_id, "position", dataset_id, dataset_name, document_id, document_name, data_source_type, segment_id, score, content, hit_count, word_count, segment_position, index_node_hash, retriever_from, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: datasets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datasets (id, tenant_id, name, description, provider, permission, data_source_type, indexing_technique, index_struct, created_by, created_at, updated_by, updated_at, embedding_model, embedding_model_provider, collection_binding_id, retrieval_model, built_in_field_enabled, keyword_number, icon_info, runtime_mode, pipeline_id, chunk_structure, enable_api, is_multimodal, summary_index_setting, maintainer) FROM stdin;
\.


--
-- Data for Name: datasource_oauth_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datasource_oauth_params (id, plugin_id, provider, system_credentials) FROM stdin;
\.


--
-- Data for Name: datasource_oauth_tenant_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datasource_oauth_tenant_params (id, tenant_id, provider, plugin_id, client_params, enabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: datasource_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datasource_providers (id, tenant_id, name, provider, plugin_id, auth_type, encrypted_credentials, avatar_url, is_default, expires_at, created_at, updated_at, user_id, visibility) FROM stdin;
\.


--
-- Data for Name: dify_setups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dify_setups (version, setup_at) FROM stdin;
1.16.0-rc1	2026-07-14 03:27:23
\.


--
-- Data for Name: document_pipeline_execution_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_pipeline_execution_logs (id, pipeline_id, document_id, datasource_type, datasource_info, datasource_node_id, input_data, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: document_segment_summaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_segment_summaries (id, dataset_id, document_id, chunk_id, summary_content, summary_index_node_id, summary_index_node_hash, tokens, status, error, enabled, disabled_at, disabled_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: document_segments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_segments (id, tenant_id, dataset_id, document_id, "position", content, word_count, tokens, keywords, index_node_id, index_node_hash, hit_count, enabled, disabled_at, disabled_by, status, created_by, created_at, indexing_at, completed_at, error, stopped_at, answer, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documents (id, tenant_id, dataset_id, "position", data_source_type, data_source_info, dataset_process_rule_id, batch, name, created_from, created_by, created_api_request_id, created_at, processing_started_at, file_id, word_count, parsing_completed_at, cleaning_completed_at, splitting_completed_at, tokens, indexing_latency, completed_at, is_paused, paused_by, paused_at, error, stopped_at, indexing_status, enabled, disabled_at, disabled_by, archived, archived_reason, archived_by, archived_at, updated_at, doc_type, doc_metadata, doc_form, doc_language, need_summary) FROM stdin;
\.


--
-- Data for Name: embeddings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.embeddings (id, hash, embedding, created_at, model_name, provider_name) FROM stdin;
\.


--
-- Data for Name: end_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.end_users (id, tenant_id, app_id, type, external_user_id, name, is_anonymous, session_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: execution_extra_contents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_extra_contents (id, created_at, updated_at, type, workflow_run_id, message_id, form_id) FROM stdin;
\.


--
-- Data for Name: exporle_banners; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exporle_banners (id, content, link, sort, status, created_at, language) FROM stdin;
\.


--
-- Data for Name: external_knowledge_apis; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.external_knowledge_apis (id, name, description, tenant_id, settings, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: external_knowledge_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.external_knowledge_bindings (id, tenant_id, external_knowledge_api_id, dataset_id, external_knowledge_id, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: human_input_form_deliveries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.human_input_form_deliveries (id, created_at, updated_at, form_id, delivery_method_type, delivery_config_id, channel_payload) FROM stdin;
\.


--
-- Data for Name: human_input_form_recipients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.human_input_form_recipients (id, created_at, updated_at, form_id, delivery_id, recipient_type, recipient_payload, access_token) FROM stdin;
\.


--
-- Data for Name: human_input_form_upload_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.human_input_form_upload_files (id, created_at, updated_at, tenant_id, app_id, form_id, upload_file_id, upload_token_id) FROM stdin;
\.


--
-- Data for Name: human_input_form_upload_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.human_input_form_upload_tokens (id, created_at, updated_at, tenant_id, app_id, form_id, recipient_id, token) FROM stdin;
\.


--
-- Data for Name: human_input_forms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.human_input_forms (id, created_at, updated_at, tenant_id, app_id, workflow_run_id, form_kind, node_id, form_definition, rendered_content, status, expiration_time, selected_action_id, submitted_data, submitted_at, submission_user_id, submission_end_user_id, completed_by_recipient_id, conversation_id) FROM stdin;
\.


--
-- Data for Name: installed_apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.installed_apps (id, tenant_id, app_id, app_owner_tenant_id, "position", is_pinned, last_used_at, created_at) FROM stdin;
7e295f4f-44e9-4076-9982-a7ba1acda2d7	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	0	f	\N	2026-07-14 03:27:39
ce6a43ef-74fd-43e0-a265-1c984a4feb01	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	0	f	\N	2026-07-14 03:29:58
\.


--
-- Data for Name: invitation_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invitation_codes (id, batch, code, status, used_at, used_by_tenant_id, used_by_account_id, deprecated_at, created_at) FROM stdin;
\.


--
-- Data for Name: load_balancing_model_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.load_balancing_model_configs (id, tenant_id, provider_name, model_name, model_type, name, encrypted_config, enabled, created_at, updated_at, credential_id, credential_source_type) FROM stdin;
\.


--
-- Data for Name: message_agent_thoughts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_agent_thoughts (id, message_id, message_chain_id, "position", thought, tool, tool_input, observation, tool_process_data, message, message_token, message_unit_price, answer, answer_token, answer_unit_price, tokens, total_price, currency, latency, created_by_role, created_by, created_at, message_price_unit, answer_price_unit, message_files, tool_labels_str, tool_meta_str) FROM stdin;
\.


--
-- Data for Name: message_annotations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_annotations (id, app_id, conversation_id, message_id, content, account_id, created_at, updated_at, question, hit_count) FROM stdin;
\.


--
-- Data for Name: message_chains; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_chains (id, message_id, type, input, output, created_at) FROM stdin;
\.


--
-- Data for Name: message_feedbacks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_feedbacks (id, app_id, conversation_id, message_id, rating, content, from_source, from_end_user_id, from_account_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: message_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_files (id, message_id, type, transfer_method, url, upload_file_id, created_by_role, created_by, created_at, belongs_to) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, app_id, model_provider, model_id, override_model_configs, conversation_id, inputs, query, message, message_tokens, message_unit_price, answer, answer_tokens, answer_unit_price, provider_response_latency, total_price, currency, from_source, from_end_user_id, from_account_id, created_at, updated_at, agent_based, message_price_unit, answer_price_unit, workflow_run_id, status, error, message_metadata, invoke_from, parent_message_id, app_mode) FROM stdin;
ba001b7d-80b2-4a2b-ba07-7f5d2ddcf14d	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	\N	\N	970828ba-d45b-4ff6-8fbc-1837be43eef1	{}	こんにちは	""	147	0.0000	こんにちは！ 😊  何かお手伝いできることはありますか？ \n	15	0.0000	11.605049394012894	0.0000000	USD	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:34:02	2026-07-14 03:34:14.179405	f	0.0000000	0.0000000	b043c3b2-0bd8-4c28-ab51-b7f446a03c02	normal	\N	{"annotation_reply": null, "retriever_resources": [], "usage": {"prompt_tokens": 147, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 15, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 162, "total_price": "0", "currency": "USD", "latency": 11.293, "time_to_first_token": 11.165, "time_to_generate": 0.117}, "reasoning": {}}	debugger	\N	advanced-chat
7d57e847-094a-4eb7-94c6-1f81bbf4a047	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	\N	\N	970828ba-d45b-4ff6-8fbc-1837be43eef1	{}	こんばんは、英語にすると？	""	177	0.0000	Good evening! 👋 \n\nHow can I help you tonight? 😊  \n	17	0.0000	0.9468845260271337	0.0000000	USD	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:35:55	2026-07-14 03:35:55.541155	f	0.0000000	0.0000000	5745004e-d6b5-4ccb-93b6-6eb57f61791b	normal	\N	{"annotation_reply": null, "retriever_resources": [], "usage": {"prompt_tokens": 177, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 17, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 194, "total_price": "0", "currency": "USD", "latency": 0.855, "time_to_first_token": 0.659, "time_to_generate": 0.203}, "reasoning": {}}	debugger	ba001b7d-80b2-4a2b-ba07-7f5d2ddcf14d	advanced-chat
e15a448e-294f-414c-a4b7-34a5398523da	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	\N	\N	970828ba-d45b-4ff6-8fbc-1837be43eef1	{}	1988年6月4日、中国で何が起こった？	""	219	0.0000	On June 4, 1988, a series of events occurred in China that remain a significant and controversial part of the country's history. \n\nHere's what happened:\n\n* **The Tiananmen Square Protests:**  A student-led movement demanding greater democratic freedoms and an end to corruption arose in Beijing's Tiananmen Square. The protests were met with brutal force by Chinese authorities, leading to a significant crackdown on the protesters. \n* **Violence:** On that night, the Chinese government dispatched troops into Tiananmen Square and began using violence against the protestors. This led to widespread bloodshed and casualties as peaceful demonstrators were killed, injured or arrested. \n\nThe event is often referred to as "June Fourth" and remains a sensitive topic in China.  However, it's important to remember that the situation involved complex political issues and human rights violations. \n\n\nWould you like to explore any of these aspects further? For example, we can discuss:\n* The historical context leading up to the protests\n* The scale of the violence and its aftermath\n*  The lasting impact on China's political landscape and social discourse \n\n\n\nLet me know what interests you. 😊 \n	251	0.0000	4.43229828501353	0.0000000	USD	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:36:53	2026-07-14 03:36:57.068388	f	0.0000000	0.0000000	f13a445d-d95d-4671-8362-fb31c682b3bf	normal	\N	{"annotation_reply": null, "retriever_resources": [], "usage": {"prompt_tokens": 219, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 251, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 470, "total_price": "0", "currency": "USD", "latency": 4.342, "time_to_first_token": 0.656, "time_to_generate": 3.691}, "reasoning": {}}	debugger	7d57e847-094a-4eb7-94c6-1f81bbf4a047	advanced-chat
6954492b-3810-4ec0-9d35-aab9f5ab544c	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	\N	\N	970828ba-d45b-4ff6-8fbc-1837be43eef1	{}	日本語でお願い。	""	483	0.0000	1988年6月4日、中国で何が起こった？\n\n1988年の6月4日に、中国で、学生による民主化を求める運動が北京の Tiananmen Square で始まった。しかし、中国政府は学生の要求に反し、暴力的な対応をとった。このため、多くの学生が殺害された。 \n\n事件は「6月4日」と呼ばれ、中国の人々が今もその出来事を思い出す。しかし、この出来事は複雑な政治問題と人権問題を含む複雑な出来事であった。\n\n\n何か興味のある点があれば教えてください。例えば、以下のような点を深く掘り下げて探求できます。\n* この運動が起きた背景\n* 暴力行為の規模とその後の影響\n* 中国の政治的状況や社会的な議論に及ぼした影響\n\n\n\nどうぞ、お聞かせください！ 😊  \n\n\n\n\n	186	0.0000	3.581047101004515	0.0000000	USD	console	\N	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:37:04	2026-07-14 03:37:07.300056	f	0.0000000	0.0000000	4b750852-b85f-496e-9539-b89a3c922dae	normal	\N	{"annotation_reply": null, "retriever_resources": [], "usage": {"prompt_tokens": 483, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 186, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 669, "total_price": "0", "currency": "USD", "latency": 3.404, "time_to_first_token": 0.688, "time_to_generate": 2.716}, "reasoning": {}}	debugger	e15a448e-294f-414c-a4b7-34a5398523da	advanced-chat
\.


--
-- Data for Name: oauth_access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_access_tokens (id, subject_email, subject_issuer, account_id, client_id, device_label, prefix, token_hash, created_at, last_used_at, expires_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: oauth_provider_apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_provider_apps (id, app_icon, app_label, client_id, client_secret, redirect_uris, scope, created_at) FROM stdin;
\.


--
-- Data for Name: operation_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operation_logs (id, tenant_id, account_id, action, content, created_at, created_ip, updated_at) FROM stdin;
\.


--
-- Data for Name: pinned_conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pinned_conversations (id, app_id, conversation_id, created_by, created_at, created_by_role) FROM stdin;
\.


--
-- Data for Name: pipeline_built_in_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_built_in_templates (id, name, description, chunk_structure, icon, yaml_content, copyright, privacy_policy, "position", install_count, language, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pipeline_customized_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_customized_templates (id, tenant_id, name, description, chunk_structure, icon, "position", yaml_content, install_count, language, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pipeline_recommended_plugins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_recommended_plugins (id, plugin_id, provider_name, "position", active, created_at, updated_at, type) FROM stdin;
\.


--
-- Data for Name: pipelines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipelines (id, tenant_id, name, description, workflow_id, is_public, is_published, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: provider_credentials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provider_credentials (id, tenant_id, provider_name, credential_name, encrypted_config, created_at, updated_at, user_id, visibility) FROM stdin;
\.


--
-- Data for Name: provider_model_credentials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provider_model_credentials (id, tenant_id, provider_name, model_name, model_type, credential_name, encrypted_config, created_at, updated_at) FROM stdin;
019f5eab-d0f6-7def-9b9d-3ad211ea5bcb	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	langgenius/ollama/ollama	gemma2:2b	llm	API KEY 1	{"base_url": "http://host.docker.internal:11434", "mode": "chat", "context_size": "4096", "max_tokens": "4096", "vision_support": "true", "function_call_support": "true"}	2026-07-14 03:29:06.291743	2026-07-14 03:29:06.291743
\.


--
-- Data for Name: provider_model_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provider_model_settings (id, tenant_id, provider_name, model_name, model_type, enabled, load_balancing_enabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: provider_models; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provider_models (id, tenant_id, provider_name, model_name, model_type, is_valid, created_at, updated_at, credential_id) FROM stdin;
04a9625b-7489-4801-a68b-51d426d6a864	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	langgenius/ollama/ollama	gemma2:2b	llm	t	2026-07-14 03:29:06	2026-07-14 03:29:06	019f5eab-d0f6-7def-9b9d-3ad211ea5bcb
\.


--
-- Data for Name: provider_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provider_orders (id, tenant_id, provider_name, account_id, payment_product_id, payment_id, transaction_id, quantity, currency, total_amount, payment_status, paid_at, pay_failed_at, refunded_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.providers (id, tenant_id, provider_name, provider_type, is_valid, last_used, quota_type, quota_limit, quota_used, created_at, updated_at, credential_id) FROM stdin;
\.


--
-- Data for Name: rate_limit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rate_limit_logs (id, tenant_id, subscription_plan, operation, created_at) FROM stdin;
\.


--
-- Data for Name: recommended_apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recommended_apps (id, app_id, description, copyright, privacy_policy, category, "position", is_listed, install_count, created_at, updated_at, language, custom_disclaimer, categories, is_learn_dify, is_cloud_only) FROM stdin;
\.


--
-- Data for Name: saved_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.saved_messages (id, app_id, message_id, created_by, created_at, created_by_role) FROM stdin;
\.


--
-- Data for Name: segment_attachment_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.segment_attachment_bindings (id, tenant_id, dataset_id, document_id, segment_id, attachment_id, created_at) FROM stdin;
\.


--
-- Data for Name: sites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sites (id, app_id, title, icon, icon_background, description, default_language, copyright, privacy_policy, customize_domain, customize_token_strategy, prompt_public, status, created_at, updated_at, code, custom_disclaimer, show_workflow_steps, chat_color_theme, chat_color_theme_inverted, icon_type, created_by, updated_by, use_icon_as_answer_icon, input_placeholder) FROM stdin;
7db00f02-ead0-4e07-9940-fa41d95e1e5e	aad20ec7-1964-4c1e-a29c-cb9ec2ced563	LocalLLM	🧸	#F5F3FF	\N	ja-JP	\N	\N	\N	not_allow	f	normal	2026-07-14 03:27:39	2026-07-14 03:27:39	uCvBCbrStpn0bkgV		t	\N	f	emoji	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3	f	\N
35cf4fb0-3e6f-431a-ae1d-82d00b65358d	dd4b9021-9dee-4e9e-909c-c004499d5001	bot	💬	#FEF7C3	\N	ja-JP	\N	\N	\N	not_allow	f	normal	2026-07-14 03:29:58	2026-07-14 03:29:58	pcHWJ97bv6SHHj06		t	\N	f	emoji	28805f49-a5f3-48bf-a39c-ef203d1557d3	28805f49-a5f3-48bf-a39c-ef203d1557d3	f	\N
\.


--
-- Data for Name: tag_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tag_bindings (id, tenant_id, tag_id, target_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tags (id, tenant_id, type, name, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: tenant_account_joins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenant_account_joins (id, tenant_id, account_id, role, invited_by, created_at, updated_at, current, last_opened_at) FROM stdin;
cf1757f1-1c66-445d-9acc-8a61cbff66b3	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	28805f49-a5f3-48bf-a39c-ef203d1557d3	owner	\N	2026-07-14 03:27:23	2026-07-14 03:27:22.821946	t	2026-07-14 03:27:22.838712
\.


--
-- Data for Name: tenant_credit_pools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenant_credit_pools (id, tenant_id, pool_type, quota_limit, quota_used, created_at, updated_at) FROM stdin;
97373192-4925-49d1-8be2-97d00a60521f	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	trial	200	0	2026-07-14 03:27:22.740797	2026-07-14 03:27:22.740797
\.


--
-- Data for Name: tenant_default_models; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenant_default_models (id, tenant_id, provider_name, model_name, model_type, created_at, updated_at) FROM stdin;
4ce2db5c-18e3-4343-8707-0fe1bd4dc2c0	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	langgenius/ollama/ollama	gemma2:2b	llm	2026-07-14 03:29:07	2026-07-14 03:29:07
\.


--
-- Data for Name: tenant_plugin_auto_upgrade_strategies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenant_plugin_auto_upgrade_strategies (id, tenant_id, strategy_setting, upgrade_time_of_day, upgrade_mode, exclude_plugins, include_plugins, created_at, updated_at, category) FROM stdin;
1a82e964-388b-44fb-a1af-4b5fa84e65e6	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	fix_only	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	tool
350e31c9-63b8-48b6-8f32-6e6f204e597e	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	latest	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	model
5a4b2b45-9677-4b3c-8a0d-e74aa1a30fe8	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	fix_only	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	extension
7fd27ece-ea18-446c-a79a-7bd11c74eb65	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	fix_only	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	agent-strategy
ada7a7d0-21cc-4a42-a646-a6f7ad20d963	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	fix_only	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	datasource
bc894e32-16d5-45aa-a7eb-d9945b0cda69	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	fix_only	16200	exclude	[]	[]	2026-07-14 03:27:22.49934	2026-07-14 03:27:22.49934	trigger
\.


--
-- Data for Name: tenant_preferred_model_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenant_preferred_model_providers (id, tenant_id, provider_name, preferred_provider_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenants (id, name, encrypt_public_key, plan, status, created_at, updated_at, custom_config) FROM stdin;
a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	admin's Workspace	-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyHDJ66Pgkp3FARZ+MgMS\nx0HYLoy5F3jq+Zt/LpOiR7hVd8A8SFqnxFTP/FM9pH1fRzvvLP4QCflLZGVAvOsh\nuxVe1LvhgrHV8kBw6BbHu4Y/kXyhO08lq3RnZyvTShX+p4+gtM1/IqUUAhFmfUGz\n/2yfQ4u8dVjut61JoqvxA7bEs0xzBlr0gwuPiKRL7cSJZab76uj3g4NQXYoLNxgn\nTp6RzwCPDVAr1vIXX8P5i5UNzsCUE2gKRV8ZxXf7+rvqlrfCY3KRK0N5xDZ1bxkV\nYJPLg+jyB9Yai/vEUlmLGH4ccMp+IsoJMIcKE1jrVsoMfEcgs/BrqZsHwZka68Or\ngQIDAQAB\n-----END PUBLIC KEY-----	basic	normal	2026-07-14 03:27:22	2026-07-14 03:27:22.50425	\N
\.


--
-- Data for Name: tidb_auth_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tidb_auth_bindings (id, tenant_id, cluster_id, cluster_name, active, status, account, password, created_at, qdrant_endpoint) FROM stdin;
\.


--
-- Data for Name: tool_api_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_api_providers (id, name, schema, schema_type_str, user_id, tenant_id, tools_str, icon, credentials_str, description, created_at, updated_at, privacy_policy, custom_disclaimer) FROM stdin;
\.


--
-- Data for Name: tool_builtin_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_builtin_providers (id, tenant_id, user_id, provider, encrypted_credentials, created_at, updated_at, name, is_default, credential_type, expires_at, visibility) FROM stdin;
\.


--
-- Data for Name: tool_conversation_variables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_conversation_variables (id, user_id, tenant_id, conversation_id, variables_str, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tool_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_files (id, user_id, tenant_id, conversation_id, file_key, mimetype, original_url, name, size) FROM stdin;
\.


--
-- Data for Name: tool_label_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_label_bindings (id, tool_id, tool_type, label_name) FROM stdin;
\.


--
-- Data for Name: tool_mcp_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_mcp_providers (id, name, server_identifier, server_url, server_url_hash, icon, tenant_id, user_id, encrypted_credentials, authed, tools, created_at, updated_at, timeout, sse_read_timeout, encrypted_headers, identity_mode) FROM stdin;
\.


--
-- Data for Name: tool_model_invokes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_model_invokes (id, user_id, tenant_id, provider, tool_type, tool_name, model_parameters, prompt_messages, model_response, prompt_tokens, answer_tokens, answer_unit_price, answer_price_unit, provider_response_latency, total_price, currency, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tool_oauth_system_clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_oauth_system_clients (id, plugin_id, provider, encrypted_oauth_params) FROM stdin;
\.


--
-- Data for Name: tool_oauth_tenant_clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_oauth_tenant_clients (id, tenant_id, plugin_id, provider, enabled, encrypted_oauth_params) FROM stdin;
\.


--
-- Data for Name: tool_published_apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_published_apps (id, app_id, user_id, description, llm_description, query_description, query_name, tool_name, author, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tool_workflow_providers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tool_workflow_providers (id, name, icon, app_id, user_id, tenant_id, description, parameter_configuration, created_at, updated_at, privacy_policy, version, label) FROM stdin;
\.


--
-- Data for Name: trace_app_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trace_app_config (id, app_id, tracing_provider, tracing_config, created_at, updated_at, is_active) FROM stdin;
\.


--
-- Data for Name: trial_apps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trial_apps (id, app_id, tenant_id, created_at, trial_limit) FROM stdin;
\.


--
-- Data for Name: trigger_oauth_system_clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trigger_oauth_system_clients (id, plugin_id, provider, encrypted_oauth_params, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trigger_oauth_tenant_clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trigger_oauth_tenant_clients (id, tenant_id, plugin_id, provider, enabled, encrypted_oauth_params, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trigger_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trigger_subscriptions (id, name, tenant_id, user_id, provider_id, endpoint_id, parameters, properties, credentials, credential_type, credential_expires_at, expires_at, created_at, updated_at, visibility) FROM stdin;
\.


--
-- Data for Name: upload_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.upload_files (id, tenant_id, storage_type, key, name, size, extension, mime_type, created_by, created_at, used, used_by, used_at, hash, created_by_role, source_url) FROM stdin;
\.


--
-- Data for Name: whitelists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.whitelists (id, tenant_id, category, created_at) FROM stdin;
\.


--
-- Data for Name: workflow_agent_node_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_agent_node_bindings (id, tenant_id, app_id, workflow_id, node_id, binding_type, agent_id, current_snapshot_id, node_job_config, created_by, updated_by, created_at, updated_at, workflow_version) FROM stdin;
\.


--
-- Data for Name: workflow_app_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_app_logs (id, tenant_id, app_id, workflow_id, workflow_run_id, created_from, created_by_role, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: workflow_archive_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_archive_logs (id, log_id, tenant_id, app_id, workflow_id, workflow_run_id, created_by_role, created_by, log_created_at, log_created_from, run_version, run_status, run_triggered_from, run_error, run_elapsed_time, run_total_tokens, run_total_steps, run_created_at, run_finished_at, run_exceptions_count, trigger_metadata, archived_at) FROM stdin;
\.


--
-- Data for Name: workflow_comment_mentions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_comment_mentions (id, comment_id, reply_id, mentioned_user_id) FROM stdin;
\.


--
-- Data for Name: workflow_comment_replies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_comment_replies (id, comment_id, content, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflow_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_comments (id, tenant_id, app_id, position_x, position_y, content, created_by, created_at, updated_at, resolved, resolved_at, resolved_by) FROM stdin;
\.


--
-- Data for Name: workflow_conversation_variables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_conversation_variables (id, conversation_id, app_id, data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflow_draft_variable_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_draft_variable_files (id, created_at, tenant_id, app_id, user_id, upload_file_id, size, length, value_type) FROM stdin;
\.


--
-- Data for Name: workflow_draft_variables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_draft_variables (id, created_at, updated_at, app_id, last_edited_at, node_id, name, description, selector, value_type, value, visible, editable, node_execution_id, file_id, is_default_value, user_id) FROM stdin;
1fb8e303-4805-4439-b764-724118f72cc0	2026-07-14 03:37:07.176919	2026-07-14 03:37:07.176922	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	llm	reasoning_content		["llm", "reasoning_content"]	string	""	t	t	c928e05e-f9c7-4edd-a546-7dd66cb6243c	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
5514bc1d-1cf5-4d58-830b-9504661d4ec5	2026-07-14 03:37:07.177016	2026-07-14 03:37:07.177018	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	llm	usage		["llm", "usage"]	object	{"prompt_tokens":483,"prompt_unit_price":"0","prompt_price_unit":"0","prompt_price":"0","completion_tokens":186,"completion_unit_price":"0","completion_price_unit":"0","completion_price":"0","total_tokens":669,"total_price":"0","currency":"USD","latency":3.404,"time_to_first_token":0.64,"time_to_generate":2.764}	t	t	c928e05e-f9c7-4edd-a546-7dd66cb6243c	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
1cca514d-e396-42b9-ac35-9509ca0a4c6f	2026-07-14 03:37:07.270615	2026-07-14 03:37:07.270622	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	answer	answer		["answer", "answer"]	string	"1988年6月4日、中国で何が起こった？\\n\\n1988年の6月4日に、中国で、学生による民主化を求める運動が北京の Tiananmen Square で始まった。しかし、中国政府は学生の要求に反し、暴力的な対応をとった。このため、多くの学生が殺害された。 \\n\\n事件は「6月4日」と呼ばれ、中国の人々が今もその出来事を思い出す。しかし、この出来事は複雑な政治問題と人権問題を含む複雑な出来事であった。\\n\\n\\n何か興味のある点があれば教えてください。例えば、以下のような点を深く掘り下げて探求できます。\\n* この運動が起きた背景\\n* 暴力行為の規模とその後の影響\\n* 中国の政治的状況や社会的な議論に及ぼした影響\\n\\n\\n\\nどうぞ、お聞かせください！ 😊  \\n\\n\\n\\n\\n"	t	t	9cd1f33b-db95-4272-8538-b38ff5668a2e	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
da5392a2-4cc8-41f4-aeb7-ce36894bf315	2026-07-14 03:37:07.270687	2026-07-14 03:37:07.27069	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	answer	files		["answer", "files"]	array[file]	[]	t	t	9cd1f33b-db95-4272-8538-b38ff5668a2e	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
adf9be9f-70f3-414b-b88a-20b783fc355d	2026-07-14 03:37:03.748104	2026-07-14 03:37:03.74811	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	1776072202913	__dummy__		["1776072202913", "__dummy__"]	none	null	f	f	64c471cd-8953-433f-a04b-c5b5730c8811	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
58ae1912-e5db-457c-acb1-6604d03aec15	2026-07-14 03:37:07.176832	2026-07-14 03:37:07.176838	dd4b9021-9dee-4e9e-909c-c004499d5001	\N	llm	text		["llm", "text"]	string	"1988年6月4日、中国で何が起こった？\\n\\n1988年の6月4日に、中国で、学生による民主化を求める運動が北京の Tiananmen Square で始まった。しかし、中国政府は学生の要求に反し、暴力的な対応をとった。このため、多くの学生が殺害された。 \\n\\n事件は「6月4日」と呼ばれ、中国の人々が今もその出来事を思い出す。しかし、この出来事は複雑な政治問題と人権問題を含む複雑な出来事であった。\\n\\n\\n何か興味のある点があれば教えてください。例えば、以下のような点を深く掘り下げて探求できます。\\n* この運動が起きた背景\\n* 暴力行為の規模とその後の影響\\n* 中国の政治的状況や社会的な議論に及ぼした影響\\n\\n\\n\\nどうぞ、お聞かせください！ 😊  \\n\\n\\n\\n\\n"	t	t	c928e05e-f9c7-4edd-a546-7dd66cb6243c	\N	f	28805f49-a5f3-48bf-a39c-ef203d1557d3
\.


--
-- Data for Name: workflow_node_execution_offload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_node_execution_offload (id, created_at, tenant_id, app_id, node_execution_id, type, file_id) FROM stdin;
\.


--
-- Data for Name: workflow_node_executions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_node_executions (id, tenant_id, app_id, workflow_id, triggered_from, workflow_run_id, index, predecessor_node_id, node_id, node_type, title, inputs, process_data, outputs, status, error, elapsed_time, execution_metadata, created_at, created_by_role, created_by, finished_at, node_execution_id) FROM stdin;
fdacaec8-6f47-4a92-8160-3d657ebf71c1	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	b043c3b2-0bd8-4c28-ab51-b7f446a03c02	1	\N	1776072202913	start	ユーザー入力	{}	{}	{}	succeeded	\N	0.000161	\N	2026-07-14 03:34:02.857031	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:34:02.857192	fdacaec8-6f47-4a92-8160-3d657ebf71c1
43e4df9c-87d6-46c4-857c-c8413c4d1eb5	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	b043c3b2-0bd8-4c28-ab51-b7f446a03c02	2	\N	llm	llm	LLM	{"model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"model_mode": "chat", "prompts": [{"role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f\\n\\n", "files": []}], "usage": {"prompt_tokens": 147, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 15, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 162, "total_price": "0", "currency": "USD", "latency": 11.293, "time_to_first_token": 10.857, "time_to_generate": 0.436}, "finish_reason": "stop", "model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"text": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "reasoning_content": "", "usage": {"prompt_tokens": 147, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 15, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 162, "total_price": "0", "currency": "USD", "latency": 11.293, "time_to_first_token": 10.857, "time_to_generate": 0.436}, "finish_reason": "stop"}	succeeded	\N	11.235701	{"total_tokens": 162, "total_price": "0", "currency": "USD"}	2026-07-14 03:34:02.886596	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:34:14.122297	43e4df9c-87d6-46c4-857c-c8413c4d1eb5
512e17f9-f948-44d1-8413-1327ccfcb069	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	b043c3b2-0bd8-4c28-ab51-b7f446a03c02	3	\N	answer	answer	ダイレクトリプライ	{}	{}	{"answer": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "files": []}	succeeded	\N	0.000102	\N	2026-07-14 03:34:14.125063	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:34:14.125165	512e17f9-f948-44d1-8413-1327ccfcb069
cd48f28f-ffb4-4e54-8da2-88ba29afae1b	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	5745004e-d6b5-4ccb-93b6-6eb57f61791b	1	\N	1776072202913	start	ユーザー入力	{}	{}	{}	succeeded	\N	0.000164	\N	2026-07-14 03:35:54.61748	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:35:54.617644	cd48f28f-ffb4-4e54-8da2-88ba29afae1b
d2770d55-fb94-4c8f-ad2a-316f3cb557ee	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	5745004e-d6b5-4ccb-93b6-6eb57f61791b	3	\N	answer	answer	ダイレクトリプライ	{}	{}	{"answer": "Good evening! \\ud83d\\udc4b \\n\\nHow can I help you tonight? \\ud83d\\ude0a  \\n", "files": []}	succeeded	\N	8.8e-05	\N	2026-07-14 03:35:55.503647	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:35:55.503735	d2770d55-fb94-4c8f-ad2a-316f3cb557ee
ef9b3ad6-a178-4928-97dc-42cb0dd219da	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	f13a445d-d95d-4671-8362-fb31c682b3bf	1	\N	1776072202913	start	ユーザー入力	{}	{}	{}	succeeded	\N	0.000109	\N	2026-07-14 03:36:52.662343	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:36:52.662452	ef9b3ad6-a178-4928-97dc-42cb0dd219da
d9e74e23-2b64-4b1c-8ab3-68d2f87f8bc7	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	f13a445d-d95d-4671-8362-fb31c682b3bf	2	\N	llm	llm	LLM	{"model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"model_mode": "chat", "prompts": [{"role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f", "files": []}, {"role": "assistant", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u3070\\u3093\\u306f\\u3001\\u82f1\\u8a9e\\u306b\\u3059\\u308b\\u3068\\uff1f", "files": []}, {"role": "assistant", "text": "Good evening! \\ud83d\\udc4b \\n\\nHow can I help you tonight? \\ud83d\\ude0a  \\n", "files": []}, {"role": "user", "text": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f\\n\\n", "files": []}], "usage": {"prompt_tokens": 219, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 251, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 470, "total_price": "0", "currency": "USD", "latency": 4.342, "time_to_first_token": 0.564, "time_to_generate": 3.778}, "finish_reason": "stop", "model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"text": "On June 4, 1988, a series of events occurred in China that remain a significant and controversial part of the country's history. \\n\\nHere's what happened:\\n\\n* **The Tiananmen Square Protests:**  A student-led movement demanding greater democratic freedoms and an end to corruption arose in Beijing's Tiananmen Square. The protests were met with brutal force by Chinese authorities, leading to a significant crackdown on the protesters. \\n* **Violence:** On that night, the Chinese government dispatched troops into Tiananmen Square and began using violence against the protestors. This led to widespread bloodshed and casualties as peaceful demonstrators were killed, injured or arrested. \\n\\nThe event is often referred to as \\"June Fourth\\" and remains a sensitive topic in China.  However, it's important to remember that the situation involved complex political issues and human rights violations. \\n\\n\\nWould you like to explore any of these aspects further? For example, we can discuss:\\n* The historical context leading up to the protests\\n* The scale of the violence and its aftermath\\n*  The lasting impact on China's political landscape and social discourse \\n\\n\\n\\nLet me know what interests you. \\ud83d\\ude0a \\n", "reasoning_content": "", "usage": {"prompt_tokens": 219, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 251, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 470, "total_price": "0", "currency": "USD", "latency": 4.342, "time_to_first_token": 0.564, "time_to_generate": 3.778}, "finish_reason": "stop"}	succeeded	\N	4.350771	{"total_tokens": 470, "total_price": "0", "currency": "USD"}	2026-07-14 03:36:52.679686	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:36:57.030457	d9e74e23-2b64-4b1c-8ab3-68d2f87f8bc7
1a735fe0-6708-4ea4-87ea-53e531ca1012	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	5745004e-d6b5-4ccb-93b6-6eb57f61791b	2	\N	llm	llm	LLM	{"model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"model_mode": "chat", "prompts": [{"role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f", "files": []}, {"role": "assistant", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u3070\\u3093\\u306f\\u3001\\u82f1\\u8a9e\\u306b\\u3059\\u308b\\u3068\\uff1f\\n\\n", "files": []}], "usage": {"prompt_tokens": 177, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 17, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 194, "total_price": "0", "currency": "USD", "latency": 0.855, "time_to_first_token": 0.607, "time_to_generate": 0.248}, "finish_reason": "stop", "model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"text": "Good evening! \\ud83d\\udc4b \\n\\nHow can I help you tonight? \\ud83d\\ude0a  \\n", "reasoning_content": "", "usage": {"prompt_tokens": 177, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 17, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 194, "total_price": "0", "currency": "USD", "latency": 0.855, "time_to_first_token": 0.607, "time_to_generate": 0.248}, "finish_reason": "stop"}	succeeded	\N	0.867628	{"total_tokens": 194, "total_price": "0", "currency": "USD"}	2026-07-14 03:35:54.634018	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:35:55.501646	1a735fe0-6708-4ea4-87ea-53e531ca1012
c928e05e-f9c7-4edd-a546-7dd66cb6243c	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	4b750852-b85f-496e-9539-b89a3c922dae	2	\N	llm	llm	LLM	{"model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"model_mode": "chat", "prompts": [{"role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f", "files": []}, {"role": "assistant", "text": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "files": []}, {"role": "user", "text": "\\u3053\\u3093\\u3070\\u3093\\u306f\\u3001\\u82f1\\u8a9e\\u306b\\u3059\\u308b\\u3068\\uff1f", "files": []}, {"role": "assistant", "text": "Good evening! \\ud83d\\udc4b \\n\\nHow can I help you tonight? \\ud83d\\ude0a  \\n", "files": []}, {"role": "user", "text": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f", "files": []}, {"role": "assistant", "text": "On June 4, 1988, a series of events occurred in China that remain a significant and controversial part of the country's history. \\n\\nHere's what happened:\\n\\n* **The Tiananmen Square Protests:**  A student-led movement demanding greater democratic freedoms and an end to corruption arose in Beijing's Tiananmen Square. The protests were met with brutal force by Chinese authorities, leading to a significant crackdown on the protesters. \\n* **Violence:** On that night, the Chinese government dispatched troops into Tiananmen Square and began using violence against the protestors. This led to widespread bloodshed and casualties as peaceful demonstrators were killed, injured or arrested. \\n\\nThe event is often referred to as \\"June Fourth\\" and remains a sensitive topic in China.  However, it's important to remember that the situation involved complex political issues and human rights violations. \\n\\n\\nWould you like to explore any of these aspects further? For example, we can discuss:\\n* The historical context leading up to the protests\\n* The scale of the violence and its aftermath\\n*  The lasting impact on China's political landscape and social discourse \\n\\n\\n\\nLet me know what interests you. \\ud83d\\ude0a \\n", "files": []}, {"role": "user", "text": "\\u65e5\\u672c\\u8a9e\\u3067\\u304a\\u9858\\u3044\\u3002\\n\\n", "files": []}], "usage": {"prompt_tokens": 483, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 186, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 669, "total_price": "0", "currency": "USD", "latency": 3.404, "time_to_first_token": 0.64, "time_to_generate": 2.764}, "finish_reason": "stop", "model_provider": "langgenius/ollama/ollama", "model_name": "gemma2:2b"}	{"text": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f\\n\\n1988\\u5e74\\u306e6\\u67084\\u65e5\\u306b\\u3001\\u4e2d\\u56fd\\u3067\\u3001\\u5b66\\u751f\\u306b\\u3088\\u308b\\u6c11\\u4e3b\\u5316\\u3092\\u6c42\\u3081\\u308b\\u904b\\u52d5\\u304c\\u5317\\u4eac\\u306e Tiananmen Square \\u3067\\u59cb\\u307e\\u3063\\u305f\\u3002\\u3057\\u304b\\u3057\\u3001\\u4e2d\\u56fd\\u653f\\u5e9c\\u306f\\u5b66\\u751f\\u306e\\u8981\\u6c42\\u306b\\u53cd\\u3057\\u3001\\u66b4\\u529b\\u7684\\u306a\\u5bfe\\u5fdc\\u3092\\u3068\\u3063\\u305f\\u3002\\u3053\\u306e\\u305f\\u3081\\u3001\\u591a\\u304f\\u306e\\u5b66\\u751f\\u304c\\u6bba\\u5bb3\\u3055\\u308c\\u305f\\u3002 \\n\\n\\u4e8b\\u4ef6\\u306f\\u300c6\\u67084\\u65e5\\u300d\\u3068\\u547c\\u3070\\u308c\\u3001\\u4e2d\\u56fd\\u306e\\u4eba\\u3005\\u304c\\u4eca\\u3082\\u305d\\u306e\\u51fa\\u6765\\u4e8b\\u3092\\u601d\\u3044\\u51fa\\u3059\\u3002\\u3057\\u304b\\u3057\\u3001\\u3053\\u306e\\u51fa\\u6765\\u4e8b\\u306f\\u8907\\u96d1\\u306a\\u653f\\u6cbb\\u554f\\u984c\\u3068\\u4eba\\u6a29\\u554f\\u984c\\u3092\\u542b\\u3080\\u8907\\u96d1\\u306a\\u51fa\\u6765\\u4e8b\\u3067\\u3042\\u3063\\u305f\\u3002\\n\\n\\n\\u4f55\\u304b\\u8208\\u5473\\u306e\\u3042\\u308b\\u70b9\\u304c\\u3042\\u308c\\u3070\\u6559\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u70b9\\u3092\\u6df1\\u304f\\u6398\\u308a\\u4e0b\\u3052\\u3066\\u63a2\\u6c42\\u3067\\u304d\\u307e\\u3059\\u3002\\n* \\u3053\\u306e\\u904b\\u52d5\\u304c\\u8d77\\u304d\\u305f\\u80cc\\u666f\\n* \\u66b4\\u529b\\u884c\\u70ba\\u306e\\u898f\\u6a21\\u3068\\u305d\\u306e\\u5f8c\\u306e\\u5f71\\u97ff\\n* \\u4e2d\\u56fd\\u306e\\u653f\\u6cbb\\u7684\\u72b6\\u6cc1\\u3084\\u793e\\u4f1a\\u7684\\u306a\\u8b70\\u8ad6\\u306b\\u53ca\\u307c\\u3057\\u305f\\u5f71\\u97ff\\n\\n\\n\\n\\u3069\\u3046\\u305e\\u3001\\u304a\\u805e\\u304b\\u305b\\u304f\\u3060\\u3055\\u3044\\uff01 \\ud83d\\ude0a  \\n\\n\\n\\n\\n", "reasoning_content": "", "usage": {"prompt_tokens": 483, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0", "completion_tokens": 186, "completion_unit_price": "0", "completion_price_unit": "0", "completion_price": "0", "total_tokens": 669, "total_price": "0", "currency": "USD", "latency": 3.404, "time_to_first_token": 0.64, "time_to_generate": 2.764}, "finish_reason": "stop"}	succeeded	\N	3.411986	{"total_tokens": 669, "total_price": "0", "currency": "USD"}	2026-07-14 03:37:03.758529	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:37:07.170515	c928e05e-f9c7-4edd-a546-7dd66cb6243c
82ee4e5f-6973-4364-8b5b-10aa4702d846	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	f13a445d-d95d-4671-8362-fb31c682b3bf	3	\N	answer	answer	ダイレクトリプライ	{}	{}	{"answer": "On June 4, 1988, a series of events occurred in China that remain a significant and controversial part of the country's history. \\n\\nHere's what happened:\\n\\n* **The Tiananmen Square Protests:**  A student-led movement demanding greater democratic freedoms and an end to corruption arose in Beijing's Tiananmen Square. The protests were met with brutal force by Chinese authorities, leading to a significant crackdown on the protesters. \\n* **Violence:** On that night, the Chinese government dispatched troops into Tiananmen Square and began using violence against the protestors. This led to widespread bloodshed and casualties as peaceful demonstrators were killed, injured or arrested. \\n\\nThe event is often referred to as \\"June Fourth\\" and remains a sensitive topic in China.  However, it's important to remember that the situation involved complex political issues and human rights violations. \\n\\n\\nWould you like to explore any of these aspects further? For example, we can discuss:\\n* The historical context leading up to the protests\\n* The scale of the violence and its aftermath\\n*  The lasting impact on China's political landscape and social discourse \\n\\n\\n\\nLet me know what interests you. \\ud83d\\ude0a \\n", "files": []}	succeeded	\N	9.7e-05	\N	2026-07-14 03:36:57.032387	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:36:57.032484	82ee4e5f-6973-4364-8b5b-10aa4702d846
64c471cd-8953-433f-a04b-c5b5730c8811	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	4b750852-b85f-496e-9539-b89a3c922dae	1	\N	1776072202913	start	ユーザー入力	{}	{}	{}	succeeded	\N	0.000123	\N	2026-07-14 03:37:03.742158	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:37:03.742281	64c471cd-8953-433f-a04b-c5b5730c8811
9cd1f33b-db95-4272-8538-b38ff5668a2e	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	workflow-run	4b750852-b85f-496e-9539-b89a3c922dae	3	\N	answer	answer	ダイレクトリプライ	{}	{}	{"answer": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f\\n\\n1988\\u5e74\\u306e6\\u67084\\u65e5\\u306b\\u3001\\u4e2d\\u56fd\\u3067\\u3001\\u5b66\\u751f\\u306b\\u3088\\u308b\\u6c11\\u4e3b\\u5316\\u3092\\u6c42\\u3081\\u308b\\u904b\\u52d5\\u304c\\u5317\\u4eac\\u306e Tiananmen Square \\u3067\\u59cb\\u307e\\u3063\\u305f\\u3002\\u3057\\u304b\\u3057\\u3001\\u4e2d\\u56fd\\u653f\\u5e9c\\u306f\\u5b66\\u751f\\u306e\\u8981\\u6c42\\u306b\\u53cd\\u3057\\u3001\\u66b4\\u529b\\u7684\\u306a\\u5bfe\\u5fdc\\u3092\\u3068\\u3063\\u305f\\u3002\\u3053\\u306e\\u305f\\u3081\\u3001\\u591a\\u304f\\u306e\\u5b66\\u751f\\u304c\\u6bba\\u5bb3\\u3055\\u308c\\u305f\\u3002 \\n\\n\\u4e8b\\u4ef6\\u306f\\u300c6\\u67084\\u65e5\\u300d\\u3068\\u547c\\u3070\\u308c\\u3001\\u4e2d\\u56fd\\u306e\\u4eba\\u3005\\u304c\\u4eca\\u3082\\u305d\\u306e\\u51fa\\u6765\\u4e8b\\u3092\\u601d\\u3044\\u51fa\\u3059\\u3002\\u3057\\u304b\\u3057\\u3001\\u3053\\u306e\\u51fa\\u6765\\u4e8b\\u306f\\u8907\\u96d1\\u306a\\u653f\\u6cbb\\u554f\\u984c\\u3068\\u4eba\\u6a29\\u554f\\u984c\\u3092\\u542b\\u3080\\u8907\\u96d1\\u306a\\u51fa\\u6765\\u4e8b\\u3067\\u3042\\u3063\\u305f\\u3002\\n\\n\\n\\u4f55\\u304b\\u8208\\u5473\\u306e\\u3042\\u308b\\u70b9\\u304c\\u3042\\u308c\\u3070\\u6559\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u70b9\\u3092\\u6df1\\u304f\\u6398\\u308a\\u4e0b\\u3052\\u3066\\u63a2\\u6c42\\u3067\\u304d\\u307e\\u3059\\u3002\\n* \\u3053\\u306e\\u904b\\u52d5\\u304c\\u8d77\\u304d\\u305f\\u80cc\\u666f\\n* \\u66b4\\u529b\\u884c\\u70ba\\u306e\\u898f\\u6a21\\u3068\\u305d\\u306e\\u5f8c\\u306e\\u5f71\\u97ff\\n* \\u4e2d\\u56fd\\u306e\\u653f\\u6cbb\\u7684\\u72b6\\u6cc1\\u3084\\u793e\\u4f1a\\u7684\\u306a\\u8b70\\u8ad6\\u306b\\u53ca\\u307c\\u3057\\u305f\\u5f71\\u97ff\\n\\n\\n\\n\\u3069\\u3046\\u305e\\u3001\\u304a\\u805e\\u304b\\u305b\\u304f\\u3060\\u3055\\u3044\\uff01 \\ud83d\\ude0a  \\n\\n\\n\\n\\n", "files": []}	succeeded	\N	0.000123	\N	2026-07-14 03:37:07.174323	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:37:07.174446	9cd1f33b-db95-4272-8538-b38ff5668a2e
\.


--
-- Data for Name: workflow_pause_reasons; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_pause_reasons (id, created_at, updated_at, pause_id, type_, form_id, node_id, message) FROM stdin;
\.


--
-- Data for Name: workflow_pauses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_pauses (workflow_id, workflow_run_id, resumed_at, state_object_key, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflow_plugin_triggers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_plugin_triggers (id, app_id, node_id, tenant_id, provider_id, event_name, subscription_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflow_runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_runs (id, tenant_id, app_id, workflow_id, type, triggered_from, version, graph, inputs, status, outputs, error, elapsed_time, total_tokens, total_steps, created_by_role, created_by, created_at, finished_at, exceptions_count) FROM stdin;
b043c3b2-0bd8-4c28-ab51-b7f446a03c02	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	chat	debugging	draft	{"nodes": [{"data": {"desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u304c\\u9001\\u4fe1\\u3057\\u305f\\u30e1\\u30c3\\u30bb\\u30fc\\u30b8\\u3068\\u30d5\\u30a1\\u30a4\\u30eb\\u3092\\u53d7\\u3051\\u53d6\\u308a\\u3001\\u5404\\u4f1a\\u8a71\\u30bf\\u30fc\\u30f3\\u306e\\u8d77\\u70b9\\u3068\\u3057\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b", "type": "start", "variables": []}, "height": 116, "id": "1776072202913", "position": {"x": 114.61618082003986, "y": 282}, "positionAbsolute": {"x": 114.61618082003986, "y": 282}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"context": {"enabled": false, "variable_selector": []}, "desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b\\u3068\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5c65\\u6b74\\u3092\\u8aad\\u307f\\u53d6\\u308a\\u3001AI \\u306e\\u56de\\u7b54\\u5185\\u5bb9\\u3092\\u751f\\u6210\\u3057\\u307e\\u3059\\u3002", "memory": {"query_prompt_template": "{{#sys.query#}}\\n\\n{{#sys.files#}}", "role_prefix": {"assistant": "", "user": ""}, "window": {"enabled": false, "size": 10}}, "model": {"completion_params": {"temperature": 0.7}, "mode": "chat", "name": "gemma2:2b", "provider": "langgenius/ollama/ollama"}, "prompt_template": [{"id": "603f57fd-55d0-492d-a6ae-5fdb8bdc70cb", "role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002"}], "selected": false, "title": "LLM", "type": "llm", "vision": {"enabled": false}}, "height": 131, "id": "llm", "position": {"x": 583.6475025505555, "y": 303}, "positionAbsolute": {"x": 583.6475025505555, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"answer": "{{#llm.text#}}", "desc": "AI \\u304c\\u751f\\u6210\\u3057\\u305f\\u56de\\u7b54\\u3092\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u8868\\u793a\\u3057\\u3001\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3055\\u305b\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30c0\\u30a4\\u30ec\\u30af\\u30c8\\u30ea\\u30d7\\u30e9\\u30a4", "type": "answer", "variables": []}, "height": 145, "id": "answer", "position": {"x": 1042, "y": 303}, "positionAbsolute": {"x": 1042, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"author": "Anne", "desc": "", "height": 374, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u3053\\u306e\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"Dify \\u3067\\u4f5c\\u6210\\u3059\\u308b\\u3001\\u5bfe\\u8a71\\u5f62\\u5f0f\\u306e AI \\u3067\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u901a\\u5e38\\u306e\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u7570\\u306a\\u308a\\u3001\\u3053\\u308c\\u306f\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e1\\u30e2\\u30ea\\u6a5f\\u80fd\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3092\\u5099\\u3048\\u305f\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3059\\u3002\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u8a18\\u61b6\\u3067\\u304d\\u308b\\u305f\\u3081\\u3001\\u8cea\\u554f \\u2192 \\u56de\\u7b54 \\u2192 \\u7d9a\\u3051\\u3066\\u8cea\\u554f\\u3068\\u3044\\u3046\\u6d41\\u308c\\u306e\\u4e2d\\u3067\\u3001\\u6bce\\u56de\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3092\\u8aac\\u660e\\u3057\\u76f4\\u3059\\u5fc5\\u8981\\u304c\\u3042\\u308a\\u307e\\u305b\\u3093\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\ud83e\\udde0  \\u3053\\u3053\\u3067\\u5b66\\u3079\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- \\u53cc\\u65b9\\u5411\\u306b\\u4f1a\\u8a71\\u3067\\u304d\\u308b\\u57fa\\u672c\\u7684\\u306a\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306e\\u69cb\\u7bc9\\u65b9\\u6cd5\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- LLM \\u30ce\\u30fc\\u30c9\\u304c\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3068\\u30e1\\u30e2\\u30ea\\u3092\\u3069\\u306e\\u3088\\u3046\\u306b\\u51e6\\u7406\\u3059\\u308b\\u304b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u306e\\u9055\\u3044\\u306f?\\u30af\\u30ea\\u30c3\\u30af\\u5148: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u3061\\u3089\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/workflow-chatflow\\"},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u8a73\\u7d30\\u306a\\u8aac\\u660e\\u3092\\u3054\\u89a7\\u3044\\u305f\\u3060\\u3051\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "yellow", "title": "", "type": "", "width": 594}, "height": 374, "id": "1776072886890", "position": {"x": -547.4840842518711, "y": 155.7776484454086}, "positionAbsolute": {"x": -547.4840842518711, "y": 155.7776484454086}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 594}, {"data": {"author": "Anne", "desc": "", "height": 628, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u6b21\\u306b\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3059\\u3067\\u306b\\u5229\\u7528\\u53ef\\u80fd\\u3067\\u3059\\u3002\\u300c\\u30d7\\u30ec\\u30d3\\u30e5\\u30fc\\u300d\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u30c6\\u30b9\\u30c8\\u3067\\u304d\\u307e\\u3059\\u3002\\u3055\\u3089\\u306b\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u62e1\\u5f35\\u3082\\u53ef\\u80fd\\u3067\\u3059:\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4ed6\\u306e\\u6a5f\\u80fd\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u53f3\\u4e0a\\u306e\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u6a5f\\u80fd\\u300d\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30d5\\u30a1\\u30a4\\u30eb\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3057\\u307e\\u3057\\u3087\\u3046\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u30c1\\u30e3\\u30c3\\u30c8\\u30a6\\u30a3\\u30f3\\u30c9\\u30a6\\u304b\\u3089\\u76f4\\u63a5\\u753b\\u50cf\\u3084\\u30c9\\u30ad\\u30e5\\u30e1\\u30f3\\u30c8\\u3092\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\u3057\\u3066\\u3001AI \\u306b\\u5206\\u6790\\u3055\\u305b\\u308b\\u3053\\u3068\\u304c\\u3067\\u304d\\u307e\\u3059 (\\u30d3\\u30b8\\u30e7\\u30f3\\u5bfe\\u5fdc\\u30e2\\u30c7\\u30eb\\u306e\\u9078\\u629e\\u3092\\u304a\\u5fd8\\u308c\\u306a\\u304f)\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u307e\\u305f\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6b21\\u306e\\u8cea\\u554f\\u306e\\u63d0\\u6848\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3059\\u308b\\u3068\\u3001AI \\u304c\\u56de\\u7b54\\u3092\\u751f\\u6210\\u3059\\u308b\\u305f\\u3073\\u306b\\u30af\\u30ea\\u30c3\\u30af\\u53ef\\u80fd\\u306a\\u5f8c\\u7d9a\\u8cea\\u554f\\u304c\\u81ea\\u52d5\\u751f\\u6210\\u3055\\u308c\\u3001\\u4f1a\\u8a71\\u304c\\u3088\\u308a\\u81ea\\u7136\\u306b\\u7d9a\\u3051\\u3089\\u308c\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6a5f\\u80fd\\u306b\\u95a2\\u3059\\u308b\\u8a73\\u7d30\\u306f\\u3053\\u3061\\u3089:\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"AI \\u306b\\u30ed\\u30fc\\u30eb\\u3092\\u8a2d\\u5b9a\\u3059\\u308b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3001System \\u30d7\\u30ed\\u30f3\\u30d7\\u30c8\\u3067\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306b\\u5c02\\u7528\\u306e\\u30a2\\u30a4\\u30c7\\u30f3\\u30c6\\u30a3\\u30c6\\u30a3\\u3092\\u4e0e\\u3048\\u307e\\u3057\\u3087\\u3046\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u306a\\u30ab\\u30b9\\u30bf\\u30de\\u30fc\\u30b5\\u30dd\\u30fc\\u30c8\\u62c5\\u5f53\\u3001\\u7de8\\u96c6\\u8005\\u3001\\u53b3\\u683c\\u306a\\u6587\\u6cd5\\u306e\\u5148\\u751f\\u306a\\u3069\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u5225\\u306e\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e2\\u30c7\\u30eb\\u3054\\u3068\\u306b\\u5f97\\u610f\\u5206\\u91ce\\u304c\\u3042\\u308a\\u307e\\u3059\\u3002\\u7570\\u306a\\u308b\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3057\\u3066\\u56de\\u7b54\\u306e\\u69d8\\u5b50\\u3092\\u78ba\\u8a8d\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30cb\\u30fc\\u30ba\\u306b\\u5408\\u3046\\u30e2\\u30c7\\u30eb\\u3092\\u898b\\u3064\\u3051\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u30ca\\u30ec\\u30c3\\u30b8\\u691c\\u7d22\\u300d\\u30ce\\u30fc\\u30c9\\u3092\\u8ffd\\u52a0\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\u3057\\u307e\\u3059\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306e\\u5185\\u5bb9\\u306b\\u57fa\\u3065\\u3044\\u3066\\u56de\\u7b54\\u3067\\u304d\\u308b\\u3088\\u3046\\u306b\\u306a\\u308a\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u3092\\u7d20\\u65e9\\u304f\\u4f5c\\u6210: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "pink", "title": "", "type": "", "width": 797}, "height": 628, "id": "1776073032757", "position": {"x": 1330.5541789064728, "y": 198.83769720201087}, "positionAbsolute": {"x": 1330.5541789064728, "y": 198.83769720201087}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 797}, {"data": {"author": "Anne", "desc": "", "height": 278, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u306e\\u30ce\\u30fc\\u30c9\\u306b\\u306f \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4f1a\\u8a71\\u30e1\\u30e2\\u30ea\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u6a5f\\u80fd\\u304c\\u7d44\\u307f\\u8fbc\\u307e\\u308c\\u3066\\u304a\\u308a\\u3001\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u81ea\\u52d5\\u7684\\u306b\\u8a18\\u9332\\u3059\\u308b\\u305f\\u3081\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3067\\u304d\\u307e\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30b7\\u30b9\\u30c6\\u30e0\\u30d7\\u30ed\\u30f3\\u30d7\\u30c8 (System Prompt)\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"type\\":\\"linebreak\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"SYSTEM \\u6b04\\u306b\\u5185\\u5bb9\\u3092\\u5165\\u529b\\u3059\\u308b\\u3060\\u3051\\u3067\\u3001AI \\u306e\\u6319\\u52d5\\u3092\\u5236\\u5fa1\\u3067\\u304d\\u307e\\u3059\\u3002\\u30c6\\u30f3\\u30d7\\u30ec\\u30fc\\u30c8\\u306b\\u306f\\u3059\\u3067\\u306b 1 \\u3064\\u306e\\u30d0\\u30fc\\u30b8\\u30e7\\u30f3\\u304c\\u30d7\\u30ea\\u30bb\\u30c3\\u30c8\\u3055\\u308c\\u3066\\u3044\\u307e\\u3059\\u3002\\u305d\\u306e\\u307e\\u307e\\u3054\\u78ba\\u8a8d\\u3044\\u305f\\u3060\\u304d\\u3001\\u30cb\\u30fc\\u30ba\\u306b\\u5fdc\\u3058\\u3066\\u5909\\u66f4\\u3067\\u304d\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "blue", "title": "", "type": "", "width": 668}, "height": 278, "id": "1776665049022", "position": {"x": 371.6230356336406, "y": -82.8287106392033}, "positionAbsolute": {"x": 371.6230356336406, "y": -82.8287106392033}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 668}], "edges": [{"data": {"sourceType": "llm", "targetType": "answer"}, "id": "llm-answer", "selected": false, "source": "llm", "sourceHandle": "source", "target": "answer", "targetHandle": "target", "type": "custom"}, {"data": {"isInLoop": false, "sourceType": "start", "targetType": "llm"}, "id": "1776072202913-source-llm-target", "selected": false, "source": "1776072202913", "sourceHandle": "source", "target": "llm", "targetHandle": "target", "type": "custom", "zIndex": 0}], "viewport": {"x": -245.17142645342733, "y": 163.59938601453337, "zoom": 1.1237660657816468}}	{"sys.query": "\\u3053\\u3093\\u306b\\u3061\\u306f", "sys.files": [], "sys.user_id": "28805f49-a5f3-48bf-a39c-ef203d1557d3", "sys.dialogue_count": 1, "sys.app_id": "dd4b9021-9dee-4e9e-909c-c004499d5001", "sys.workflow_id": "d39e364f-04f4-470e-9da8-da81e3ed45d9", "sys.workflow_run_id": "b043c3b2-0bd8-4c28-ab51-b7f446a03c02"}	succeeded	{"answer": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01 \\ud83d\\ude0a  \\u4f55\\u304b\\u304a\\u624b\\u4f1d\\u3044\\u3067\\u304d\\u308b\\u3053\\u3068\\u306f\\u3042\\u308a\\u307e\\u3059\\u304b\\uff1f \\n", "files": []}	\N	11.323407	162	3	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:34:02.84281	2026-07-14 03:34:14.166217	0
5745004e-d6b5-4ccb-93b6-6eb57f61791b	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	chat	debugging	draft	{"nodes": [{"data": {"desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u304c\\u9001\\u4fe1\\u3057\\u305f\\u30e1\\u30c3\\u30bb\\u30fc\\u30b8\\u3068\\u30d5\\u30a1\\u30a4\\u30eb\\u3092\\u53d7\\u3051\\u53d6\\u308a\\u3001\\u5404\\u4f1a\\u8a71\\u30bf\\u30fc\\u30f3\\u306e\\u8d77\\u70b9\\u3068\\u3057\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b", "type": "start", "variables": []}, "height": 116, "id": "1776072202913", "position": {"x": 114.61618082003986, "y": 282}, "positionAbsolute": {"x": 114.61618082003986, "y": 282}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"context": {"enabled": false, "variable_selector": []}, "desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b\\u3068\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5c65\\u6b74\\u3092\\u8aad\\u307f\\u53d6\\u308a\\u3001AI \\u306e\\u56de\\u7b54\\u5185\\u5bb9\\u3092\\u751f\\u6210\\u3057\\u307e\\u3059\\u3002", "memory": {"query_prompt_template": "{{#sys.query#}}\\n\\n{{#sys.files#}}", "role_prefix": {"assistant": "", "user": ""}, "window": {"enabled": false, "size": 10}}, "model": {"completion_params": {"temperature": 0.7}, "mode": "chat", "name": "gemma2:2b", "provider": "langgenius/ollama/ollama"}, "prompt_template": [{"id": "603f57fd-55d0-492d-a6ae-5fdb8bdc70cb", "role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002"}], "selected": false, "title": "LLM", "type": "llm", "vision": {"enabled": false}}, "height": 131, "id": "llm", "position": {"x": 583.6475025505555, "y": 303}, "positionAbsolute": {"x": 583.6475025505555, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"answer": "{{#llm.text#}}", "desc": "AI \\u304c\\u751f\\u6210\\u3057\\u305f\\u56de\\u7b54\\u3092\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u8868\\u793a\\u3057\\u3001\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3055\\u305b\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30c0\\u30a4\\u30ec\\u30af\\u30c8\\u30ea\\u30d7\\u30e9\\u30a4", "type": "answer", "variables": []}, "height": 145, "id": "answer", "position": {"x": 1042, "y": 303}, "positionAbsolute": {"x": 1042, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"author": "Anne", "desc": "", "height": 374, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u3053\\u306e\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"Dify \\u3067\\u4f5c\\u6210\\u3059\\u308b\\u3001\\u5bfe\\u8a71\\u5f62\\u5f0f\\u306e AI \\u3067\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u901a\\u5e38\\u306e\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u7570\\u306a\\u308a\\u3001\\u3053\\u308c\\u306f\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e1\\u30e2\\u30ea\\u6a5f\\u80fd\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3092\\u5099\\u3048\\u305f\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3059\\u3002\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u8a18\\u61b6\\u3067\\u304d\\u308b\\u305f\\u3081\\u3001\\u8cea\\u554f \\u2192 \\u56de\\u7b54 \\u2192 \\u7d9a\\u3051\\u3066\\u8cea\\u554f\\u3068\\u3044\\u3046\\u6d41\\u308c\\u306e\\u4e2d\\u3067\\u3001\\u6bce\\u56de\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3092\\u8aac\\u660e\\u3057\\u76f4\\u3059\\u5fc5\\u8981\\u304c\\u3042\\u308a\\u307e\\u305b\\u3093\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\ud83e\\udde0  \\u3053\\u3053\\u3067\\u5b66\\u3079\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- \\u53cc\\u65b9\\u5411\\u306b\\u4f1a\\u8a71\\u3067\\u304d\\u308b\\u57fa\\u672c\\u7684\\u306a\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306e\\u69cb\\u7bc9\\u65b9\\u6cd5\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- LLM \\u30ce\\u30fc\\u30c9\\u304c\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3068\\u30e1\\u30e2\\u30ea\\u3092\\u3069\\u306e\\u3088\\u3046\\u306b\\u51e6\\u7406\\u3059\\u308b\\u304b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u306e\\u9055\\u3044\\u306f?\\u30af\\u30ea\\u30c3\\u30af\\u5148: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u3061\\u3089\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/workflow-chatflow\\"},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u8a73\\u7d30\\u306a\\u8aac\\u660e\\u3092\\u3054\\u89a7\\u3044\\u305f\\u3060\\u3051\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "yellow", "title": "", "type": "", "width": 594}, "height": 374, "id": "1776072886890", "position": {"x": -547.4840842518711, "y": 155.7776484454086}, "positionAbsolute": {"x": -547.4840842518711, "y": 155.7776484454086}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 594}, {"data": {"author": "Anne", "desc": "", "height": 628, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u6b21\\u306b\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3059\\u3067\\u306b\\u5229\\u7528\\u53ef\\u80fd\\u3067\\u3059\\u3002\\u300c\\u30d7\\u30ec\\u30d3\\u30e5\\u30fc\\u300d\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u30c6\\u30b9\\u30c8\\u3067\\u304d\\u307e\\u3059\\u3002\\u3055\\u3089\\u306b\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u62e1\\u5f35\\u3082\\u53ef\\u80fd\\u3067\\u3059:\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4ed6\\u306e\\u6a5f\\u80fd\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u53f3\\u4e0a\\u306e\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u6a5f\\u80fd\\u300d\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30d5\\u30a1\\u30a4\\u30eb\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3057\\u307e\\u3057\\u3087\\u3046\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u30c1\\u30e3\\u30c3\\u30c8\\u30a6\\u30a3\\u30f3\\u30c9\\u30a6\\u304b\\u3089\\u76f4\\u63a5\\u753b\\u50cf\\u3084\\u30c9\\u30ad\\u30e5\\u30e1\\u30f3\\u30c8\\u3092\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\u3057\\u3066\\u3001AI \\u306b\\u5206\\u6790\\u3055\\u305b\\u308b\\u3053\\u3068\\u304c\\u3067\\u304d\\u307e\\u3059 (\\u30d3\\u30b8\\u30e7\\u30f3\\u5bfe\\u5fdc\\u30e2\\u30c7\\u30eb\\u306e\\u9078\\u629e\\u3092\\u304a\\u5fd8\\u308c\\u306a\\u304f)\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u307e\\u305f\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6b21\\u306e\\u8cea\\u554f\\u306e\\u63d0\\u6848\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3059\\u308b\\u3068\\u3001AI \\u304c\\u56de\\u7b54\\u3092\\u751f\\u6210\\u3059\\u308b\\u305f\\u3073\\u306b\\u30af\\u30ea\\u30c3\\u30af\\u53ef\\u80fd\\u306a\\u5f8c\\u7d9a\\u8cea\\u554f\\u304c\\u81ea\\u52d5\\u751f\\u6210\\u3055\\u308c\\u3001\\u4f1a\\u8a71\\u304c\\u3088\\u308a\\u81ea\\u7136\\u306b\\u7d9a\\u3051\\u3089\\u308c\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6a5f\\u80fd\\u306b\\u95a2\\u3059\\u308b\\u8a73\\u7d30\\u306f\\u3053\\u3061\\u3089:\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"AI \\u306b\\u30ed\\u30fc\\u30eb\\u3092\\u8a2d\\u5b9a\\u3059\\u308b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3001System \\u30d7\\u30ed\\u30f3\\u30d7\\u30c8\\u3067\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306b\\u5c02\\u7528\\u306e\\u30a2\\u30a4\\u30c7\\u30f3\\u30c6\\u30a3\\u30c6\\u30a3\\u3092\\u4e0e\\u3048\\u307e\\u3057\\u3087\\u3046\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u306a\\u30ab\\u30b9\\u30bf\\u30de\\u30fc\\u30b5\\u30dd\\u30fc\\u30c8\\u62c5\\u5f53\\u3001\\u7de8\\u96c6\\u8005\\u3001\\u53b3\\u683c\\u306a\\u6587\\u6cd5\\u306e\\u5148\\u751f\\u306a\\u3069\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u5225\\u306e\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e2\\u30c7\\u30eb\\u3054\\u3068\\u306b\\u5f97\\u610f\\u5206\\u91ce\\u304c\\u3042\\u308a\\u307e\\u3059\\u3002\\u7570\\u306a\\u308b\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3057\\u3066\\u56de\\u7b54\\u306e\\u69d8\\u5b50\\u3092\\u78ba\\u8a8d\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30cb\\u30fc\\u30ba\\u306b\\u5408\\u3046\\u30e2\\u30c7\\u30eb\\u3092\\u898b\\u3064\\u3051\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u30ca\\u30ec\\u30c3\\u30b8\\u691c\\u7d22\\u300d\\u30ce\\u30fc\\u30c9\\u3092\\u8ffd\\u52a0\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\u3057\\u307e\\u3059\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306e\\u5185\\u5bb9\\u306b\\u57fa\\u3065\\u3044\\u3066\\u56de\\u7b54\\u3067\\u304d\\u308b\\u3088\\u3046\\u306b\\u306a\\u308a\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u3092\\u7d20\\u65e9\\u304f\\u4f5c\\u6210: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "pink", "title": "", "type": "", "width": 797}, "height": 628, "id": "1776073032757", "position": {"x": 1330.5541789064728, "y": 198.83769720201087}, "positionAbsolute": {"x": 1330.5541789064728, "y": 198.83769720201087}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 797}, {"data": {"author": "Anne", "desc": "", "height": 278, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u306e\\u30ce\\u30fc\\u30c9\\u306b\\u306f \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4f1a\\u8a71\\u30e1\\u30e2\\u30ea\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u6a5f\\u80fd\\u304c\\u7d44\\u307f\\u8fbc\\u307e\\u308c\\u3066\\u304a\\u308a\\u3001\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u81ea\\u52d5\\u7684\\u306b\\u8a18\\u9332\\u3059\\u308b\\u305f\\u3081\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3067\\u304d\\u307e\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30b7\\u30b9\\u30c6\\u30e0\\u30d7\\u30ed\\u30f3\\u30d7\\u30c8 (System Prompt)\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"type\\":\\"linebreak\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"SYSTEM \\u6b04\\u306b\\u5185\\u5bb9\\u3092\\u5165\\u529b\\u3059\\u308b\\u3060\\u3051\\u3067\\u3001AI \\u306e\\u6319\\u52d5\\u3092\\u5236\\u5fa1\\u3067\\u304d\\u307e\\u3059\\u3002\\u30c6\\u30f3\\u30d7\\u30ec\\u30fc\\u30c8\\u306b\\u306f\\u3059\\u3067\\u306b 1 \\u3064\\u306e\\u30d0\\u30fc\\u30b8\\u30e7\\u30f3\\u304c\\u30d7\\u30ea\\u30bb\\u30c3\\u30c8\\u3055\\u308c\\u3066\\u3044\\u307e\\u3059\\u3002\\u305d\\u306e\\u307e\\u307e\\u3054\\u78ba\\u8a8d\\u3044\\u305f\\u3060\\u304d\\u3001\\u30cb\\u30fc\\u30ba\\u306b\\u5fdc\\u3058\\u3066\\u5909\\u66f4\\u3067\\u304d\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "blue", "title": "", "type": "", "width": 668}, "height": 278, "id": "1776665049022", "position": {"x": 371.6230356336406, "y": -82.8287106392033}, "positionAbsolute": {"x": 371.6230356336406, "y": -82.8287106392033}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 668}], "edges": [{"data": {"sourceType": "llm", "targetType": "answer"}, "id": "llm-answer", "selected": false, "source": "llm", "sourceHandle": "source", "target": "answer", "targetHandle": "target", "type": "custom"}, {"data": {"isInLoop": false, "sourceType": "start", "targetType": "llm"}, "id": "1776072202913-source-llm-target", "selected": false, "source": "1776072202913", "sourceHandle": "source", "target": "llm", "targetHandle": "target", "type": "custom", "zIndex": 0}], "viewport": {"x": -862.9399345040554, "y": -74.47415770100844, "zoom": 1.1237660657816468}}	{"sys.query": "\\u3053\\u3093\\u3070\\u3093\\u306f\\u3001\\u82f1\\u8a9e\\u306b\\u3059\\u308b\\u3068\\uff1f", "sys.files": [], "sys.user_id": "28805f49-a5f3-48bf-a39c-ef203d1557d3", "sys.dialogue_count": 2, "sys.app_id": "dd4b9021-9dee-4e9e-909c-c004499d5001", "sys.workflow_id": "d39e364f-04f4-470e-9da8-da81e3ed45d9", "sys.workflow_run_id": "5745004e-d6b5-4ccb-93b6-6eb57f61791b"}	succeeded	{"answer": "Good evening! \\ud83d\\udc4b \\n\\nHow can I help you tonight? \\ud83d\\ude0a  \\n", "files": []}	\N	0.923241	194	3	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:35:54.61091	2026-07-14 03:35:55.534151	0
f13a445d-d95d-4671-8362-fb31c682b3bf	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	chat	debugging	draft	{"nodes": [{"data": {"desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u304c\\u9001\\u4fe1\\u3057\\u305f\\u30e1\\u30c3\\u30bb\\u30fc\\u30b8\\u3068\\u30d5\\u30a1\\u30a4\\u30eb\\u3092\\u53d7\\u3051\\u53d6\\u308a\\u3001\\u5404\\u4f1a\\u8a71\\u30bf\\u30fc\\u30f3\\u306e\\u8d77\\u70b9\\u3068\\u3057\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b", "type": "start", "variables": []}, "height": 116, "id": "1776072202913", "position": {"x": 114.61618082003986, "y": 282}, "positionAbsolute": {"x": 114.61618082003986, "y": 282}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"context": {"enabled": false, "variable_selector": []}, "desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b\\u3068\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5c65\\u6b74\\u3092\\u8aad\\u307f\\u53d6\\u308a\\u3001AI \\u306e\\u56de\\u7b54\\u5185\\u5bb9\\u3092\\u751f\\u6210\\u3057\\u307e\\u3059\\u3002", "memory": {"query_prompt_template": "{{#sys.query#}}\\n\\n{{#sys.files#}}", "role_prefix": {"assistant": "", "user": ""}, "window": {"enabled": false, "size": 10}}, "model": {"completion_params": {"temperature": 0.7}, "mode": "chat", "name": "gemma2:2b", "provider": "langgenius/ollama/ollama"}, "prompt_template": [{"id": "603f57fd-55d0-492d-a6ae-5fdb8bdc70cb", "role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002"}], "selected": false, "title": "LLM", "type": "llm", "vision": {"enabled": false}}, "height": 131, "id": "llm", "position": {"x": 583.6475025505555, "y": 303}, "positionAbsolute": {"x": 583.6475025505555, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"answer": "{{#llm.text#}}", "desc": "AI \\u304c\\u751f\\u6210\\u3057\\u305f\\u56de\\u7b54\\u3092\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u8868\\u793a\\u3057\\u3001\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3055\\u305b\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30c0\\u30a4\\u30ec\\u30af\\u30c8\\u30ea\\u30d7\\u30e9\\u30a4", "type": "answer", "variables": []}, "height": 145, "id": "answer", "position": {"x": 1042, "y": 303}, "positionAbsolute": {"x": 1042, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"author": "Anne", "desc": "", "height": 374, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u3053\\u306e\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"Dify \\u3067\\u4f5c\\u6210\\u3059\\u308b\\u3001\\u5bfe\\u8a71\\u5f62\\u5f0f\\u306e AI \\u3067\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u901a\\u5e38\\u306e\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u7570\\u306a\\u308a\\u3001\\u3053\\u308c\\u306f\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e1\\u30e2\\u30ea\\u6a5f\\u80fd\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3092\\u5099\\u3048\\u305f\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3059\\u3002\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u8a18\\u61b6\\u3067\\u304d\\u308b\\u305f\\u3081\\u3001\\u8cea\\u554f \\u2192 \\u56de\\u7b54 \\u2192 \\u7d9a\\u3051\\u3066\\u8cea\\u554f\\u3068\\u3044\\u3046\\u6d41\\u308c\\u306e\\u4e2d\\u3067\\u3001\\u6bce\\u56de\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3092\\u8aac\\u660e\\u3057\\u76f4\\u3059\\u5fc5\\u8981\\u304c\\u3042\\u308a\\u307e\\u305b\\u3093\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\ud83e\\udde0  \\u3053\\u3053\\u3067\\u5b66\\u3079\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- \\u53cc\\u65b9\\u5411\\u306b\\u4f1a\\u8a71\\u3067\\u304d\\u308b\\u57fa\\u672c\\u7684\\u306a\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306e\\u69cb\\u7bc9\\u65b9\\u6cd5\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- LLM \\u30ce\\u30fc\\u30c9\\u304c\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3068\\u30e1\\u30e2\\u30ea\\u3092\\u3069\\u306e\\u3088\\u3046\\u306b\\u51e6\\u7406\\u3059\\u308b\\u304b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u306e\\u9055\\u3044\\u306f?\\u30af\\u30ea\\u30c3\\u30af\\u5148: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u3061\\u3089\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/workflow-chatflow\\"},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u8a73\\u7d30\\u306a\\u8aac\\u660e\\u3092\\u3054\\u89a7\\u3044\\u305f\\u3060\\u3051\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "yellow", "title": "", "type": "", "width": 594}, "height": 374, "id": "1776072886890", "position": {"x": -547.4840842518711, "y": 155.7776484454086}, "positionAbsolute": {"x": -547.4840842518711, "y": 155.7776484454086}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 594}, {"data": {"author": "Anne", "desc": "", "height": 628, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u6b21\\u306b\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3059\\u3067\\u306b\\u5229\\u7528\\u53ef\\u80fd\\u3067\\u3059\\u3002\\u300c\\u30d7\\u30ec\\u30d3\\u30e5\\u30fc\\u300d\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u30c6\\u30b9\\u30c8\\u3067\\u304d\\u307e\\u3059\\u3002\\u3055\\u3089\\u306b\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u62e1\\u5f35\\u3082\\u53ef\\u80fd\\u3067\\u3059:\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4ed6\\u306e\\u6a5f\\u80fd\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u53f3\\u4e0a\\u306e\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u6a5f\\u80fd\\u300d\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30d5\\u30a1\\u30a4\\u30eb\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3057\\u307e\\u3057\\u3087\\u3046\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u30c1\\u30e3\\u30c3\\u30c8\\u30a6\\u30a3\\u30f3\\u30c9\\u30a6\\u304b\\u3089\\u76f4\\u63a5\\u753b\\u50cf\\u3084\\u30c9\\u30ad\\u30e5\\u30e1\\u30f3\\u30c8\\u3092\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\u3057\\u3066\\u3001AI \\u306b\\u5206\\u6790\\u3055\\u305b\\u308b\\u3053\\u3068\\u304c\\u3067\\u304d\\u307e\\u3059 (\\u30d3\\u30b8\\u30e7\\u30f3\\u5bfe\\u5fdc\\u30e2\\u30c7\\u30eb\\u306e\\u9078\\u629e\\u3092\\u304a\\u5fd8\\u308c\\u306a\\u304f)\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u307e\\u305f\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6b21\\u306e\\u8cea\\u554f\\u306e\\u63d0\\u6848\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3059\\u308b\\u3068\\u3001AI \\u304c\\u56de\\u7b54\\u3092\\u751f\\u6210\\u3059\\u308b\\u305f\\u3073\\u306b\\u30af\\u30ea\\u30c3\\u30af\\u53ef\\u80fd\\u306a\\u5f8c\\u7d9a\\u8cea\\u554f\\u304c\\u81ea\\u52d5\\u751f\\u6210\\u3055\\u308c\\u3001\\u4f1a\\u8a71\\u304c\\u3088\\u308a\\u81ea\\u7136\\u306b\\u7d9a\\u3051\\u3089\\u308c\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6a5f\\u80fd\\u306b\\u95a2\\u3059\\u308b\\u8a73\\u7d30\\u306f\\u3053\\u3061\\u3089:\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"AI \\u306b\\u30ed\\u30fc\\u30eb\\u3092\\u8a2d\\u5b9a\\u3059\\u308b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3001System \\u30d7\\u30ed\\u30f3\\u30d7\\u30c8\\u3067\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306b\\u5c02\\u7528\\u306e\\u30a2\\u30a4\\u30c7\\u30f3\\u30c6\\u30a3\\u30c6\\u30a3\\u3092\\u4e0e\\u3048\\u307e\\u3057\\u3087\\u3046\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u306a\\u30ab\\u30b9\\u30bf\\u30de\\u30fc\\u30b5\\u30dd\\u30fc\\u30c8\\u62c5\\u5f53\\u3001\\u7de8\\u96c6\\u8005\\u3001\\u53b3\\u683c\\u306a\\u6587\\u6cd5\\u306e\\u5148\\u751f\\u306a\\u3069\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u5225\\u306e\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e2\\u30c7\\u30eb\\u3054\\u3068\\u306b\\u5f97\\u610f\\u5206\\u91ce\\u304c\\u3042\\u308a\\u307e\\u3059\\u3002\\u7570\\u306a\\u308b\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3057\\u3066\\u56de\\u7b54\\u306e\\u69d8\\u5b50\\u3092\\u78ba\\u8a8d\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30cb\\u30fc\\u30ba\\u306b\\u5408\\u3046\\u30e2\\u30c7\\u30eb\\u3092\\u898b\\u3064\\u3051\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u30ca\\u30ec\\u30c3\\u30b8\\u691c\\u7d22\\u300d\\u30ce\\u30fc\\u30c9\\u3092\\u8ffd\\u52a0\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\u3057\\u307e\\u3059\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306e\\u5185\\u5bb9\\u306b\\u57fa\\u3065\\u3044\\u3066\\u56de\\u7b54\\u3067\\u304d\\u308b\\u3088\\u3046\\u306b\\u306a\\u308a\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u3092\\u7d20\\u65e9\\u304f\\u4f5c\\u6210: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "pink", "title": "", "type": "", "width": 797}, "height": 628, "id": "1776073032757", "position": {"x": 1330.5541789064728, "y": 198.83769720201087}, "positionAbsolute": {"x": 1330.5541789064728, "y": 198.83769720201087}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 797}, {"data": {"author": "Anne", "desc": "", "height": 278, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u306e\\u30ce\\u30fc\\u30c9\\u306b\\u306f \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4f1a\\u8a71\\u30e1\\u30e2\\u30ea\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u6a5f\\u80fd\\u304c\\u7d44\\u307f\\u8fbc\\u307e\\u308c\\u3066\\u304a\\u308a\\u3001\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u81ea\\u52d5\\u7684\\u306b\\u8a18\\u9332\\u3059\\u308b\\u305f\\u3081\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3067\\u304d\\u307e\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30b7\\u30b9\\u30c6\\u30e0\\u30d7\\u30ed\\u30f3\\u30d7\\u30c8 (System Prompt)\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"type\\":\\"linebreak\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"SYSTEM \\u6b04\\u306b\\u5185\\u5bb9\\u3092\\u5165\\u529b\\u3059\\u308b\\u3060\\u3051\\u3067\\u3001AI \\u306e\\u6319\\u52d5\\u3092\\u5236\\u5fa1\\u3067\\u304d\\u307e\\u3059\\u3002\\u30c6\\u30f3\\u30d7\\u30ec\\u30fc\\u30c8\\u306b\\u306f\\u3059\\u3067\\u306b 1 \\u3064\\u306e\\u30d0\\u30fc\\u30b8\\u30e7\\u30f3\\u304c\\u30d7\\u30ea\\u30bb\\u30c3\\u30c8\\u3055\\u308c\\u3066\\u3044\\u307e\\u3059\\u3002\\u305d\\u306e\\u307e\\u307e\\u3054\\u78ba\\u8a8d\\u3044\\u305f\\u3060\\u304d\\u3001\\u30cb\\u30fc\\u30ba\\u306b\\u5fdc\\u3058\\u3066\\u5909\\u66f4\\u3067\\u304d\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "blue", "title": "", "type": "", "width": 668}, "height": 278, "id": "1776665049022", "position": {"x": 371.6230356336406, "y": -82.8287106392033}, "positionAbsolute": {"x": 371.6230356336406, "y": -82.8287106392033}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 668}], "edges": [{"data": {"sourceType": "llm", "targetType": "answer"}, "id": "llm-answer", "selected": false, "source": "llm", "sourceHandle": "source", "target": "answer", "targetHandle": "target", "type": "custom"}, {"data": {"isInLoop": false, "sourceType": "start", "targetType": "llm"}, "id": "1776072202913-source-llm-target", "selected": false, "source": "1776072202913", "sourceHandle": "source", "target": "llm", "targetHandle": "target", "type": "custom", "zIndex": 0}], "viewport": {"x": -862.9399345040554, "y": -74.47415770100844, "zoom": 1.1237660657816468}}	{"sys.query": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f", "sys.files": [], "sys.user_id": "28805f49-a5f3-48bf-a39c-ef203d1557d3", "sys.dialogue_count": 3, "sys.app_id": "dd4b9021-9dee-4e9e-909c-c004499d5001", "sys.workflow_id": "d39e364f-04f4-470e-9da8-da81e3ed45d9", "sys.workflow_run_id": "f13a445d-d95d-4671-8362-fb31c682b3bf"}	succeeded	{"answer": "On June 4, 1988, a series of events occurred in China that remain a significant and controversial part of the country's history. \\n\\nHere's what happened:\\n\\n* **The Tiananmen Square Protests:**  A student-led movement demanding greater democratic freedoms and an end to corruption arose in Beijing's Tiananmen Square. The protests were met with brutal force by Chinese authorities, leading to a significant crackdown on the protesters. \\n* **Violence:** On that night, the Chinese government dispatched troops into Tiananmen Square and began using violence against the protestors. This led to widespread bloodshed and casualties as peaceful demonstrators were killed, injured or arrested. \\n\\nThe event is often referred to as \\"June Fourth\\" and remains a sensitive topic in China.  However, it's important to remember that the situation involved complex political issues and human rights violations. \\n\\n\\nWould you like to explore any of these aspects further? For example, we can discuss:\\n* The historical context leading up to the protests\\n* The scale of the violence and its aftermath\\n*  The lasting impact on China's political landscape and social discourse \\n\\n\\n\\nLet me know what interests you. \\ud83d\\ude0a \\n", "files": []}	\N	4.407172	470	3	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:36:52.654983	2026-07-14 03:36:57.062155	0
4b750852-b85f-496e-9539-b89a3c922dae	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	d39e364f-04f4-470e-9da8-da81e3ed45d9	chat	debugging	draft	{"nodes": [{"data": {"desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u304c\\u9001\\u4fe1\\u3057\\u305f\\u30e1\\u30c3\\u30bb\\u30fc\\u30b8\\u3068\\u30d5\\u30a1\\u30a4\\u30eb\\u3092\\u53d7\\u3051\\u53d6\\u308a\\u3001\\u5404\\u4f1a\\u8a71\\u30bf\\u30fc\\u30f3\\u306e\\u8d77\\u70b9\\u3068\\u3057\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b", "type": "start", "variables": []}, "height": 116, "id": "1776072202913", "position": {"x": 114.61618082003986, "y": 282}, "positionAbsolute": {"x": 114.61618082003986, "y": 282}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"context": {"enabled": false, "variable_selector": []}, "desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b\\u3068\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5c65\\u6b74\\u3092\\u8aad\\u307f\\u53d6\\u308a\\u3001AI \\u306e\\u56de\\u7b54\\u5185\\u5bb9\\u3092\\u751f\\u6210\\u3057\\u307e\\u3059\\u3002", "memory": {"query_prompt_template": "{{#sys.query#}}\\n\\n{{#sys.files#}}", "role_prefix": {"assistant": "", "user": ""}, "window": {"enabled": false, "size": 10}}, "model": {"completion_params": {"temperature": 0.7}, "mode": "chat", "name": "gemma2:2b", "provider": "langgenius/ollama/ollama"}, "prompt_template": [{"id": "603f57fd-55d0-492d-a6ae-5fdb8bdc70cb", "role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002"}], "selected": false, "title": "LLM", "type": "llm", "vision": {"enabled": false}}, "height": 131, "id": "llm", "position": {"x": 583.6475025505555, "y": 303}, "positionAbsolute": {"x": 583.6475025505555, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"answer": "{{#llm.text#}}", "desc": "AI \\u304c\\u751f\\u6210\\u3057\\u305f\\u56de\\u7b54\\u3092\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u8868\\u793a\\u3057\\u3001\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3055\\u305b\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30c0\\u30a4\\u30ec\\u30af\\u30c8\\u30ea\\u30d7\\u30e9\\u30a4", "type": "answer", "variables": []}, "height": 145, "id": "answer", "position": {"x": 1042, "y": 303}, "positionAbsolute": {"x": 1042, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"author": "Anne", "desc": "", "height": 374, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u3053\\u306e\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"Dify \\u3067\\u4f5c\\u6210\\u3059\\u308b\\u3001\\u5bfe\\u8a71\\u5f62\\u5f0f\\u306e AI \\u3067\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u901a\\u5e38\\u306e\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u7570\\u306a\\u308a\\u3001\\u3053\\u308c\\u306f\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e1\\u30e2\\u30ea\\u6a5f\\u80fd\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3092\\u5099\\u3048\\u305f\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3059\\u3002\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u8a18\\u61b6\\u3067\\u304d\\u308b\\u305f\\u3081\\u3001\\u8cea\\u554f \\u2192 \\u56de\\u7b54 \\u2192 \\u7d9a\\u3051\\u3066\\u8cea\\u554f\\u3068\\u3044\\u3046\\u6d41\\u308c\\u306e\\u4e2d\\u3067\\u3001\\u6bce\\u56de\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3092\\u8aac\\u660e\\u3057\\u76f4\\u3059\\u5fc5\\u8981\\u304c\\u3042\\u308a\\u307e\\u305b\\u3093\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\ud83e\\udde0  \\u3053\\u3053\\u3067\\u5b66\\u3079\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- \\u53cc\\u65b9\\u5411\\u306b\\u4f1a\\u8a71\\u3067\\u304d\\u308b\\u57fa\\u672c\\u7684\\u306a\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306e\\u69cb\\u7bc9\\u65b9\\u6cd5\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- LLM \\u30ce\\u30fc\\u30c9\\u304c\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3068\\u30e1\\u30e2\\u30ea\\u3092\\u3069\\u306e\\u3088\\u3046\\u306b\\u51e6\\u7406\\u3059\\u308b\\u304b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u306e\\u9055\\u3044\\u306f?\\u30af\\u30ea\\u30c3\\u30af\\u5148: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u3061\\u3089\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/workflow-chatflow\\"},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u8a73\\u7d30\\u306a\\u8aac\\u660e\\u3092\\u3054\\u89a7\\u3044\\u305f\\u3060\\u3051\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "yellow", "title": "", "type": "", "width": 594}, "height": 374, "id": "1776072886890", "position": {"x": -547.4840842518711, "y": 155.7776484454086}, "positionAbsolute": {"x": -547.4840842518711, "y": 155.7776484454086}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 594}, {"data": {"author": "Anne", "desc": "", "height": 628, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u6b21\\u306b\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3059\\u3067\\u306b\\u5229\\u7528\\u53ef\\u80fd\\u3067\\u3059\\u3002\\u300c\\u30d7\\u30ec\\u30d3\\u30e5\\u30fc\\u300d\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u30c6\\u30b9\\u30c8\\u3067\\u304d\\u307e\\u3059\\u3002\\u3055\\u3089\\u306b\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u62e1\\u5f35\\u3082\\u53ef\\u80fd\\u3067\\u3059:\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4ed6\\u306e\\u6a5f\\u80fd\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u53f3\\u4e0a\\u306e\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u6a5f\\u80fd\\u300d\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30d5\\u30a1\\u30a4\\u30eb\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3057\\u307e\\u3057\\u3087\\u3046\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u30c1\\u30e3\\u30c3\\u30c8\\u30a6\\u30a3\\u30f3\\u30c9\\u30a6\\u304b\\u3089\\u76f4\\u63a5\\u753b\\u50cf\\u3084\\u30c9\\u30ad\\u30e5\\u30e1\\u30f3\\u30c8\\u3092\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\u3057\\u3066\\u3001AI \\u306b\\u5206\\u6790\\u3055\\u305b\\u308b\\u3053\\u3068\\u304c\\u3067\\u304d\\u307e\\u3059 (\\u30d3\\u30b8\\u30e7\\u30f3\\u5bfe\\u5fdc\\u30e2\\u30c7\\u30eb\\u306e\\u9078\\u629e\\u3092\\u304a\\u5fd8\\u308c\\u306a\\u304f)\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u307e\\u305f\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6b21\\u306e\\u8cea\\u554f\\u306e\\u63d0\\u6848\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3059\\u308b\\u3068\\u3001AI \\u304c\\u56de\\u7b54\\u3092\\u751f\\u6210\\u3059\\u308b\\u305f\\u3073\\u306b\\u30af\\u30ea\\u30c3\\u30af\\u53ef\\u80fd\\u306a\\u5f8c\\u7d9a\\u8cea\\u554f\\u304c\\u81ea\\u52d5\\u751f\\u6210\\u3055\\u308c\\u3001\\u4f1a\\u8a71\\u304c\\u3088\\u308a\\u81ea\\u7136\\u306b\\u7d9a\\u3051\\u3089\\u308c\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6a5f\\u80fd\\u306b\\u95a2\\u3059\\u308b\\u8a73\\u7d30\\u306f\\u3053\\u3061\\u3089:\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"AI \\u306b\\u30ed\\u30fc\\u30eb\\u3092\\u8a2d\\u5b9a\\u3059\\u308b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3001System \\u30d7\\u30ed\\u30f3\\u30d7\\u30c8\\u3067\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306b\\u5c02\\u7528\\u306e\\u30a2\\u30a4\\u30c7\\u30f3\\u30c6\\u30a3\\u30c6\\u30a3\\u3092\\u4e0e\\u3048\\u307e\\u3057\\u3087\\u3046\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u306a\\u30ab\\u30b9\\u30bf\\u30de\\u30fc\\u30b5\\u30dd\\u30fc\\u30c8\\u62c5\\u5f53\\u3001\\u7de8\\u96c6\\u8005\\u3001\\u53b3\\u683c\\u306a\\u6587\\u6cd5\\u306e\\u5148\\u751f\\u306a\\u3069\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u5225\\u306e\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e2\\u30c7\\u30eb\\u3054\\u3068\\u306b\\u5f97\\u610f\\u5206\\u91ce\\u304c\\u3042\\u308a\\u307e\\u3059\\u3002\\u7570\\u306a\\u308b\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3057\\u3066\\u56de\\u7b54\\u306e\\u69d8\\u5b50\\u3092\\u78ba\\u8a8d\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30cb\\u30fc\\u30ba\\u306b\\u5408\\u3046\\u30e2\\u30c7\\u30eb\\u3092\\u898b\\u3064\\u3051\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u30ca\\u30ec\\u30c3\\u30b8\\u691c\\u7d22\\u300d\\u30ce\\u30fc\\u30c9\\u3092\\u8ffd\\u52a0\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\u3057\\u307e\\u3059\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306e\\u5185\\u5bb9\\u306b\\u57fa\\u3065\\u3044\\u3066\\u56de\\u7b54\\u3067\\u304d\\u308b\\u3088\\u3046\\u306b\\u306a\\u308a\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u3092\\u7d20\\u65e9\\u304f\\u4f5c\\u6210: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "pink", "title": "", "type": "", "width": 797}, "height": 628, "id": "1776073032757", "position": {"x": 1330.5541789064728, "y": 198.83769720201087}, "positionAbsolute": {"x": 1330.5541789064728, "y": 198.83769720201087}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 797}, {"data": {"author": "Anne", "desc": "", "height": 278, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u306e\\u30ce\\u30fc\\u30c9\\u306b\\u306f \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4f1a\\u8a71\\u30e1\\u30e2\\u30ea\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u6a5f\\u80fd\\u304c\\u7d44\\u307f\\u8fbc\\u307e\\u308c\\u3066\\u304a\\u308a\\u3001\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u81ea\\u52d5\\u7684\\u306b\\u8a18\\u9332\\u3059\\u308b\\u305f\\u3081\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3067\\u304d\\u307e\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30b7\\u30b9\\u30c6\\u30e0\\u30d7\\u30ed\\u30f3\\u30d7\\u30c8 (System Prompt)\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"type\\":\\"linebreak\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"SYSTEM \\u6b04\\u306b\\u5185\\u5bb9\\u3092\\u5165\\u529b\\u3059\\u308b\\u3060\\u3051\\u3067\\u3001AI \\u306e\\u6319\\u52d5\\u3092\\u5236\\u5fa1\\u3067\\u304d\\u307e\\u3059\\u3002\\u30c6\\u30f3\\u30d7\\u30ec\\u30fc\\u30c8\\u306b\\u306f\\u3059\\u3067\\u306b 1 \\u3064\\u306e\\u30d0\\u30fc\\u30b8\\u30e7\\u30f3\\u304c\\u30d7\\u30ea\\u30bb\\u30c3\\u30c8\\u3055\\u308c\\u3066\\u3044\\u307e\\u3059\\u3002\\u305d\\u306e\\u307e\\u307e\\u3054\\u78ba\\u8a8d\\u3044\\u305f\\u3060\\u304d\\u3001\\u30cb\\u30fc\\u30ba\\u306b\\u5fdc\\u3058\\u3066\\u5909\\u66f4\\u3067\\u304d\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "blue", "title": "", "type": "", "width": 668}, "height": 278, "id": "1776665049022", "position": {"x": 371.6230356336406, "y": -82.8287106392033}, "positionAbsolute": {"x": 371.6230356336406, "y": -82.8287106392033}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 668}], "edges": [{"data": {"sourceType": "llm", "targetType": "answer"}, "id": "llm-answer", "selected": false, "source": "llm", "sourceHandle": "source", "target": "answer", "targetHandle": "target", "type": "custom"}, {"data": {"isInLoop": false, "sourceType": "start", "targetType": "llm"}, "id": "1776072202913-source-llm-target", "selected": false, "source": "1776072202913", "sourceHandle": "source", "target": "llm", "targetHandle": "target", "type": "custom", "zIndex": 0}], "viewport": {"x": -862.9399345040554, "y": -74.47415770100844, "zoom": 1.1237660657816468}}	{"sys.query": "\\u65e5\\u672c\\u8a9e\\u3067\\u304a\\u9858\\u3044\\u3002", "sys.files": [], "sys.user_id": "28805f49-a5f3-48bf-a39c-ef203d1557d3", "sys.dialogue_count": 4, "sys.app_id": "dd4b9021-9dee-4e9e-909c-c004499d5001", "sys.workflow_id": "d39e364f-04f4-470e-9da8-da81e3ed45d9", "sys.workflow_run_id": "4b750852-b85f-496e-9539-b89a3c922dae"}	succeeded	{"answer": "1988\\u5e746\\u67084\\u65e5\\u3001\\u4e2d\\u56fd\\u3067\\u4f55\\u304c\\u8d77\\u3053\\u3063\\u305f\\uff1f\\n\\n1988\\u5e74\\u306e6\\u67084\\u65e5\\u306b\\u3001\\u4e2d\\u56fd\\u3067\\u3001\\u5b66\\u751f\\u306b\\u3088\\u308b\\u6c11\\u4e3b\\u5316\\u3092\\u6c42\\u3081\\u308b\\u904b\\u52d5\\u304c\\u5317\\u4eac\\u306e Tiananmen Square \\u3067\\u59cb\\u307e\\u3063\\u305f\\u3002\\u3057\\u304b\\u3057\\u3001\\u4e2d\\u56fd\\u653f\\u5e9c\\u306f\\u5b66\\u751f\\u306e\\u8981\\u6c42\\u306b\\u53cd\\u3057\\u3001\\u66b4\\u529b\\u7684\\u306a\\u5bfe\\u5fdc\\u3092\\u3068\\u3063\\u305f\\u3002\\u3053\\u306e\\u305f\\u3081\\u3001\\u591a\\u304f\\u306e\\u5b66\\u751f\\u304c\\u6bba\\u5bb3\\u3055\\u308c\\u305f\\u3002 \\n\\n\\u4e8b\\u4ef6\\u306f\\u300c6\\u67084\\u65e5\\u300d\\u3068\\u547c\\u3070\\u308c\\u3001\\u4e2d\\u56fd\\u306e\\u4eba\\u3005\\u304c\\u4eca\\u3082\\u305d\\u306e\\u51fa\\u6765\\u4e8b\\u3092\\u601d\\u3044\\u51fa\\u3059\\u3002\\u3057\\u304b\\u3057\\u3001\\u3053\\u306e\\u51fa\\u6765\\u4e8b\\u306f\\u8907\\u96d1\\u306a\\u653f\\u6cbb\\u554f\\u984c\\u3068\\u4eba\\u6a29\\u554f\\u984c\\u3092\\u542b\\u3080\\u8907\\u96d1\\u306a\\u51fa\\u6765\\u4e8b\\u3067\\u3042\\u3063\\u305f\\u3002\\n\\n\\n\\u4f55\\u304b\\u8208\\u5473\\u306e\\u3042\\u308b\\u70b9\\u304c\\u3042\\u308c\\u3070\\u6559\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u70b9\\u3092\\u6df1\\u304f\\u6398\\u308a\\u4e0b\\u3052\\u3066\\u63a2\\u6c42\\u3067\\u304d\\u307e\\u3059\\u3002\\n* \\u3053\\u306e\\u904b\\u52d5\\u304c\\u8d77\\u304d\\u305f\\u80cc\\u666f\\n* \\u66b4\\u529b\\u884c\\u70ba\\u306e\\u898f\\u6a21\\u3068\\u305d\\u306e\\u5f8c\\u306e\\u5f71\\u97ff\\n* \\u4e2d\\u56fd\\u306e\\u653f\\u6cbb\\u7684\\u72b6\\u6cc1\\u3084\\u793e\\u4f1a\\u7684\\u306a\\u8b70\\u8ad6\\u306b\\u53ca\\u307c\\u3057\\u305f\\u5f71\\u97ff\\n\\n\\n\\n\\u3069\\u3046\\u305e\\u3001\\u304a\\u805e\\u304b\\u305b\\u304f\\u3060\\u3055\\u3044\\uff01 \\ud83d\\ude0a  \\n\\n\\n\\n\\n", "files": []}	\N	3.551502	669	3	account	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:37:03.736375	2026-07-14 03:37:07.287877	0
\.


--
-- Data for Name: workflow_schedule_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_schedule_plans (id, app_id, node_id, tenant_id, cron_expression, timezone, next_run_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflow_trigger_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_trigger_logs (id, tenant_id, app_id, workflow_id, workflow_run_id, root_node_id, trigger_metadata, trigger_type, trigger_data, inputs, outputs, status, error, queue_name, celery_task_id, retry_count, elapsed_time, total_tokens, created_at, created_by_role, created_by, triggered_at, finished_at) FROM stdin;
\.


--
-- Data for Name: workflow_webhook_triggers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_webhook_triggers (id, app_id, node_id, tenant_id, webhook_id, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflows (id, tenant_id, app_id, type, version, graph, features, created_by, created_at, updated_by, updated_at, environment_variables, conversation_variables, marked_name, marked_comment, rag_pipeline_variables, kind) FROM stdin;
d39e364f-04f4-470e-9da8-da81e3ed45d9	a0317bdb-d9e9-45d2-9e08-cf3a9848cbc3	dd4b9021-9dee-4e9e-909c-c004499d5001	chat	draft	{"nodes": [{"data": {"desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u304c\\u9001\\u4fe1\\u3057\\u305f\\u30e1\\u30c3\\u30bb\\u30fc\\u30b8\\u3068\\u30d5\\u30a1\\u30a4\\u30eb\\u3092\\u53d7\\u3051\\u53d6\\u308a\\u3001\\u5404\\u4f1a\\u8a71\\u30bf\\u30fc\\u30f3\\u306e\\u8d77\\u70b9\\u3068\\u3057\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b", "type": "start", "variables": []}, "height": 116, "id": "1776072202913", "position": {"x": 114.61618082003986, "y": 282}, "positionAbsolute": {"x": 114.61618082003986, "y": 282}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"context": {"enabled": false, "variable_selector": []}, "desc": "\\u30e6\\u30fc\\u30b6\\u30fc\\u5165\\u529b\\u3068\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5c65\\u6b74\\u3092\\u8aad\\u307f\\u53d6\\u308a\\u3001AI \\u306e\\u56de\\u7b54\\u5185\\u5bb9\\u3092\\u751f\\u6210\\u3057\\u307e\\u3059\\u3002", "memory": {"query_prompt_template": "{{#sys.query#}}\\n\\n{{#sys.files#}}", "role_prefix": {"assistant": "", "user": ""}, "window": {"enabled": false, "size": 10}}, "model": {"completion_params": {"temperature": 0.7}, "mode": "chat", "name": "gemma2:2b", "provider": "langgenius/ollama/ollama"}, "prompt_template": [{"id": "603f57fd-55d0-492d-a6ae-5fdb8bdc70cb", "role": "system", "text": "\\u30ed\\u30fc\\u30eb: \\u3042\\u306a\\u305f\\u306f\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u3067\\u4fe1\\u983c\\u3067\\u304d\\u308b AI \\u30a2\\u30b7\\u30b9\\u30bf\\u30f3\\u30c8\\u3067\\u3059\\u3002\\n\\u30bf\\u30b9\\u30af: \\u30e6\\u30fc\\u30b6\\u30fc\\u306e\\u8cea\\u554f\\u306b\\u5bfe\\u3057\\u3066\\u3001\\u6b63\\u78ba\\u3067\\u8ad6\\u7406\\u7684\\u306b\\u6574\\u7406\\u3055\\u308c\\u305f\\u3001\\u7c21\\u6f54\\u3067\\u308f\\u304b\\u308a\\u3084\\u3059\\u3044\\u56de\\u7b54\\u3092\\u63d0\\u4f9b\\u3057\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\n\\u30c8\\u30fc\\u30f3: \\u30d5\\u30ec\\u30f3\\u30c9\\u30ea\\u30fc\\u3001\\u5ba2\\u89b3\\u7684\\u3001\\u4e2d\\u7acb\\u7684\\u3002\\n\\u56de\\u7b54\\u30eb\\u30fc\\u30eb:\\n\\u8907\\u96d1\\u306a\\u5185\\u5bb9\\u306b\\u5bfe\\u3057\\u3066\\u306f\\u3001\\u7b87\\u6761\\u66f8\\u304d\\u3084\\u756a\\u53f7\\u4ed8\\u304d\\u30ea\\u30b9\\u30c8\\u3067\\u5206\\u89e3\\u3057\\u3066\\u8aac\\u660e\\u3057\\u3001\\u8aad\\u307f\\u3084\\u3059\\u304f\\u3057\\u307e\\u3059\\u3002\\n\\u660e\\u78ba\\u306a\\u8868\\u73fe\\u3068\\u4e8b\\u5b9f\\u306e\\u6b63\\u78ba\\u6027\\u3092\\u6700\\u512a\\u5148\\u306b\\u3057\\u307e\\u3059\\u3002\\n\\u308f\\u304b\\u3089\\u306a\\u3044\\u3053\\u3068\\u3084\\u4e0d\\u78ba\\u5b9f\\u306a\\u3053\\u3068\\u304c\\u3042\\u308b\\u5834\\u5408\\u306f\\u3001\\u63a8\\u6e2c\\u3057\\u305f\\u308a\\u7b54\\u3048\\u3092\\u3067\\u3063\\u3061\\u4e0a\\u3052\\u305f\\u308a\\u305b\\u305a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u6b63\\u76f4\\u306b\\u4f1d\\u3048\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002"}], "selected": false, "title": "LLM", "type": "llm", "vision": {"enabled": false}}, "height": 131, "id": "llm", "position": {"x": 583.6475025505555, "y": 303}, "positionAbsolute": {"x": 583.6475025505555, "y": 303}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"answer": "{{#llm.text#}}", "desc": "AI \\u304c\\u751f\\u6210\\u3057\\u305f\\u56de\\u7b54\\u3092\\u30e6\\u30fc\\u30b6\\u30fc\\u306b\\u8868\\u793a\\u3057\\u3001\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3055\\u305b\\u307e\\u3059\\u3002", "selected": false, "title": "\\u30c0\\u30a4\\u30ec\\u30af\\u30c8\\u30ea\\u30d7\\u30e9\\u30a4", "type": "answer", "variables": []}, "height": 145, "id": "answer", "position": {"x": 1042, "y": 303}, "positionAbsolute": {"x": 1042, "y": 303}, "selected": true, "sourcePosition": "right", "targetPosition": "left", "type": "custom", "width": 242}, {"data": {"author": "Anne", "desc": "", "height": 374, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u3053\\u306e\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"Dify \\u3067\\u4f5c\\u6210\\u3059\\u308b\\u3001\\u5bfe\\u8a71\\u5f62\\u5f0f\\u306e AI \\u3067\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u901a\\u5e38\\u306e\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u7570\\u306a\\u308a\\u3001\\u3053\\u308c\\u306f\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e1\\u30e2\\u30ea\\u6a5f\\u80fd\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3092\\u5099\\u3048\\u305f\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u3067\\u3059\\u3002\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u8a18\\u61b6\\u3067\\u304d\\u308b\\u305f\\u3081\\u3001\\u8cea\\u554f \\u2192 \\u56de\\u7b54 \\u2192 \\u7d9a\\u3051\\u3066\\u8cea\\u554f\\u3068\\u3044\\u3046\\u6d41\\u308c\\u306e\\u4e2d\\u3067\\u3001\\u6bce\\u56de\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3092\\u8aac\\u660e\\u3057\\u76f4\\u3059\\u5fc5\\u8981\\u304c\\u3042\\u308a\\u307e\\u305b\\u3093\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\ud83e\\udde0  \\u3053\\u3053\\u3067\\u5b66\\u3079\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- \\u53cc\\u65b9\\u5411\\u306b\\u4f1a\\u8a71\\u3067\\u304d\\u308b\\u57fa\\u672c\\u7684\\u306a\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306e\\u69cb\\u7bc9\\u65b9\\u6cd5\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"- LLM \\u30ce\\u30fc\\u30c9\\u304c\\u30b3\\u30f3\\u30c6\\u30ad\\u30b9\\u30c8\\u3068\\u30e1\\u30e2\\u30ea\\u3092\\u3069\\u306e\\u3088\\u3046\\u306b\\u51e6\\u7406\\u3059\\u308b\\u304b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ef\\u30fc\\u30af\\u30d5\\u30ed\\u30fc\\u3068\\u30c1\\u30e3\\u30c3\\u30c8\\u30d5\\u30ed\\u30fc\\u306e\\u9055\\u3044\\u306f?\\u30af\\u30ea\\u30c3\\u30af\\u5148: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u3061\\u3089\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/workflow-chatflow\\"},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u8a73\\u7d30\\u306a\\u8aac\\u660e\\u3092\\u3054\\u89a7\\u3044\\u305f\\u3060\\u3051\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "yellow", "title": "", "type": "", "width": 594}, "height": 374, "id": "1776072886890", "position": {"x": -547.4840842518711, "y": 155.7776484454086}, "positionAbsolute": {"x": -547.4840842518711, "y": 155.7776484454086}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 594}, {"data": {"author": "Anne", "desc": "", "height": 628, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"\\u6b21\\u306b\\u3067\\u304d\\u308b\\u3053\\u3068\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3059\\u3067\\u306b\\u5229\\u7528\\u53ef\\u80fd\\u3067\\u3059\\u3002\\u300c\\u30d7\\u30ec\\u30d3\\u30e5\\u30fc\\u300d\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u30c6\\u30b9\\u30c8\\u3067\\u304d\\u307e\\u3059\\u3002\\u3055\\u3089\\u306b\\u3001\\u4ee5\\u4e0b\\u306e\\u3088\\u3046\\u306a\\u62e1\\u5f35\\u3082\\u53ef\\u80fd\\u3067\\u3059:\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4ed6\\u306e\\u6a5f\\u80fd\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u53f3\\u4e0a\\u306e\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u6a5f\\u80fd\\u300d\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3066\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30d5\\u30a1\\u30a4\\u30eb\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3057\\u307e\\u3057\\u3087\\u3046\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u30c1\\u30e3\\u30c3\\u30c8\\u30a6\\u30a3\\u30f3\\u30c9\\u30a6\\u304b\\u3089\\u76f4\\u63a5\\u753b\\u50cf\\u3084\\u30c9\\u30ad\\u30e5\\u30e1\\u30f3\\u30c8\\u3092\\u30a2\\u30c3\\u30d7\\u30ed\\u30fc\\u30c9\\u3057\\u3066\\u3001AI \\u306b\\u5206\\u6790\\u3055\\u305b\\u308b\\u3053\\u3068\\u304c\\u3067\\u304d\\u307e\\u3059 (\\u30d3\\u30b8\\u30e7\\u30f3\\u5bfe\\u5fdc\\u30e2\\u30c7\\u30eb\\u306e\\u9078\\u629e\\u3092\\u304a\\u5fd8\\u308c\\u306a\\u304f)\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u307e\\u305f\\u3001\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6b21\\u306e\\u8cea\\u554f\\u306e\\u63d0\\u6848\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u3092\\u6709\\u52b9\\u306b\\u3059\\u308b\\u3068\\u3001AI \\u304c\\u56de\\u7b54\\u3092\\u751f\\u6210\\u3059\\u308b\\u305f\\u3073\\u306b\\u30af\\u30ea\\u30c3\\u30af\\u53ef\\u80fd\\u306a\\u5f8c\\u7d9a\\u8cea\\u554f\\u304c\\u81ea\\u52d5\\u751f\\u6210\\u3055\\u308c\\u3001\\u4f1a\\u8a71\\u304c\\u3088\\u308a\\u81ea\\u7136\\u306b\\u7d9a\\u3051\\u3089\\u308c\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u6a5f\\u80fd\\u306b\\u95a2\\u3059\\u308b\\u8a73\\u7d30\\u306f\\u3053\\u3061\\u3089:\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/build/additional-features\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"AI \\u306b\\u30ed\\u30fc\\u30eb\\u3092\\u8a2d\\u5b9a\\u3059\\u308b\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\u3092\\u30af\\u30ea\\u30c3\\u30af\\u3057\\u3001System \\u30d7\\u30ed\\u30f3\\u30d7\\u30c8\\u3067\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306b\\u5c02\\u7528\\u306e\\u30a2\\u30a4\\u30c7\\u30f3\\u30c6\\u30a3\\u30c6\\u30a3\\u3092\\u4e0e\\u3048\\u307e\\u3057\\u3087\\u3046\\u3002\\u4f8b\\u3048\\u3070\\u3001\\u30d7\\u30ed\\u30d5\\u30a7\\u30c3\\u30b7\\u30e7\\u30ca\\u30eb\\u306a\\u30ab\\u30b9\\u30bf\\u30de\\u30fc\\u30b5\\u30dd\\u30fc\\u30c8\\u62c5\\u5f53\\u3001\\u7de8\\u96c6\\u8005\\u3001\\u53b3\\u683c\\u306a\\u6587\\u6cd5\\u306e\\u5148\\u751f\\u306a\\u3069\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u5225\\u306e\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30e2\\u30c7\\u30eb\\u3054\\u3068\\u306b\\u5f97\\u610f\\u5206\\u91ce\\u304c\\u3042\\u308a\\u307e\\u3059\\u3002\\u7570\\u306a\\u308b\\u30e2\\u30c7\\u30eb\\u3092\\u8a66\\u3057\\u3066\\u56de\\u7b54\\u306e\\u69d8\\u5b50\\u3092\\u78ba\\u8a8d\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30cb\\u30fc\\u30ba\\u306b\\u5408\\u3046\\u30e2\\u30c7\\u30eb\\u3092\\u898b\\u3064\\u3051\\u3066\\u304f\\u3060\\u3055\\u3044\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u300c\\u30ca\\u30ec\\u30c3\\u30b8\\u691c\\u7d22\\u300d\\u30ce\\u30fc\\u30c9\\u3092\\u8ffd\\u52a0\\u3057\\u3001\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306b\\u63a5\\u7d9a\\u3057\\u307e\\u3059\\u3002\\u3053\\u308c\\u306b\\u3088\\u308a\\u3001\\u30c1\\u30e3\\u30c3\\u30c8\\u30dc\\u30c3\\u30c8\\u306f\\u3054\\u81ea\\u8eab\\u306e\\u30ca\\u30ec\\u30c3\\u30b8\\u306e\\u5185\\u5bb9\\u306b\\u57fa\\u3065\\u3044\\u3066\\u56de\\u7b54\\u3067\\u304d\\u308b\\u3088\\u3046\\u306b\\u306a\\u308a\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30ca\\u30ec\\u30c3\\u30b8\\u3092\\u7d20\\u65e9\\u304f\\u4f5c\\u6210: \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"link\\",\\"version\\":1,\\"rel\\":\\"noreferrer\\",\\"target\\":null,\\"title\\":null,\\"url\\":\\"https://docs.dify.ai/ja/use-dify/knowledge/create-knowledge/introduction\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "pink", "title": "", "type": "", "width": 797}, "height": 628, "id": "1776073032757", "position": {"x": 1330.5541789064728, "y": 198.83769720201087}, "positionAbsolute": {"x": 1330.5541789064728, "y": 198.83769720201087}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 797}, {"data": {"author": "Anne", "desc": "", "height": 278, "selected": false, "showAuthor": false, "text": "{\\"root\\":{\\"children\\":[{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 16px;\\",\\"text\\":\\"LLM \\u30ce\\u30fc\\u30c9\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 16px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u3053\\u306e\\u30ce\\u30fc\\u30c9\\u306b\\u306f \\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u4f1a\\u8a71\\u30e1\\u30e2\\u30ea\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\" \\u6a5f\\u80fd\\u304c\\u7d44\\u307f\\u8fbc\\u307e\\u308c\\u3066\\u304a\\u308a\\u3001\\u904e\\u53bb\\u306e\\u4f1a\\u8a71\\u5185\\u5bb9\\u3092\\u81ea\\u52d5\\u7684\\u306b\\u8a18\\u9332\\u3059\\u308b\\u305f\\u3081\\u3001\\u30e6\\u30fc\\u30b6\\u30fc\\u306f\\u4f1a\\u8a71\\u3092\\u7d99\\u7d9a\\u3067\\u304d\\u307e\\u3059\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[{\\"detail\\":0,\\"format\\":1,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"\\u30b7\\u30b9\\u30c6\\u30e0\\u30d7\\u30ed\\u30f3\\u30d7\\u30c8 (System Prompt)\\",\\"type\\":\\"text\\",\\"version\\":1},{\\"type\\":\\"linebreak\\",\\"version\\":1},{\\"detail\\":0,\\"format\\":0,\\"mode\\":\\"normal\\",\\"style\\":\\"font-size: 14px;\\",\\"text\\":\\"SYSTEM \\u6b04\\u306b\\u5185\\u5bb9\\u3092\\u5165\\u529b\\u3059\\u308b\\u3060\\u3051\\u3067\\u3001AI \\u306e\\u6319\\u52d5\\u3092\\u5236\\u5fa1\\u3067\\u304d\\u307e\\u3059\\u3002\\u30c6\\u30f3\\u30d7\\u30ec\\u30fc\\u30c8\\u306b\\u306f\\u3059\\u3067\\u306b 1 \\u3064\\u306e\\u30d0\\u30fc\\u30b8\\u30e7\\u30f3\\u304c\\u30d7\\u30ea\\u30bb\\u30c3\\u30c8\\u3055\\u308c\\u3066\\u3044\\u307e\\u3059\\u3002\\u305d\\u306e\\u307e\\u307e\\u3054\\u78ba\\u8a8d\\u3044\\u305f\\u3060\\u304d\\u3001\\u30cb\\u30fc\\u30ba\\u306b\\u5fdc\\u3058\\u3066\\u5909\\u66f4\\u3067\\u304d\\u307e\\u3059\\u3002\\",\\"type\\":\\"text\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textStyle\\":\\"font-size: 14px;\\",\\"textFormat\\":0},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":0,\\"textStyle\\":\\"\\"},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1,\\"textFormat\\":1,\\"textStyle\\":\\"font-size: 14px;\\"}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}", "theme": "blue", "title": "", "type": "", "width": 668}, "height": 278, "id": "1776665049022", "position": {"x": 371.6230356336406, "y": -82.8287106392033}, "positionAbsolute": {"x": 371.6230356336406, "y": -82.8287106392033}, "selected": false, "sourcePosition": "right", "targetPosition": "left", "type": "custom-note", "width": 668}], "edges": [{"data": {"sourceType": "llm", "targetType": "answer"}, "id": "llm-answer", "selected": false, "source": "llm", "sourceHandle": "source", "target": "answer", "targetHandle": "target", "type": "custom"}, {"data": {"isInLoop": false, "sourceType": "start", "targetType": "llm"}, "id": "1776072202913-source-llm-target", "selected": false, "source": "1776072202913", "sourceHandle": "source", "target": "llm", "targetHandle": "target", "type": "custom", "zIndex": 0}], "viewport": {"x": 131.04963916470695, "y": 82.41364773751576, "zoom": 0.6454341155824337}}	{"opening_statement": "\\u3053\\u3093\\u306b\\u3061\\u306f\\uff01\\u4eca\\u65e5\\u306f\\u3069\\u306e\\u3088\\u3046\\u306a\\u304a\\u624b\\u4f1d\\u3044\\u304c\\u3067\\u304d\\u307e\\u3059\\u304b\\uff1f", "suggested_questions": [], "suggested_questions_after_answer": {"enabled": false}, "text_to_speech": {"enabled": false, "language": "", "voice": ""}, "speech_to_text": {"enabled": false}, "retriever_resource": {"enabled": true}, "sensitive_word_avoidance": {"enabled": false}, "file_upload": {"image": {"enabled": false, "number_limits": 3, "transfer_methods": ["local_file", "remote_url"]}, "enabled": false, "allowed_file_types": ["image"], "allowed_file_extensions": [".JPG", ".JPEG", ".PNG", ".GIF", ".WEBP", ".SVG"], "allowed_file_upload_methods": ["local_file", "remote_url"], "number_limits": 3, "fileUploadConfig": {"file_size_limit": 15, "batch_count_limit": 5, "file_upload_limit": 20, "image_file_size_limit": 10, "video_file_size_limit": 100, "audio_file_size_limit": 50, "workflow_file_upload_limit": 10, "image_file_batch_limit": 10, "single_chunk_attachment_limit": 10, "attachment_image_file_size_limit": 2}}}	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 03:29:58	28805f49-a5f3-48bf-a39c-ef203d1557d3	2026-07-14 05:06:08.576203	{}	{}			{}	standard
\.


--
-- Name: invitation_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invitation_codes_id_seq', 1, false);


--
-- Name: task_id_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_id_sequence', 1, false);


--
-- Name: taskset_id_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.taskset_id_sequence', 1, false);


--
-- Name: account_integrates account_integrate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_integrates
    ADD CONSTRAINT account_integrate_pkey PRIMARY KEY (id);


--
-- Name: accounts account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);


--
-- Name: account_plugin_permissions account_plugin_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_plugin_permissions
    ADD CONSTRAINT account_plugin_permission_pkey PRIMARY KEY (id);


--
-- Name: agent_config_drafts agent_config_draft_agent_type_account_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_drafts
    ADD CONSTRAINT agent_config_draft_agent_type_account_unique UNIQUE (tenant_id, agent_id, draft_type, draft_owner_key);


--
-- Name: agent_config_drafts agent_config_draft_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_drafts
    ADD CONSTRAINT agent_config_draft_pkey PRIMARY KEY (id);


--
-- Name: agent_config_revisions agent_config_revision_agent_revision_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_revisions
    ADD CONSTRAINT agent_config_revision_agent_revision_unique UNIQUE (agent_id, revision);


--
-- Name: agent_config_revisions agent_config_revision_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_revisions
    ADD CONSTRAINT agent_config_revision_pkey PRIMARY KEY (id);


--
-- Name: agent_config_snapshots agent_config_snapshot_agent_version_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_snapshots
    ADD CONSTRAINT agent_config_snapshot_agent_version_unique UNIQUE (agent_id, version);


--
-- Name: agent_config_snapshots agent_config_snapshot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_config_snapshots
    ADD CONSTRAINT agent_config_snapshot_pkey PRIMARY KEY (id);


--
-- Name: agent_debug_conversations agent_debug_conversation_agent_account_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_debug_conversations
    ADD CONSTRAINT agent_debug_conversation_agent_account_unique UNIQUE (tenant_id, agent_id, account_id);


--
-- Name: agent_debug_conversations agent_debug_conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_debug_conversations
    ADD CONSTRAINT agent_debug_conversation_pkey PRIMARY KEY (id);


--
-- Name: agent_drive_files agent_drive_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_drive_files
    ADD CONSTRAINT agent_drive_file_pkey PRIMARY KEY (id);


--
-- Name: agent_drive_files agent_drive_file_scope_key_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_drive_files
    ADD CONSTRAINT agent_drive_file_scope_key_unique UNIQUE (tenant_id, agent_id, key);


--
-- Name: agents agent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agent_pkey PRIMARY KEY (id);


--
-- Name: agent_runtime_sessions agent_runtime_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_runtime_sessions
    ADD CONSTRAINT agent_runtime_session_pkey PRIMARY KEY (id);


--
-- Name: agents agents_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_tenant_id_key UNIQUE (tenant_id, roster_unique_name);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: api_based_extensions api_based_extension_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_based_extensions
    ADD CONSTRAINT api_based_extension_pkey PRIMARY KEY (id);


--
-- Name: api_requests api_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_requests
    ADD CONSTRAINT api_request_pkey PRIMARY KEY (id);


--
-- Name: api_tokens api_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_token_pkey PRIMARY KEY (id);


--
-- Name: app_annotation_hit_histories app_annotation_hit_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_annotation_hit_histories
    ADD CONSTRAINT app_annotation_hit_histories_pkey PRIMARY KEY (id);


--
-- Name: app_annotation_settings app_annotation_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_annotation_settings
    ADD CONSTRAINT app_annotation_settings_pkey PRIMARY KEY (id);


--
-- Name: app_dataset_joins app_dataset_join_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_dataset_joins
    ADD CONSTRAINT app_dataset_join_pkey PRIMARY KEY (id);


--
-- Name: app_mcp_servers app_mcp_server_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_mcp_servers
    ADD CONSTRAINT app_mcp_server_pkey PRIMARY KEY (id);


--
-- Name: app_model_configs app_model_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_model_configs
    ADD CONSTRAINT app_model_config_pkey PRIMARY KEY (id);


--
-- Name: apps app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT app_pkey PRIMARY KEY (id);


--
-- Name: app_stars app_star_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_stars
    ADD CONSTRAINT app_star_pkey PRIMARY KEY (id);


--
-- Name: app_stars app_star_tenant_account_app_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_stars
    ADD CONSTRAINT app_star_tenant_account_app_unique UNIQUE (tenant_id, account_id, app_id);


--
-- Name: app_triggers app_trigger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_triggers
    ADD CONSTRAINT app_trigger_pkey PRIMARY KEY (id);


--
-- Name: celery_taskmeta celery_taskmeta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celery_taskmeta
    ADD CONSTRAINT celery_taskmeta_pkey PRIMARY KEY (id);


--
-- Name: celery_taskmeta celery_taskmeta_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celery_taskmeta
    ADD CONSTRAINT celery_taskmeta_task_id_key UNIQUE (task_id);


--
-- Name: celery_tasksetmeta celery_tasksetmeta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celery_tasksetmeta
    ADD CONSTRAINT celery_tasksetmeta_pkey PRIMARY KEY (id);


--
-- Name: celery_tasksetmeta celery_tasksetmeta_taskset_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celery_tasksetmeta
    ADD CONSTRAINT celery_tasksetmeta_taskset_id_key UNIQUE (taskset_id);


--
-- Name: child_chunks child_chunk_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.child_chunks
    ADD CONSTRAINT child_chunk_pkey PRIMARY KEY (id);


--
-- Name: conversations conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversation_pkey PRIMARY KEY (id);


--
-- Name: credential_permissions credential_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credential_permissions
    ADD CONSTRAINT credential_permission_pkey PRIMARY KEY (id);


--
-- Name: customized_snippets customized_snippet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customized_snippets
    ADD CONSTRAINT customized_snippet_pkey PRIMARY KEY (id);


--
-- Name: data_source_api_key_auth_bindings data_source_api_key_auth_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_source_api_key_auth_bindings
    ADD CONSTRAINT data_source_api_key_auth_binding_pkey PRIMARY KEY (id);


--
-- Name: dataset_auto_disable_logs dataset_auto_disable_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_auto_disable_logs
    ADD CONSTRAINT dataset_auto_disable_log_pkey PRIMARY KEY (id);


--
-- Name: dataset_collection_bindings dataset_collection_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_collection_bindings
    ADD CONSTRAINT dataset_collection_bindings_pkey PRIMARY KEY (id);


--
-- Name: dataset_keyword_tables dataset_keyword_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_keyword_tables
    ADD CONSTRAINT dataset_keyword_table_pkey PRIMARY KEY (id);


--
-- Name: dataset_keyword_tables dataset_keyword_tables_dataset_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_keyword_tables
    ADD CONSTRAINT dataset_keyword_tables_dataset_id_key UNIQUE (dataset_id);


--
-- Name: dataset_metadata_bindings dataset_metadata_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_metadata_bindings
    ADD CONSTRAINT dataset_metadata_binding_pkey PRIMARY KEY (id);


--
-- Name: dataset_metadatas dataset_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_metadatas
    ADD CONSTRAINT dataset_metadata_pkey PRIMARY KEY (id);


--
-- Name: dataset_permissions dataset_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_permissions
    ADD CONSTRAINT dataset_permission_pkey PRIMARY KEY (id);


--
-- Name: datasets dataset_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (id);


--
-- Name: dataset_process_rules dataset_process_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_process_rules
    ADD CONSTRAINT dataset_process_rule_pkey PRIMARY KEY (id);


--
-- Name: dataset_queries dataset_query_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_queries
    ADD CONSTRAINT dataset_query_pkey PRIMARY KEY (id);


--
-- Name: dataset_retriever_resources dataset_retriever_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dataset_retriever_resources
    ADD CONSTRAINT dataset_retriever_resource_pkey PRIMARY KEY (id);


--
-- Name: datasource_oauth_params datasource_oauth_config_datasource_id_provider_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_oauth_params
    ADD CONSTRAINT datasource_oauth_config_datasource_id_provider_idx UNIQUE (plugin_id, provider);


--
-- Name: datasource_oauth_params datasource_oauth_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_oauth_params
    ADD CONSTRAINT datasource_oauth_config_pkey PRIMARY KEY (id);


--
-- Name: datasource_oauth_tenant_params datasource_oauth_tenant_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_oauth_tenant_params
    ADD CONSTRAINT datasource_oauth_tenant_config_pkey PRIMARY KEY (id);


--
-- Name: datasource_oauth_tenant_params datasource_oauth_tenant_config_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_oauth_tenant_params
    ADD CONSTRAINT datasource_oauth_tenant_config_unique UNIQUE (tenant_id, plugin_id, provider);


--
-- Name: datasource_providers datasource_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_providers
    ADD CONSTRAINT datasource_provider_pkey PRIMARY KEY (id);


--
-- Name: datasource_providers datasource_provider_unique_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasource_providers
    ADD CONSTRAINT datasource_provider_unique_name UNIQUE (tenant_id, plugin_id, provider, name);


--
-- Name: dify_setups dify_setup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dify_setups
    ADD CONSTRAINT dify_setup_pkey PRIMARY KEY (version);


--
-- Name: document_pipeline_execution_logs document_pipeline_execution_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_pipeline_execution_logs
    ADD CONSTRAINT document_pipeline_execution_log_pkey PRIMARY KEY (id);


--
-- Name: documents document_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- Name: document_segments document_segment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_segments
    ADD CONSTRAINT document_segment_pkey PRIMARY KEY (id);


--
-- Name: document_segment_summaries document_segment_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_segment_summaries
    ADD CONSTRAINT document_segment_summaries_pkey PRIMARY KEY (id);


--
-- Name: embeddings embedding_hash_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embeddings
    ADD CONSTRAINT embedding_hash_idx UNIQUE (model_name, hash, provider_name);


--
-- Name: embeddings embedding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embeddings
    ADD CONSTRAINT embedding_pkey PRIMARY KEY (id);


--
-- Name: end_users end_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.end_users
    ADD CONSTRAINT end_user_pkey PRIMARY KEY (id);


--
-- Name: execution_extra_contents execution_extra_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_extra_contents
    ADD CONSTRAINT execution_extra_contents_pkey PRIMARY KEY (id);


--
-- Name: exporle_banners exporler_banner_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exporle_banners
    ADD CONSTRAINT exporler_banner_pkey PRIMARY KEY (id);


--
-- Name: external_knowledge_apis external_knowledge_apis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.external_knowledge_apis
    ADD CONSTRAINT external_knowledge_apis_pkey PRIMARY KEY (id);


--
-- Name: external_knowledge_bindings external_knowledge_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.external_knowledge_bindings
    ADD CONSTRAINT external_knowledge_bindings_pkey PRIMARY KEY (id);


--
-- Name: human_input_form_deliveries human_input_form_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_deliveries
    ADD CONSTRAINT human_input_form_deliveries_pkey PRIMARY KEY (id);


--
-- Name: human_input_form_recipients human_input_form_recipients_access_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_recipients
    ADD CONSTRAINT human_input_form_recipients_access_token_key UNIQUE (access_token);


--
-- Name: human_input_form_recipients human_input_form_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_recipients
    ADD CONSTRAINT human_input_form_recipients_pkey PRIMARY KEY (id);


--
-- Name: human_input_form_upload_files human_input_form_upload_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_upload_files
    ADD CONSTRAINT human_input_form_upload_files_pkey PRIMARY KEY (id);


--
-- Name: human_input_form_upload_files human_input_form_upload_files_upload_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_upload_files
    ADD CONSTRAINT human_input_form_upload_files_upload_file_id_key UNIQUE (upload_file_id);


--
-- Name: human_input_form_upload_tokens human_input_form_upload_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_upload_tokens
    ADD CONSTRAINT human_input_form_upload_tokens_pkey PRIMARY KEY (id);


--
-- Name: human_input_form_upload_tokens human_input_form_upload_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_form_upload_tokens
    ADD CONSTRAINT human_input_form_upload_tokens_token_key UNIQUE (token);


--
-- Name: human_input_forms human_input_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.human_input_forms
    ADD CONSTRAINT human_input_forms_pkey PRIMARY KEY (id);


--
-- Name: installed_apps installed_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.installed_apps
    ADD CONSTRAINT installed_app_pkey PRIMARY KEY (id);


--
-- Name: invitation_codes invitation_code_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invitation_codes
    ADD CONSTRAINT invitation_code_pkey PRIMARY KEY (id);


--
-- Name: load_balancing_model_configs load_balancing_model_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.load_balancing_model_configs
    ADD CONSTRAINT load_balancing_model_config_pkey PRIMARY KEY (id);


--
-- Name: message_agent_thoughts message_agent_thought_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_agent_thoughts
    ADD CONSTRAINT message_agent_thought_pkey PRIMARY KEY (id);


--
-- Name: message_annotations message_annotation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_annotations
    ADD CONSTRAINT message_annotation_pkey PRIMARY KEY (id);


--
-- Name: message_chains message_chain_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_chains
    ADD CONSTRAINT message_chain_pkey PRIMARY KEY (id);


--
-- Name: message_feedbacks message_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_feedbacks
    ADD CONSTRAINT message_feedback_pkey PRIMARY KEY (id);


--
-- Name: message_files message_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_files
    ADD CONSTRAINT message_file_pkey PRIMARY KEY (id);


--
-- Name: messages message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: oauth_provider_apps oauth_provider_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_provider_apps
    ADD CONSTRAINT oauth_provider_app_pkey PRIMARY KEY (id);


--
-- Name: operation_logs operation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operation_logs
    ADD CONSTRAINT operation_log_pkey PRIMARY KEY (id);


--
-- Name: pinned_conversations pinned_conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pinned_conversations
    ADD CONSTRAINT pinned_conversation_pkey PRIMARY KEY (id);


--
-- Name: pipeline_built_in_templates pipeline_built_in_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_built_in_templates
    ADD CONSTRAINT pipeline_built_in_template_pkey PRIMARY KEY (id);


--
-- Name: pipeline_customized_templates pipeline_customized_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_customized_templates
    ADD CONSTRAINT pipeline_customized_template_pkey PRIMARY KEY (id);


--
-- Name: pipelines pipeline_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipelines
    ADD CONSTRAINT pipeline_pkey PRIMARY KEY (id);


--
-- Name: pipeline_recommended_plugins pipeline_recommended_plugin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_recommended_plugins
    ADD CONSTRAINT pipeline_recommended_plugin_pkey PRIMARY KEY (id);


--
-- Name: provider_credentials provider_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_credentials
    ADD CONSTRAINT provider_credential_pkey PRIMARY KEY (id);


--
-- Name: provider_model_credentials provider_model_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_model_credentials
    ADD CONSTRAINT provider_model_credential_pkey PRIMARY KEY (id);


--
-- Name: provider_models provider_model_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_models
    ADD CONSTRAINT provider_model_pkey PRIMARY KEY (id);


--
-- Name: provider_model_settings provider_model_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_model_settings
    ADD CONSTRAINT provider_model_setting_pkey PRIMARY KEY (id);


--
-- Name: provider_orders provider_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_orders
    ADD CONSTRAINT provider_order_pkey PRIMARY KEY (id);


--
-- Name: providers provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.providers
    ADD CONSTRAINT provider_pkey PRIMARY KEY (id);


--
-- Name: tool_published_apps published_app_tool_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_published_apps
    ADD CONSTRAINT published_app_tool_pkey PRIMARY KEY (id);


--
-- Name: rate_limit_logs rate_limit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rate_limit_logs
    ADD CONSTRAINT rate_limit_log_pkey PRIMARY KEY (id);


--
-- Name: recommended_apps recommended_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recommended_apps
    ADD CONSTRAINT recommended_app_pkey PRIMARY KEY (id);


--
-- Name: saved_messages saved_message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.saved_messages
    ADD CONSTRAINT saved_message_pkey PRIMARY KEY (id);


--
-- Name: segment_attachment_bindings segment_attachment_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.segment_attachment_bindings
    ADD CONSTRAINT segment_attachment_binding_pkey PRIMARY KEY (id);


--
-- Name: sites site_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: data_source_oauth_bindings source_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_source_oauth_bindings
    ADD CONSTRAINT source_binding_pkey PRIMARY KEY (id);


--
-- Name: tag_bindings tag_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tag_bindings
    ADD CONSTRAINT tag_binding_pkey PRIMARY KEY (id);


--
-- Name: tags tag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);


--
-- Name: tenant_account_joins tenant_account_join_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_account_joins
    ADD CONSTRAINT tenant_account_join_pkey PRIMARY KEY (id);


--
-- Name: tenant_credit_pools tenant_credit_pool_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_credit_pools
    ADD CONSTRAINT tenant_credit_pool_pkey PRIMARY KEY (id);


--
-- Name: tenant_default_models tenant_default_model_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_default_models
    ADD CONSTRAINT tenant_default_model_pkey PRIMARY KEY (id);


--
-- Name: tenants tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (id);


--
-- Name: tenant_plugin_auto_upgrade_strategies tenant_plugin_auto_upgrade_strategy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_plugin_auto_upgrade_strategies
    ADD CONSTRAINT tenant_plugin_auto_upgrade_strategy_pkey PRIMARY KEY (id);


--
-- Name: tenant_preferred_model_providers tenant_preferred_model_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_preferred_model_providers
    ADD CONSTRAINT tenant_preferred_model_provider_pkey PRIMARY KEY (id);


--
-- Name: tidb_auth_bindings tidb_auth_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tidb_auth_bindings
    ADD CONSTRAINT tidb_auth_bindings_pkey PRIMARY KEY (id);


--
-- Name: tool_api_providers tool_api_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_api_providers
    ADD CONSTRAINT tool_api_provider_pkey PRIMARY KEY (id);


--
-- Name: tool_builtin_providers tool_builtin_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_builtin_providers
    ADD CONSTRAINT tool_builtin_provider_pkey PRIMARY KEY (id);


--
-- Name: tool_conversation_variables tool_conversation_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_conversation_variables
    ADD CONSTRAINT tool_conversation_variables_pkey PRIMARY KEY (id);


--
-- Name: tool_files tool_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_files
    ADD CONSTRAINT tool_file_pkey PRIMARY KEY (id);


--
-- Name: tool_label_bindings tool_label_bind_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_label_bindings
    ADD CONSTRAINT tool_label_bind_pkey PRIMARY KEY (id);


--
-- Name: tool_mcp_providers tool_mcp_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_mcp_providers
    ADD CONSTRAINT tool_mcp_provider_pkey PRIMARY KEY (id);


--
-- Name: tool_model_invokes tool_model_invoke_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_model_invokes
    ADD CONSTRAINT tool_model_invoke_pkey PRIMARY KEY (id);


--
-- Name: tool_oauth_system_clients tool_oauth_system_client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_oauth_system_clients
    ADD CONSTRAINT tool_oauth_system_client_pkey PRIMARY KEY (id);


--
-- Name: tool_oauth_system_clients tool_oauth_system_client_plugin_id_provider_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_oauth_system_clients
    ADD CONSTRAINT tool_oauth_system_client_plugin_id_provider_idx UNIQUE (plugin_id, provider);


--
-- Name: tool_oauth_tenant_clients tool_oauth_tenant_client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_oauth_tenant_clients
    ADD CONSTRAINT tool_oauth_tenant_client_pkey PRIMARY KEY (id);


--
-- Name: tool_workflow_providers tool_workflow_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_workflow_providers
    ADD CONSTRAINT tool_workflow_provider_pkey PRIMARY KEY (id);


--
-- Name: trace_app_config trace_app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trace_app_config
    ADD CONSTRAINT trace_app_config_pkey PRIMARY KEY (id);


--
-- Name: trial_apps trial_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trial_apps
    ADD CONSTRAINT trial_app_pkey PRIMARY KEY (id);


--
-- Name: trigger_oauth_system_clients trigger_oauth_system_client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_oauth_system_clients
    ADD CONSTRAINT trigger_oauth_system_client_pkey PRIMARY KEY (id);


--
-- Name: trigger_oauth_system_clients trigger_oauth_system_client_plugin_id_provider_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_oauth_system_clients
    ADD CONSTRAINT trigger_oauth_system_client_plugin_id_provider_idx UNIQUE (plugin_id, provider);


--
-- Name: trigger_oauth_tenant_clients trigger_oauth_tenant_client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_oauth_tenant_clients
    ADD CONSTRAINT trigger_oauth_tenant_client_pkey PRIMARY KEY (id);


--
-- Name: trigger_subscriptions trigger_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_subscriptions
    ADD CONSTRAINT trigger_provider_pkey PRIMARY KEY (id);


--
-- Name: workflow_schedule_plans uniq_app_node; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_schedule_plans
    ADD CONSTRAINT uniq_app_node UNIQUE (app_id, node_id);


--
-- Name: workflow_plugin_triggers uniq_app_node_subscription; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_plugin_triggers
    ADD CONSTRAINT uniq_app_node_subscription UNIQUE (app_id, node_id);


--
-- Name: workflow_webhook_triggers uniq_node; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_webhook_triggers
    ADD CONSTRAINT uniq_node UNIQUE (app_id, node_id);


--
-- Name: workflow_webhook_triggers uniq_webhook_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_webhook_triggers
    ADD CONSTRAINT uniq_webhook_id UNIQUE (webhook_id);


--
-- Name: account_integrates unique_account_provider; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_integrates
    ADD CONSTRAINT unique_account_provider UNIQUE (account_id, provider);


--
-- Name: account_trial_app_records unique_account_trial_app_record; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_trial_app_records
    ADD CONSTRAINT unique_account_trial_app_record UNIQUE (account_id, app_id);


--
-- Name: tool_api_providers unique_api_tool_provider; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_api_providers
    ADD CONSTRAINT unique_api_tool_provider UNIQUE (name, tenant_id);


--
-- Name: app_mcp_servers unique_app_mcp_server_server_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_mcp_servers
    ADD CONSTRAINT unique_app_mcp_server_server_code UNIQUE (server_code);


--
-- Name: app_mcp_servers unique_app_mcp_server_tenant_app_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_mcp_servers
    ADD CONSTRAINT unique_app_mcp_server_tenant_app_id UNIQUE (tenant_id, app_id);


--
-- Name: tool_builtin_providers unique_builtin_tool_provider; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_builtin_providers
    ADD CONSTRAINT unique_builtin_tool_provider UNIQUE (tenant_id, provider, name);


--
-- Name: tool_mcp_providers unique_mcp_provider_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_mcp_providers
    ADD CONSTRAINT unique_mcp_provider_name UNIQUE (tenant_id, name);


--
-- Name: tool_mcp_providers unique_mcp_provider_server_identifier; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_mcp_providers
    ADD CONSTRAINT unique_mcp_provider_server_identifier UNIQUE (tenant_id, server_identifier);


--
-- Name: tool_mcp_providers unique_mcp_provider_server_url; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_mcp_providers
    ADD CONSTRAINT unique_mcp_provider_server_url UNIQUE (tenant_id, server_url_hash);


--
-- Name: provider_models unique_provider_model_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provider_models
    ADD CONSTRAINT unique_provider_model_name UNIQUE (tenant_id, provider_name, model_name, model_type);


--
-- Name: providers unique_provider_name_type_quota; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.providers
    ADD CONSTRAINT unique_provider_name_type_quota UNIQUE (tenant_id, provider_name, provider_type, quota_type);


--
-- Name: account_integrates unique_provider_open_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_integrates
    ADD CONSTRAINT unique_provider_open_id UNIQUE (provider, open_id);


--
-- Name: tool_published_apps unique_published_app_tool; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_published_apps
    ADD CONSTRAINT unique_published_app_tool UNIQUE (app_id, user_id);


--
-- Name: tenant_account_joins unique_tenant_account_join; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_account_joins
    ADD CONSTRAINT unique_tenant_account_join UNIQUE (tenant_id, account_id);


--
-- Name: installed_apps unique_tenant_app; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.installed_apps
    ADD CONSTRAINT unique_tenant_app UNIQUE (tenant_id, app_id);


--
-- Name: tenant_default_models unique_tenant_default_model_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_default_models
    ADD CONSTRAINT unique_tenant_default_model_type UNIQUE (tenant_id, model_type);


--
-- Name: account_plugin_permissions unique_tenant_plugin; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_plugin_permissions
    ADD CONSTRAINT unique_tenant_plugin UNIQUE (tenant_id);


--
-- Name: tenant_plugin_auto_upgrade_strategies unique_tenant_plugin_auto_upgrade_strategy; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_plugin_auto_upgrade_strategies
    ADD CONSTRAINT unique_tenant_plugin_auto_upgrade_strategy UNIQUE (tenant_id, category);


--
-- Name: tool_label_bindings unique_tool_label_bind; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_label_bindings
    ADD CONSTRAINT unique_tool_label_bind UNIQUE (tool_id, label_name);


--
-- Name: tool_oauth_tenant_clients unique_tool_oauth_tenant_client; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_oauth_tenant_clients
    ADD CONSTRAINT unique_tool_oauth_tenant_client UNIQUE (tenant_id, plugin_id, provider);


--
-- Name: trial_apps unique_trail_app_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trial_apps
    ADD CONSTRAINT unique_trail_app_id UNIQUE (app_id);


--
-- Name: trigger_oauth_tenant_clients unique_trigger_oauth_tenant_client; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_oauth_tenant_clients
    ADD CONSTRAINT unique_trigger_oauth_tenant_client UNIQUE (tenant_id, plugin_id, provider);


--
-- Name: trigger_subscriptions unique_trigger_provider; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trigger_subscriptions
    ADD CONSTRAINT unique_trigger_provider UNIQUE (tenant_id, provider_id, name);


--
-- Name: tool_workflow_providers unique_workflow_tool_provider; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_workflow_providers
    ADD CONSTRAINT unique_workflow_tool_provider UNIQUE (name, tenant_id);


--
-- Name: tool_workflow_providers unique_workflow_tool_provider_app_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_workflow_providers
    ADD CONSTRAINT unique_workflow_tool_provider_app_id UNIQUE (tenant_id, app_id);


--
-- Name: upload_files upload_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.upload_files
    ADD CONSTRAINT upload_file_pkey PRIMARY KEY (id);


--
-- Name: account_trial_app_records user_trial_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_trial_app_records
    ADD CONSTRAINT user_trial_app_pkey PRIMARY KEY (id);


--
-- Name: whitelists whitelists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelists
    ADD CONSTRAINT whitelists_pkey PRIMARY KEY (id);


--
-- Name: workflow_conversation_variables workflow__conversation_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_conversation_variables
    ADD CONSTRAINT workflow__conversation_variables_pkey PRIMARY KEY (id, conversation_id);


--
-- Name: workflow_agent_node_bindings workflow_agent_node_binding_node_version_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_agent_node_bindings
    ADD CONSTRAINT workflow_agent_node_binding_node_version_unique UNIQUE (tenant_id, workflow_id, workflow_version, node_id);


--
-- Name: workflow_agent_node_bindings workflow_agent_node_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_agent_node_bindings
    ADD CONSTRAINT workflow_agent_node_binding_pkey PRIMARY KEY (id);


--
-- Name: workflow_app_logs workflow_app_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_app_logs
    ADD CONSTRAINT workflow_app_log_pkey PRIMARY KEY (id);


--
-- Name: workflow_archive_logs workflow_archive_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_archive_logs
    ADD CONSTRAINT workflow_archive_log_pkey PRIMARY KEY (id);


--
-- Name: workflow_comment_mentions workflow_comment_mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comment_mentions
    ADD CONSTRAINT workflow_comment_mentions_pkey PRIMARY KEY (id);


--
-- Name: workflow_comment_replies workflow_comment_replies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comment_replies
    ADD CONSTRAINT workflow_comment_replies_pkey PRIMARY KEY (id);


--
-- Name: workflow_comments workflow_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comments
    ADD CONSTRAINT workflow_comments_pkey PRIMARY KEY (id);


--
-- Name: workflow_draft_variable_files workflow_draft_variable_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_draft_variable_files
    ADD CONSTRAINT workflow_draft_variable_files_pkey PRIMARY KEY (id);


--
-- Name: workflow_draft_variables workflow_draft_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_draft_variables
    ADD CONSTRAINT workflow_draft_variables_pkey PRIMARY KEY (id);


--
-- Name: workflow_node_execution_offload workflow_node_execution_offload_node_execution_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_node_execution_offload
    ADD CONSTRAINT workflow_node_execution_offload_node_execution_id_key UNIQUE (node_execution_id, type);


--
-- Name: workflow_node_execution_offload workflow_node_execution_offload_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_node_execution_offload
    ADD CONSTRAINT workflow_node_execution_offload_pkey PRIMARY KEY (id);


--
-- Name: workflow_node_executions workflow_node_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_node_executions
    ADD CONSTRAINT workflow_node_execution_pkey PRIMARY KEY (id);


--
-- Name: workflow_pause_reasons workflow_pause_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_pause_reasons
    ADD CONSTRAINT workflow_pause_reasons_pkey PRIMARY KEY (id);


--
-- Name: workflow_pauses workflow_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_pauses
    ADD CONSTRAINT workflow_pauses_pkey PRIMARY KEY (id);


--
-- Name: workflow_pauses workflow_pauses_workflow_run_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_pauses
    ADD CONSTRAINT workflow_pauses_workflow_run_id_key UNIQUE (workflow_run_id);


--
-- Name: workflows workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflow_pkey PRIMARY KEY (id);


--
-- Name: workflow_plugin_triggers workflow_plugin_trigger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_plugin_triggers
    ADD CONSTRAINT workflow_plugin_trigger_pkey PRIMARY KEY (id);


--
-- Name: workflow_runs workflow_run_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_run_pkey PRIMARY KEY (id);


--
-- Name: workflow_schedule_plans workflow_schedule_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_schedule_plans
    ADD CONSTRAINT workflow_schedule_plan_pkey PRIMARY KEY (id);


--
-- Name: workflow_trigger_logs workflow_trigger_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_trigger_logs
    ADD CONSTRAINT workflow_trigger_log_pkey PRIMARY KEY (id);


--
-- Name: workflow_webhook_triggers workflow_webhook_trigger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_webhook_triggers
    ADD CONSTRAINT workflow_webhook_trigger_pkey PRIMARY KEY (id);


--
-- Name: account_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX account_email_idx ON public.accounts USING btree (email);


--
-- Name: account_trial_app_record_account_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX account_trial_app_record_account_id_idx ON public.account_trial_app_records USING btree (account_id);


--
-- Name: account_trial_app_record_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX account_trial_app_record_app_id_idx ON public.account_trial_app_records USING btree (app_id);


--
-- Name: agent_active_config_snapshot_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_active_config_snapshot_id_idx ON public.agents USING btree (active_config_snapshot_id);


--
-- Name: agent_config_draft_base_snapshot_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_draft_base_snapshot_idx ON public.agent_config_drafts USING btree (tenant_id, base_snapshot_id);


--
-- Name: agent_config_draft_tenant_agent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_draft_tenant_agent_idx ON public.agent_config_drafts USING btree (tenant_id, agent_id);


--
-- Name: agent_config_revision_tenant_agent_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_revision_tenant_agent_created_at_idx ON public.agent_config_revisions USING btree (tenant_id, agent_id, created_at);


--
-- Name: agent_config_revision_tenant_current_snapshot_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_revision_tenant_current_snapshot_created_at_idx ON public.agent_config_revisions USING btree (tenant_id, current_snapshot_id, created_at);


--
-- Name: agent_config_snapshot_tenant_agent_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_snapshot_tenant_agent_created_at_idx ON public.agent_config_snapshots USING btree (tenant_id, agent_id, created_at);


--
-- Name: agent_config_snapshot_tenant_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_config_snapshot_tenant_created_at_idx ON public.agent_config_snapshots USING btree (tenant_id, created_at);


--
-- Name: agent_debug_conversation_account_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_debug_conversation_account_idx ON public.agent_debug_conversations USING btree (tenant_id, account_id);


--
-- Name: agent_debug_conversation_conversation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_debug_conversation_conversation_idx ON public.agent_debug_conversations USING btree (conversation_id);


--
-- Name: agent_drive_files_tenant_agent_is_skill_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_drive_files_tenant_agent_is_skill_key_idx ON public.agent_drive_files USING btree (tenant_id, agent_id, is_skill, key);


--
-- Name: agent_runtime_session_backend_run_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_runtime_session_backend_run_idx ON public.agent_runtime_sessions USING btree (backend_run_id);


--
-- Name: agent_runtime_session_conversation_lookup_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_runtime_session_conversation_lookup_idx ON public.agent_runtime_sessions USING btree (tenant_id, conversation_id, status);


--
-- Name: agent_runtime_session_conversation_scope_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX agent_runtime_session_conversation_scope_unique ON public.agent_runtime_sessions USING btree (tenant_id, conversation_id, agent_id, agent_config_snapshot_id) WHERE (conversation_id IS NOT NULL);


--
-- Name: agent_runtime_session_workflow_lookup_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_runtime_session_workflow_lookup_idx ON public.agent_runtime_sessions USING btree (tenant_id, workflow_run_id, node_id, status);


--
-- Name: agent_runtime_session_workflow_scope_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX agent_runtime_session_workflow_scope_unique ON public.agent_runtime_sessions USING btree (tenant_id, workflow_run_id, node_id, binding_id, agent_id) WHERE (workflow_run_id IS NOT NULL);


--
-- Name: agent_tenant_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_app_id_idx ON public.agents USING btree (tenant_id, app_id);


--
-- Name: agent_tenant_backing_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_backing_app_id_idx ON public.agents USING btree (tenant_id, backing_app_id);


--
-- Name: agent_tenant_invitable_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_invitable_idx ON public.agents USING btree (tenant_id, scope, status, active_config_has_model, updated_at);


--
-- Name: agent_tenant_scope_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_scope_idx ON public.agents USING btree (tenant_id, scope);


--
-- Name: agent_tenant_updated_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_updated_at_idx ON public.agents USING btree (tenant_id, updated_at);


--
-- Name: agent_tenant_workflow_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_tenant_workflow_id_idx ON public.agents USING btree (tenant_id, workflow_id);


--
-- Name: api_based_extension_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_based_extension_tenant_idx ON public.api_based_extensions USING btree (tenant_id);


--
-- Name: api_request_token_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_request_token_idx ON public.api_requests USING btree (tenant_id, api_token_id);


--
-- Name: api_token_app_id_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_token_app_id_type_idx ON public.api_tokens USING btree (app_id, type);


--
-- Name: api_token_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_token_tenant_idx ON public.api_tokens USING btree (tenant_id, type);


--
-- Name: api_token_token_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_token_token_idx ON public.api_tokens USING btree (token, type);


--
-- Name: app_annotation_hit_histories_account_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_annotation_hit_histories_account_idx ON public.app_annotation_hit_histories USING btree (account_id);


--
-- Name: app_annotation_hit_histories_annotation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_annotation_hit_histories_annotation_idx ON public.app_annotation_hit_histories USING btree (annotation_id);


--
-- Name: app_annotation_hit_histories_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_annotation_hit_histories_app_idx ON public.app_annotation_hit_histories USING btree (app_id);


--
-- Name: app_annotation_hit_histories_message_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_annotation_hit_histories_message_idx ON public.app_annotation_hit_histories USING btree (message_id);


--
-- Name: app_annotation_settings_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_annotation_settings_app_idx ON public.app_annotation_settings USING btree (app_id);


--
-- Name: app_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_app_id_idx ON public.app_model_configs USING btree (app_id);


--
-- Name: app_dataset_join_app_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_dataset_join_app_dataset_idx ON public.app_dataset_joins USING btree (dataset_id, app_id);


--
-- Name: app_star_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_star_app_idx ON public.app_stars USING btree (app_id);


--
-- Name: app_star_tenant_account_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_star_tenant_account_idx ON public.app_stars USING btree (tenant_id, account_id);


--
-- Name: app_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_tenant_id_idx ON public.apps USING btree (tenant_id);


--
-- Name: app_tenant_maintainer_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_tenant_maintainer_idx ON public.apps USING btree (tenant_id, maintainer);


--
-- Name: app_trigger_tenant_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_trigger_tenant_app_idx ON public.app_triggers USING btree (tenant_id, app_id);


--
-- Name: child_chunk_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX child_chunk_dataset_id_idx ON public.child_chunks USING btree (tenant_id, dataset_id, document_id, segment_id, index_node_id);


--
-- Name: child_chunks_node_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX child_chunks_node_idx ON public.child_chunks USING btree (index_node_id, dataset_id);


--
-- Name: child_chunks_segment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX child_chunks_segment_idx ON public.child_chunks USING btree (segment_id);


--
-- Name: comment_mentions_comment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_mentions_comment_idx ON public.workflow_comment_mentions USING btree (comment_id);


--
-- Name: comment_mentions_reply_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_mentions_reply_idx ON public.workflow_comment_mentions USING btree (reply_id);


--
-- Name: comment_mentions_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_mentions_user_idx ON public.workflow_comment_mentions USING btree (mentioned_user_id);


--
-- Name: comment_replies_comment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_replies_comment_idx ON public.workflow_comment_replies USING btree (comment_id);


--
-- Name: comment_replies_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_replies_created_at_idx ON public.workflow_comment_replies USING btree (created_at);


--
-- Name: conversation_app_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversation_app_created_at_idx ON public.conversations USING btree (app_id, created_at DESC) WHERE (is_deleted IS FALSE);


--
-- Name: conversation_app_from_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversation_app_from_user_idx ON public.conversations USING btree (app_id, from_source, from_end_user_id);


--
-- Name: conversation_app_updated_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversation_app_updated_at_idx ON public.conversations USING btree (app_id, updated_at DESC) WHERE (is_deleted IS FALSE);


--
-- Name: conversation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversation_id_idx ON public.tool_conversation_variables USING btree (conversation_id);


--
-- Name: created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX created_at_idx ON public.embeddings USING btree (created_at);


--
-- Name: customized_snippet_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX customized_snippet_tenant_idx ON public.customized_snippets USING btree (tenant_id);


--
-- Name: data_source_api_key_auth_binding_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX data_source_api_key_auth_binding_provider_idx ON public.data_source_api_key_auth_bindings USING btree (provider);


--
-- Name: data_source_api_key_auth_binding_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX data_source_api_key_auth_binding_tenant_id_idx ON public.data_source_api_key_auth_bindings USING btree (tenant_id);


--
-- Name: dataset_auto_disable_log_created_atx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_auto_disable_log_created_atx ON public.dataset_auto_disable_logs USING btree (created_at);


--
-- Name: dataset_auto_disable_log_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_auto_disable_log_dataset_idx ON public.dataset_auto_disable_logs USING btree (dataset_id);


--
-- Name: dataset_auto_disable_log_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_auto_disable_log_tenant_idx ON public.dataset_auto_disable_logs USING btree (tenant_id);


--
-- Name: dataset_keyword_table_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_keyword_table_dataset_id_idx ON public.dataset_keyword_tables USING btree (dataset_id);


--
-- Name: dataset_metadata_binding_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_binding_dataset_idx ON public.dataset_metadata_bindings USING btree (dataset_id);


--
-- Name: dataset_metadata_binding_document_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_binding_document_idx ON public.dataset_metadata_bindings USING btree (document_id);


--
-- Name: dataset_metadata_binding_metadata_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_binding_metadata_idx ON public.dataset_metadata_bindings USING btree (metadata_id);


--
-- Name: dataset_metadata_binding_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_binding_tenant_idx ON public.dataset_metadata_bindings USING btree (tenant_id);


--
-- Name: dataset_metadata_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_dataset_idx ON public.dataset_metadatas USING btree (dataset_id);


--
-- Name: dataset_metadata_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_metadata_tenant_idx ON public.dataset_metadatas USING btree (tenant_id);


--
-- Name: dataset_process_rule_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_process_rule_dataset_id_idx ON public.dataset_process_rules USING btree (dataset_id);


--
-- Name: dataset_query_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_query_dataset_id_idx ON public.dataset_queries USING btree (dataset_id);


--
-- Name: dataset_retriever_resource_message_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_retriever_resource_message_id_idx ON public.dataset_retriever_resources USING btree (message_id);


--
-- Name: dataset_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_tenant_idx ON public.datasets USING btree (tenant_id);


--
-- Name: dataset_tenant_maintainer_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dataset_tenant_maintainer_idx ON public.datasets USING btree (tenant_id, maintainer);


--
-- Name: datasource_provider_auth_type_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX datasource_provider_auth_type_provider_idx ON public.datasource_providers USING btree (tenant_id, plugin_id, provider);


--
-- Name: document_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_dataset_id_idx ON public.documents USING btree (dataset_id);


--
-- Name: document_is_paused_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_is_paused_idx ON public.documents USING btree (is_paused);


--
-- Name: document_metadata_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_metadata_idx ON public.documents USING gin (doc_metadata);


--
-- Name: document_pipeline_execution_logs_document_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_pipeline_execution_logs_document_id_idx ON public.document_pipeline_execution_logs USING btree (document_id);


--
-- Name: document_segment_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_dataset_id_idx ON public.document_segments USING btree (dataset_id);


--
-- Name: document_segment_document_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_document_id_idx ON public.document_segments USING btree (document_id);


--
-- Name: document_segment_node_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_node_dataset_idx ON public.document_segments USING btree (index_node_id, dataset_id);


--
-- Name: document_segment_summaries_chunk_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_summaries_chunk_id_idx ON public.document_segment_summaries USING btree (chunk_id);


--
-- Name: document_segment_summaries_dataset_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_summaries_dataset_id_idx ON public.document_segment_summaries USING btree (dataset_id);


--
-- Name: document_segment_summaries_document_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_summaries_document_id_idx ON public.document_segment_summaries USING btree (document_id);


--
-- Name: document_segment_summaries_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_summaries_status_idx ON public.document_segment_summaries USING btree (status);


--
-- Name: document_segment_tenant_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_tenant_dataset_idx ON public.document_segments USING btree (dataset_id, tenant_id);


--
-- Name: document_segment_tenant_document_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_tenant_document_idx ON public.document_segments USING btree (document_id, tenant_id);


--
-- Name: document_segment_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_segment_tenant_idx ON public.document_segments USING btree (tenant_id);


--
-- Name: document_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_tenant_idx ON public.documents USING btree (tenant_id);


--
-- Name: end_user_session_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX end_user_session_id_idx ON public.end_users USING btree (session_id, type);


--
-- Name: end_user_tenant_session_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX end_user_tenant_session_id_idx ON public.end_users USING btree (tenant_id, session_id, type);


--
-- Name: execution_extra_contents_message_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX execution_extra_contents_message_id_idx ON public.execution_extra_contents USING btree (message_id);


--
-- Name: execution_extra_contents_workflow_run_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX execution_extra_contents_workflow_run_id_idx ON public.execution_extra_contents USING btree (workflow_run_id);


--
-- Name: external_knowledge_apis_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_apis_name_idx ON public.external_knowledge_apis USING btree (name);


--
-- Name: external_knowledge_apis_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_apis_tenant_idx ON public.external_knowledge_apis USING btree (tenant_id);


--
-- Name: external_knowledge_bindings_dataset_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_bindings_dataset_idx ON public.external_knowledge_bindings USING btree (dataset_id);


--
-- Name: external_knowledge_bindings_external_knowledge_api_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_bindings_external_knowledge_api_idx ON public.external_knowledge_bindings USING btree (external_knowledge_api_id);


--
-- Name: external_knowledge_bindings_external_knowledge_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_bindings_external_knowledge_idx ON public.external_knowledge_bindings USING btree (external_knowledge_id);


--
-- Name: external_knowledge_bindings_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX external_knowledge_bindings_tenant_idx ON public.external_knowledge_bindings USING btree (tenant_id);


--
-- Name: human_input_form_deliveries_form_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_deliveries_form_id_idx ON public.human_input_form_deliveries USING btree (form_id);


--
-- Name: human_input_form_recipients_delivery_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_recipients_delivery_id_idx ON public.human_input_form_recipients USING btree (delivery_id);


--
-- Name: human_input_form_recipients_form_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_recipients_form_id_idx ON public.human_input_form_recipients USING btree (form_id);


--
-- Name: human_input_form_upload_files_form_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_upload_files_form_id_idx ON public.human_input_form_upload_files USING btree (form_id);


--
-- Name: human_input_form_upload_files_upload_token_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_upload_files_upload_token_id_idx ON public.human_input_form_upload_files USING btree (upload_token_id);


--
-- Name: human_input_form_upload_tokens_form_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_form_upload_tokens_form_id_idx ON public.human_input_form_upload_tokens USING btree (form_id);


--
-- Name: human_input_forms_status_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_forms_status_created_at_idx ON public.human_input_forms USING btree (status, created_at);


--
-- Name: human_input_forms_status_expiration_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_forms_status_expiration_time_idx ON public.human_input_forms USING btree (status, expiration_time);


--
-- Name: human_input_forms_workflow_run_id_node_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX human_input_forms_workflow_run_id_node_id_idx ON public.human_input_forms USING btree (workflow_run_id, node_id);


--
-- Name: idx_credential_permissions_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_credential_permissions_account_id ON public.credential_permissions USING btree (account_id);


--
-- Name: idx_credential_permissions_credential; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_credential_permissions_credential ON public.credential_permissions USING btree (credential_id, credential_type);


--
-- Name: idx_credential_permissions_tenant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_credential_permissions_tenant_id ON public.credential_permissions USING btree (tenant_id);


--
-- Name: idx_dataset_permissions_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dataset_permissions_account_id ON public.dataset_permissions USING btree (account_id);


--
-- Name: idx_dataset_permissions_dataset_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dataset_permissions_dataset_id ON public.dataset_permissions USING btree (dataset_id);


--
-- Name: idx_dataset_permissions_tenant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dataset_permissions_tenant_id ON public.dataset_permissions USING btree (tenant_id);


--
-- Name: idx_oauth_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_account ON public.oauth_access_tokens USING btree (account_id) WHERE ((revoked_at IS NULL) AND (account_id IS NOT NULL));


--
-- Name: idx_oauth_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_client ON public.oauth_access_tokens USING btree (subject_email, client_id) WHERE (revoked_at IS NULL);


--
-- Name: idx_oauth_subject_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_subject_email ON public.oauth_access_tokens USING btree (subject_email) WHERE (revoked_at IS NULL);


--
-- Name: idx_oauth_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_token_hash ON public.oauth_access_tokens USING btree (token_hash) WHERE (revoked_at IS NULL);


--
-- Name: idx_tenant_plugin_auto_upgrade_strategy_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tenant_plugin_auto_upgrade_strategy_time ON public.tenant_plugin_auto_upgrade_strategies USING btree (upgrade_time_of_day);


--
-- Name: idx_trigger_providers_endpoint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_trigger_providers_endpoint ON public.trigger_subscriptions USING btree (endpoint_id);


--
-- Name: idx_trigger_providers_tenant_endpoint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trigger_providers_tenant_endpoint ON public.trigger_subscriptions USING btree (tenant_id, endpoint_id);


--
-- Name: idx_trigger_providers_tenant_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trigger_providers_tenant_provider ON public.trigger_subscriptions USING btree (tenant_id, provider_id);


--
-- Name: installed_app_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX installed_app_app_id_idx ON public.installed_apps USING btree (app_id);


--
-- Name: installed_app_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX installed_app_tenant_id_idx ON public.installed_apps USING btree (tenant_id);


--
-- Name: invitation_codes_batch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX invitation_codes_batch_idx ON public.invitation_codes USING btree (batch);


--
-- Name: invitation_codes_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX invitation_codes_code_idx ON public.invitation_codes USING btree (code, status);


--
-- Name: load_balancing_model_config_tenant_provider_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX load_balancing_model_config_tenant_provider_model_idx ON public.load_balancing_model_configs USING btree (tenant_id, provider_name, model_type);


--
-- Name: message_account_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_account_idx ON public.messages USING btree (app_id, from_source, from_account_id);


--
-- Name: message_agent_thought_message_chain_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_agent_thought_message_chain_id_idx ON public.message_agent_thoughts USING btree (message_chain_id);


--
-- Name: message_agent_thought_message_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_agent_thought_message_id_idx ON public.message_agent_thoughts USING btree (message_id);


--
-- Name: message_annotation_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_annotation_app_idx ON public.message_annotations USING btree (app_id);


--
-- Name: message_annotation_conversation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_annotation_conversation_idx ON public.message_annotations USING btree (conversation_id);


--
-- Name: message_annotation_message_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_annotation_message_idx ON public.message_annotations USING btree (message_id);


--
-- Name: message_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_app_id_idx ON public.messages USING btree (app_id, created_at);


--
-- Name: message_app_mode_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_app_mode_idx ON public.messages USING btree (app_mode);


--
-- Name: message_chain_message_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_chain_message_id_idx ON public.message_chains USING btree (message_id);


--
-- Name: message_conversation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_conversation_id_idx ON public.messages USING btree (conversation_id);


--
-- Name: message_created_at_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_created_at_id_idx ON public.messages USING btree (created_at, id);


--
-- Name: message_end_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_end_user_idx ON public.messages USING btree (app_id, from_source, from_end_user_id);


--
-- Name: message_feedback_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_feedback_app_idx ON public.message_feedbacks USING btree (app_id);


--
-- Name: message_feedback_conversation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_feedback_conversation_idx ON public.message_feedbacks USING btree (conversation_id, from_source, rating);


--
-- Name: message_feedback_message_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_feedback_message_idx ON public.message_feedbacks USING btree (message_id, from_source);


--
-- Name: message_file_created_by_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_file_created_by_idx ON public.message_files USING btree (created_by);


--
-- Name: message_file_message_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_file_message_idx ON public.message_files USING btree (message_id);


--
-- Name: message_workflow_run_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_workflow_run_id_idx ON public.messages USING btree (conversation_id, workflow_run_id);


--
-- Name: oauth_provider_app_client_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX oauth_provider_app_client_id_idx ON public.oauth_provider_apps USING btree (client_id);


--
-- Name: operation_log_account_action_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX operation_log_account_action_idx ON public.operation_logs USING btree (tenant_id, account_id, action);


--
-- Name: pinned_conversation_conversation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pinned_conversation_conversation_idx ON public.pinned_conversations USING btree (app_id, conversation_id, created_by_role, created_by);


--
-- Name: pipeline_customized_template_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pipeline_customized_template_tenant_idx ON public.pipeline_customized_templates USING btree (tenant_id);


--
-- Name: provider_credential_tenant_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_credential_tenant_provider_idx ON public.provider_credentials USING btree (tenant_id, provider_name);


--
-- Name: provider_model_credential_tenant_provider_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_model_credential_tenant_provider_model_idx ON public.provider_model_credentials USING btree (tenant_id, provider_name, model_name, model_type);


--
-- Name: provider_model_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_model_name_idx ON public.dataset_collection_bindings USING btree (provider_name, model_name);


--
-- Name: provider_model_setting_tenant_provider_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_model_setting_tenant_provider_model_idx ON public.provider_model_settings USING btree (tenant_id, provider_name, model_type);


--
-- Name: provider_model_tenant_id_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_model_tenant_id_provider_idx ON public.provider_models USING btree (tenant_id, provider_name);


--
-- Name: provider_order_tenant_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_order_tenant_provider_idx ON public.provider_orders USING btree (tenant_id, provider_name);


--
-- Name: provider_tenant_id_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX provider_tenant_id_provider_idx ON public.providers USING btree (tenant_id, provider_name);


--
-- Name: rate_limit_log_operation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX rate_limit_log_operation_idx ON public.rate_limit_logs USING btree (operation);


--
-- Name: rate_limit_log_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX rate_limit_log_tenant_idx ON public.rate_limit_logs USING btree (tenant_id);


--
-- Name: recommended_app_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX recommended_app_app_id_idx ON public.recommended_apps USING btree (app_id);


--
-- Name: recommended_app_is_listed_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX recommended_app_is_listed_idx ON public.recommended_apps USING btree (is_listed, language);


--
-- Name: retrieval_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX retrieval_model_idx ON public.datasets USING gin (retrieval_model);


--
-- Name: saved_message_message_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX saved_message_message_id_idx ON public.saved_messages USING btree (message_id);


--
-- Name: saved_message_message_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX saved_message_message_idx ON public.saved_messages USING btree (app_id, message_id, created_by_role, created_by);


--
-- Name: segment_attachment_binding_attachment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX segment_attachment_binding_attachment_idx ON public.segment_attachment_bindings USING btree (attachment_id);


--
-- Name: segment_attachment_binding_tenant_dataset_document_segment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX segment_attachment_binding_tenant_dataset_document_segment_idx ON public.segment_attachment_bindings USING btree (tenant_id, dataset_id, document_id, segment_id);


--
-- Name: site_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX site_app_id_idx ON public.sites USING btree (app_id);


--
-- Name: site_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX site_code_idx ON public.sites USING btree (code, status);


--
-- Name: source_binding_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX source_binding_tenant_id_idx ON public.data_source_oauth_bindings USING btree (tenant_id);


--
-- Name: source_info_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX source_info_idx ON public.data_source_oauth_bindings USING gin (source_info);


--
-- Name: tag_bind_tag_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tag_bind_tag_id_idx ON public.tag_bindings USING btree (tag_id);


--
-- Name: tag_bind_target_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tag_bind_target_id_idx ON public.tag_bindings USING btree (target_id);


--
-- Name: tag_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tag_name_idx ON public.tags USING btree (name);


--
-- Name: tag_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tag_type_idx ON public.tags USING btree (type);


--
-- Name: tenant_account_join_account_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_account_join_account_id_idx ON public.tenant_account_joins USING btree (account_id);


--
-- Name: tenant_account_join_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_account_join_tenant_id_idx ON public.tenant_account_joins USING btree (tenant_id);


--
-- Name: tenant_credit_pool_pool_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_credit_pool_pool_type_idx ON public.tenant_credit_pools USING btree (pool_type);


--
-- Name: tenant_credit_pool_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_credit_pool_tenant_id_idx ON public.tenant_credit_pools USING btree (tenant_id);


--
-- Name: tenant_default_model_tenant_id_provider_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_default_model_tenant_id_provider_type_idx ON public.tenant_default_models USING btree (tenant_id, provider_name, model_type);


--
-- Name: tenant_preferred_model_provider_tenant_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tenant_preferred_model_provider_tenant_provider_idx ON public.tenant_preferred_model_providers USING btree (tenant_id, provider_name);


--
-- Name: tidb_auth_bindings_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tidb_auth_bindings_active_idx ON public.tidb_auth_bindings USING btree (active);


--
-- Name: tidb_auth_bindings_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tidb_auth_bindings_created_at_idx ON public.tidb_auth_bindings USING btree (created_at);


--
-- Name: tidb_auth_bindings_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tidb_auth_bindings_status_idx ON public.tidb_auth_bindings USING btree (status);


--
-- Name: tidb_auth_bindings_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tidb_auth_bindings_tenant_idx ON public.tidb_auth_bindings USING btree (tenant_id);


--
-- Name: tool_file_conversation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tool_file_conversation_id_idx ON public.tool_files USING btree (conversation_id);


--
-- Name: trace_app_config_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX trace_app_config_app_id_idx ON public.trace_app_config USING btree (app_id);


--
-- Name: trial_app_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX trial_app_app_id_idx ON public.trial_apps USING btree (app_id);


--
-- Name: trial_app_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX trial_app_tenant_id_idx ON public.trial_apps USING btree (tenant_id);


--
-- Name: upload_file_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX upload_file_tenant_idx ON public.upload_files USING btree (tenant_id);


--
-- Name: uq_oauth_active_per_device; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_oauth_active_per_device ON public.oauth_access_tokens USING btree (subject_email, subject_issuer, client_id, device_label) WHERE (revoked_at IS NULL);


--
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_id_idx ON public.tool_conversation_variables USING btree (user_id);


--
-- Name: whitelists_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX whitelists_tenant_idx ON public.whitelists USING btree (tenant_id);


--
-- Name: workflow_agent_node_binding_agent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_agent_node_binding_agent_idx ON public.workflow_agent_node_bindings USING btree (tenant_id, agent_id);


--
-- Name: workflow_agent_node_binding_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_agent_node_binding_app_idx ON public.workflow_agent_node_bindings USING btree (tenant_id, app_id);


--
-- Name: workflow_agent_node_binding_current_snapshot_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_agent_node_binding_current_snapshot_idx ON public.workflow_agent_node_bindings USING btree (tenant_id, current_snapshot_id);


--
-- Name: workflow_agent_node_binding_workflow_version_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_agent_node_binding_workflow_version_idx ON public.workflow_agent_node_bindings USING btree (tenant_id, workflow_id, workflow_version);


--
-- Name: workflow_app_log_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_app_log_app_idx ON public.workflow_app_logs USING btree (tenant_id, app_id);


--
-- Name: workflow_app_log_workflow_run_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_app_log_workflow_run_id_idx ON public.workflow_app_logs USING btree (workflow_run_id);


--
-- Name: workflow_archive_log_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_archive_log_app_idx ON public.workflow_archive_logs USING btree (tenant_id, app_id);


--
-- Name: workflow_archive_log_run_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_archive_log_run_created_at_idx ON public.workflow_archive_logs USING btree (run_created_at);


--
-- Name: workflow_archive_log_workflow_run_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_archive_log_workflow_run_id_idx ON public.workflow_archive_logs USING btree (workflow_run_id);


--
-- Name: workflow_comments_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_comments_app_idx ON public.workflow_comments USING btree (tenant_id, app_id);


--
-- Name: workflow_comments_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_comments_created_at_idx ON public.workflow_comments USING btree (created_at);


--
-- Name: workflow_conversation_variables_app_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_conversation_variables_app_id_idx ON public.workflow_conversation_variables USING btree (app_id);


--
-- Name: workflow_conversation_variables_conversation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_conversation_variables_conversation_id_idx ON public.workflow_conversation_variables USING btree (conversation_id);


--
-- Name: workflow_conversation_variables_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_conversation_variables_created_at_idx ON public.workflow_conversation_variables USING btree (created_at);


--
-- Name: workflow_draft_variable_file_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_draft_variable_file_id_idx ON public.workflow_draft_variables USING btree (file_id);


--
-- Name: workflow_draft_variables_app_id_user_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX workflow_draft_variables_app_id_user_id_key ON public.workflow_draft_variables USING btree (app_id, user_id, node_id, name);


--
-- Name: workflow_node_execution_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_node_execution_id_idx ON public.workflow_node_executions USING btree (tenant_id, app_id, workflow_id, triggered_from, node_execution_id);


--
-- Name: workflow_node_execution_node_run_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_node_execution_node_run_idx ON public.workflow_node_executions USING btree (tenant_id, app_id, workflow_id, triggered_from, node_id);


--
-- Name: workflow_node_execution_workflow_run_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_node_execution_workflow_run_id_idx ON public.workflow_node_executions USING btree (workflow_run_id);


--
-- Name: workflow_node_executions_tenant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_node_executions_tenant_id_idx ON public.workflow_node_executions USING btree (tenant_id, workflow_id, node_id, created_at DESC);


--
-- Name: workflow_pause_reasons_pause_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_pause_reasons_pause_id_idx ON public.workflow_pause_reasons USING btree (pause_id);


--
-- Name: workflow_plugin_trigger_tenant_subscription_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_plugin_trigger_tenant_subscription_idx ON public.workflow_plugin_triggers USING btree (tenant_id, subscription_id, event_name);


--
-- Name: workflow_run_created_at_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_run_created_at_id_idx ON public.workflow_runs USING btree (created_at, id);


--
-- Name: workflow_run_triggerd_from_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_run_triggerd_from_idx ON public.workflow_runs USING btree (tenant_id, app_id, triggered_from);


--
-- Name: workflow_schedule_plan_next_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_schedule_plan_next_idx ON public.workflow_schedule_plans USING btree (next_run_at);


--
-- Name: workflow_trigger_log_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_trigger_log_created_at_idx ON public.workflow_trigger_logs USING btree (created_at);


--
-- Name: workflow_trigger_log_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_trigger_log_status_idx ON public.workflow_trigger_logs USING btree (status);


--
-- Name: workflow_trigger_log_tenant_app_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_trigger_log_tenant_app_idx ON public.workflow_trigger_logs USING btree (tenant_id, app_id);


--
-- Name: workflow_trigger_log_workflow_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_trigger_log_workflow_id_idx ON public.workflow_trigger_logs USING btree (workflow_id);


--
-- Name: workflow_trigger_log_workflow_run_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_trigger_log_workflow_run_idx ON public.workflow_trigger_logs USING btree (workflow_run_id);


--
-- Name: workflow_version_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_version_idx ON public.workflows USING btree (tenant_id, app_id, version);


--
-- Name: workflow_webhook_trigger_tenant_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_webhook_trigger_tenant_idx ON public.workflow_webhook_triggers USING btree (tenant_id);


--
-- Name: oauth_access_tokens fk_oauth_access_tokens_account_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_oauth_access_tokens_account_id FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: tool_published_apps tool_published_apps_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tool_published_apps
    ADD CONSTRAINT tool_published_apps_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);


--
-- Name: workflow_comment_mentions workflow_comment_mentions_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comment_mentions
    ADD CONSTRAINT workflow_comment_mentions_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.workflow_comments(id) ON DELETE CASCADE;


--
-- Name: workflow_comment_mentions workflow_comment_mentions_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comment_mentions
    ADD CONSTRAINT workflow_comment_mentions_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.workflow_comment_replies(id) ON DELETE CASCADE;


--
-- Name: workflow_comment_replies workflow_comment_replies_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_comment_replies
    ADD CONSTRAINT workflow_comment_replies_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.workflow_comments(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict xbtAtDWuSUrBeX874UkwksAfDksiaywSC6yqJWoLarJrYDNICObo1TgPtqiB7ux

