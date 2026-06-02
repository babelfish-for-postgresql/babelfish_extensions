-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '6.2.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar, arg_types varchar DEFAULT '') AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
    full_object_name text;
BEGIN
    -- Construct full object name with argument types if provided (for aggregates)
    IF arg_types <> '' THEN
        full_object_name := pg_catalog.format('%s.%s(%s)', schema_name, object_name, arg_types);
    ELSE
        full_object_name := pg_catalog.format('%s.%s', schema_name, object_name);
    END IF;

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', object_type, full_object_name);
    query2 := pg_catalog.format('drop %s %s', object_type, full_object_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when undefined_function then --if 'Deprecated function does not exist'
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

DO
LANGUAGE plpgsql
$$
BEGIN
    -- Check if the GUC is empty
    IF current_setting('babelfishpg_tsql.restored_server_collation_name', true) <> '' THEN
        -- Call the function to update the collation
        EXECUTE 'SELECT sys.babelfish_update_server_collation_name()';
    END IF;
END;
$$;

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- reset babelfishpg_tsql.restored_server_collation_name GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
    end;
$$;

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(
    id INT,
    property SYS.VARCHAR
)
RETURNS SYS.SQL_VARIANT AS
'babelfishpg_tsql', 'objectpropertyex_internal'
LANGUAGE C STABLE;

-- BABELFISH_FUNCTION_EXT (antlr_parse_cache)
SET allow_system_table_mods = on;
ALTER TABLE sys.babelfish_function_ext ADD COLUMN IF NOT EXISTS antlr_parse_cache_tree TEXT DEFAULT NULL;
ALTER TABLE sys.babelfish_function_ext ADD COLUMN IF NOT EXISTS antlr_parse_cache_datums TEXT DEFAULT NULL;
ALTER TABLE sys.babelfish_function_ext ADD COLUMN IF NOT EXISTS antlr_parse_cache_bbf_version TEXT DEFAULT NULL;
ALTER TABLE sys.babelfish_function_ext ADD COLUMN IF NOT EXISTS antlr_parse_cache_enabled BOOL DEFAULT NULL;
RESET allow_system_table_mods;

CREATE OR REPLACE FUNCTION sys.enable_antlr_parse_cache(
    IN routine_id OID,
    IN use_antlr_parse_cache BOOLEAN
) RETURNS BOOLEAN
AS 'babelfishpg_tsql', 'enable_antlr_parse_cache'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

CREATE OR REPLACE FUNCTION sys.antlr_parse_cache_stats(
    OUT cache_hits INT,
    OUT cache_misses INT,
    OUT cache_writes INT,
    OUT cache_evictions INT,
    OUT cache_errors INT
) RETURNS RECORD
AS 'babelfishpg_tsql', 'antlr_parse_cache_stats'
LANGUAGE C VOLATILE PARALLEL RESTRICTED;

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Upgrade FOR XML aggregates from 7 args to 8 args (add auto_metadata)

-- Deprecate and drop old aggregate (7 args) - tsql_select_for_xml_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_agg(anyelement, integer, text, boolean, text, boolean, boolean)
    RENAME TO tsql_select_for_xml_agg_deprecated_in_6_2_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_agg_deprecated_in_5_7_0', 'anyelement, integer, text, boolean, text, boolean, boolean');

-- Deprecate and drop old aggregate (7 args) - tsql_select_for_xml_text_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_text_agg(anyelement, integer, text, boolean, text, boolean, boolean)
    RENAME TO tsql_select_for_xml_text_agg_deprecated_in_6_2_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_text_agg_deprecated_in_5_7_0', 'anyelement, integer, text, boolean, text, boolean, boolean');

-- Deprecate and drop old function (8 args: state + 7 args) - after aggregates are gone
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.tsql_query_to_xml_sfunc(internal, anyelement, integer, text, boolean, text, boolean, boolean)
    RENAME TO tsql_query_to_xml_sfunc_deprecated_in_6_2_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_sfunc_deprecated_in_5_7_0');

-- Create new function with auto_metadata parameter (9 args: state + 8 args)
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

-- Create new aggregate with auto_metadata parameter (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

-- Create new aggregate with auto_metadata parameter (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
