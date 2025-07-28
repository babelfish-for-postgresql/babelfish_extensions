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
  OR pg_has_role(sys.suser_id(), Ext.rolname, 'MEMBER')
  OR Base.rolname = (SELECT pg_get_userbyid(super_user) FROM super_user) COLLATE sys.database_default)
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

-- user_token
CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CASE Ext.orig_username
    WHEN 'dbo' THEN CAST(CAST(Base3.oid AS INT) AS SYS.VARBINARY(85))
    WHEN 'guest' THEN CAST(0 AS SYS.VARBINARY(85))
    -- these are SIDs which are constant for all the fixed roles used across databases 
    -- hence we are hardcoding these SIDs
    WHEN 'db_owner' THEN CAST('\x01050000000000090400000000000000000000000000000000400000'::bytea AS SYS.VARBINARY(85)) 
    WHEN 'db_accessadmin' THEN CAST('\x01050000000000090400000000000000000000000000000001400000'::bytea AS SYS.VARBINARY(85))    
    WHEN 'db_securityadmin' THEN CAST('\x01050000000000090400000000000000000000000000000002400000'::bytea AS SYS.VARBINARY(85))  
    WHEN 'db_ddladmin' THEN CAST('\x01050000000000090400000000000000000000000000000003400000'::bytea AS SYS.VARBINARY(85))       
    WHEN 'db_backupoperator' THEN CAST('\x01050000000000090400000000000000000000000000000005400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datareader' THEN CAST('\x01050000000000090400000000000000000000000000000006400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datawriter' THEN CAST('\x01050000000000090400000000000000000000000000000007400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatareader' THEN CAST('\x01050000000000090400000000000000000000000000000008400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatawriter' THEN CAST('\x01050000000000090400000000000000000000000000000009400000'::bytea AS SYS.VARBINARY(85))
    ELSE CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85))
END AS SID,
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
LEFT OUTER JOIN sys.babelfish_sysdatabases AS Db
ON Ext.database_name COLLATE sys.database_default = Db.name
LEFT OUTER JOIN pg_catalog.pg_roles AS Base3
ON Db.owner = Base3.rolname
WHERE Ext.database_name = sys.DB_NAME()
AND ((Ext.rolname = CURRENT_USER AND Ext.type in ('S','U')) OR
((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo' AND Ext.type = 'R' AND pg_has_role(current_user, Ext.rolname, 'MEMBER')))
UNION ALL
SELECT
CAST(1 AS INT) AS principal_id,
CAST(CAST(1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';
GRANT SELECT ON sys.user_token TO PUBLIC;

-- DATABASE_PRINCIPALS
CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
-- PG reserves these oid > 16383 AND oid < 16400 for PG specific internal roles.
-- Any change here in the oid should be reflected in sys.database_role_members view as well.
CAST(
  CASE Ext.orig_username
    WHEN 'db_owner' THEN 16384
    WHEN 'db_accessadmin' THEN 16385
    WHEN 'db_securityadmin' THEN 16386
    WHEN 'db_ddladmin' THEN 16387
    WHEN 'db_datareader' THEN 16390
    WHEN 'db_datawriter' THEN 16391
    ELSE Base.oid
  END AS INT) AS principal_id,
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
CASE Ext.orig_username
    WHEN 'dbo' THEN CAST(CAST(Base3.oid AS INT) AS SYS.VARBINARY(85))
    WHEN 'guest' THEN CAST(0 AS SYS.VARBINARY(85))
    -- these are SIDs which are constant for all the fixed roles used across databases 
    -- hence we are hardcoding these SIDs
    WHEN 'db_owner' THEN CAST('\x01050000000000090400000000000000000000000000000000400000'::bytea AS SYS.VARBINARY(85)) 
    WHEN 'db_accessadmin' THEN CAST('\x01050000000000090400000000000000000000000000000001400000'::bytea AS SYS.VARBINARY(85))    
    WHEN 'db_securityadmin' THEN CAST('\x01050000000000090400000000000000000000000000000002400000'::bytea AS SYS.VARBINARY(85))  
    WHEN 'db_ddladmin' THEN CAST('\x01050000000000090400000000000000000000000000000003400000'::bytea AS SYS.VARBINARY(85))       
    WHEN 'db_backupoperator' THEN CAST('\x01050000000000090400000000000000000000000000000005400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datareader' THEN CAST('\x01050000000000090400000000000000000000000000000006400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datawriter' THEN CAST('\x01050000000000090400000000000000000000000000000007400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatareader' THEN CAST('\x01050000000000090400000000000000000000000000000008400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatawriter' THEN CAST('\x01050000000000090400000000000000000000000000000009400000'::bytea AS SYS.VARBINARY(85))
    ELSE CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85))
END AS SID,
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
LEFT OUTER JOIN sys.babelfish_sysdatabases AS Db
ON Ext.database_name COLLATE sys.database_default = Db.name
LEFT OUTER JOIN pg_catalog.pg_roles AS Base3
ON Db.owner = Base3.rolname
WHERE Ext.database_name = DB_NAME()
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin', 'guest') -- system users should always be visible
  OR bbf_is_role_member(current_user, Ext.rolname)) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(
  CASE name
    WHEN 'public' THEN 1
    WHEN 'INFORMATION_SCHEMA' THEN 3
    WHEN 'sys' THEN 4
  END AS INT) AS principal_id,
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

-- Please add your SQLs here
CREATE OR REPLACE PROCEDURE sys.sp_helplogins(IN "@loginname" sys.sysname DEFAULT NULL)
LANGUAGE pltsql
AS $$
DECLARE @input_loginname sys.sysname;
DECLARE @current_username sys.nvarchar(128)
DECLARE @is_sysadmin BIT
BEGIN

	IF is_srvrolemember('securityadmin') = 0 
	BEGIN
		RAISERROR('User does not have permission to perform this action.', 16, 1);
		RETURN 0;
	END

	SET @current_username = LOWER(sys.suser_name());
	SET @is_sysadmin = is_srvrolemember('sysadmin');

	SET @input_loginname = sys.RTRIM(@loginname);

	SELECT DISTINCT
		CAST(LExt.orig_loginname AS sys.SYSNAME) AS LoginName,
		CAST(CAST(Base.oid AS INT) AS sys.varbinary(85)) AS SID,
		CAST(LExt.default_database_name AS SYS.SYSNAME) AS DefDBName,
		CAST(LExt.default_language_name AS SYS.SYSNAME) AS DefLangName,
		CASE
		    WHEN Ext.login_name IS NOT NULL AND Ext.login_name = LExt.rolname COLLATE database_default THEN CAST('yes' AS sys.char(5)) -- if there exists a mapping between user and logins, then we can say that there are users attached to this login
		    WHEN Db.owner COLLATE database_default = LExt.orig_loginname THEN CAST('yes' AS sys.char(5)) -- this is the case for superuser
		    ELSE CAST('no' AS sys.char(5))
		END AS AUser,
		CAST('no' AS sys.char(7)) AS ARemote -- Currently we do not support linking local logins to remote logins
	FROM pg_catalog.pg_roles AS Base
	INNER JOIN sys.babelfish_authid_login_ext AS LExt ON Base.rolname = LExt.rolname
	LEFT JOIN sys.babelfish_authid_user_ext AS Ext ON Ext.login_name = Base.rolname AND Ext.type != 'R'
	LEFT JOIN sys.babelfish_sysdatabases AS Db ON Db.owner COLLATE database_default = LExt.orig_loginname
	WHERE LExt.type NOT IN ('R', 'Z') AND
	      (@loginname IS NULL OR LExt.orig_loginname = @input_loginname)

	-- first selector in the union is to get all the mapped users
	-- second selector in the union is to get all the mapped database/user-defined roles
	SELECT
		CAST(LExt.orig_loginname AS sys.SYSNAME) AS LoginName,
		CAST(UExt.database_name AS sys.SYSNAME) AS DBName,
		CAST(UExt.orig_username AS SYS.SYSNAME) AS UserName,
		CAST('User' AS sys.char(8)) AS UserOrAlias
	FROM sys.babelfish_authid_user_ext UExt
	LEFT JOIN sys.babelfish_sysdatabases Db ON Db.name COLLATE database_default = UExt.database_name
	LEFT JOIN sys.babelfish_authid_login_ext LExt ON LExt.rolname COLLATE database_default = COALESCE(NULLIF(UExt.login_name, ''), Db.owner)
	WHERE UExt.type != 'R' AND  
		UExt.orig_username != 'guest' AND 
		has_dbaccess(UExt.database_name) = 1 AND
		(@loginname IS NULL OR LExt.orig_loginname = @input_loginname) AND
		(
			@is_sysadmin = 1 OR
			LExt.orig_loginname = @current_username OR
			ISNULL(UExt.login_name, '') = '' OR
			-- a co-related query to find out if the current_user is a member of db_securityadmin or db_accessadmin role in database - UExt.database_name 
			EXISTS (
				SELECT 1 
				FROM pg_catalog.pg_auth_members AS Authmbr
				INNER JOIN pg_catalog.pg_roles AS PGR1 ON PGR1.oid = Authmbr.roleid
				INNER JOIN pg_catalog.pg_roles AS PGR2 ON PGR2.oid = Authmbr.member
				INNER JOIN sys.babelfish_authid_user_ext AS UExt1 ON PGR1.rolname = UExt1.rolname
				INNER JOIN sys.babelfish_authid_user_ext AS UExt2 ON PGR2.rolname = UExt2.rolname
				WHERE UExt1.orig_username IN ('db_owner', 'db_securityadmin', 'db_accessadmin') 
				AND UExt2.database_name = UExt.database_name -- filter to check if the processing db is equal to the outer query db, since we want to find if the user is a member of the roles in the outer db
				AND UExt2.login_name = @current_username
			)
		)
	UNION
	SELECT
		CAST(LExt.orig_loginname AS sys.SYSNAME) AS LoginName,
		CAST(UExt2.database_name AS sys.SYSNAME) AS DBName,
		CAST(UExt1.orig_username AS sys.SYSNAME) AS UserName,
		CAST('MemberOf' AS sys.char(8)) AS UserOrAlias
	FROM pg_catalog.pg_auth_members AS Authmbr
	INNER JOIN pg_catalog.pg_roles AS PGR1 ON PGR1.oid = Authmbr.roleid
	INNER JOIN pg_catalog.pg_roles AS PGR2 ON PGR2.oid = Authmbr.member
	INNER JOIN sys.babelfish_authid_user_ext AS UExt1 ON PGR1.rolname = UExt1.rolname AND UExt1.type = 'R'
	INNER JOIN sys.babelfish_authid_user_ext AS UExt2 ON PGR2.rolname = UExt2.rolname AND UExt2.orig_username != 'db_owner'
	LEFT JOIN sys.babelfish_sysdatabases Db ON Db.name COLLATE database_default = UExt1.database_name
	LEFT JOIN sys.babelfish_authid_login_ext LExt ON LExt.rolname COLLATE database_default = COALESCE(NULLIF(UExt2.login_name, ''), Db.owner)
	WHERE 
		has_dbaccess(UExt2.database_name) = 1 AND
		(@loginname IS NULL OR LExt.orig_loginname = @input_loginname) AND
		(
			@is_sysadmin = 1 OR
			LExt.orig_loginname = @current_username OR
			ISNULL(UExt2.login_name, '') = '' OR
			-- a co-related query to find out if the current_user is a member of db_securityadmin or db_accessadmin role in database - UExt.database_name 
			EXISTS (
				SELECT 1
				FROM pg_catalog.pg_auth_members AS Authmbr
				INNER JOIN pg_catalog.pg_roles AS PGR1 ON PGR1.oid = Authmbr.roleid
				INNER JOIN pg_catalog.pg_roles AS PGR2 ON PGR2.oid = Authmbr.member
				INNER JOIN sys.babelfish_authid_user_ext AS UExt3 ON PGR1.rolname = UExt3.rolname
				INNER JOIN sys.babelfish_authid_user_ext AS UExt4 ON PGR2.rolname = UExt4.rolname
				WHERE UExt3.orig_username IN ('db_owner', 'db_securityadmin', 'db_accessadmin') 
				AND UExt4.database_name = UExt2.database_name -- filter to check if the processing db is equal to the outer query db, since we want to find if the user is a member of the roles in the outer db
				AND UExt4.login_name = @current_username
			)
		)
	ORDER BY LoginName, DBName, UserName
    
	RETURN 0;
END;
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_helplogins TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_type_precision_helper(IN type TEXT, IN typemod INT) RETURNS sys.TINYINT
AS $$
DECLARE
	precision INT;
  v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
		WHEN 'bigint' THEN precision = 19;
		WHEN 'bit' THEN precision = 1;
		WHEN 'date' THEN precision = 10;
		WHEN 'datetime' THEN precision = 23;
		WHEN 'datetime2' THEN precision = 26;
		WHEN 'datetimeoffset' THEN precision = 33;
		WHEN 'decimal' THEN precision = 38;
		WHEN 'numeric' THEN precision = 38;
		WHEN 'float' THEN precision = 53;
		WHEN 'int' THEN precision = 10;
		WHEN 'money' THEN precision = 19;
		WHEN 'real' THEN precision = 24;
		WHEN 'smalldatetime' THEN precision = 16;
		WHEN 'smallint' THEN precision = 5;
		WHEN 'smallmoney' THEN precision = 10;
		WHEN 'time' THEN precision = 15;
		WHEN 'tinyint' THEN precision = 3;
		ELSE precision = 0;
		END CASE;
		RETURN precision;
	END IF;

	CASE v_type
	WHEN 'numeric' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'decimal' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'money' THEN precision = 19;
	WHEN 'smallmoney' THEN precision = 10;
	WHEN 'smalldatetime' THEN precision = 16;
	WHEN 'datetime2' THEN 
		CASE typemod 
		WHEN 0 THEN precision = 19;
		WHEN 1 THEN precision = 21;
		WHEN 2 THEN precision = 22;
		WHEN 3 THEN precision = 23;
		WHEN 4 THEN precision = 24;
		WHEN 5 THEN precision = 25;
		WHEN 6 THEN precision = 26;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 27;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN precision = 26;
		WHEN 1 THEN precision = 28;
		WHEN 2 THEN precision = 29;
		WHEN 3 THEN precision = 30;
		WHEN 4 THEN precision = 31;
		WHEN 5 THEN precision = 32;
		WHEN 6 THEN precision = 33;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN precision = 34;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN precision = 8;
		WHEN 1 THEN precision = 10;
		WHEN 2 THEN precision = 11;
		WHEN 3 THEN precision = 12;
		WHEN 4 THEN precision = 13;
		WHEN 5 THEN precision = 14;
		WHEN 6 THEN precision = 15;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 16;
		END CASE;
	ELSE precision = 0;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
	scale INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
		WHEN 'date' THEN scale = 0;
		WHEN 'datetime' THEN scale = 3;
		WHEN 'smalldatetime' THEN scale = 0;
		WHEN 'datetime2' THEN scale = 6;
		WHEN 'datetimeoffset' THEN scale = 6;
		WHEN 'decimal' THEN scale = 38;
		WHEN 'numeric' THEN scale = 38;
		WHEN 'money' THEN scale = 4;
		WHEN 'smallmoney' THEN scale = 4;
		WHEN 'time' THEN scale = 6;
		WHEN 'tinyint' THEN scale = 0;
		ELSE
			IF return_null_for_rest
				THEN scale = NULL;
			ELSE scale = 0;
			END IF;
		END CASE;
		RETURN scale;
	END IF;

	CASE v_type 
	WHEN 'decimal' THEN scale = (typemod - 4) & 65535;
	WHEN 'numeric' THEN scale = (typemod - 4) & 65535;
	WHEN 'money' THEN scale = 4;
	WHEN 'smallmoney' THEN scale = 4;
	WHEN 'smalldatetime' THEN scale = 0;
	WHEN 'datetime2' THEN
		CASE typemod 
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	ELSE
		IF return_null_for_rest
			THEN scale = NULL;
		ELSE scale = 0;
		END IF;
	END CASE;
	RETURN scale;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

/*
 * Updates typmod values in pg_proc for smallmoney/money data types in
 * PLTSQL procedures/functions, defined in babelfish_namespace_ext schemas.
 * Sets money typmod to 1245192(19,4) and smallmoney to 655368(10,4) where typmod is -1.
 */
UPDATE pg_proc p
SET probin = (
	SELECT jsonb_set(
		p.probin::jsonb,
		'{typmod_array}',
		to_jsonb(
			(
				SELECT jsonb_agg(
					CASE
						WHEN p.prokind = 'p' OR (p.prokind = 'f' AND p.proargtypes[typ_index-1] IS NOT NULL) THEN
							CASE
								WHEN typmod = '-1' AND (p.proargtypes[typ_index-1] = 'sys.money'::regtype::oid) THEN '1245192'
								WHEN typmod = '-1' and (p.proargtypes[typ_index-1] = 'sys.smallmoney'::regtype::oid) THEN '655368'
								ELSE typmod
							END
						WHEN p.prokind = 'f' AND p.prorettype IS NOT NULL THEN
							CASE
								WHEN typmod = '-1' AND (p.prorettype = 'sys.money'::regtype::oid) THEN '1245192'
								WHEN typmod = '-1' AND (p.prorettype = 'sys.smallmoney'::regtype::oid) THEN '655368'
								ELSE typmod
							END
						ELSE typmod
					END
				)
				FROM jsonb_array_elements_text(p.probin::jsonb->'typmod_array') WITH ORDINALITY AS elem(typmod,typ_index)
			)
		)
	)
)
FROM sys.babelfish_namespace_ext sch, pg_language l
WHERE sch.nspname = p.pronamespace::regnamespace::name
	AND p.prolang = l.oid
	AND l.lanname = 'pltsql'
	AND ((p.prokind = 'p' AND p.proargtypes <> '') OR (p.prokind = 'f' AND p.proallargtypes IS NULL));

/*
 * Updates typmod values in pg_attribute for smallmoney/money columns
 * in r = ordinary table, i = index, v = view, p = partitioned table, I = partitioned index.
 * For other relkinds, we either don't create from TDS side or they don't support money/smallmoney.
 * Sets money typmod to 1245192(19,4) and smallmoney to 655368(10,4) where typmod is -1.
 */
UPDATE pg_attribute a
SET atttypmod =
	CASE
		WHEN atttypmod = '-1' AND (a.atttypid = 'sys.money'::regtype::oid)
		THEN 1245192
		WHEN atttypmod = '-1' AND (a.atttypid = 'sys.smallmoney'::regtype::oid)
		THEN 655368
		ELSE atttypmod
	END
FROM pg_class c
INNER JOIN sys.babelfish_namespace_ext sch
	ON sch.nspname = c.relnamespace::regnamespace::name
WHERE a.attrelid = c.oid
	AND a.atttypmod = -1
	AND NOT a.attisdropped
	AND (a.atttypid = 'sys.money'::regtype::oid OR
		a.atttypid = 'sys.smallmoney'::regtype::oid)
	AND c.relkind IN ('r', 'i', 'v', 'p', 'I');

/*
 * Updates typmod values for UDTs based on money/smallmoney types in babelfish_namespace_ext schemas.
 * Required when creating new tables or using these UDTs directly to ensure proper type handling.
 */
UPDATE pg_type t
SET typtypmod =
	CASE
		WHEN sys.bbf_get_immediate_base_type_of_UDT(t.oid) = 'sys.money'::regtype::oid
		THEN 1245192
		WHEN sys.bbf_get_immediate_base_type_of_UDT(t.oid) = 'sys.smallmoney'::regtype::oid
		THEN 655368
		ELSE t.typtypmod
	END
FROM sys.babelfish_namespace_ext sch
WHERE sch.nspname = t.typnamespace::regnamespace::name
	AND t.typtypmod = -1
	AND t.typtype = 'd';

CREATE OR REPLACE FUNCTION sys.power(IN arg1 sys.FIXEDDECIMAL, IN arg2 NUMERIC)
RETURNS sys.MONEY  AS 'babelfishpg_money','fixeddecimal_power' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(sys.FIXEDDECIMAL,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SMALLINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.TINYINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg BIGINT) RETURNS BIGINT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::BIGINT THEN 1::BIGINT
		WHEN arg < 0::BIGINT THEN -1::BIGINT
		ELSE 0::BIGINT
	END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.MONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::SYS.MONEY THEN 1::SYS.MONEY
		WHEN arg < 0::SYS.MONEY THEN -1::SYS.MONEY
		ELSE 0::SYS.MONEY
	END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.MONEY) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.SMALLMONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT sys.sign(arg::SYS.MONEY);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.SMALLMONEY) TO PUBLIC;

-- To handle remaining input datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg ANYELEMENT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(ANYELEMENT) TO PUBLIC;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.sign(IN arg TEXT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.floor(sys.fixeddecimal) RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimal_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(sys.fixeddecimal) RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimal_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.OBJECT_DEFINITION(IN object_id INT)
RETURNS sys.NVARCHAR
AS $$
DECLARE
    definition sys.NVARCHAR;
BEGIN

    definition = (SELECT cc.definition FROM sys.check_constraints cc WHERE cc.object_id = $1);
    IF (definition IS NULL)
    THEN
        definition = (SELECT dc.definition FROM sys.default_constraints dc WHERE dc.object_id = $1);
        IF (definition IS NULL)
        THEN
            definition = (SELECT asm.definition FROM sys.all_sql_modules asm WHERE asm.object_id = $1);
            IF (definition IS NULL)
            THEN
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    RETURN definition;
END;
$$
LANGUAGE plpgsql STABLE;

create or replace function sys.PATINDEX(in pattern varchar, in expression varchar) returns bigint as
$body$
declare
  v_find_result VARCHAR;
  v_pos bigint;
  v_regexp_pattern VARCHAR;
  start_offset boolean;
  end_offset boolean;
begin
  if pattern is null or expression is null then
    return null;
  end if;
  if pattern = '%' or pattern = '%%' then
    return 1;
  end if;
  if sys.is_collated_ai(expression) then
    return sys.patindex_ai_collations(pattern, expression);
  end if;
  if PG_CATALOG.left(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"', 'i'::pg_catalog.TEXT);
    start_offset := true;
  else
    v_regexp_pattern := '#"' || pattern;
    start_offset := false;
  end if;

  if PG_CATALOG.right(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%', 'i'::pg_catalog.TEXT);
    end_offset := true;
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
   end_offset := false;
  end if;
  v_find_result := substring(expression, v_regexp_pattern, '#');
  if v_find_result <> '' collate sys.database_default then
    if start_offset and not end_offset then
      v_pos := LENGTH(expression) - STRPOS(REVERSE(expression), REVERSE(v_find_result)) + 2 - LENGTH(v_find_result);
    else
      v_pos := strpos(expression, v_find_result);
    end if;
  else
    v_pos := 0;
  end if;
  return v_pos;
end;
$body$
language plpgsql immutable returns null on null input;

CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_BINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- CAST and related functions.
CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT)
RETURNS SMALLINT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS SMALLINT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS SMALLINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT)
RETURNS INT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS INT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS INT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT)
RETURNS BIGINT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS BIGINT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS BIGINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg anyelement) RETURNS TEXT AS 
$BODY$
DECLARE
    date_arg_datatype regtype;
    result TEXT;
    datetimeoffset_value sys.datetimeoffset;
BEGIN
    date_arg_datatype := pg_typeof(arg);

    IF dp = 'month'::text THEN
        result := to_char(arg::sys.DATETIME, 'TMMonth');
    -- '1969-12-28' is a Sunday
    ELSIF dp = 'dow'::text THEN
        result := to_char(arg::sys.DATETIME, 'TMDay');
    ELSIF dp = 'tzoffset'::text THEN
        IF date_arg_datatype IN ('sys.datetimeoffset'::regtype, 'sys.datetime2'::regtype) THEN
            -- Explicitly cast to datetimeoffset to validate
            -- This will throw an error if the timezone offset is invalid
            datetimeoffset_value := arg::DATETIMEOFFSET;
            result := PG_CATALOG.RIGHT(datetimeoffset_value::PG_CATALOG.TEXT, 6);
        ELSE
            RAISE EXCEPTION 'The datepart tzoffset is not supported by date function datename for data type %.', date_arg_datatype;
        END IF;
    ELSE
        result := sys.datepart(dp, arg)::TEXT;
    END IF;
    RETURN result;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;

-- Duplicate function with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg TEXT) RETURNS TEXT AS
$BODY$
DECLARE
    result TEXT;
    datetimeoffset_value sys.datetimeoffset;
BEGIN
    IF dp = 'month'::text THEN
        result := to_char(arg::date, 'TMMonth');
    -- '1969-12-28' is a Sunday
    ELSIF dp = 'dow'::text THEN
        result := to_char(arg::date, 'TMDay');
    ELSIF dp = 'tzoffset'::text THEN
        -- Explicitly cast to datetimeoffset to validate
        -- This will throw an error if the timezone offset is invalid
        datetimeoffset_value := arg::datetimeoffset;
        result := PG_CATALOG.RIGHT(datetimeoffset_value::PG_CATALOG.TEXT, 6);
    ELSE
        result := sys.datepart(dp, arg)::TEXT;
    END IF;
    RETURN result;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_broken_view_function()
RETURNS INT
AS $$
BEGIN
    RAISE EXCEPTION 'Cannot reference a broken view in query';
    RETURN 1;
END;
$$
LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION sys.babelfish_broken_view_function() TO PUBLIC;
COMMENT ON FUNCTION sys.babelfish_broken_view_function() IS 'Internal function used by broken views to prevent silent failures';

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
