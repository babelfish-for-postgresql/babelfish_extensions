-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.5.0'" to load this file. \quit
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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
DO $$
DECLARE
    exception_message text;
BEGIN
    IF (SELECT count(*) FROM pg_proc as p where p.pronamespace = 'sys'::regnamespace::oid AND p.proname = 'round' AND p.pronargs = 2 AND p.proargtypes[0] = 'pg_catalog.numeric'::regtype AND p.proargtypes[1] = 'integer'::regtype AND p.prorettype = 'sys.decimal'::regtype) = 0 THEN
        ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) 
        RENAME TO bbf_numeric_round_deprecated_5_5_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_round_deprecated_5_5_0');
    END IF;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

DO $$
DECLARE
    exception_message text;
BEGIN
    IF (SELECT count(*) FROM pg_proc as p where p.pronamespace = 'sys'::regnamespace::oid AND p.proname = 'round' AND p.pronargs = 3 AND p.proargtypes[0] = 'pg_catalog.numeric'::regtype AND p.proargtypes[1] = 'integer'::regtype AND p.proargtypes[2] = 'integer'::regtype AND p.prorettype = 'sys.decimal'::regtype) = 0 THEN
        ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) 
        RENAME TO bbf_numeric_trunc_deprecated_5_5_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_trunc_deprecated_5_5_0');
    END IF;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER) TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
