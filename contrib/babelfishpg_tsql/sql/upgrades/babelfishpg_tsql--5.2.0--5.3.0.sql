-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.3.0'" to load this file. \quit
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.fn_varbintohexsubstring RENAME TO fn_varbintohexsubstring_deprecated_in_5_3_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_varbintohexsubstring_deprecated_in_5_3_0');

CREATE OR REPLACE FUNCTION sys.fn_varbintohexsubstring(set_prefix sys.BIT, expression sys.varbinary, start_offset INT, substr_length INT)
RETURNS sys.nvarchar AS 
$$ 
DECLARE 
    pstrout sys.nvarchar;
    hex_str text;
BEGIN 
    IF expression IS NULL THEN 
        RETURN NULL;
    END IF;

    IF substr_length IS NULL OR substr_length <= 0 OR substr_length > sys.LEN(expression) THEN 
        substr_length := sys.LEN(expression);
    END IF;

    IF start_offset IS NULL OR start_offset < 1 OR start_offset > sys.LEN(expression) THEN 
        RETURN NULL;
    END IF;

    IF (sys.LEN(expression) - start_offset + 1) < substr_length THEN 
        substr_length := sys.LEN(expression) - start_offset + 1;
    END IF;

    hex_str := sys.LOWER(pg_catalog.ENCODE(sys.SUBSTRING(expression, start_offset, substr_length)::bytea, 'hex'));
    
    pstrout := CASE 
                WHEN set_prefix IS NULL THEN N''
                WHEN set_prefix = 0 THEN N'' 
                ELSE N'0x' 
               END || hex_str;
    RETURN pstrout;
END;
$$ 
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE VIEW sys.server_permissions AS 
WITH super_user AS (SELECT datdba AS super_user FROM pg_database WHERE datname = CURRENT_DATABASE()) 
SELECT 
CAST(100 AS sys.tinyint) AS class,
CAST('SERVER' AS sys.nvarchar(60)) AS class_desc,
CAST(0 AS int) AS major_id,
CAST(0 AS int) AS minor_id,
CAST(Base.oid AS INT) AS grantee_principal_id,
CAST((SELECT super_user FROM super_user) AS INT) AS grantor_principal_id,
CAST('COSQ' AS sys.BPCHAR(4)) AS type,
CAST('CONNECT SQL' AS sys.nvarchar(128)) AS permission_name,
CAST('G' AS sys.BPCHAR(1)) AS state,
CAST('GRANT' AS sys.nvarchar(60)) AS state_desc 
FROM pg_catalog.pg_roles AS Base 
INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname 
WHERE(pg_has_role(sys.suser_id(), 'sysadmin'::TEXT, 'MEMBER')
  OR pg_has_role(sys.suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Base.rolname = sys.suser_name() COLLATE sys.database_default 
  OR Base.rolname = (SELECT pg_get_userbyid(super_user) FROM super_user))
  AND Ext.type IN ('S', 'U') 
UNION ALL 
SELECT 
CAST(105 AS sys.tinyint) AS class,
CAST('ENDPOINT' AS sys.nvarchar(60)) AS class_desc,
CAST(4 AS int) AS major_id,
CAST(0 AS int) AS minor_id,
CAST(2 AS INT) AS grantee_principal_id,
CAST((SELECT super_user FROM super_user) AS INT) AS grantor_principal_id,
CAST('CO' AS sys.BPCHAR(4)) AS type,
CAST('CONNECT' AS sys.nvarchar(128)) AS permission_name,
CAST('G' AS sys.BPCHAR(1)) AS state,
CAST('GRANT' AS sys.nvarchar(60)) AS state_desc;
GRANT SELECT ON sys.server_permissions TO PUBLIC;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER VIEW sys.sql_logins RENAME TO sql_logins_deprecated_in_5_3_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sql_logins_deprecated_in_5_3_0');

CREATE OR REPLACE VIEW sys.sql_logins AS 
WITH super_user AS (SELECT pg_get_userbyid(datdba) COLLATE sys.database_default AS super_user FROM pg_database WHERE datname = CURRENT_DATABASE())
SELECT
  CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
  CAST(Base.oid AS INT) AS principal_id,
  CAST(CAST(Base.oid AS INT) AS sys.varbinary(85)) AS sid,
  CAST('S' AS sys.BPCHAR(1)) AS type,
  CAST('SQL_LOGIN' AS sys.NVARCHAR(60)) AS type_desc,
  CAST(Ext.is_disabled AS INT) AS is_disabled,
  CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
  CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
  CAST(Ext.default_database_name AS SYS.SYSNAME) AS default_database_name,
  CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
  CAST(Ext.credential_id AS INT) AS credential_id,
  CAST(
    CASE
      WHEN Ext.orig_loginname = (SELECT super_user FROM super_user) THEN 0
      ELSE 1
    END
  AS sys.BIT) AS is_policy_checked,
  CAST(0 AS sys.BIT) AS is_expiration_checked,
  CAST(NULL AS sys.varbinary(256)) AS password_hash 
FROM pg_catalog.pg_roles AS Base 
INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname 
WHERE(pg_has_role(sys.suser_id(), 'sysadmin'::TEXT, 'MEMBER')
  OR pg_has_role(sys.suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Ext.orig_loginname = sys.suser_name()
  OR Ext.orig_loginname = (SELECT super_user FROM super_user))
  AND Ext.type = 'S';
GRANT SELECT ON sys.sql_logins TO PUBLIC;

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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
