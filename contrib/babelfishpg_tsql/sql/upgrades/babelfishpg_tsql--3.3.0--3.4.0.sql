-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.4.0'" to load this file. \quit

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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE VIEW information_schema_tsql.key_column_usage AS
	SELECT
		CAST(ss.nc_dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
		CAST(ss.nc_schema_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
		CAST(ss.conname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME",
		CAST(ss.nr_dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		CAST(ss.nr_schema_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		CAST(ss.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
		CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
		CAST((ss.x).n AS int) AS "ORDINAL_POSITION"
	
	FROM
		pg_attribute a, (
		SELECT
			r.oid AS roid,
			r.relname,
			r.relowner,
			nc.dbname AS nc_dbname,
			nr.dbname AS nr_dbname,
			extc.orig_name AS nc_schema_name,
			extr.orig_name AS nr_schema_name,
			c.oid AS coid,
			c.conname,
			c.contype,
			c.conindid,
			c.confkey,
			c.confrelid,
			information_schema._pg_expandarray(c.conkey) AS x
		FROM
			sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
			sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
			pg_class r,
			pg_constraint c,
			sys.pg_namespace_ext t
		WHERE
			nr.oid = r.relnamespace
			AND r.oid = c.conrelid
			AND nc.oid = c.connamespace
			AND nr.nspname = t.nspname
			AND t.dbname = nc.dbname
			AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"]))
			AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"]))
			AND NOT pg_is_other_temp_schema(nr.oid)
		) ss
	
	WHERE
		ss.roid = a.attrelid
		AND a.attnum = (ss.x).x
		AND NOT a.attisdropped
		AND (pg_has_role(ss.relowner, 'USAGE'::text) OR has_column_privilege(ss.roid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text));

GRANT SELECT ON information_schema_tsql.key_column_usage TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
