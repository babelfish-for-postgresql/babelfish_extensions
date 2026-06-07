-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.7.0'" to load this file. \quit
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

-- helper function for XML QUERY(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlquery(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS XML
AS 'babelfishpg_tsql', 'bbf_xmlquery'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

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
    RENAME TO tsql_select_for_xml_agg_deprecated_in_5_7_0;
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
    RENAME TO tsql_select_for_xml_text_agg_deprecated_in_5_7_0;
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
    RENAME TO tsql_query_to_xml_sfunc_deprecated_in_5_7_0;
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

-- WITH XMLNAMESPACES support: extend FOR XML aggregate to carry namespace declarations
-- and add namespace-aware overloads for XML data type methods.
--
-- The previous block above already migrated the aggregate from 7 args (legacy) to
-- 8 args (adding auto_metadata for FOR XML AUTO). We now drop those 8-arg
-- definitions and recreate at 9 args (adding ns_decls for WITH XMLNAMESPACES),
-- so the final shape matches sys_functions.sql.
CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_agg', 'ANYELEMENT, int, text, boolean, text, boolean, boolean, text');
CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_text_agg', 'ANYELEMENT, int, text, boolean, text, boolean, boolean, text');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_sfunc', 'INTERNAL, ANYELEMENT, int, text, boolean, text, boolean, boolean, text');

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text,
    ns_decls text
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text,
    ns_decls text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean,
    auto_metadata text,
    ns_decls text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

-- helper function for XML QUERY(xpath) with namespace support
CREATE OR REPLACE FUNCTION sys.bbf_xmlquery(xpath_pattern TEXT, xml_element ANYELEMENT, nsarray TEXT[][])
RETURNS XML
AS 'babelfishpg_tsql', 'bbf_xmlquery_ns'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

-- helper function for XML EXIST(xpath) with namespace support
CREATE OR REPLACE FUNCTION sys.bbf_xmlexist(xpath_pattern TEXT, xml_element ANYELEMENT, nsarray TEXT[][])
RETURNS sys.BIT
AS
$BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
    pltsql_quoted_identifier text;
BEGIN
    arg_datatype_oid := pg_typeof(xml_element)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    IF (arg_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', arg_datatype;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;

    RETURN (cardinality(xpath(xpath_pattern, xml_element, nsarray)) > 0)::int::sys.BIT;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- helper function for XML VALUE(xpath) with namespace support
CREATE OR REPLACE FUNCTION sys.bbf_xmlvalue(xpath_pattern TEXT, datatype TEXT, xml_element ANYELEMENT, nsarray TEXT[][])
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    temp_datatype text;
    temp_basetype oid;
    result_set xml[];
    result sys.NVARCHAR;
    pltsql_quoted_identifier text;
BEGIN
    temp_datatype := sys.translate_pg_type_to_tsql(pg_typeof(xml_element)::oid);
    IF temp_datatype IS NULL THEN
        temp_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(xml_element)::oid);
        temp_datatype := sys.translate_pg_type_to_tsql(temp_basetype);
    END IF;

    IF (temp_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', temp_datatype;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;

    result_set := xpath(xpath_pattern, xml_element, nsarray);
    IF (cardinality(result_set) > 1) THEN
        RAISE EXCEPTION 'XML Value result is not a single value.';
    ELSIF (cardinality(result_set) = 0) THEN
        RETURN NULL;
    ELSE
        result := (xpath('string(' || xpath_pattern || ')', xml_element, nsarray))[1];
        result := pg_catalog.replace(result, '&lt;', '<');
        result := pg_catalog.replace(result, '&gt;', '>');
        result := pg_catalog.replace(result, '&apos;', '''');
        result := pg_catalog.replace(result, '&quot;', '"');
        result := pg_catalog.replace(result, '&amp;', '&');
        return result;
    END IF;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
