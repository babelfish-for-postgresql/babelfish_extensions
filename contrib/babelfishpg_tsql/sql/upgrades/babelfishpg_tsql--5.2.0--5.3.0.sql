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

CREATE OR REPLACE PROCEDURE sys.sp_helplogins_internal_logins() 
LANGUAGE pltsql
AS $$
BEGIN
	IF is_srvrolemember('securityadmin') = 0 
  BEGIN
    RAISERROR('User does not have permission to perform this action.', 16, 1);
		RETURN 0;
  END

	SELECT DISTINCT
		CASE 
			WHEN Ext.orig_username = 'dbo' THEN Base3.oid
			WHEN Ext.orig_username = 'guest' THEN 0
			ELSE Base2.oid
		END AS oid INTO #all_database_users
	FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
	ON Base.rolname = Ext.rolname
	LEFT OUTER JOIN pg_catalog.pg_roles Base2
	ON Ext.login_name = Base2.rolname
	LEFT OUTER JOIN sys.babelfish_sysdatabases AS Db
	ON Ext.database_name COLLATE database_default = Db.name
	LEFT OUTER JOIN pg_catalog.pg_roles AS Base3
	ON Db.owner = Base3.rolname
	WHERE Ext.type != 'R' AND Ext.orig_username IS NOT NULL;

	SELECT
    CAST(LExt.orig_loginname AS sys.SYSNAME) AS LoginName,
    CAST(CAST(Base.oid AS INT) AS sys.varbinary(85)) AS sid,
    CAST(LExt.default_database_name AS SYS.SYSNAME) AS DefDBName,
    CAST(LExt.default_language_name AS SYS.SYSNAME) AS DefLangName,
    CASE 
      WHEN Dp.oid IS NOT NULL THEN 'YES'
      ELSE 'NO'
    END as AUser,
    'NO' AS ARemote -- Currently we do not support linking local logins to remote logins
  FROM pg_catalog.pg_roles AS Base 
  INNER JOIN sys.babelfish_authid_login_ext AS LExt ON Base.rolname = LExt.rolname
  LEFT JOIN #all_database_users Dp ON Dp.oid = Base.oid -- In order to find out if a login has any users associated with it
  WHERE LExt.type NOT IN ('R', 'Z');

	RETURN 0;
END;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helplogins_internal_user_mappings() 
LANGUAGE pltsql
AS $$
DECLARE @current_username sys.nvarchar(128)
BEGIN

	IF is_srvrolemember('securityadmin') = 0 
  BEGIN
    RAISERROR('User does not have permission to perform this action.', 16, 1);
		RETURN 0;
  END

	SELECT
		UExt2.database_name as database_name,
		UExt1.orig_username as role_name,
		UExt2.login_name as member_login INTO #db_role_mapping
	FROM pg_catalog.pg_auth_members AS Authmbr
	INNER JOIN pg_catalog.pg_roles AS PGR1 ON PGR1.oid = Authmbr.roleid
	INNER JOIN pg_catalog.pg_roles AS PGR2 ON PGR2.oid = Authmbr.member
	INNER JOIN sys.babelfish_authid_user_ext AS UExt1 ON PGR1.rolname = UExt1.rolname
	INNER JOIN sys.babelfish_authid_user_ext AS UExt2 ON PGR2.rolname = UExt2.rolname
	WHERE UExt1.orig_username IN ('db_securityadmin', 'db_accessadmin');

	SET @current_username = sys.suser_name();

  SELECT
    CAST(COALESCE(NULLIF(UExt.login_name, ''), Db.owner) AS sys.SYSNAME) AS LoginName,
		CAST(UExt.database_name AS sys.SYSNAME) AS DBName,
		CAST(UExt.orig_username AS SYS.SYSNAME) AS UserName,
		'User' AS UserOrAlias 
  FROM sys.babelfish_authid_user_ext UExt
  LEFT JOIN sys.babelfish_sysdatabases Db ON Db.name = UExt.database_name COLLATE database_default
  WHERE UExt.type != 'R' AND  
		UExt.orig_username != 'guest' AND 
		has_dbaccess(UExt.database_name) = 1 AND
		(
      is_srvrolemember('sysadmin') = 1 OR 
		  EXISTS (SELECT 1 from #db_role_mapping WHERE database_name = UExt.database_name AND member_login = @current_username) OR
		  UExt.login_name = LOWER(@current_username) OR
		  ISNULL(UExt.login_name, '') = ''
    )
  UNION
  SELECT
		CAST(COALESCE(NULLIF(UExt2.login_name, ''), Db.owner) AS sys.SYSNAME) AS LoginName,
    CAST(UExt2.database_name AS sys.SYSNAME) AS DBName,
    CAST(UExt1.orig_username AS SYS.SYSNAME) AS UserName,
    'Member of' AS UserOrAlias 
  FROM pg_catalog.pg_auth_members AS Authmbr
  INNER JOIN pg_catalog.pg_roles AS PGR1 ON PGR1.oid = Authmbr.roleid
  INNER JOIN pg_catalog.pg_roles AS PGR2 ON PGR2.oid = Authmbr.member
  INNER JOIN sys.babelfish_authid_user_ext AS UExt1 ON PGR1.rolname = UExt1.rolname AND UExt1.type = 'R'
  INNER JOIN sys.babelfish_authid_user_ext AS UExt2 ON PGR2.rolname = UExt2.rolname AND UExt2.orig_username != 'db_owner'
  LEFT JOIN sys.babelfish_sysdatabases Db ON Db.name = UExt1.database_name COLLATE database_default
  WHERE has_dbaccess(UExt2.database_name) = 1 AND
		(
			is_srvrolemember('sysadmin') = 1 OR 
			UExt2.login_name = LOWER(@current_username) OR
			ISNULL(UExt2.login_name, '') = ''
		)
	RETURN 0;
END;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helplogins(IN "@loginname" sys.sysname DEFAULT NULL)
LANGUAGE pltsql
AS $$
DECLARE @input_loginname sys.sysname;
BEGIN

	IF is_srvrolemember('securityadmin') = 0 
  BEGIN
    RAISERROR('User does not have permission to perform this action.', 16, 1);
		RETURN 0;
  END

	IF @loginname IS NULL
	BEGIN
		EXEC sp_helplogins_internal_logins;
		EXEC sp_helplogins_internal_user_mappings;
	END
	ELSE
	BEGIN
		SET @input_loginname = sys.RTRIM(@loginname);
		SET NOCOUNT ON;

		CREATE TABLE #sp_helplogins_internal_logins_temp(LoginName sys.sysname, sid sys.varbinary(85), DefDBName sys.sysname, DefLangName sys.sysname, AUser sys.nvarchar(8), ARemote sys.nvarchar(8))
		INSERT INTO #sp_helplogins_internal_logins_temp EXEC sp_helplogins_internal_logins;

		CREATE TABLE #sp_helplogins_internal_user_mappings_temp(LoginName sys.sysname, DBName sys.sysname, UserName sys.sysname, UserOrAlias sys.nvarchar(16))
		INSERT INTO #sp_helplogins_internal_user_mappings_temp EXEC sp_helplogins_internal_user_mappings;

		SET NOCOUNT OFF;

		SELECT * FROM #sp_helplogins_internal_logins_temp
		WHERE LoginName = @input_loginname;

		SELECT * FROM #sp_helplogins_internal_user_mappings_temp
		WHERE LoginName = @input_loginname;
	END;
  RETURN 0;
END;
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_helplogins TO PUBLIC;

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

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
