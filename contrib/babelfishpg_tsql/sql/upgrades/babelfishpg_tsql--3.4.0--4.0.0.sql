-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.0.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- please add your SQL here

-- for 4.0.0 we need to give CREATEROLE privileges to <db_name>_db_owner
do
LANGUAGE plpgsql
$$
DECLARE temprow RECORD;
DECLARE query TEXT;
BEGIN
    FOR temprow IN
        SELECT name FROM sys.databases
    LOOP
        query := pg_catalog.format('ALTER ROLE %I_db_owner WITH CREATEROLE;', temprow.name);
        EXECUTE query;
    END LOOP;
END;
$$;

-- Give bbf_role_admin privileges on every Babelfish role
-- Need to create the role if it doesn't exist (e.g. from upgrade)
do
LANGUAGE plpgsql
$$
DECLARE bbf_role_admin TEXT;
DECLARE temprow RECORD;
DECLARE query TEXT;
BEGIN
    IF EXISTS (
               SELECT FROM pg_catalog.pg_roles
               WHERE  rolname = 'bbf_role_admin') 
        THEN
            RAISE NOTICE 'Role "bbf_role_admin" already exists. Skipping.';
    ELSE
        EXECUTE format('CREATE ROLE bbf_role_admin WITH CREATEDB CREATEROLE INHERIT PASSWORD NULL');
        EXECUTE format('GRANT CREATE ON DATABASE %s TO bbf_role_admin WITH GRANT OPTION', CURRENT_DATABASE());
	    EXECUTE format('GRANT sysadmin TO bbf_role_admin WITH ADMIN TRUE');
        CALL sys.babel_initialize_logins('bbf_role_admin');
    END IF;
    FOR temprow IN
        SELECT DISTINCT on (grantee, role_name) grantee, role_name FROM information_schema.applicable_roles WHERE NOT (role_name = 'sysadmin' OR role_name = 'bbf_role_admin' OR grantee = 'bbf_role_admin' OR role_name LIKE 'pg_%')
    LOOP
        query := pg_catalog.format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', temprow.grantee);
        EXECUTE query;
        query := pg_catalog.format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', temprow.role_name);
        EXECUTE query;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helpuser("@name_in_db" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If security account is not specified, return info about all users
	IF @name_in_db IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public'
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
					ELSE LogExt.orig_loginname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username != 'db_owner'
		ORDER BY UserName, RoleName;
	END
	-- If the security account is the db fixed role - db_owner
    ELSE IF @name_in_db = 'db_owner'
	BEGIN
		-- TODO: Need to change after we can add/drop members to/from db_owner
		SELECT CAST('db_owner' AS SYS.SYSNAME) AS 'Role_name',
			   ROLE_ID('db_owner') AS 'Role_id',
			   CAST('dbo' AS SYS.SYSNAME) AS 'Users_in_role',
			   USER_ID('dbo') AS 'Userid';
	END
	-- If the security account is a db role
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR lower(orig_username) = lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'Role_name',
			   CAST(Base1.oid AS INT) AS 'Role_id',
			   CAST(Ext2.orig_username AS SYS.SYSNAME) AS 'Users_in_role',
			   CAST(Base2.oid AS INT) AS 'Userid'
		FROM sys.babelfish_authid_user_ext AS Ext2
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.rolname = Ext2.rolname
		INNER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base2.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
		ORDER BY Role_name, Users_in_role;
	END
	-- If the security account is a user
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR lower(orig_username) = lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type != 'R')
	BEGIN
		SELECT DISTINCT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public' 
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
					ELSE LogExt.orig_loginname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
		ORDER BY UserName, RoleName;
	END
	-- If the security account is not valid
	ELSE 
		RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_helpuser TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);