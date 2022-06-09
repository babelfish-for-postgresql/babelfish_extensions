-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit

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

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name sys.SYSNAME NOT NULL,
	object_name sys.SYSNAME NOT NULL,
	definition sys.NTEXT,
	is_ansi_nulls_on sys.BIT,
	uses_quoted_identifier sys.BIT,
	is_schema_bound	sys.BIT,
	uses_database_collation sys.BIT,
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');

/*
 * VIEWS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.views AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS  "TABLE_SCHEMA",
			CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",

			CAST(
				CASE WHEN LENGTH(vd.definition) <= 4000
					THEN vd.definition
					ELSE NULL END
				AS sys.nvarchar(4000)) AS "VIEW_DEFINITION",

			CAST(
				CASE WHEN 'check_option=cascaded' = ANY (c.reloptions)
					THEN 'CASCADE'
					ELSE 'NONE' END
				AS sys.varchar(7)) AS "CHECK_OPTION",

			CAST('NO' AS sys.varchar(2)) AS "IS_UPDATABLE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname
		LEFT OUTER JOIN sys.babelfish_view_def vd
			ON ext.dbid = vd.dbid AND ext.orig_name = vd.schema_name AND c.relname = vd.object_name

	WHERE c.relkind = 'v'
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.views TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);