-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.4.0'" to load this file. \quit
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

-- Binary conversion helper functions
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg anyelement,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_binary(typmod, arg, p_style);
    ELSE
        IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
            RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
        ELSE
            IF typmod = -1 THEN
                RETURN CAST(arg as sys.binary);
            ELSE
                EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
                RETURN result;
            END IF;
        END IF;
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg sys.VARCHAR,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_binary(arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_binary(IN arg sys.VARCHAR,
                                                                   IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_binary(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
        RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
    ELSE
        IF typmod = -1 THEN
            RETURN CAST(arg as sys.binary);
        ELSE
            EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
            RETURN result;
        END IF;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_binary(IN input_value sys.VARCHAR, IN style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE
    result bytea;
BEGIN
    IF style = 0 THEN
        RETURN CAST(input_value AS sys.binary);
    ELSIF style = 1 THEN
        IF (PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" AND PG_CATALOG.length(input_value) % 2 = 0) THEN
            result := decode(substring(input_value from 3), 'hex');
        ELSE
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        END IF;
    ELSIF style = 2 THEN
        IF PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" THEN
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        ELSE
            result := decode(input_value, 'hex');
        END IF;
    ELSE
        RAISE EXCEPTION 'The style % is not supported for conversions from varchar to binary.', style;
    END IF;

    RETURN CAST(result AS sys.binary);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
STRICT;

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

CREATE OR REPLACE VIEW sys.servers
AS
SELECT
    CAST(f.oid as int) AS server_id,
    CAST(f.srvname as sys.sysname) AS name,
    CAST('' as sys.sysname) AS product,
    CAST('tds_fdw' as sys.sysname) AS provider,
    CAST((select PG_CATALOG.string_agg(
                                    case
                                    when option like 'servername=%%' then substring(option, 12)
                                    else NULL
                                    end, ',')
                    from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
    CAST(NULL as sys.nvarchar(4000)) AS location,
    CAST(NULL as sys.nvarchar(4000)) AS provider_string,
    CAST((select PG_CATALOG.string_agg(
                                    case
                                    when option like 'database=%%' then substring(option, 10)
                                    else NULL
                                    end, ',')
                    from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
    CAST(d.connect_timeout as int) AS connect_timeout,
    CAST(d.query_timeout as int) AS query_timeout,
    CAST(1 as sys.bit) AS is_linked,
    CAST(0 as sys.bit) AS is_remote_login_enabled,
    CAST(d.rpc_out_enabled as sys.bit) AS is_rpc_out_enabled,
    CAST(1 as sys.bit) AS is_data_access_enabled,
    CAST(0 as sys.bit) AS is_collation_compatible,
    CAST(1 as sys.bit) AS uses_remote_collation,
    CAST(NULL as sys.sysname) AS collation_name,
    CAST(0 as sys.bit) AS lazy_schema_validation,
    CAST(0 as sys.bit) AS is_system,
    CAST(0 as sys.bit) AS is_publisher,
    CAST(0 as sys.bit) AS is_subscriber,
    CAST(0 as sys.bit) AS is_distributor,
    CAST(0 as sys.bit) AS is_nonsql_subscriber,
    CAST(1 as sys.bit) AS is_remote_proc_transaction_promotion_enabled,
    CAST(NULL as sys.datetime) AS modify_date,
    CAST(0 as sys.bit) AS is_rda_server
FROM pg_foreign_server AS f
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
LEFT JOIN pg_dblink AS l ON l.dblserver = f.oid
LEFT JOIN LATERAL
(
    SELECT COALESCE(MAX(CASE
                                                WHEN o.option_name = 'connect_timeout' THEN o.option_value::int
                                                ELSE NULL
                                            END), 0) AS connect_timeout,
                 COALESCE(MAX(CASE
                                                WHEN o.option_name = 'query_timeout' THEN o.option_value::int
                                                ELSE NULL
                                            END), 0) AS query_timeout,
                 COALESCE(MAX(CASE
                                                WHEN o.option_name = 'rpc out' AND pg_catalog.lower(o.option_value) = 'true' THEN 1
                                                ELSE NULL
                                            END), 0) AS rpc_out_enabled
        FROM pg_catalog.pg_options_to_table(COALESCE(l.dbloptions, ARRAY[]::text[])) AS o
) AS d ON true
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

CALL babelfish_drop_deprecated_object('table', 'sys', 'babelfish_server_options');

CREATE OR REPLACE FUNCTION sys.sqrt(number PG_CATALOG.NUMERIC)
RETURNS sys.float
AS $$
BEGIN
    RETURN PG_CATALOG.SQRT(number::float8);
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_xmlvalue(xpath_pattern TEXT, datatype TEXT, xml_element ANYELEMENT)
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
        -- for User Defined Datatype, use immediate base type to check for xml_element datatype validation
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

    result_set := xpath(xpath_pattern, xml_element);
    IF (cardinality(result_set) > 1) THEN
        RAISE EXCEPTION 'XML Value result is not a single value.';
    ELSIF (cardinality(result_set) = 0) THEN
        RETURN NULL;
    ELSE
        result := (xpath('string(' + xpath_pattern + ')', xml_element))[1];
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_sp_xml_preparedocument RENAME TO babelfish_sp_xml_preparedocument_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_sp_xml_preparedocument_deprecated_in_5_4_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_sp_xml_removedocument RENAME TO babelfish_sp_xml_removedocument_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_sp_xml_removedocument_deprecated_in_5_4_0');

CREATE OR REPLACE PROCEDURE sys.sp_xml_preparedocument(
    INOUT "@hdoc"  INTEGER,                 
    IN "@xmltext" XML DEFAULT NULL,    
    IN "@xpath_namespaces" XML DEFAULT NULL 
) 
AS 'babelfishpg_tsql', 'sp_xml_preparedocument'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_xml_preparedocument(
	INOUT INTEGER, IN XML, IN XML
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_xml_removedocument(
    IN "@hdoc" INTEGER
) 
AS 'babelfishpg_tsql', 'sp_xml_removedocument'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_xml_removedocument(
	IN INTEGER
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_openxml_get_xmldoc(int)
RETURNS xml
AS 'babelfishpg_tsql', 'tsql_openxml_get_xmldoc'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_openxml_get_colpattern(text,int)
RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'tsql_openxml_get_colpattern'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.openxml_simple(document_id INT, 
                                       rowpattern TEXT, 
                                       flags INTEGER DEFAULT 0)
RETURNS table (
  id sys.BIGINT,
  parentid sys.BIGINT,
  nodetype sys.INT,
  localname sys.NVARCHAR,
  prefix sys.NVARCHAR,
  namespaceuri sys.NVARCHAR,
  datatype sys.NVARCHAR,
  prev sys.BIGINT,
  text sys.NTEXT
) 
AS 'babelfishpg_tsql', 'openxml_simple'
LANGUAGE C IMMUTABLE;

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
    ALTER FUNCTION sys.babelfish_openxml RENAME TO babelfish_openxml_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_openxml_deprecated_in_5_4_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    IF (SELECT count(*) FROM pg_proc as p where p.pronamespace = 'sys'::regnamespace::oid AND p.proname = 'round' AND p.pronargs = 2 AND p.proargtypes[0] = 'pg_catalog.numeric'::regtype AND p.proargtypes[1] = 'integer'::regtype AND p.prorettype = 'sys.decimal'::regtype) = 0 THEN
        ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) 
        RENAME TO bbf_numeric_round_deprecated_5_4_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_round_deprecated_5_4_0');
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
        RENAME TO bbf_numeric_trunc_deprecated_5_4_0;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_trunc_deprecated_5_4_0');
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

create or replace function sys.pltsql_timezone_mapping_pg_to_windows(IN tmz text) returns text
AS 'babelfishpg_tsql', 'pltsql_timezone_mapping_pg_to_windows'
LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE VIEW sys.time_zone_info AS
SELECT 
    -- Mapping PostgreSQL timezone names to Windows format names
    CAST(pg_catalog.initcap(sys.pltsql_timezone_mapping_pg_to_windows(name)) AS sys.nvarchar(128))
    AS name,
    CAST(
      CASE 
          WHEN utc_offset < INTERVAL '00:00:00' THEN 
              '-' || pg_catalog.RIGHT('0' || CAST(pg_catalog.ABS(EXTRACT(HOUR FROM utc_offset)) AS VARCHAR(2)), 2) || ':' ||
              pg_catalog.RIGHT('0' || CAST(pg_catalog.ABS(EXTRACT(MINUTE FROM utc_offset)) AS VARCHAR(2)), 2)
          ELSE 
              '+' || pg_catalog.RIGHT('0' || CAST(EXTRACT(HOUR FROM utc_offset) AS VARCHAR(2)), 2) || ':' || 
              pg_catalog.RIGHT('0' || CAST(EXTRACT(MINUTE FROM utc_offset) AS VARCHAR(2)), 2)
      END AS sys.NVARCHAR(12)
    ) AS current_utc_offset,
    -- Converting boolean is_dst to bit (0/1)
    CAST(
        CASE 
            WHEN is_dst = true THEN 1
            ELSE 0
        END AS sys.BIT
    ) AS is_currently_dst
FROM pg_catalog.pg_timezone_names
WHERE sys.pltsql_timezone_mapping_pg_to_windows(name) IS NOT NULL
ORDER BY name;
GRANT SELECT ON sys.time_zone_info TO PUBLIC;
