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

-- BABELFISH_SCHEMA_PERMISSIONS
-- This catalog is implemented specially to support GRANT/REVOKE .. ON SCHEMA ..
-- Please avoid using this catalog anywhere else.
CREATE TABLE sys.babelfish_schema_permissions (
  dbid smallint NOT NULL,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  permission INT CHECK(permission > 0),
  grantee sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_type CHAR(1) NOT NULL COLLATE sys.database_default,
  function_args TEXT COLLATE "C",
  grantor sys.NVARCHAR(128) COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, object_name, grantee, object_type)
);

-- BABELFISH_FUNCTION_EXT
CREATE TABLE sys.babelfish_function_ext (
	nspname NAME NOT NULL,
	funcname NAME NOT NULL,
	orig_name sys.NVARCHAR(128), -- original input name of users
	funcsignature TEXT NOT NULL COLLATE "C",
	default_positions TEXT COLLATE "C",
	flag_validity BIGINT,
	flag_values BIGINT,
	create_date SYS.DATETIME NOT NULL,
	modify_date SYS.DATETIME NOT NULL,
	definition sys.NTEXT DEFAULT NULL,
	PRIMARY KEY(funcname, nspname, funcsignature)
);
GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');

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
CAST(120 AS SYS.TINYINT) AS cmptlevel,
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
from pg_catalog.pg_namespace base 
inner join sys.babelfish_namespace_ext ext on base.nspname = ext.nspname
where ext.dbid = sys.db_id();
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

-- The items in initialize_babel_extras procedure need to be initialized or created 
-- during babelfish initialization. They depend on the core babelfish to be initialized first.
CREATE OR REPLACE PROCEDURE initialize_babel_extras()
LANGUAGE plpgsql
AS $$
BEGIN
  CREATE OR REPLACE PROCEDURE sys.create_xp_qv_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_qv_in_master_dbo_internal';

  CREATE OR REPLACE PROCEDURE sys.create_xp_instance_regread_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_instance_regread_in_master_dbo_internal';

  CALL sys.create_xp_qv_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_qv OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_qv_in_master_dbo;

  CALL sys.create_xp_instance_regread_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), int) OWNER TO sysadmin;
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), sys.nvarchar(512)) OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_instance_regread_in_master_dbo;

  CREATE OR REPLACE VIEW msdb_dbo.syspolicy_system_health_state
  AS
    SELECT 
      CAST(0 as BIGINT) AS health_state_id,
      CAST(0 as INT) AS policy_id,
      CAST(NULL AS sys.DATETIME) AS last_run_date,
      CAST('' AS sys.NVARCHAR(400)) AS target_query_expression_with_id,
      CAST('' AS sys.NVARCHAR) AS target_query_expression,
      CAST(1 as sys.BIT) AS result
    WHERE FALSE;
  GRANT SELECT ON msdb_dbo.syspolicy_system_health_state TO PUBLIC;
  ALTER VIEW msdb_dbo.syspolicy_system_health_state OWNER TO sysadmin;

  CREATE OR REPLACE FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled()
  RETURNS INTEGER
  AS 
  $fn_body$    
    SELECT 0;
  $fn_body$
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
  ALTER FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled() OWNER TO sysadmin;

  CREATE OR REPLACE VIEW msdb_dbo.syspolicy_configuration
  AS
    SELECT CAST(t.name AS sys.sysname), CAST(t.current_value AS sys.sql_variant) FROM
    (
      VALUES
      ('Enabled', CAST(0 AS int)),
      ('HistoryRetentionInDays', CAST(0 AS int)),
      ('LogOnSuccess', CAST(0 AS int))
    )t (name, current_value);
  GRANT SELECT ON msdb_dbo.syspolicy_configuration TO PUBLIC;
  ALTER VIEW msdb_dbo.syspolicy_configuration OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_addlinkedserver( IN "@server" sys.sysname,
                                                    IN "@srvproduct" sys.nvarchar(128) DEFAULT NULL,
                                                    IN "@provider" sys.nvarchar(128) DEFAULT 'SQLNCLI',
                                                    IN "@datasrc" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@location" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@provstr" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@catalog" sys.sysname DEFAULT NULL)
  AS 'babelfishpg_tsql', 'sp_addlinkedserver_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_addlinkedserver OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_addlinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                      IN "@useself" sys.varchar(8) DEFAULT 'TRUE',
                                                      IN "@locallogin" sys.sysname DEFAULT NULL,
                                                      IN "@rmtuser" sys.sysname DEFAULT NULL,
                                                      IN "@rmtpassword" sys.sysname DEFAULT NULL)
  AS 'babelfishpg_tsql', 'sp_addlinkedsrvlogin_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_addlinkedsrvlogin OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_droplinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                              IN "@locallogin" sys.sysname)
  AS 'babelfishpg_tsql', 'sp_droplinkedsrvlogin_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_droplinkedsrvlogin OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10) DEFAULT NULL)
  AS 'babelfishpg_tsql', 'sp_dropserver_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_dropserver OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_testlinkedserver( IN "@servername" sys.sysname)
  AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_testlinkedserver OWNER TO sysadmin;

  CREATE OR REPLACE PROCEDURE master_dbo.sp_enum_oledb_providers()
  AS 'babelfishpg_tsql', 'sp_enum_oledb_providers_internal'
  LANGUAGE C;

  ALTER PROCEDURE master_dbo.sp_enum_oledb_providers OWNER TO sysadmin;

  -- let sysadmin only to update babelfish_domain_mapping
  GRANT ALL ON TABLE sys.babelfish_domain_mapping TO sysadmin;
END
$$;

CREATE OR REPLACE PROCEDURE sys.analyze_babelfish_catalogs()
LANGUAGE plpgsql
AS $$ 
DECLARE 
	babelfish_catalog RECORD;
	schema_name varchar = 'sys';
	error_msg text;
BEGIN
	FOR babelfish_catalog IN (
		SELECT relname as name from pg_class t 
		INNER JOIN pg_namespace n on n.oid = t.relnamespace
		WHERE t.relkind = 'r' and n.nspname = schema_name
		)
	LOOP
		BEGIN
			EXECUTE format('ANALYZE %I.%I', schema_name, babelfish_catalog.name);
		EXCEPTION WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
			RAISE WARNING 'ANALYZE for babelfish catalog %.% failed with error: %s', schema_name, babelfish_catalog.name, error_msg;
		END;
	END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
	reserved_roles varchar[] := ARRAY['sysadmin', 'securityadmin', 'master_dbo', 'master_guest', 'master_db_owner', 'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner', 'msdb_dbo', 'msdb_guest', 'msdb_db_owner'];
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

	EXECUTE format('CREATE ROLE securityadmin CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE format('CREATE ROLE bbf_role_admin CREATEDB CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE format('GRANT CREATE ON DATABASE %s TO bbf_role_admin WITH GRANT OPTION', CURRENT_DATABASE());
	EXECUTE format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', sa_name);
	EXECUTE format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
	EXECUTE format('GRANT sysadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE format('GRANT securityadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_function_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_scheme_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', CURRENT_DATABASE());
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', CURRENT_DATABASE());
	EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
	CALL sys.babel_initialize_logins(sa_name);
	CALL sys.babel_initialize_logins('sysadmin');
	CALL sys.babel_initialize_logins('bbf_role_admin');
	CALL sys.babel_initialize_logins('securityadmin');
	CALL sys.babel_create_builtin_dbs(sa_name);
	CALL sys.initialize_babel_extras();
	-- run analyze for all babelfish catalog
	CALL sys.analyze_babelfish_catalogs();
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
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_function_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_scheme_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
	DROP OWNED BY bbf_role_admin;
	DROP ROLE bbf_role_admin;
	DROP OWNED BY securityadmin;
	DROP ROLE securityadmin;
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
orig_loginname SYS.NVARCHAR(128) NOT NULL,
PRIMARY KEY (rolname));
GRANT SELECT ON sys.babelfish_authid_login_ext TO PUBLIC;

-- SERVER_PRINCIPALS
CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
    WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_LOGIN'
    ELSE NULL
  END
  AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE (pg_has_role(suser_id(), 'sysadmin'::TEXT, 'MEMBER') 
  OR pg_has_role(suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Ext.orig_loginname = suser_name()
  OR Ext.orig_loginname = (SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = CURRENT_DATABASE()) COLLATE sys.database_default
  OR Ext.type = 'R')
  AND Ext.type != 'Z'
UNION ALL
SELECT
CAST('public' AS SYS.SYSNAME) AS name,
CAST(-1 AS INT) AS principal_id,
CAST(CAST(0 as INT) as sys.varbinary(85)) AS sid,
CAST('R' AS CHAR(1)) as type,
CAST('SERVER_ROLE' AS NVARCHAR(60)) AS type_desc,
CAST(0 AS INT) AS is_disabled,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(NULL AS SYS.SYSNAME) AS default_database_name,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(NULL AS INT) AS credential_id,
CAST(1 AS INT) AS owning_principal_id,
CAST(0 AS sys.BIT) AS is_fixed_role;

GRANT SELECT ON sys.server_principals TO PUBLIC;


-- USER extension
CREATE TABLE sys.babelfish_authid_user_ext (
rolname NAME NOT NULL,
login_name NAME NOT NULL,
type CHAR(1) NOT NULL DEFAULT 'S',
owning_principal_id INT,
is_fixed_role INT NOT NULL DEFAULT 0,
authentication_type INT,
default_language_lcid INT,
allow_encrypted_value_modifications INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
orig_username SYS.NVARCHAR(128) NOT NULL,
database_name SYS.NVARCHAR(128) NOT NULL,
default_schema_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128),
authentication_type_desc SYS.NVARCHAR(60),
user_can_connect INT NOT NULL DEFAULT 1,
PRIMARY KEY (rolname));

CREATE INDEX babelfish_authid_user_ext_login_db_idx ON sys.babelfish_authid_user_ext (login_name, database_name);

GRANT SELECT ON sys.babelfish_authid_user_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_sysdatabases', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_db_seq', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_namespace_ext', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_login_ext', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_user_ext', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_schema_permissions', '');

-- DATABASE_PRINCIPALS
CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME()
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'guest') -- system users should always be visible
  OR pg_has_role(Ext.rolname, 'MEMBER')) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(-1 AS INT) AS principal_id,
CAST(type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN type = 'S' THEN 'SQL_USER'
    WHEN type = 'R' THEN 'DATABASE_ROLE'
    WHEN type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_schema_name,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(-1 AS INT) AS owning_principal_id,
CAST(CAST(0 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(0 AS SYS.BIT) AS is_fixed_role,
CAST(-1 AS INT) AS authentication_type,
CAST(NULL AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(-1 AS INT) AS default_language_lcid,
CAST(0 AS SYS.BIT) AS allow_encrypted_value_modifications
FROM (VALUES ('public', 'R'), ('sys', 'S'), ('INFORMATION_SCHEMA', 'S')) as dummy_principals(name, type);

GRANT SELECT ON sys.database_principals TO PUBLIC;

-- login_token
CREATE OR REPLACE VIEW sys.login_token
AS SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
ELSE 'SQL LOGIN' END AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.orig_loginname = sys.suser_name()
AND Ext.type in ('S','U')
UNION ALL
SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST('SERVER ROLE' AS sys.nvarchar(128)) AS type,
CAST ('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.type = 'R'
AND bbf_is_member_of_role_nosuper(sys.suser_id(), Base.oid);

GRANT SELECT ON sys.login_token TO PUBLIC;

-- user_token
CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.orig_username AS SYS.NVARCHAR(128)) AS NAME,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
WHEN Ext.type = 'R' THEN 'ROLE'
ELSE 'SQL USER' END
AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = sys.DB_NAME()
AND ((Ext.rolname = CURRENT_USER AND Ext.type in ('S','U')) OR
((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo' AND Ext.type = 'R' AND pg_has_role(current_user, Ext.rolname, 'MEMBER')))
UNION ALL
SELECT
CAST(-1 AS INT) AS principal_id,
CAST(CAST(-1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

-- SYSUSERS
CREATE OR REPLACE VIEW sys.sysusers AS SELECT
Dbp.principal_id AS uid,
CAST(0 AS INT) AS status,
Dbp.name AS name,
Dbp.sid AS sid,
CAST(NULL AS SYS.VARBINARY(2048)) AS roles,
Dbp.create_date AS createdate,
Dbp.modify_date AS updatedate,
CAST(0 AS INT) AS altuid,
CAST(NULL AS SYS.VARBINARY(256)) AS password,
CAST(0 AS INT) AS gid,
CAST(NULL AS SYS.VARCHAR(85)) AS environ,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.type_desc = 'DATABASE_ROLE'
    THEN 0
  WHEN (Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER') AND Ext.user_can_connect = 1 THEN 1
  ELSE 0
END AS hasdbaccess,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.name = 'guest'
    OR Dbp.name = 'dbo' 
    THEN 1
  WHEN Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER' THEN 1
  ELSE 0
END AS islogin,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntname,
CAST(0 AS INT) AS isntgroup,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntuser,
CASE WHEN Dbp.type_desc = 'SQL_USER' THEN 1 ELSE 0 END AS issqluser,
CAST(0 AS INT) AS isaliased,
CASE WHEN Dbp.type_desc = 'DATABASE_ROLE' THEN 1 ELSE 0 END AS issqlrole,
CAST(0 AS INT) AS isapprole
FROM sys.database_principals AS Dbp LEFT JOIN 
  (SELECT orig_username, user_can_connect FROM sys.babelfish_authid_user_ext 
    WHERE database_name = DB_NAME()) AS Ext
ON Dbp.name = Ext.orig_username;
 
GRANT SELECT ON sys.sysusers TO PUBLIC;

-- DATABASE_ROLE_MEMBERS
CREATE OR REPLACE VIEW sys.database_role_members AS
SELECT
CAST(Auth1.oid AS INT) AS role_principal_id,
CAST(Auth2.oid AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_roles AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_roles AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = DB_NAME() 
AND Ext2.database_name = DB_NAME()
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';

GRANT SELECT ON sys.database_role_members TO PUBLIC;

--SERVER_ROLE_MEMBER
CREATE OR REPLACE VIEW sys.server_role_members AS
SELECT
CAST(Authmbr.roleid AS INT) AS role_principal_id,
CAST(Authmbr.member AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_roles AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_roles AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.type = 'R' AND Ext1.type != 'Z';

GRANT SELECT ON sys.server_role_members TO PUBLIC;

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
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C STABLE;

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
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C STABLE;

create or replace view sys.databases as
select
  CAST(d.name as SYS.SYSNAME) as name
  , CAST(sys.db_id(d.name) as INT) as database_id
  , CAST(NULL as INT) as source_database_id
  , cast(s.sid as SYS.VARBINARY(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(s.cmptlevel AS SYS.TINYINT) as compatibility_level
  , CAST(c.collname as SYS.SYSNAME) as collation_name
  , CAST(0 AS SYS.TINYINT)  as user_access
  , CAST('MULTI_USER' AS SYS.NVARCHAR(60)) as user_access_desc
  , CAST(0 AS SYS.BIT) as is_read_only
  , CAST(0 AS SYS.BIT) as is_auto_close_on
  , CAST(0 AS SYS.BIT) as is_auto_shrink_on
  , CAST(0 AS SYS.TINYINT) as state
  , CAST('ONLINE' AS SYS.NVARCHAR(60)) as state_desc
  , CAST(
	  	CASE 
			WHEN pg_is_in_recovery() is false THEN 0 
			WHEN pg_is_in_recovery() is true THEN 1 
		END 
	AS SYS.BIT) as is_in_standby
  , CAST(0 AS SYS.BIT) as is_cleanly_shutdown
  , CAST(0 AS SYS.BIT) as is_supplemental_logging_enabled
  , CAST(1 AS SYS.TINYINT) as snapshot_isolation_state
  , CAST('ON' AS SYS.NVARCHAR(60)) as snapshot_isolation_state_desc
  , CAST(1 AS SYS.BIT) as is_read_committed_snapshot_on
  , CAST(1 AS SYS.TINYINT) as recovery_model
  , CAST('FULL' AS SYS.NVARCHAR(60)) as recovery_model_desc
  , CAST(0 AS SYS.TINYINT) as page_verify_option
  , CAST(NULL AS SYS.NVARCHAR(60)) as page_verify_option_desc
  , CAST(1 AS SYS.BIT) as is_auto_create_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_create_stats_incremental_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_async_on
  , CAST(0 AS SYS.BIT) as is_ansi_null_default_on
  , CAST(0 AS SYS.BIT) as is_ansi_nulls_on
  , CAST(0 AS SYS.BIT) as is_ansi_padding_on
  , CAST(0 AS SYS.BIT) as is_ansi_warnings_on
  , CAST(0 AS SYS.BIT) as is_arithabort_on
  , CAST(0 AS SYS.BIT) as is_concat_null_yields_null_on
  , CAST(0 AS SYS.BIT) as is_numeric_roundabort_on
  , CAST(0 AS SYS.BIT) as is_quoted_identifier_on
  , CAST(0 AS SYS.BIT) as is_recursive_triggers_on
  , CAST(0 AS SYS.BIT) as is_cursor_close_on_commit_on
  , CAST(0 AS SYS.BIT) as is_local_cursor_default
  , CAST(0 AS SYS.BIT) as is_fulltext_enabled
  , CAST(0 AS SYS.BIT) as is_trustworthy_on
  , CAST(0 AS SYS.BIT) as is_db_chaining_on
  , CAST(0 AS SYS.BIT) as is_parameterization_forced
  , CAST(0 AS SYS.BIT) as is_master_key_encrypted_by_server
  , CAST(0 AS SYS.BIT) as is_query_store_on
  , CAST(0 AS SYS.BIT) as is_published
  , CAST(0 AS SYS.BIT) as is_subscribed
  , CAST(0 AS SYS.BIT) as is_merge_published
  , CAST(0 AS SYS.BIT) as is_distributor
  , CAST(0 AS SYS.BIT) as is_sync_with_backup
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as service_broker_guid
  , CAST(0 AS SYS.BIT) as is_broker_enabled
  , CAST(0 AS SYS.TINYINT) as log_reuse_wait
  , CAST('NOTHING' AS SYS.NVARCHAR(60)) as log_reuse_wait_desc
  , CAST(0 AS SYS.BIT) as is_date_correlation_on
  , CAST(0 AS SYS.BIT) as is_cdc_enabled
  , CAST(0 AS SYS.BIT) as is_encrypted
  , CAST(0 AS SYS.BIT) as is_honor_broker_priority_on
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as replica_id
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as group_database_id
  , CAST(NULL AS INT) as resource_pool_id
  , CAST(NULL AS SMALLINT) as default_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_language_name
  , CAST(NULL AS INT) as default_fulltext_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_fulltext_language_name
  , CAST(NULL AS SYS.BIT) as is_nested_triggers_on
  , CAST(NULL AS SYS.BIT) as is_transform_noise_words_on
  , CAST(NULL AS SMALLINT) as two_digit_year_cutoff
  , CAST(0 AS SYS.TINYINT) as containment
  , CAST('NONE' AS SYS.NVARCHAR(60)) as containment_desc
  , CAST(0 AS INT) as target_recovery_time_in_seconds
  , CAST(0 AS INT) as delayed_durability
  , CAST(NULL AS SYS.NVARCHAR(60)) as delayed_durability_desc
  , CAST(0 AS SYS.BIT) as is_memory_optimized_elevate_to_snapshot_on
  , CAST(0 AS SYS.BIT) as is_federation_member
  , CAST(0 AS SYS.BIT) as is_remote_data_archive_enabled
  , CAST(0 AS SYS.BIT) as is_mixed_page_allocation_on
  , CAST(0 AS SYS.BIT) as is_temporal_history_retention_enabled
  , CAST(0 AS INT) as catalog_collation_type
  , CAST('Not Applicable' AS SYS.NVARCHAR(60)) as catalog_collation_type_desc
  , CAST(NULL AS SYS.NVARCHAR(128)) as physical_database_name
  , CAST(0 AS SYS.BIT) as is_result_set_caching_on
  , CAST(0 AS SYS.BIT) as is_accelerated_database_recovery_on
  , CAST(0 AS SYS.BIT) as is_tempdb_spill_to_remote_store
  , CAST(0 AS SYS.BIT) as is_stale_page_detection_on
  , CAST(0 AS SYS.BIT) as is_memory_optimized_enabled
  , CAST(0 AS SYS.BIT) as is_ledger_on
 from sys.babelfish_sysdatabases d 
 INNER JOIN sys.sysdatabases s on d.dbid = s.dbid
 LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname;
GRANT SELECT ON sys.databases TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_inconsistent_metadata(return_consistency boolean default false)
RETURNS table (
  object_type varchar(32),
  schema_name varchar(128),
  object_name varchar(128),
  detail jsonb
) AS 'babelfishpg_tsql', 'babelfish_inconsistent_metadata' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.check_for_inconsistent_metadata()
RETURNS BOOLEAN AS $$
DECLARE
    has_inconsistent_metadata BOOLEAN;
    num_rows INT;
BEGIN
    has_inconsistent_metadata := FALSE;

    -- Count the number of inconsistent metadata rows from Babelfish catalogs
    SELECT COUNT(*) INTO num_rows
    FROM sys.babelfish_inconsistent_metadata();

    has_inconsistent_metadata := num_rows > 0;

    -- Additional checks can be added here to update has_inconsistent_metadata accordingly

    RETURN has_inconsistent_metadata;
END;
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.role_id(role_name SYS.SYSNAME)
RETURNS INT
AS 'babelfishpg_tsql', 'role_id'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.role_id TO PUBLIC;

CREATE TABLE sys.babelfish_domain_mapping (
  netbios_domain_name sys.VARCHAR(15) NOT NULL, -- Netbios domain name
  fq_domain_name sys.VARCHAR(128) NOT NULL, -- DNS domain name
  PRIMARY KEY (netbios_domain_name)
);
GRANT SELECT ON TABLE sys.babelfish_domain_mapping TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_domain_mapping', '');

CREATE OR REPLACE PROCEDURE sys.babelfish_add_domain_mapping_entry(IN sys.VARCHAR(15), IN sys.VARCHAR(128))
  AS 'babelfishpg_tsql', 'babelfish_add_domain_mapping_entry_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_add_domain_mapping_entry TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_remove_domain_mapping_entry(IN sys.VARCHAR(15))
  AS 'babelfishpg_tsql', 'babelfish_remove_domain_mapping_entry_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_remove_domain_mapping_entry TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_truncate_domain_mapping_table()
  AS 'babelfishpg_tsql', 'babelfish_truncate_domain_mapping_table_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_truncate_domain_mapping_table TO PUBLIC;

CREATE TABLE sys.babelfish_extended_properties (
  dbid smallint NOT NULL,
  schema_name name NOT NULL,
  major_name name NOT NULL,
  minor_name name NOT NULL,
  type sys.varchar(50) NOT NULL,
  name sys.sysname NOT NULL,
  orig_name sys.sysname NOT NULL,
  value sys.sql_variant,
  PRIMARY KEY (dbid, type, schema_name, major_name, minor_name, name)
);
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_extended_properties', '');

-- This view contains many outer joins that could potentially impair performance.
-- To optimize this, it may be beneficial to begin by acquiring the object identifier (OID) and verifying permissions.
CREATE OR REPLACE VIEW sys.extended_properties
AS
SELECT
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 3
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 1
		WHEN ep.type = 'TYPE' THEN 6
		END) AS sys.tinyint) AS class,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 'DATABASE'
		WHEN ep.type = 'SCHEMA' THEN 'SCHEMA'
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 'OBJECT_OR_COLUMN'
		WHEN ep.type = 'TYPE' THEN 'TYPE'
	END) AS sys.nvarchar(60)) AS class_desc,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN n.oid
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE') THEN c.oid
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN p.oid
		WHEN ep.type = 'TYPE' THEN t.oid
	END) AS int) AS major_id,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 0
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION', 'TYPE') THEN 0
		WHEN ep.type = 'TABLE COLUMN' THEN a.attnum
	END) AS int) AS minor_id,
	ep.orig_name AS name, ep.value AS value
	FROM sys.babelfish_extended_properties ep
		LEFT JOIN pg_catalog.pg_namespace n ON n.nspname = ep.schema_name
		LEFT JOIN pg_catalog.pg_class c ON c.relname = ep.major_name AND c.relnamespace = n.oid
		LEFT JOIN pg_catalog.pg_proc p ON p.proname = ep.major_name AND p.pronamespace = n.oid
		LEFT JOIN pg_catalog.pg_type t ON t.typname = ep.major_name AND t.typnamespace = n.oid
		LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = ep.minor_name
	WHERE ep.dbid = sys.db_id() AND
	(CASE
		WHEN ep.type = 'DATABASE' THEN true
		WHEN ep.type = 'SCHEMA' THEN has_schema_privilege(n.oid, 'USAGE, CREATE')
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'))
		WHEN ep.type IN ('TABLE COLUMN') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') OR has_column_privilege(a.attrelid, a.attname, 'SELECT, INSERT, UPDATE, REFERENCES'))
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN has_function_privilege(p.oid, 'EXECUTE')
		WHEN ep.type = 'TYPE' THEN has_type_privilege(t.oid, 'USAGE')
	END)
	ORDER BY class, class_desc, major_id, minor_id, ep.orig_name;
GRANT SELECT ON sys.extended_properties TO PUBLIC;
