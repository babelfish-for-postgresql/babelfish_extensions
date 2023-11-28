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

CREATE VIEW information_schema_tsql.tables AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
			 CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
                  ELSE c.relname END
			 AS sys._ci_sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS sys.varchar(10)) COLLATE sys.database_default AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
		   left join sys.table_types_internal tt on c.oid = tt.typrelid

	WHERE c.relkind IN ('r', 'v', 'p')
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid is null
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

create or replace view sys.views as 
select 
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type 
  , 'VIEW'::varchar(60) as type_desc
  , vd.create_date::timestamp as create_date
  , vd.create_date::timestamp as modify_date
  , 0 as is_ms_shipped 
  , 0 as is_published 
  , 0 as is_schema_published 
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join sys.schemas sch on (t.relnamespace = sch.schema_id)
left join sys.shipped_objects_not_in_sys nis on (nis.name = t.relname and nis.schemaid = sch.schema_id and nis.type = 'V')
left outer join sys.babelfish_view_def vd on t.relname::sys.sysname = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id() 
where t.relkind = 'v'
and nis.name is null
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
