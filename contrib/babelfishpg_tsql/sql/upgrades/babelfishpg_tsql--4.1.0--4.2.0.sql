-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.2.0'" to load this file. \quit

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

-- helper functions for upper and lower --
CREATE OR REPLACE FUNCTION sys.upper_helper(sys.VARCHAR)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_upper' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.lower_helper(sys.VARCHAR)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_lower' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- upper --
CREATE OR REPLACE FUNCTION sys.upper(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    varch sys.varchar;
BEGIN
    IF pg_typeof($1) IN ('image'::regtype, 'sql_variant'::regtype, 'xml'::regtype, 'geometry'::regtype, 'geography'::regtype) THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of upper function.', pg_typeof($1);
    END IF;
    varch := (SELECT CAST ($1 AS sys.varchar));
    -- Call the underlying function after preprocessing
    RETURN (SELECT sys.upper_helper(varch));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NCHAR)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_upper' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_upper' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- lower --
CREATE OR REPLACE FUNCTION sys.lower(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    varch sys.varchar;
BEGIN
    IF pg_typeof($1) IN ('image'::regtype, 'sql_variant'::regtype, 'xml'::regtype, 'geometry'::regtype, 'geography'::regtype) THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of upper function.', pg_typeof($1);
    END IF;
    varch := (SELECT CAST ($1 AS sys.varchar));
    -- Call the underlying function after preprocessing
    RETURN (SELECT sys.lower_helper(varch));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NCHAR)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_lower' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_lower' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
