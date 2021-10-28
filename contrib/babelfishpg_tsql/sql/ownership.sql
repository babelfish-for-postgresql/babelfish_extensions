-- BBF_SYSDATABASES
-- Note: change here requires change in FormData_sysdatabases too
CREATE TABLE sys.babelfish_sysdatabases (
	dbid SMALLINT NOT NULL UNIQUE,
	status INT NOT NULL,
	status2 INT NOT NULL,
	owner NAME NOT NULL,
	default_collation NAME NOT NULL,
	name TEXT NOT NULL COLLATE "C",
	crdate timestamptz NOT NULL,
	properties TEXT NOT NULL COLLATE "C",
	PRIMARY KEY (name)
);

GRANT SELECT on sys.babelfish_sysdatabases TO PUBLIC;

-- BABELFISH_NAMESPACE_EXT
CREATE TABLE sys.babelfish_namespace_ext (
    nspname NAME NOT NULL,
    dbid SMALLINT NOT NULL,
    orig_name sys.NVARCHAR(128) NOT NULL,
	properties TEXT NOT NULL COLLATE "C",
    PRIMARY KEY (nspname)
);
GRANT SELECT ON sys.babelfish_namespace_ext TO PUBLIC;

-- SYSDATABASES
CREATE OR REPLACE VIEW sys.sysdatabases AS
SELECT
t.name,
sys.db_id(t.name) AS dbid,
CAST(CAST(r.oid AS int) AS SYS.VARBINARY(85)) AS sid,
CAST(0 AS SMALLINT) AS mode,
t.status,
t.status2,
CAST(t.crdate AS SYS.DATETIME) AS crdate,
CAST('1900-01-01 00:00:00.000' AS SYS.DATETIME) AS reserved,
CAST(0 AS INT) AS category,
CAST(NULL AS SYS.TINYINT) AS cmptlevel,
CAST(NULL AS SYS.NVARCHAR(260)) AS filename,
CAST(NULL AS SMALLINT) AS version
FROM sys.babelfish_sysdatabases AS t
LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = t.owner;

GRANT SELECT ON sys.sysdatabases TO PUBLIC;

-- PG_NAMESPACE_EXT
CREATE VIEW sys.pg_namespace_ext AS
SELECT BASE.* , DB.name as dbname FROM
pg_catalog.pg_namespace AS base
LEFT OUTER JOIN sys.babelfish_namespace_ext AS EXT on BASE.nspname = EXT.nspname
INNER JOIN sys.babelfish_sysdatabases AS DB ON EXT.dbid = DB.dbid;

GRANT SELECT ON sys.pg_namespace_ext TO PUBLIC;

-- Logical Schema Views
create or replace view sys.schemas as
select
  CAST(ext.orig_name as sys.SYSNAME) as name
  , base.oid as schema_id
  , base.nspowner as principal_id
from pg_catalog.pg_namespace base INNER JOIN sys.babelfish_namespace_ext ext on base.nspname = ext.nspname
where base.nspname not in ('information_schema', 'pg_catalog', 'pg_toast', 'sys', 'public')
and ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT ON sys.schemas TO PUBLIC;
CREATE SEQUENCE sys.babelfish_db_seq MAXVALUE 32767 CYCLE;

-- CATALOG INITIALIZER
CREATE OR REPLACE PROCEDURE babel_catalog_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_catalog';

CALL babel_catalog_initializer();

CREATE OR REPLACE PROCEDURE babel_create_builtin_dbs(IN login TEXT)
LANGUAGE C
AS 'babelfishpg_tsql', 'create_builtin_dbs';

CREATE OR REPLACE PROCEDURE sys.babel_drop_all_dbs()
LANGUAGE C
AS 'babelfishpg_tsql', 'drop_all_dbs';

CREATE OR REPLACE PROCEDURE sys.babel_initialize_logins(IN login TEXT)
LANGUAGE C
AS 'babelfishpg_tsql', 'initialize_logins';

CREATE OR REPLACE PROCEDURE sys.babel_drop_all_logins()
LANGUAGE C
AS 'babelfishpg_tsql', 'drop_all_logins';

CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
	reserved_roles varchar[] := ARRAY['sysadmin', 'master_dbo', 'master_guest', 'master_db_owner', 'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner'];
	user_id  oid := -1;
	db_name  name := NULL;
	role_name varchar;
	dba_name varchar;
BEGIN
	-- check reserved roles
	FOREACH role_name IN ARRAY reserved_roles LOOP
	BEGIN
		SELECT oid INTO user_id FROM pg_roles WHERE rolname = role_name;
		IF user_id > 0 THEN
			SELECT datname INTO db_name FROM pg_shdepend AS s INNER JOIN pg_database AS d ON s.dbid = d.oid WHERE s.refobjid = user_id;
			IF db_name IS NOT NULL THEN
				RAISE E'Could not initialize babelfish in current database: Reserved role % used in database %.\nIf babelfish was initialized in %, please remove babelfish and try again.', role_name, db_name, db_name;
			ELSE
				RAISE E'Could not initialize babelfish in current database: Reserved role % exists. \nPlease rename or drop existing role and try again ', role_name;
			END IF;
		END IF;
	END;
	END LOOP;

	SELECT pg_get_userbyid(datdba) INTO dba_name FROM pg_database WHERE datname = CURRENT_DATABASE();
	IF sa_name <> dba_name THEN
		RAISE E'Could not initialize babelfish with given role name: % is not the DB owner of current database.', sa_name;
	END IF;

	EXECUTE format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', CURRENT_DATABASE());
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', CURRENT_DATABASE());
	EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
	CALL sys.babel_initialize_logins(sa_name);
	CALL sys.babel_create_builtin_dbs(sa_name);
END
$$;

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sys.babel_drop_all_dbs();
    CALL sys.babel_drop_all_logins();
   	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', CURRENT_DATABASE());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
END
$$;

-- LOGIN EXT
-- Note: change here requires change in FormData_authid_login_ext too
CREATE TABLE sys.babelfish_authid_login_ext (
rolname NAME NOT NULL, -- pg_authid.rolname
is_disabled INT NOT NULL DEFAULT 0, -- to support enable/disable login
type CHAR(1) NOT NULL DEFAULT 'S',
credential_id INT NOT NULL,
owning_principal_id INT NOT NULL,
is_fixed_role INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
default_database_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128) NOT NULL,
properties JSONB,
PRIMARY KEY (rolname));
GRANT SELECT ON sys.babelfish_authid_login_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_sysdatabases', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_db_seq', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_namespace_ext', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_login_ext', '');

-- SERVER_PRINCIPALS
CREATE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
Ext.type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN' ELSE NULL END AS NVARCHAR(60)) AS type_desc,
Ext.is_disabled,
Ext.create_date,
Ext.modify_date,
Ext.default_database_name,
Ext.default_language_name,
Ext.credential_id,
Ext.owning_principal_id,
CAST(Ext.is_fixed_role AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

GRANT SELECT ON sys.server_principals TO PUBLIC;

-- internal table function for sp_helpdb with no arguments
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb()
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C;

-- internal table function for helpdb with dbname as input
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb(varchar)
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C;

create or replace view sys.databases as
select
  d.name as name
  , sys.db_id(d.name) as database_id
  , null::integer as source_database_id
  , cast(cast(r.oid as int) as varbinary(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(NULL AS SYS.TINYINT) as compatibility_level
  , c.collname::sys.nvarchar(128) as collation_name
  , 0 as user_access
  , 'MULTI_USER'::varchar(60) as user_access_desc
  , 0 as is_read_only
  , 0 as is_auto_close_on
  , 0 as is_auto_shrink_on
  , 0 as state
  , 'ONLINE'::varchar(60) as state_desc
  , CASE 
		WHEN pg_is_in_recovery() is false THEN 0 
		WHEN pg_is_in_recovery() is true THEN 1 
	END as is_in_standby
  , 0 as is_cleanly_shutdown
  , 0 as is_supplemental_logging_enabled
  , 1 as snapshot_isolation_state
  , 'ON'::varchar(60) as snapshot_isolation_state_desc
  , 1 as is_read_committed_snapshot_on
  , 1 as recovery_model
  , 'FULL'::varchar(60) as recovery_model_desc
  , 0 as page_verify_option
  , null::varchar(60) as page_verify_option_desc
  , 1 as is_auto_create_stats_on
  , 0 as is_auto_create_stats_incremental_on
  , 0 as is_auto_update_stats_on
  , 0 as is_auto_update_stats_async_on
  , 0 as is_ansi_null_default_on
  , 0 as is_ansi_nulls_on
  , 0 as is_ansi_padding_on
  , 0 as is_ansi_warnings_on
  , 0 as is_arithabort_on
  , 0 as is_concat_null_yields_null_on
  , 0 as is_numeric_roundabort_on
  , 0 as is_quoted_identifier_on
  , 0 as is_recursive_triggers_on
  , 0 as is_cursor_close_on_commit_on
  , 0 as is_local_cursor_default
  , 0 as is_fulltext_enabled
  , 0 as is_trustworthy_on
  , 0 as is_db_chaining_on
  , 0 as is_parameterization_forced
  , 0 as is_master_key_encrypted_by_server
  , 0 as is_query_store_on
  , 0 as is_published
  , 0 as is_subscribed
  , 0 as is_merge_published
  , 0 as is_distributor
  , 0 as is_sync_with_backup
  , null::sys.UNIQUEIDENTIFIER as service_broker_guid
  , 0 as is_broker_enabled
  , 0 as log_reuse_wait
  , 'NOTHING'::varchar(60) as log_reuse_wait_desc
  , 0 as is_date_correlation_on
  , 0 as is_cdc_enabled
  , 0 as is_encrypted
  , 0 as is_honor_broker_priority_on
  , null::sys.UNIQUEIDENTIFIER as replica_id
  , null::sys.UNIQUEIDENTIFIER as group_database_id
  , null::int as resource_pool_id
  , null::smallint as default_language_lcid
  , null::sys.nvarchar(128) as default_language_name
  , null::int as default_fulltext_language_lcid
  , null::sys.nvarchar(128) as default_fulltext_language_name
  , null::sys.bit as is_nested_triggers_on
  , null::sys.bit as is_transform_noise_words_on
  , null::smallint as two_digit_year_cutoff
  , 0 as containment
  , 'NONE'::varchar(60) as containment_desc
  , 0 as target_recovery_time_in_seconds
  , 0 as delayed_durability
  , null::sys.nvarchar(60) as delayed_durability_desc
  , 0 as is_memory_optimized_elevate_to_snapshot_on
  , 0 as is_federation_member
  , 0 as is_remote_data_archive_enabled
  , 0 as is_mixed_page_allocation_on
  , 0 as is_temporal_history_retention_enabled
  , 0 as catalog_collation_type
  , 'Not Applicable'::sys.nvarchar(60) as catalog_collation_type_desc
  , null::sys.nvarchar(128) as physical_database_name
  , 0 as is_result_set_caching_on
  , 0 as is_accelerated_database_recovery_on
  , 0 as is_tempdb_spill_to_remote_store
  , 0 as is_stale_page_detection_on
  , 0 as is_memory_optimized_enabled
  , 0 as is_ledger_on
 from sys.babelfish_sysdatabases d LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname
 LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = d.owner;

GRANT SELECT ON sys.databases TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_inconsistent_metadata()
RETURNS table (
  object_type varchar(32),
  schema_name varchar(128),
  object_name varchar(128),
  detail text
) AS 'babelfishpg_tsql', 'babelfish_inconsistent_metadata' LANGUAGE C;

