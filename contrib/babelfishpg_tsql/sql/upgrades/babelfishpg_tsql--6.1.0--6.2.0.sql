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


CREATE OR REPLACE VIEW sys.all_sql_modules AS
WITH all_sql_modules_cte AS MATERIALIZED (
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
)
SELECT * FROM all_sql_modules_cte;
GRANT SELECT ON sys.all_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.system_sql_modules AS
WITH system_sql_modules_cte AS MATERIALIZED ( 
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 1
)
SELECT * FROM system_sql_modules_cte;
GRANT SELECT ON sys.system_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.sql_modules AS
WITH sql_modules_cte AS MATERIALIZED (
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 0
)
SELECT * FROM sql_modules_cte;
GRANT SELECT ON sys.sql_modules TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
