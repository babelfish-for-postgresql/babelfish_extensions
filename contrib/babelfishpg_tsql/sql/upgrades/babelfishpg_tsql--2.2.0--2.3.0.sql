-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.3.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_view(schema_name varchar, view_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop view %s.%s', schema_name, view_name);
    query2 := format('drop view %s.%s', schema_name, view_name);
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
		WHERE Ext1.type = 'R'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	-- If the role is a SQL server predefined role (i.e. serveradmin), 
	-- do not raise an error even if it does not exist
	ELSE IF EXISTS (SELECT 1
				FROM sys.babelfish_authid_login_ext
				WHERE (rolname = @srvrolename
				OR lower(rolname) = lower(@srvrolename))
				AND type = 'R') 
			OR lower(@srvrolename) IN (
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
		WHERE Ext1.type = 'R'
		AND (Ext1.rolname = @srvrolename OR lower(Ext1.rolname) = lower(@srvrolename))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

-- BABELFISH_FUNCTION_EXT
CREATE TABLE sys.babelfish_function_ext (
	nspname NAME NOT NULL,
	funcname NAME NOT NULL,
	orig_name sys.NVARCHAR(128), -- users' original input name
	funcsignature TEXT NOT NULL COLLATE "C",
	default_positions TEXT COLLATE "C",
	PRIMARY KEY(nspname, funcsignature)
);
GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
