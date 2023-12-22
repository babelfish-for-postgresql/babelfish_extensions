-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.0.0'" to load this file. \quit

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

-- please add your SQL here

-- Give bbf_role_admin privileges on every Babelfish role
DO
LANGUAGE plpgsql
$$
DECLARE temprow RECORD;
DECLARE query TEXT;
BEGIN
    IF EXISTS (
               SELECT FROM pg_catalog.pg_roles
               WHERE  rolname = 'bbf_role_admin') 
        THEN
            RAISE EXCEPTION 'Role "bbf_role_admin" already exists.';
    ELSE
        EXECUTE format('CREATE ROLE bbf_role_admin WITH CREATEDB CREATEROLE INHERIT PASSWORD NULL');
        EXECUTE format('GRANT CREATE ON DATABASE %s TO bbf_role_admin WITH GRANT OPTION', CURRENT_DATABASE());
        CALL sys.babel_initialize_logins('bbf_role_admin');
        FOR temprow IN
        SELECT rolname FROM sys.babelfish_authid_login_ext WHERE rolname != 'bbf_role_admin' UNION SELECT rolname FROM sys.babelfish_authid_user_ext
        LOOP
            query := pg_catalog.format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', temprow.rolname);
            EXECUTE query;
        END LOOP;
    END IF;
END;
$$;

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
OR Ext.orig_loginname = suser_name()
OR Ext.orig_loginname = (SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = CURRENT_DATABASE()) COLLATE sys.database_default
OR Ext.type = 'R')
AND Ext.type != 'Z';

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

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If server role is not specified, return info for all server roles
	IF @srvrolename IS NULL
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	-- If the role is a SQL server predefined role (i.e. serveradmin), 
	-- do not raise an error even if it does not exist
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_login_ext
					WHERE (rolname = RTRIM(@srvrolename)
					OR lower(rolname) = lower(RTRIM(@srvrolename)))
					AND type = 'R')
					OR lower(RTRIM(@srvrolename)) IN (
					'serveradmin', 'setupadmin', 'securityadmin', 'processadmin',
					'dbcreator', 'diskadmin', 'bulkadmin')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
		AND (Ext1.rolname = RTRIM(@srvrolename) OR lower(Ext1.rolname) = lower(RTRIM(@srvrolename)))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';

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

-- Rename functions for dependencies
DO $$
DECLARE
  exception_message text;
BEGIN
  -- Rename parsename for dependencies
  ALTER FUNCTION sys.parsename(sys.VARCHAR, INT) RENAME TO parsename_deprecated_in_3_5_0;

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
  -- Rename sp_set_session_context for dependencies
  ALTER PROCEDURE sys.sp_set_session_context(sys.SYSNAME, sys.SQL_VARIANT, sys.BIT) RENAME TO sp_set_session_context_deprecated_in_3_5_0;

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
  -- Rename session_context for dependencies
  ALTER FUNCTION sys.session_context(sys.SYSNAME) RENAME TO session_context_deprecated_in_3_5_0;

EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.NVARCHAR, object_piece int)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE PROCEDURE sys.sp_set_session_context ("@key" sys.NVARCHAR(128), 
	"@value" sys.SQL_VARIANT, "@read_only" sys.bit = 0)
AS 'babelfishpg_tsql', 'sp_set_session_context'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_set_session_context TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.session_context ("@key" sys.NVARCHAR(128))
RETURNS sys.SQL_VARIANT 
AS 'babelfishpg_tsql', 'session_context' 
LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.session_context TO PUBLIC;

-- === DROP deprecated functions (if exists)
DO $$
DECLARE
    exception_message text;
BEGIN
    -- === DROP parsename_deprecated_in_3_5_0
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_5_0');

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
    -- === DROP sp_set_session_context_deprecated_in_3_5_0
    CALL sys.babelfish_drop_deprecated_object('procedure', 'sys', 'sp_set_session_context_deprecated_in_3_5_0');

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
    -- === DROP session_context_deprecated_in_3_5_0
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'session_context_deprecated_in_3_5_0');

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
