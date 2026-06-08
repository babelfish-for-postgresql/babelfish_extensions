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

CREATE OR REPLACE FUNCTION sys.DATETRUNC(IN datepart PG_CATALOG.TEXT, IN date ANYELEMENT) RETURNS ANYELEMENT AS
$body$
DECLARE
    days_offset INT;
    v_day INT;
    result_date timestamp;
    input_expr_timestamp timestamp;
    date_arg_datatype regtype;
    offset_string PG_CATALOG.TEXT;
    datefirst_value INT;
BEGIN
    BEGIN
        /* perform input validation */
        date_arg_datatype := pg_typeof(date);
        IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'tsql_week', 'hour', 'minute', 'second', 'millisecond', 'microsecond', 
                            'doy', 'day', 'nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION '''%'' is not a recognized datetrunc option.', datepart;
        ELSIF date_arg_datatype NOT IN ('date'::regtype, 'time'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype,
                                        'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype) THEN
            RAISE EXCEPTION 'Argument data type ''%'' is invalid for argument 2 of datetrunc function.', date_arg_datatype;
        ELSIF datepart IN ('nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''%''.',datepart, date_arg_datatype;
        ELSIF datepart IN ('dow') THEN
            RAISE EXCEPTION 'The datepart ''weekday'' is not supported by date function datetrunc for data type ''%''.', date_arg_datatype;
        ELSIF date_arg_datatype = 'date'::regtype AND datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''date''.', datepart;
        ELSIF date_arg_datatype = 'sys.datetime'::regtype AND datepart IN ('microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''datetime''.', datepart;
        ELSIF date_arg_datatype = 'sys.smalldatetime'::regtype AND datepart IN ('millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''smalldatetime''.', datepart;
        ELSIF date_arg_datatype = 'time'::regtype THEN
            IF datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'tsql_week') THEN
                RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''time''.', datepart;
            END IF;
            -- Limitation in determining if the specified fractional scale (if provided any) for time datatype is 
            -- insufficient to support provided datepart (millisecond, microsecond) value
        ELSIF date_arg_datatype IN ('sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype) THEN
            -- Limitation in determining if the specified fractional scale (if provided any) for the above datatype is
            -- insufficient to support for provided datepart (millisecond, microsecond) value
        END IF;

        /* input validation is complete, proceed with result calculation. */
        IF date_arg_datatype = 'time'::regtype THEN
            RETURN date_trunc(datepart, date);
        ELSE
            input_expr_timestamp = date::timestamp;
            -- preserving offset_string value in the case of datetimeoffset datatype before converting it to timestamps 
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                offset_string = PG_CATALOG.RIGHT(date::PG_CATALOG.TEXT, 6);
                input_expr_timestamp := PG_CATALOG.LEFT(date::PG_CATALOG.TEXT, -6)::timestamp;
            END IF;
            CASE
                WHEN datepart IN ('year', 'quarter', 'month', 'week', 'hour', 'minute', 'second', 'millisecond', 'microsecond')  THEN
                    result_date := date_trunc(datepart, input_expr_timestamp);
                WHEN datepart IN ('doy', 'day') THEN
                    result_date := date_trunc('day', input_expr_timestamp);
                WHEN datepart IN ('tsql_week') THEN
                -- sql server datepart 'iso_week' is similar to postgres 'week' datepart
                -- handle sql server datepart 'week' here based on the value of set variable 'DATEFIRST'
                    v_day := EXTRACT(dow from input_expr_timestamp)::INT;
                    datefirst_value := current_setting('babelfishpg_tsql.datefirst')::INT;
                    IF v_day = 0 THEN
                        v_day := 7;
                    END IF;
                    result_date := date_trunc('day', input_expr_timestamp);
                    days_offset := (7 + v_day - datefirst_value)%7;
                    result_date := result_date - make_interval(days => days_offset);
            END CASE;
            -- concat offset_string to result_date in case of datetimeoffset before converting it to datetimeoffset datatype.
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                RETURN PG_CATALOG.concat(result_date, ' ', offset_string)::sys.datetimeoffset;
            ELSE
                RETURN result_date;
            END IF;
        END IF;
    END;
END;
$body$
LANGUAGE plpgsql STABLE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
