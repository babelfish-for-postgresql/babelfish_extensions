-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.12.0'" to load this file. \quit
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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE PROCEDURE sys.analyze_babelfish_catalogs()
LANGUAGE plpgsql
AS $$ 
DECLARE 
	babelfish_catalog RECORD;
	schema_name varchar = 'sys';
	error_msg text;
BEGIN
	FOR babelfish_catalog IN (
		SELECT relname as name FROM pg_catalog.pg_class t 
		INNER JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
		WHERE t.relkind = 'r' AND n.nspname = schema_name
		)
	LOOP
		BEGIN
			EXECUTE pg_catalog.format('ANALYZE %I.%I', schema_name, babelfish_catalog.name);
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
	reserved_roles varchar[] := ARRAY['sysadmin', 'securityadmin', 'dbcreator',
									  'master_dbo', 'master_guest', 'master_db_owner',
									  'master_db_accessadmin', 'master_db_securityadmin',
									  'master_db_datareader', 'master_db_datawriter', 'master_db_ddladmin',
									  'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner', 
									  'tempdb_db_accessadmin', 'tempdb_db_securityadmin',
									  'tempdb_db_datareader', 'tempdb_db_datawriter', 'tempdb_db_ddladmin',
									  'msdb_dbo', 'msdb_guest', 'msdb_db_owner',
									  'msdb_db_accessadmin', 'msdb_db_securityadmin',
									  'msdb_db_datareader', 'msdb_db_datawriter', 'msdb_db_ddladmin'];
	user_id  oid := -1;
	db_name  name := NULL;
	role_name varchar;
	dba_name varchar;
BEGIN
	-- check reserved roles
	FOREACH role_name IN ARRAY reserved_roles LOOP
	BEGIN
		SELECT oid INTO user_id FROM pg_catalog.pg_roles WHERE rolname = role_name;
		IF user_id > 0 THEN
			SELECT datname INTO db_name FROM pg_catalog.pg_shdepend AS s INNER JOIN pg_catalog.pg_database AS d ON s.dbid = d.oid WHERE s.refobjid = user_id;
			IF db_name IS NOT NULL THEN
				RAISE E'Could not initialize babelfish in current database: Reserved role % used in database %.\nIf babelfish was initialized in %, please remove babelfish and try again.', role_name, db_name, db_name;
			ELSE
				RAISE E'Could not initialize babelfish in current database: Reserved role % exists. \nPlease rename or drop existing role and try again ', role_name;
			END IF;
		END IF;
	END;
	END LOOP;

	SELECT pg_catalog.pg_get_userbyid(datdba) INTO dba_name FROM pg_catalog.pg_database WHERE datname = pg_catalog.current_database();
	IF sa_name <> dba_name THEN
		RAISE E'Could not initialize babelfish with given role name: % is not the DB owner of current database.', sa_name;
	END IF;

	EXECUTE pg_catalog.format('CREATE ROLE securityadmin CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('CREATE ROLE dbcreator CREATEDB INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('CREATE ROLE bbf_role_admin CREATEDB CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('GRANT CREATE ON DATABASE %s TO bbf_role_admin', pg_catalog.current_database());
	EXECUTE pg_catalog.format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', sa_name);
	EXECUTE pg_catalog.format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
	EXECUTE pg_catalog.format('GRANT sysadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT securityadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT dbcreator TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_function_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_scheme_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', pg_catalog.current_database());
	EXECUTE pg_catalog.format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', pg_catalog.current_database());
	EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
	CALL sys.babel_initialize_logins(sa_name);
	CALL sys.babel_initialize_logins('sysadmin');
	CALL sys.babel_initialize_logins('bbf_role_admin');
	CALL sys.babel_initialize_logins('securityadmin');
	CALL sys.babel_initialize_logins('dbcreator');
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
	EXECUTE pg_catalog.format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', pg_catalog.current_database());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_function_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_scheme_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
	DROP OWNED BY bbf_role_admin;
	DROP ROLE bbf_role_admin;
	DROP OWNED BY securityadmin;
	DROP ROLE securityadmin;
	DROP OWNED BY dbcreator;
	DROP ROLE dbcreator;
END
$$;
 
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
