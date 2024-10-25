-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.0.0'" to load this file. \quit

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
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE VIEW information_schema_tsql.table_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(nr.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(extr.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) COLLATE sys.database_default AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype IN ('c', 'f', 'p', 'u')
          AND r.relkind IN ('r', 'p')
          AND relispartition = false
          AND (NOT pg_is_other_temp_schema(nr.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		  AND  extc.dbid = sys.db_id();

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
