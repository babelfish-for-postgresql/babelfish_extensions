-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.7.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- This is a temporary procedure which is called during upgrade to update guest schema
-- for the guest users in the already existing databases
CREATE OR REPLACE PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema()
LANGUAGE C
AS 'babelfishpg_tsql', 'update_user_catalog_for_guest_schema';

CALL sys.babelfish_update_user_catalog_for_guest_schema();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema();

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

DO $$
DECLARE
    exception_message text;
BEGIN

    ALTER FUNCTION sys.datepart_internal(PG_CATALOG.TEXT, anyelement, INTEGER) RENAME TO datepart_internal_deprecated_3_5;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.BIT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_int'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.TINYINT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_int'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date SMALLINT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_int'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_int'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date BIGINT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_int'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.MONEY ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_money'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.SMALLMONEY ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_money'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date date ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_date'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.datetime ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_datetime'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.datetime2 ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_datetime'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.smalldatetime ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_datetime'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.DATETIMEOFFSET ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_datetimeoffset'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date time ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_time'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INTERVAL ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_interval'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.DECIMAL ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_decimal'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date NUMERIC ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_decimal'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date REAL ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_real'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

    CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date FLOAT ,df_tz INTEGER DEFAULT 0)
    RETURNS INTEGER
    AS 'babelfishpg_tsql', 'datepart_internal_float'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

     CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datepart_internal_deprecated_3_5');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
	JOIN information_schema_tsql.columns t4 ON (cast(t1.relname as sys.nvarchar(128)) = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA" )
	JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	, generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = sys.db_id();


-- Delete orphan entries in babelfish view definition system catalog
-- We delete the entry if the view does not exists in pg_class or the
-- schema as whole does not exists
DO $$
DECLARE
    r RECORD;
    nsp_oid OID;
    nsp_name NAME;
BEGIN
    FOR r IN 
        SELECT * FROM sys.babelfish_view_def
    LOOP
        SELECT nspname INTO nsp_name FROM sys.babelfish_namespace_ext AS a WHERE a.orig_name = r.schema_name AND a.dbid = r.dbid;
        SELECT oid INTO nsp_oid FROM sys.pg_namespace_ext as b WHERE b.nspname = nsp_name;
        IF((SELECT COUNT(*) FROM pg_class WHERE pg_class.relnamespace = nsp_oid AND CAST(pg_class.relname AS sys.SYSNAME) = r.object_name AND pg_class.relkind = 'v') = 0) THEN
            DELETE FROM ONLY sys.babelfish_view_def AS c WHERE c.dbid = r.dbid AND c.schema_name = r.schema_name AND c.object_name = r.object_name;
        END IF;        
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error while dropping orphan entries in system catalog sys.babelfish_view_def';
END $$
LANGUAGE plpgsql;

DO $$
BEGIN
    ALTER TABLE sys.babelfish_view_def DROP CONSTRAINT babelfish_view_def_pkey;
    ALTER TABLE sys.babelfish_view_def ADD PRIMARY KEY (dbid, schema_name, object_name);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to recreate primary key for system catalog sys.babelfish_view_def';
END $$;

-- Update existing logins to remove createrole privilege
CREATE OR REPLACE PROCEDURE sys.bbf_remove_createrole_from_logins()
LANGUAGE C
AS 'babelfishpg_tsql', 'remove_createrole_from_logins';
CALL sys.bbf_remove_createrole_from_logins();

CREATE OR REPLACE VIEW sys.availability_replicas 
AS SELECT  
    CAST(NULL as sys.UNIQUEIDENTIFIER) AS replica_id
    , CAST(NULL as sys.UNIQUEIDENTIFIER) AS group_id
    , CAST(0 as INT) AS replica_metadata_id
    , CAST(NULL as sys.NVARCHAR(256)) AS replica_server_name
    , CAST(NULL as sys.VARBINARY(85)) AS owner_sid
    , CAST(NULL as sys.NVARCHAR(128)) AS endpoint_url
    , CAST(0 as sys.TINYINT) AS availability_mode
    , CAST(NULL as sys.NVARCHAR(60)) AS availability_mode_desc
    , CAST(0 as sys.TINYINT) AS failover_mode
    , CAST(NULL as sys.NVARCHAR(60)) AS failover_mode_desc
    , CAST(0 as INT) AS session_timeout
    , CAST(0 as sys.TINYINT) AS primary_role_allow_connections
    , CAST(NULL as sys.NVARCHAR(60)) AS primary_role_allow_connections_desc
    , CAST(0 as sys.TINYINT) AS secondary_role_allow_connections
    , CAST(NULL as sys.NVARCHAR(60)) AS secondary_role_allow_connections_desc
    , CAST(NULL as sys.DATETIME) AS create_date
    , CAST(NULL as sys.DATETIME) AS modify_date
    , CAST(0 as INT) AS backup_priority
    , CAST(NULL as sys.NVARCHAR(256)) AS read_only_routing_url
    , CAST(NULL as sys.NVARCHAR(256)) AS read_write_routing_url
    , CAST(0 as sys.TINYINT) AS seeding_mode
    , CAST(NULL as sys.NVARCHAR(60)) AS seeding_mode_desc
WHERE FALSE;
GRANT SELECT ON sys.availability_replicas TO PUBLIC;

CREATE OR REPLACE VIEW sys.availability_groups 
AS SELECT  
    CAST(NULL as sys.UNIQUEIDENTIFIER) AS group_id
    , CAST(NULL as sys.SYSNAME) AS name
    , CAST(NULL as sys.NVARCHAR(40)) AS resource_id
    , CAST(NULL as sys.NVARCHAR(40)) AS resource_group_id
    , CAST(0 as INT) AS failure_condition_level
    , CAST(0 as INT) AS health_check_timeout
    , CAST(0 as sys.TINYINT) AS automated_backup_preference
    , CAST(NULL as sys.NVARCHAR(60)) AS automated_backup_preference_desc
    , CAST(0 as SMALLINT) AS version
    , CAST(0 as sys.BIT) AS basic_features
    , CAST(0 as sys.BIT) AS dtc_support
    , CAST(0 as sys.BIT) AS db_failover
    , CAST(0 as sys.BIT) AS is_distributed
    , CAST(0 as sys.TINYINT) AS cluster_type
    , CAST(NULL as sys.NVARCHAR(60)) AS cluster_type_desc
    , CAST(0 as INT) AS required_synchronized_secondaries_to_commit
    , CAST(0 as sys.BIGINT) AS sequence_number
    , CAST(0 as sys.BIT) AS is_contained
WHERE FALSE;
GRANT SELECT ON sys.availability_groups TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
