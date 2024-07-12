-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.6.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Rename functions for dependencies
DO $$
DECLARE
  exception_message text;
BEGIN
  -- Rename REPLICATE for dependencies
  ALTER FUNCTION sys.REPLICATE(TEXT, INTEGER) RENAME TO replicate_deprecated_in_3_7_0_0;

EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;

-- wrapper functions for replicate
CREATE OR REPLACE FUNCTION sys.replicate(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := (SELECT typbasetype FROM pg_type WHERE oid = pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for replicate function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of replicate function.', string_arg_datatype;
    END IF;

    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.BPCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.VARCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that replicate with text input
-- will use following definition instead of PG replicate
CREATE OR REPLACE FUNCTION sys.replicate(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that replicate with ntext input
-- will use following definition instead of PG replicate
CREATE OR REPLACE FUNCTION sys.replicate(string NTEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- DROP deprecated function of replicate (if exists)
DO $$
DECLARE
    exception_message text;
BEGIN
    -- DROP replicate_deprecated_in_3_7_0_0
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'replicate_deprecated_in_3_7_0_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
