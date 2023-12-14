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

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);