-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.3.0'" to load this file. \quit

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

ALTER FUNCTION sys.parsename(VARCHAR,INT) RENAME TO parsename_deprecated_in_3_3_0;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.VARCHAR, object_piece int)
RETURNS sys.SYSNAME
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_3_0');

CREATE OR REPLACE FUNCTION sys.EOMONTH(date,int DEFAULT 0)
RETURNS date
AS 'babelfishpg_tsql', 'EOMONTH'
LANGUAGE C STABLE PARALLEL SAFE;

ALTER TABLE sys.extended_properties RENAME TO extended_properties_deprecated_in_3_3_0;
CREATE TABLE sys.babelfish_extended_properties (
  dbid smallint NOT NULL,
  schema_name name NOT NULL,
  major_name name NOT NULL,
  minor_name name NOT NULL,
  type sys.varchar(50) NOT NULL,
  name sys.sysname NOT NULL,
  orig_name sys.sysname NOT NULL,
  value sys.sql_variant,
  PRIMARY KEY (dbid, type, schema_name, major_name, minor_name, name)
);
GRANT SELECT on sys.babelfish_extended_properties TO PUBLIC;

CREATE OR REPLACE VIEW sys.extended_properties
AS
SELECT
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 3
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 1
		WHEN ep.type = 'TYPE' THEN 6
		END) AS sys.tinyint) AS class,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 'DATABASE'
		WHEN ep.type = 'SCHEMA' THEN 'SCHEMA'
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 'OBJECT_OR_COLUMN'
		WHEN ep.type = 'TYPE' THEN 'TYPE'
	END) AS sys.nvarchar(60)) AS class_desc,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN n.oid
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE') THEN c.oid
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN p.oid
		WHEN ep.type = 'TYPE' THEN t.oid
	END) AS int) AS major_id,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 0
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION', 'TYPE') THEN 0
		WHEN ep.type = 'TABLE COLUMN' THEN a.attnum
	END) AS int) AS minor_id,
	ep.orig_name AS name, ep.value AS value
	FROM sys.babelfish_extended_properties ep
		LEFT JOIN sys.babelfish_namespace_ext ne ON ne.dbid = sys.db_id() AND ne.orig_name = ep.schema_name COLLATE "C"
		LEFT JOIN pg_catalog.pg_namespace n ON n.nspname = ne.nspname
		LEFT JOIN pg_catalog.pg_class c ON c.relname = ep.major_name AND c.relnamespace = n.oid
		LEFT JOIN pg_catalog.pg_proc p ON p.proname = ep.major_name AND p.pronamespace = n.oid
		LEFT JOIN pg_catalog.pg_type t ON t.typname = ep.major_name AND t.typnamespace = n.oid
		LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = ep.minor_name
	WHERE ep.dbid = sys.db_id() AND
	(CASE
		WHEN ep.type = 'DATABASE' THEN true
		WHEN ep.type = 'SCHEMA' THEN has_schema_privilege(n.oid, 'USAGE, CREATE')
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'))
		WHEN ep.type IN ('TABLE COLUMN') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') OR has_column_privilege(a.attrelid, a.attname, 'SELECT, INSERT, UPDATE, REFERENCES'))
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN has_function_privilege(p.oid, 'EXECUTE')
		WHEN ep.type = 'TYPE' THEN has_type_privilege(t.oid, 'USAGE')
	END)
	ORDER BY class, class_desc, major_id, minor_id, ep.orig_name;
GRANT SELECT ON sys.extended_properties TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('table', 'sys', 'extended_properties_deprecated_in_3_3_0');

ALTER FUNCTION sys.fn_listextendedproperty RENAME TO fn_listextendedproperty_deprecated_in_3_3_0;
CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty
(
    IN "@name" sys.sysname DEFAULT NULL,
    IN "@level0type" VARCHAR(128) DEFAULT NULL,
    IN "@level0name" sys.sysname DEFAULT NULL,
    IN "@level1type" VARCHAR(128) DEFAULT NULL,
    IN "@level1name" sys.sysname DEFAULT NULL,
    IN "@level2type" VARCHAR(128) DEFAULT NULL,
    IN "@level2name" sys.sysname DEFAULT NULL,
    OUT objtype sys.sysname,
    OUT objname sys.sysname,
    OUT name sys.sysname,
    OUT value sys.sql_variant
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_listextendedproperty_deprecated_in_3_3_0');

CREATE OR REPLACE PROCEDURE sys.sp_addextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_addextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updateextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_updateextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_dropextendedproperty
(
  "@name" sys.sysname,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_dropextendedproperty TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
