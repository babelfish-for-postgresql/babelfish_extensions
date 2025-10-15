-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.8.0'" to load this file. \quit
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

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, false) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.degrees(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.radians(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqrt(number PG_CATALOG.NUMERIC)
RETURNS sys.float
AS $$
BEGIN
    RETURN PG_CATALOG.SQRT(number::float8);
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ascii(ANYELEMENT)
RETURNS INTEGER
AS $$
DECLARE
    arg_datatype text;
    basetype oid;
BEGIN
    arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof($1)::oid);
    IF arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof($1)::oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    -- restricting arguments with invalid datatypes for ascii function
    IF arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of ascii function.', arg_datatype;
    END IF;
    
    IF arg_datatype IN ('binary', 'varbinary') THEN
        IF len($1) = 0 THEN
            RETURN NULL;
        END IF;
    ELSE
        IF length($1::TEXT) = 0 THEN
            RETURN NULL;
        END IF;
    END IF;
    RETURN pg_catalog.ascii(CAST($1 AS sys.VARCHAR));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ascii(TEXT)
RETURNS INTEGER
AS $$
BEGIN
    IF length($1) = 0 THEN
        RETURN NULL;
    END IF;
    RETURN pg_catalog.ascii(CAST($1 AS sys.VARCHAR));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    IF (SELECT count(*) FROM pg_proc as p where p.pronamespace = 'sys'::regnamespace::oid AND p.proname = 'round' AND p.pronargs = 2 AND p.proargtypes[0] = 'pg_catalog.numeric'::regtype AND p.proargtypes[1] = 'integer'::regtype AND p.prorettype = 'sys.decimal'::regtype) = 0 THEN
        ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) 
        RENAME TO bbf_numeric_round_deprecated_4_8_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_round_deprecated_4_8_0');
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
        RENAME TO bbf_numeric_trunc_deprecated_4_8_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_trunc_deprecated_4_8_0');
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

CREATE OR REPLACE VIEW sys.dm_os_sys_info 
AS SELECT 
  CAST(0 AS BIGINT) AS cpu_ticks,
  CAST(ROUND(CAST(EXTRACT(EPOCH FROM NOW()) AS NUMERIC(38,0)) * 1000.0, 0) AS BIGINT) AS ms_ticks, 
  CAST(0 AS INT) AS cpu_count,
  CAST(0 AS INT) AS hyperthread_ratio,
  CAST(0 AS BIGINT) AS physical_memory_kb,
  CAST(0 AS BIGINT) AS virtual_memory_kb,
  CAST(0 AS BIGINT) AS committed_kb,
  CAST(0 AS BIGINT) AS committed_target_kb,
  CAST(0 AS BIGINT) AS visible_target_kb,
  CAST(0 AS INT) AS stack_size_in_bytes,
  CAST(0 AS BIGINT) AS os_quantum,
  CAST(0 AS INT) AS os_error_mode,
  CAST(0 AS INT) AS os_priority_class,
  CAST(0 AS INT) AS max_workers_count,
  CAST(0 AS INT) AS scheduler_count,
  CAST(0 AS INT) AS scheduler_total_count,
  CAST(0 AS INT) AS deadlock_monitor_serial_number,
  CAST(ROUND(CAST(EXTRACT(EPOCH FROM pg_postmaster_start_time()) AS NUMERIC(38,0)) * 1000.0, 0) AS BIGINT) AS sqlserver_start_time_ms_ticks, 
  CAST(pg_postmaster_start_time() AS sys.DATETIME) AS sqlserver_start_time,
  CAST(0 AS INT) AS affinity_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS affinity_type_desc,
  CAST(0 AS BIGINT) AS process_kernel_time_ms,
  CAST(0 AS BIGINT) AS process_user_time_ms,
  CAST(0 AS INT) AS time_source,
  CAST(NULL AS sys.NVARCHAR(60)) AS time_source_desc,
  CAST(0 AS INT) AS virtual_machine_type,
  CAST('NONE' AS sys.NVARCHAR(60)) AS virtual_machine_type_desc,
  CAST(0 AS INT) AS softnuma_configuration,
  CAST('OFF' AS sys.NVARCHAR(60)) AS softnuma_configuration_desc,
  CAST(NULL AS sys.NVARCHAR(3072)) AS process_physical_affinity,
  CAST(0 AS INT) AS sql_memory_model,
  CAST(NULL AS sys.NVARCHAR(60)) AS sql_memory_model_desc,
  CAST(0 AS INT) AS socket_count,
  CAST(0 AS INT) AS cores_per_socket,
  CAST(0 AS INT) AS numa_node_count,
  CAST(0 AS INT) AS container_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS container_type_desc;
GRANT SELECT ON sys.dm_os_sys_info TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);