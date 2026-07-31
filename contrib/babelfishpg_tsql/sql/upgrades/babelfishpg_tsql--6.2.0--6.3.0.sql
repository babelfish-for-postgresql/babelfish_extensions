-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '6.3.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar, arg_types varchar DEFAULT '') AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
    full_object_name text;
BEGIN
    -- Construct full object name with argument types if provided (for aggregates)
    IF arg_types <> '' THEN
        full_object_name := pg_catalog.format('%s.%s(%s)', schema_name, object_name, arg_types);
    ELSE
        full_object_name := pg_catalog.format('%s.%s', schema_name, object_name);
    END IF;

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', object_type, full_object_name);
    query2 := pg_catalog.format('drop %s %s', object_type, full_object_name);
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

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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



-- BABEL-5975: Add orig_name column to babelfish_sysdatabases and database name resolution
-- 2. Add orig_name column to babelfish_sysdatabases if not exists
SET allow_system_table_mods = on;
ALTER TABLE sys.babelfish_sysdatabases ADD COLUMN IF NOT EXISTS orig_name sys.NVARCHAR(128) COLLATE sys.database_default;
RESET allow_system_table_mods;

-- 3. Populate orig_name for existing databases (copy from name column for case preservation)
UPDATE sys.babelfish_sysdatabases SET orig_name = name WHERE orig_name IS NULL;

-- 5i. sys.databases and sys.sysdatabases (use orig_name)
-- Save user views depending on wrapper sysdatabases views before rename
CREATE TEMPORARY TABLE IF NOT EXISTS _saved_sysdatabases_deps (stmt TEXT);
DO $$
DECLARE r RECORD;
    dep RECORD;
    schema_name TEXT;
BEGIN
    FOR r IN SELECT name FROM sys.babelfish_sysdatabases LOOP
        schema_name := r.name || '_dbo';
        IF length(schema_name) > 63 THEN
            schema_name := sys.babelfish_truncate_identifier(schema_name);
        END IF;
        FOR dep IN
            SELECT DISTINCT depv.oid, n.nspname, depv.relname, pg_get_viewdef(depv.oid, true) AS viewdef, depv.relowner
            FROM pg_depend d
            JOIN pg_rewrite rw ON rw.oid = d.objid
            JOIN pg_class depv ON depv.oid = rw.ev_class
            JOIN pg_class src ON src.oid = d.refobjid
            JOIN pg_namespace n ON n.oid = depv.relnamespace
            WHERE src.relname = 'sysdatabases'
              AND src.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = schema_name)
              AND depv.oid != src.oid
              AND depv.relkind = 'v'
        LOOP
            INSERT INTO _saved_sysdatabases_deps VALUES (format('CREATE OR REPLACE VIEW %I.%I AS %s', dep.nspname, dep.relname, dep.viewdef));
            INSERT INTO _saved_sysdatabases_deps VALUES (format('ALTER TABLE %I.%I OWNER TO %s', dep.nspname, dep.relname, (SELECT rolname FROM pg_roles WHERE oid = dep.relowner)));
        END LOOP;
    END LOOP;
END $$;

ALTER VIEW sys.sysdatabases RENAME TO sysdatabases_deprecated_in_6_3_0;

CREATE OR REPLACE VIEW sys.sysdatabases AS
SELECT
CAST(t.orig_name AS sys.nvarchar(128)) AS name,
sys.db_id(t.name) AS dbid,
CAST(CAST(r.oid AS int) AS SYS.VARBINARY(85)) AS sid,
CAST(0 AS SMALLINT) AS mode,
t.status,
t.status2,
CAST(t.crdate AS SYS.DATETIME) AS crdate,
CAST('1900-01-01 00:00:00.000' AS SYS.DATETIME) AS reserved,
CAST(0 AS INT) AS category,
CAST(120 AS SYS.TINYINT) AS cmptlevel,
CAST(NULL AS SYS.NVARCHAR(260)) AS filename,
CAST(NULL AS SMALLINT) AS version
FROM sys.babelfish_sysdatabases AS t
LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = t.owner;

GRANT SELECT ON sys.sysdatabases TO PUBLIC;

-- 5j. sys.pg_namespace_ext (uses orig_name for dbname)
ALTER VIEW sys.pg_namespace_ext RENAME TO pg_namespace_ext_deprecated_in_6_3_0;

CREATE OR REPLACE VIEW sys.pg_namespace_ext AS
SELECT BASE.*, DB.orig_name as dbname FROM
pg_catalog.pg_namespace AS base
LEFT OUTER JOIN sys.babelfish_namespace_ext AS EXT on BASE.nspname = EXT.nspname
INNER JOIN sys.babelfish_sysdatabases AS DB ON EXT.dbid = DB.dbid;
GRANT SELECT ON sys.pg_namespace_ext TO PUBLIC;
-- Recreate dependent views after pg_namespace_ext rename (rebind to new OID)

CREATE OR replace view sys.identity_columns AS
SELECT
  CAST(out_object_id AS INT) AS object_id
  , CAST(out_name AS sys.sysname) AS name
  , CAST(out_column_id AS INT) AS column_id
  , CAST(out_system_type_id AS sys.tinyint) AS system_type_id
  , CAST(out_user_type_id AS INT) AS user_type_id
  , CAST(out_max_length AS SMALLINT) AS max_length
  , CAST(out_precision AS sys.tinyint) AS precision
  , CAST(out_scale AS sys.tinyint) AS scale
  , CAST(out_collation_name AS sys.sysname) AS collation_name
  , CAST(out_is_nullable AS sys.BIT) AS is_nullable
  , CAST(out_is_ansi_padded AS sys.BIT) AS is_ansi_padded
  , CAST(out_is_rowguidcol AS sys.BIT) AS is_rowguidcol
  , CAST(out_is_identity AS sys.BIT) AS is_identity
  , CAST(out_is_computed AS sys.BIT) AS is_computed
  , CAST(out_is_filestream AS sys.BIT) AS is_filestream
  , CAST(out_is_replicated AS sys.BIT) AS is_replicated
  , CAST(out_is_non_sql_subscribed AS sys.BIT) AS is_non_sql_subscribed
  , CAST(out_is_merge_published AS sys.BIT) AS is_merge_published
  , CAST(out_is_dts_replicated AS sys.BIT) AS is_dts_replicated
  , CAST(out_is_xml_document AS sys.BIT) AS is_xml_document
  , CAST(out_xml_collection_id AS INT) AS xml_collection_id
  , CAST(out_default_object_id AS INT) AS default_object_id
  , CAST(out_rule_object_id AS INT) AS rule_object_id
  , CAST(out_is_sparse AS sys.BIT) AS is_sparse
  , CAST(out_is_column_set AS sys.BIT) AS is_column_set
  , CAST(out_generated_always_type AS sys.tinyint) AS generated_always_type
  , CAST(out_generated_always_type_desc AS sys.NVARCHAR(60)) AS generated_always_type_desc
  , CAST(out_encryption_type AS INT) AS encryption_type
  , CAST(out_encryption_type_desc AS sys.NVARCHAR(60)) AS encryption_type_desc
  , CAST(out_encryption_algorithm_name AS sys.sysname) AS encryption_algorithm_name
  , CAST(out_column_encryption_key_id AS INT) column_encryption_key_id
  , CAST(out_column_encryption_key_database_name AS sys.sysname) AS column_encryption_key_database_name
  , CAST(out_is_hidden AS sys.BIT) AS is_hidden
  , CAST(out_is_masked AS sys.BIT) AS is_masked
  , CAST(sys.ident_seed(sys.OBJECT_NAME(sc.out_object_id)) AS sys.sql_variant) AS seed_value
  , CAST(sys.ident_incr(sys.OBJECT_NAME(sc.out_object_id)) AS sys.sql_variant) AS increment_value
  , CAST(sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) AS sys.sql_variant) AS last_value
  , CAST(0 as sys.BIT) as is_not_for_replication
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON a.attrelid = sc.out_object_id AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar) AS definition
  , CAST(1 as sys.bit) AS uses_ansi_nulls
  , CAST(1 as sys.bit) AS uses_quoted_identifier
  , CAST(0 as sys.bit) AS is_schema_bound
  , CAST(0 as sys.bit) AS uses_database_collation
  , CAST(0 as sys.bit) AS is_recompiled
  , CAST(ao.type IN ('P', 'FN', 'IN', 'TF', 'RF', 'IF')
        AND p.proisstrict
    AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nmext.nspname = ext.nspname
LEFT OUTER JOIN sys.babelfish_view_def bvd
 on (
      ext.orig_name = bvd.schema_name AND
      ext.dbid = bvd.dbid AND
      sys.babelfish_truncate_identifier(ao.name::text) = bvd.object_name COLLATE sys.database_default
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
LEFT JOIN sys.babelfish_function_ext f ON ao.name = f.funcname COLLATE "C" AND ao.schema_id::regnamespace::name = f.nspname
AND sys.babelfish_get_pltsql_function_signature(ao.object_id) = f.funcsignature COLLATE "C"
WHERE ao.type in ('P', 'RF', 'V', 'FN', 'IF', 'TF', 'R')
UNION ALL
SELECT
  ao.object_id AS object_id
  , CAST(COALESCE(f.definition, '') AS sys.nvarchar) AS definition
  , CAST(1 as sys.bit) AS uses_ansi_nulls
  , CAST(1 as sys.bit) AS uses_quoted_identifier
  , CAST(0 as sys.bit) AS is_schema_bound
  , CAST(0 as sys.bit) AS uses_database_collation
  , CAST(0 as sys.bit) AS is_recompiled
  , CAST(0 AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT JOIN pg_trigger tr ON ao.object_id = CAST(tr.oid AS INT)
LEFT JOIN sys.babelfish_function_ext f ON ao.name = f.funcname COLLATE "C" AND ao.schema_id::regnamespace::name = f.nspname
AND sys.babelfish_get_pltsql_function_signature(tr.tgfoid) = f.funcsignature COLLATE "C"
WHERE ao.type = 'TR';
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
 JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
 JOIN pg_constraint t5 ON t1.oid = t5.conrelid
 , generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = sys.db_id();

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
     CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
     CAST(sys.tsql_get_constraintdef(c.oid) AS sys.nvarchar(4000)) AS "CHECK_CLAUSE"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nc.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND r.relispartition = false
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
    AND extc.dbid = sys.db_id();

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.routines AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SPECIFIC_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "SPECIFIC_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "SPECIFIC_NAME",
           CAST(nc.dbname AS sys.nvarchar(128)) AS "ROUTINE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "ROUTINE_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "ROUTINE_NAME",
           CAST(CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END
             AS sys.nvarchar(20)) AS "ROUTINE_TYPE",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_NAME",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_NAME",
    CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
           CAST(information_schema_tsql._pgtsql_char_max_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_MAXIMUM_LENGTH",
           CAST(information_schema_tsql._pgtsql_char_octet_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_OCTET_LENGTH",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_SCHEMA",
           CAST(
                 CASE co.collname
                       WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
                       ELSE co.collname
                 END
            AS sys.nvarchar(128)) AS "COLLATION_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",




     CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
     CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION",
     CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_SCALE",
            CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
                        AS smallint)
            AS "DATETIME_PRECISION",
     CAST(NULL AS sys.nvarchar(30)) AS "INTERVAL_TYPE",
            CAST(NULL AS smallint) AS "INTERVAL_PRECISION",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_NAME",
            CAST(NULL AS bigint) AS "MAXIMUM_CARDINALITY",
            CAST(NULL AS sys.nvarchar(128)) AS "DTD_IDENTIFIER",
            CAST(CASE WHEN l.lanname = 'sql' THEN 'SQL' WHEN l.lanname = 'pltsql' THEN 'SQL' ELSE 'EXTERNAL' END AS sys.nvarchar(30)) AS "ROUTINE_BODY",
            CAST(f.definition AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
     CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
     inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT)
  LEFT JOIN sys.babelfish_function_ext f ON p.proname = f.funcname AND sch.schema_id::regnamespace::name = f.nspname
   AND sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature COLLATE "C",
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
     sys.is_table_type(t.typrelid) as is_tbl_type

       WHERE
            (case p.prokind
        when 'p' then true
        when 'a' then false
               else
                (case format_type(p.prorettype, null)
           when 'trigger' then false
           else true
         end)
            end)
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND has_function_privilege(p.oid, 'EXECUTE')
            AND (pg_has_role(t.typowner, 'USAGE')
            OR has_type_privilege(t.oid, 'USAGE'))
            AND ext.dbid = sys.db_id()
     AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid
     AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.schemata AS
 SELECT CAST(sys.db_name() AS sys.sysname) AS "CATALOG_NAME",
 CAST(CASE WHEN np.nspname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN PG_CATALOG.RIGHT(np.nspname, LENGTH(np.nspname) - LENGTH(sys.db_name()) - 1)
      ELSE np.nspname END AS sys.nvarchar(128)) AS "SCHEMA_NAME",
 -- For system-defined schemas, schema-owner name will be same as schema_name
 -- For user-defined schemas having default owner, schema-owner will be dbo
 -- For user-defined schemas with explicit owners, rolname contains dbname followed
 -- by owner name, so need to extract the owner name from rolname always.
 CAST(CASE WHEN sys.bbf_is_shared_schema(np.nspname) = TRUE THEN np.nspname
    WHEN r.rolname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN
   CASE WHEN PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) = 'db_owner' THEN 'dbo'
        ELSE PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) END ELSE 'dbo' END
   AS sys.nvarchar(128)) AS "SCHEMA_OWNER",
 CAST(null AS sys.varchar(6)) AS "DEFAULT_CHARACTER_SET_CATALOG",
 CAST(null AS sys.varchar(3)) AS "DEFAULT_CHARACTER_SET_SCHEMA",
 -- TODO: We need to first create mapping of collation name to char-set name;
 -- Until then return null for DEFAULT_CHARACTER_SET_NAME
 CAST(null AS sys.sysname) AS "DEFAULT_CHARACTER_SET_NAME"
 FROM ((pg_catalog.pg_namespace np LEFT JOIN sys.pg_namespace_ext nc on np.nspname = nc.nspname)
  LEFT JOIN pg_catalog.pg_roles r on r.oid = nc.nspowner) LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
 WHERE (ext.dbid = sys.db_id() OR np.nspname in ('sys', 'information_schema_tsql')) AND
       (pg_has_role(np.nspowner, 'USAGE') OR has_schema_privilege(np.oid, 'CREATE, USAGE'))
 ORDER BY nc.nspname, np.nspname;

GRANT SELECT ON information_schema_tsql.schemata TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.SEQUENCES AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SEQUENCE_CATALOG",
            CAST(extc.orig_name AS sys.nvarchar(128)) AS "SEQUENCE_SCHEMA",
            CAST(r.relname AS sys.nvarchar(128)) AS "SEQUENCE_NAME",
            CAST(CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype) ELSE tsql_type_name END
                    AS sys.nvarchar(128))AS "DATA_TYPE", -- numeric and decimal data types are converted into bigint which is due to Postgres inherent implementation
            CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, -1)
                        AS smallint) AS "NUMERIC_PRECISION",
            CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, -1)
                        AS smallint) AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, -1)
                        AS int) AS "NUMERIC_SCALE",
            CAST(s.seqstart AS sys.sql_variant) AS "START_VALUE",
            CAST(s.seqmin AS sys.sql_variant) AS "MINIMUM_VALUE",
            CAST(s.seqmax AS sys.sql_variant) AS "MAXIMUM_VALUE",
            CAST(s.seqincrement AS sys.sql_variant) AS "INCREMENT",
            CAST( CASE WHEN s.seqcycle = 't' THEN 1 ELSE 0 END AS int) AS "CYCLE_OPTION",
            CAST(NULL AS sys.nvarchar(128)) AS "DECLARED_DATA_TYPE",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_PRECISION",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_SCALE"
        FROM sys.pg_namespace_ext nc JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
            pg_sequence s join pg_class r on s.seqrelid = r.oid join pg_type t on s.seqtypid=t.oid,
            sys.translate_pg_type_to_tsql(s.seqtypid) AS tsql_type_name
        WHERE nc.oid = r.relnamespace
        AND extc.dbid = sys.db_id()
            AND r.relkind = 'S'
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND (pg_has_role(r.relowner, 'USAGE')
                OR has_sequence_privilege(r.oid, 'SELECT, UPDATE, USAGE'));


CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT 
CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(PG_CATALOG.concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(PG_CATALOG.concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(PG_CATALOG.concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(PG_CATALOG.concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM    pg_catalog.pg_namespace n 
JOIN    pg_catalog.pg_proc p 
ON      pronamespace = n.oid   
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

GRANT SELECT ON sys.sp_stored_procedures_view TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.bbf_cur_db() RETURNS TEXT
AS 'babelfishpg_tsql', 'babelfish_db_name_internal'
LANGUAGE C PARALLEL SAFE STABLE;

-- Fix sp_helpdb parameter to accept long names
CREATE OR REPLACE PROCEDURE sys.sp_helpdb(IN "@dbname" sys.sysname)
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT
  CAST(name AS sys.nvarchar(128)),
  CAST(db_size AS sys.nvarchar(13)),
  CAST(owner AS sys.nvarchar(128)),
  CAST(dbid AS sys.int),
  CAST(created AS sys.nvarchar(11)),
  CAST(status AS sys.nvarchar(600)),
  CAST(compatibility_level AS sys.tinyint)
  FROM sys.babelfish_helpdb(CAST("@dbname" AS VARCHAR(128)));

  SELECT
  CAST(NULL AS sys.NCHAR(128)) AS name,
  CAST(NULL AS SMALLINT) AS fileid,
  CAST(NULL AS sys.NCHAR(260)) AS filename,
  CAST(NULL AS sys.NVARCHAR(128)) AS filegroup,
  CAST(NULL AS sys.NVARCHAR(18)) AS size,
  CAST(NULL AS sys.NVARCHAR(18)) AS maxsize,
  CAST(NULL AS sys.NVARCHAR(18)) AS growth,
  CAST(NULL AS sys.VARCHAR(9)) AS usage;

  RETURN 0;
END;
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_helpdb(sys.sysname) TO PUBLIC;



-- Recreate views dependent on pg_namespace_ext (rebind after rename)

ALTER VIEW sys.sp_tables_view RENAME TO sp_tables_view_deprecated_in_6_3_0;
CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
CAST(t3.name AS name) AS TABLE_OWNER,
t1.relname AS TABLE_NAME,

CASE 
WHEN t1.relkind = 'v' 
	THEN 'VIEW'
ELSE 'TABLE'
END AS TABLE_TYPE,

CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, sys.schemas AS t3
WHERE t1.relnamespace = t3.schema_id AND t1.relnamespace = t2.oid AND t1.relkind IN ('r','p','v','m') 
AND t1.relispartition = false
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.sp_tables_view TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
SELECT 
	CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
	CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
	CAST(
		COALESCE(
			(SELECT pg_catalog.string_agg(
				CASE
					WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23 /* prefix length */)
					ELSE NULL
				END, ',')
			FROM unnest(t1.reloptions) AS option),
			t4."TABLE_NAME")
		AS sys.sysname) AS TABLE_NAME,
	CAST(
		COALESCE(
			(SELECT pg_catalog.string_agg(
				CASE
					WHEN option LIKE 'bbf_original_name=%' THEN substring(option, 19 /* prefix length */)
					ELSE NULL
				END, ',')
			FROM unnest(a.attoptions) AS option),
			t4."COLUMN_NAME")
		AS sys.sysname) AS COLUMN_NAME,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,
	CASE 
		WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
		WHEN a.atttypmod != -1
			THEN CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
		WHEN tsql_type_name = 'timestamp'
			THEN 8
		ELSE
			CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
	END AS PRECISION,
	CASE 
		WHEN a.atttypmod != -1
			THEN CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
		ELSE
			CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
	END AS LENGTH,
	CASE 
		WHEN a.atttypmod != -1
			THEN CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
		ELSE
			CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
	END AS SCALE,
	CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
	CASE 
		WHEN t4."IS_NULLABLE" = 'YES'
			THEN CAST(1 AS smallint)
		ELSE
			CAST(0 AS smallint)
	END AS NULLABLE,
	CAST(NULL AS varchar(254)) AS remarks,
	CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,
	CASE 
		WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
		WHEN t4."DATA_TYPE" = 'sql_variant' THEN 8000::INT
		WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
		ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
	END AS CHAR_OCTET_LENGTH,
	CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
	CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(0 AS smallint) AS SS_IS_SPARSE,
	CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
	CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
	CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
	CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
	CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
	CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
	CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
	CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
	CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME
FROM 
	pg_catalog.pg_class t1
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
	LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
	JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
	LEFT JOIN pg_type t ON t.oid = a.atttypid
	LEFT JOIN sys.columns t6 ON
	(
		t1.oid = t6.object_id AND
		t4."ORDINAL_POSITION" = t6.column_id
	)
	, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
	, sys.spt_datatype_info_table AS t5
WHERE 
	(t4."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)) OR (t4."DATA_TYPE" = 'bytea' AND t5.TYPE_NAME = 'image'))
	AND ext.dbid = sys.db_id();

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

ALTER VIEW sys.sp_special_columns_view RENAME TO sp_special_columns_view_deprecated_in_6_3_0;
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
CAST(coalesce (split_part(a.attoptions[1] COLLATE "C", '=', 2) ,a.attname) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS SMALLINT) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN  a.attidentity <> ''::"char" AND (t1.name = 'decimal' OR t1.name = 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, '() identity') AS sys.sysname)
	WHEN  a.attidentity <> ''::"char" AND (t1.name != 'decimal' AND t1.name != 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, ' identity') AS sys.sysname)
	ELSE CAST(t1.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(COALESCE(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS SMALLINT) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CASE
	WHEN a.attnotnull
	THEN CAST(0 AS INT)
	ELSE CAST(1 AS INT) END
AS IS_NULLABLE,
CAST(nsp_ext.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(C.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN X.indisprimary
	THEN CAST('p' AS sys.sysname)
	ELSE CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
END AS CONSTRAINT_TYPE,
CAST(I.relname AS sys.sysname) CONSTRAINT_NAME,
CAST(X.indexrelid AS int) AS INDEX_ID

FROM( pg_index X
JOIN pg_class C ON X.indrelid = C.oid
JOIN pg_class I ON I.oid = X.indexrelid
CROSS JOIN LATERAL unnest(X.indkey) AS ak(k)
        LEFT JOIN pg_attribute a
                       ON (a.attrelid = X.indrelid AND a.attnum = ak.k)
)
LEFT JOIN sys.pg_namespace_ext nsp_ext ON C.relnamespace = nsp_ext.oid
LEFT JOIN sys.schemas s1 ON s1.schema_id = C.relnamespace
LEFT JOIN sys.columns c1 ON c1.object_id = X.indrelid AND cast(a.attname AS sys.sysname) = c1.name COLLATE sys.database_default
LEFT JOIN pg_catalog.pg_type AS T ON T.oid = c1.system_type_id
LEFT JOIN sys.types AS t1 ON a.atttypid = t1.user_type_id
LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON T.typname = t6.pg_type_name OR T.typname = t6.type_name --need in order to get accurate DATA_TYPE value
, sys.translate_pg_type_to_tsql(t1.user_type_id) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t1.system_type_id) AS tsql_base_type_name
WHERE X.indislive ;

GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC; 

ALTER VIEW sys.sp_fkeys_view RENAME TO sp_fkeys_view_deprecated_in_6_3_0;
CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
CAST(c2.relname AS sys.sysname) AS PKTABLE_NAME,
CAST(COALESCE(split_part(a2.attoptions[1] COLLATE "C", '=', 2),a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
CAST(c.relname AS sys.sysname) AS FKTABLE_NAME,
CAST(COALESCE(split_part(a.attoptions[1] COLLATE "C", '=', 2),a.attname) AS sys.sysname) AS FKCOLUMN_NAME,
CAST(nr AS smallint) AS KEY_SEQ,
CASE
   WHEN const1.confupdtype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confupdtype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confupdtype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confupdtype = 'd' THEN CAST(3 AS smallint) -- set default
END AS UPDATE_RULE,

CASE
   WHEN const1.confdeltype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confdeltype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confdeltype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confdeltype = 'd' THEN CAST(3 AS smallint) -- set default
   ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(const1.conname AS sys.sysname) AS FK_NAME,
CAST(const2.conname AS sys.sysname) AS PK_NAME,
CASE
   WHEN const1.condeferrable = false THEN CAST(7 as smallint) -- not deferrable
   ELSE (CASE WHEN const1.condeferred = false THEN CAST(6 as smallint) --  not deferred by default
              ELSE CAST(5 as smallint) -- deferred by default
         END)
END AS DEFERRABILITY

FROM (pg_constraint const1
-- join with nsp_Ext to get constraints in current namespace
JOIN sys.pg_namespace_ext nsp_ext ON nsp_ext.oid = const1.connamespace
--get the table names corresponding to foreign keys
JOIN pg_class c ON const1.conrelid = c.oid AND const1.contype ='f'
-- join wiht bbf_nsp to get all constraint related to tsql endpoint and the owner of foreign key
JOIN sys.babelfish_namespace_ext bbf_nsp ON bbf_nsp.nspname = nsp_ext.nspname AND bbf_nsp.dbid = sys.db_id()
-- lateral join to use the conkey and confkey to join with pg_attribute to get column names
CROSS JOIN LATERAL unnest(const1.conkey,const1.confkey) WITH ORDINALITY AS ak(j, k, nr)
            LEFT JOIN pg_attribute a
                       ON (a.attrelid = const1.conrelid AND a.attnum = ak.j)
            LEFT JOIN pg_attribute a2
                       ON (a2.attrelid = const1.confrelid AND a2.attnum = ak.k)
)
-- get the index that foreign key depends on
LEFT JOIN pg_depend d1 ON d1.objid = const1.oid AND d1.classid = 'pg_constraint'::regclass
           AND d1.refclassid = 'pg_class'::regclass AND d1.refobjsubid = 0
-- get the pkey/ukey constraint for this index
LEFT JOIN pg_depend d2 ON d2.refclassid = 'pg_constraint'::regclass AND d2.classid = 'pg_class'::regclass AND d2.objid = d1.refobjid AND d2.objsubid = 0 AND d2.deptype = 'i'
-- get the constraint name from new pg_constraint
LEFT JOIN pg_constraint const2 ON const2.oid = d2.refobjid AND const2.contype IN ('p', 'u') AND const2.conrelid = const1.confrelid
-- get the namespace name for primary key
LEFT JOIN sys.pg_namespace_ext nsp_ext2 ON const2.connamespace = nsp_ext2.oid
-- get the owner name for primary key
LEFT JOIN sys.babelfish_namespace_ext bbf_nsp2 ON bbf_nsp2.nspname = nsp_ext2.nspname AND bbf_nsp2.dbid = sys.db_id()
-- get the table name for primary key
LEFT JOIN pg_class c2 ON const2.conrelid = c2.oid AND const2.contype IN ('p', 'u');

GRANT SELECT ON sys.sp_fkeys_view TO PUBLIC;

create or replace view sys.all_views as
SELECT
    CAST(c.relname AS sys.SYSNAME) as name
  , CAST(c.oid AS INT) as object_id
  , CAST(null AS INT) as principal_id
  , CAST(c.relnamespace as INT) as schema_id
  , CAST(0 as INT) as parent_object_id
  , CAST('V' as sys.bpchar(2)) as type
  , CAST('VIEW'as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(((c.relnamespace::regnamespace::text = 'sys') or 
    c.relname in (select name from sys.shipped_objects_not_in_sys nis
  	where nis.name = c.relname and nis.schemaid = c.relnamespace and nis.type = 'V')) 
    as sys.bit) AS is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.BIT) AS is_replicated
  , CAST(0 as sys.BIT) AS has_replication_filter
  , CAST(0 as sys.BIT) AS has_opaque_metadata
  , CAST(0 as sys.BIT) AS has_unchecked_assembly_data
  , CAST(
      CASE 
        WHEN (v.check_option = 'NONE') 
          THEN 0
        ELSE 1
      END
    AS sys.BIT) AS with_check_option
  , CAST(0 as sys.BIT) AS is_date_correlation_view
FROM pg_catalog.pg_namespace AS ns
INNER JOIN pg_class c ON ns.oid = c.relnamespace
INNER JOIN information_schema.views v ON c.relname = v.table_name AND ns.nspname = v.table_schema
WHERE c.relkind = 'v' AND ns.nspname in 
  (SELECT nspname from sys.babelfish_namespace_ext where dbid = sys.db_id() UNION ALL SELECT CAST('sys' AS NAME))
AND pg_is_other_temp_schema(ns.oid) = false
AND (pg_has_role(c.relowner, 'USAGE') = true
OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') = true
OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') = true);
GRANT SELECT ON sys.all_views TO PUBLIC;

CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(tr.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(f.create_date as sys.datetime) AS create_date,
  CAST(f.create_date as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(tr.tgenabled = 'D' AS sys.bit)	AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where 
has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columns_internal()
RETURNS TABLE (
    out_object_id int,
    out_name sys.sysname,
    out_column_id int,
    out_system_type_id int,
    out_user_type_id int,
    out_max_length smallint,
    out_precision sys.tinyint,
    out_scale sys.tinyint,
    out_collation_name sys.sysname,
    out_collation_id int,
    out_offset smallint,
    out_is_nullable sys.bit,
    out_is_ansi_padded sys.bit,
    out_is_rowguidcol sys.bit,
    out_is_identity sys.bit,
    out_is_computed sys.bit,
    out_is_filestream sys.bit,
    out_is_replicated sys.bit,
    out_is_non_sql_subscribed sys.bit,
    out_is_merge_published sys.bit,
    out_is_dts_replicated sys.bit,
    out_is_xml_document sys.bit,
    out_xml_collection_id int,
    out_default_object_id int,
    out_rule_object_id int,
    out_is_sparse sys.bit,
    out_is_column_set sys.bit,
    out_generated_always_type sys.tinyint,
    out_generated_always_type_desc sys.nvarchar(60),
    out_encryption_type int,
    out_encryption_type_desc sys.nvarchar(64),
    out_encryption_algorithm_name sys.sysname,
    out_column_encryption_key_id int,
    out_column_encryption_key_database_name sys.sysname,
    out_is_hidden sys.bit,
    out_is_masked sys.bit,
    out_graph_type int,
    out_graph_type_desc sys.nvarchar(60)
)
AS
$$
BEGIN
	RETURN QUERY
		SELECT CAST(c.oid AS int),
			CAST(a.attname AS sys.sysname),
			CAST(a.attnum AS int),
			CASE 
			WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
				-- either tsql or PG base type 
				CAST(a.atttypid AS int)
			ELSE 
				CAST(t.typbasetype AS int)
			END,
			CAST(a.atttypid AS int),
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
			ELSE 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
			ELSE 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
			ELSE 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
			END,
			CAST(coll.collname AS sys.sysname),
			CAST(a.attcollation AS int),
			CAST(a.attnum AS smallint),
			CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
			CAST(t.typname in ('bpchar', 'nchar', 'binary') AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(a.attidentity <> ''::"char" AS sys.bit),
			CAST(a.attgenerated <> ''::"char" AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS int),
			CAST(coalesce(d.oid, 0) AS int),
			CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
						and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.tinyint),
			CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(64)),
			CAST(null AS sys.sysname),
			CAST(null AS int),
			CAST(null AS sys.sysname),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(60))
		FROM pg_attribute a
		INNER JOIN pg_class c ON c.oid = a.attrelid
		INNER JOIN pg_type t ON t.oid = a.atttypid
		INNER JOIN sys.schemas sch on c.relnamespace = sch.schema_id 
		INNER JOIN sys.pg_namespace_ext ext on sch.schema_id = ext.oid 
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
		, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
		WHERE NOT a.attisdropped
		AND a.attnum > 0
		-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
		AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
		AND c.relispartition = false
		AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
		union all
		-- system tables information
		SELECT CAST(c.oid AS int),
			CAST(a.attname AS sys.sysname),
			CAST(a.attnum AS int),
			CASE 
			WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
				-- either tsql or PG base type 
				CAST(a.atttypid AS int)
			ELSE 
				CAST(t.typbasetype AS int)
			END,
			CAST(a.atttypid AS int),
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
			ELSE 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
			ELSE 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
			ELSE 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
			END,
			CAST(coll.collname AS sys.sysname),
			CAST(a.attcollation AS int),
			CAST(a.attnum AS smallint),
			CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
			CAST(t.typname in ('bpchar', 'nchar', 'binary') AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(a.attidentity <> ''::"char" AS sys.bit),
			CAST(a.attgenerated <> ''::"char" AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS int),
			CAST(coalesce(d.oid, 0) AS int),
			CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
						and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.tinyint),
			CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(64)),
			CAST(null AS sys.sysname),
			CAST(null AS int),
			CAST(null AS sys.sysname),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(60))
		FROM pg_attribute a
		INNER JOIN pg_class c ON c.oid = a.attrelid
		INNER JOIN pg_type t ON t.oid = a.atttypid
		INNER JOIN pg_namespace nsp ON (nsp.oid = c.relnamespace and nsp.nspname = 'sys')
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
		, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
		WHERE NOT a.attisdropped
		AND a.attnum > 0
		AND c.relkind = 'r'
		AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
END;
$$
language plpgsql STABLE;
;

create or replace view sys.databases as
select
  CAST(d.orig_name as SYS.SYSNAME) as name
  , CAST(sys.db_id(d.name) as INT) as database_id
  , CAST(NULL as INT) as source_database_id
  , cast(s.sid as SYS.VARBINARY(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(s.cmptlevel AS SYS.TINYINT) as compatibility_level
  , CAST(c.collname as SYS.SYSNAME) as collation_name
  , CAST(0 AS SYS.TINYINT)  as user_access
  , CAST('MULTI_USER' AS SYS.NVARCHAR(60)) as user_access_desc
  , CAST(0 AS SYS.BIT) as is_read_only
  , CAST(0 AS SYS.BIT) as is_auto_close_on
  , CAST(0 AS SYS.BIT) as is_auto_shrink_on
  , CAST(0 AS SYS.TINYINT) as state
  , CAST('ONLINE' AS SYS.NVARCHAR(60)) as state_desc
  , CAST(
	  	CASE 
			WHEN pg_is_in_recovery() is false THEN 0 
			WHEN pg_is_in_recovery() is true THEN 1 
		END 
	AS SYS.BIT) as is_in_standby
  , CAST(0 AS SYS.BIT) as is_cleanly_shutdown
  , CAST(0 AS SYS.BIT) as is_supplemental_logging_enabled
  , CAST(1 AS SYS.TINYINT) as snapshot_isolation_state
  , CAST('ON' AS SYS.NVARCHAR(60)) as snapshot_isolation_state_desc
  , CAST(1 AS SYS.BIT) as is_read_committed_snapshot_on
  , CAST(1 AS SYS.TINYINT) as recovery_model
  , CAST('FULL' AS SYS.NVARCHAR(60)) as recovery_model_desc
  , CAST(0 AS SYS.TINYINT) as page_verify_option
  , CAST(NULL AS SYS.NVARCHAR(60)) as page_verify_option_desc
  , CAST(1 AS SYS.BIT) as is_auto_create_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_create_stats_incremental_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_async_on
  , CAST(0 AS SYS.BIT) as is_ansi_null_default_on
  , CAST(0 AS SYS.BIT) as is_ansi_nulls_on
  , CAST(0 AS SYS.BIT) as is_ansi_padding_on
  , CAST(0 AS SYS.BIT) as is_ansi_warnings_on
  , CAST(0 AS SYS.BIT) as is_arithabort_on
  , CAST(0 AS SYS.BIT) as is_concat_null_yields_null_on
  , CAST(0 AS SYS.BIT) as is_numeric_roundabort_on
  , CAST(0 AS SYS.BIT) as is_quoted_identifier_on
  , CAST(0 AS SYS.BIT) as is_recursive_triggers_on
  , CAST(0 AS SYS.BIT) as is_cursor_close_on_commit_on
  , CAST(0 AS SYS.BIT) as is_local_cursor_default
  , CAST(0 AS SYS.BIT) as is_fulltext_enabled
  , CAST(0 AS SYS.BIT) as is_trustworthy_on
  , CAST(0 AS SYS.BIT) as is_db_chaining_on
  , CAST(0 AS SYS.BIT) as is_parameterization_forced
  , CAST(0 AS SYS.BIT) as is_master_key_encrypted_by_server
  , CAST(0 AS SYS.BIT) as is_query_store_on
  , CAST(0 AS SYS.BIT) as is_published
  , CAST(0 AS SYS.BIT) as is_subscribed
  , CAST(0 AS SYS.BIT) as is_merge_published
  , CAST(0 AS SYS.BIT) as is_distributor
  , CAST(0 AS SYS.BIT) as is_sync_with_backup
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as service_broker_guid
  , CAST(0 AS SYS.BIT) as is_broker_enabled
  , CAST(0 AS SYS.TINYINT) as log_reuse_wait
  , CAST('NOTHING' AS SYS.NVARCHAR(60)) as log_reuse_wait_desc
  , CAST(0 AS SYS.BIT) as is_date_correlation_on
  , CAST(0 AS SYS.BIT) as is_cdc_enabled
  , CAST(0 AS SYS.BIT) as is_encrypted
  , CAST(0 AS SYS.BIT) as is_honor_broker_priority_on
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as replica_id
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as group_database_id
  , CAST(NULL AS INT) as resource_pool_id
  , CAST(NULL AS SMALLINT) as default_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_language_name
  , CAST(NULL AS INT) as default_fulltext_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_fulltext_language_name
  , CAST(NULL AS SYS.BIT) as is_nested_triggers_on
  , CAST(NULL AS SYS.BIT) as is_transform_noise_words_on
  , CAST(NULL AS SMALLINT) as two_digit_year_cutoff
  , CAST(0 AS SYS.TINYINT) as containment
  , CAST('NONE' AS SYS.NVARCHAR(60)) as containment_desc
  , CAST(0 AS INT) as target_recovery_time_in_seconds
  , CAST(0 AS INT) as delayed_durability
  , CAST(NULL AS SYS.NVARCHAR(60)) as delayed_durability_desc
  , CAST(0 AS SYS.BIT) as is_memory_optimized_elevate_to_snapshot_on
  , CAST(0 AS SYS.BIT) as is_federation_member
  , CAST(0 AS SYS.BIT) as is_remote_data_archive_enabled
  , CAST(0 AS SYS.BIT) as is_mixed_page_allocation_on
  , CAST(0 AS SYS.BIT) as is_temporal_history_retention_enabled
  , CAST(0 AS INT) as catalog_collation_type
  , CAST('Not Applicable' AS SYS.NVARCHAR(60)) as catalog_collation_type_desc
  , CAST(NULL AS SYS.NVARCHAR(128)) as physical_database_name
  , CAST(0 AS SYS.BIT) as is_result_set_caching_on
  , CAST(0 AS SYS.BIT) as is_accelerated_database_recovery_on
  , CAST(0 AS SYS.BIT) as is_tempdb_spill_to_remote_store
  , CAST(0 AS SYS.BIT) as is_stale_page_detection_on
  , CAST(0 AS SYS.BIT) as is_memory_optimized_enabled
  , CAST(0 AS SYS.BIT) as is_ledger_on
 from sys.babelfish_sysdatabases d 
 INNER JOIN sys.sysdatabases s on d.dbid = s.dbid
 LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname;
GRANT SELECT ON sys.databases TO PUBLIC;


-- sp_columns_100 procedure
CREATE OR REPLACE PROCEDURE sys.sp_columns_100 (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
	"@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
	-- TODO: we should be able to get rid of babelfish_truncate_identifier when we fix BABEL-5416
	declare @truncated_ident sys.nvarchar(384);
	select @truncated_ident = sys.babelfish_truncate_identifier(pg_catalog.lower(@table_name));
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		-- TODO: Temporary fix to use \ as escape character for now, need to remove ESCAPE clause from LIKE once we have fixed the dependencies on this procedure
		where table_name like @truncated_ident COLLATE database_default ESCAPE '\' -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_owner,'') = '' or table_owner like @table_owner collate database_default ESCAPE '\') -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_qualifier,'') = '' or table_qualifier like @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name like @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
			where table_name = @truncated_ident collate database_default
			and (coalesce(@table_owner, '') = '' or table_owner = @table_owner collate database_default)
			and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name = @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sp_tables_view_deprecated_in_6_3_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sp_special_columns_view_deprecated_in_6_3_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sp_fkeys_view_deprecated_in_6_3_0');

-- Drop and recreate wrapper views, then restore user deps
DO $$
DECLARE r RECORD;
    schema_name TEXT;
    dep RECORD;
BEGIN
    -- Drop wrapper views
    FOR r IN SELECT name FROM sys.babelfish_sysdatabases LOOP
        schema_name := r.name || '_dbo';
        IF length(schema_name) > 63 THEN
            schema_name := sys.babelfish_truncate_identifier(schema_name);
        END IF;
        EXECUTE format('DROP VIEW IF EXISTS %I.sysdatabases CASCADE', schema_name);
    END LOOP;
    -- Recreate wrapper views
    FOR r IN SELECT name FROM sys.babelfish_sysdatabases LOOP
        schema_name := r.name || '_dbo';
        IF length(schema_name) > 63 THEN
            schema_name := sys.babelfish_truncate_identifier(schema_name);
        END IF;
        EXECUTE format('CREATE VIEW %I.sysdatabases AS SELECT * FROM sys.sysdatabases', schema_name);
        EXECUTE format('ALTER EXTENSION babelfishpg_tsql DROP VIEW %I.sysdatabases', schema_name);
        EXECUTE format('ALTER TABLE %I.sysdatabases OWNER TO %I', schema_name, schema_name);
    END LOOP;
    -- Restore dependent user views
    FOR dep IN SELECT stmt FROM _saved_sysdatabases_deps LOOP
        BEGIN
            EXECUTE dep.stmt;
            IF dep.stmt LIKE 'CREATE%VIEW%' THEN
                DECLARE
                    view_fqn TEXT;
                BEGIN
                    view_fqn := split_part(split_part(dep.stmt, 'VIEW ', 2), ' AS ', 1);
                    EXECUTE format('ALTER EXTENSION babelfishpg_tsql DROP VIEW %s', view_fqn);
                EXCEPTION WHEN OTHERS THEN NULL;
                END;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Could not restore dependent view: %', dep.stmt;
        END;
    END LOOP;
END $$;
DROP TABLE IF EXISTS _saved_sysdatabases_deps;
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sysdatabases_deprecated_in_6_3_0');

-- Recreate information_schema views dependent on pg_namespace_ext

CREATE OR REPLACE VIEW information_schema_tsql.columns_internal AS
	SELECT c.oid AS "TABLE_OID",
			CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
			CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23 /* prefix length */)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
					c.relname)
				AS sys.nvarchar(128)) AS "TABLE_NAME",

			CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_name=%' THEN substring(option, 19 /* prefix length */)
						ELSE NULL
						END, ',')
					FROM unnest(a.attoptions) AS option),
					a.attname)
				AS sys.nvarchar(128)) AS "COLUMN_NAME",

			CAST(a.attnum AS int) AS "ORDINAL_POSITION",
			CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
			CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
				AS varchar(3))
				AS "IS_NULLABLE",

			CAST(
				CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
				WHEN tsql_type_name.tsql_type_name IS NULL THEN format_type(t.oid, NULL::integer)
				ELSE tsql_type_name END
				AS sys.nvarchar(128))
				AS "DATA_TYPE",

			CAST(
				information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_MAXIMUM_LENGTH",

			CAST(
				information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_OCTET_LENGTH",

			CAST(
				/* Handle Tinyint separately */
				information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
				AS sys.tinyint)
				AS "NUMERIC_PRECISION",

			CAST(
				information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
				AS smallint)
				AS "NUMERIC_PRECISION_RADIX",

			CAST(
				information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
				AS int)
				AS "NUMERIC_SCALE",

			CAST(
				information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
				AS smallint)
				AS "DATETIME_PRECISION",

			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
			/*
			 * TODO: We need to first create mapping of collation name to char-set name;
			 * Until then return null.
			 */
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

			/* Returns Babelfish specific collation name. */
			CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN nc.dbname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN ext.orig_name ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN t.typname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_NAME"

	FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
		JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
		JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
		LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
			ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
		LEFT JOIN pg_collation co on co.oid = a.attcollation
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
		information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
		information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
		sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

	WHERE (NOT pg_is_other_temp_schema(nc.oid))
		AND a.attnum > 0 AND NOT a.attisdropped
		AND c.relkind IN ('r', 'v', 'p')
		AND c.relispartition = false
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid =sys.db_id();

/*
 * COLUMNS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.columns AS
	SELECT
		"TABLE_CATALOG",
		"TABLE_SCHEMA",
		"TABLE_NAME",
		"COLUMN_NAME",
		"ORDINAL_POSITION",
		"COLUMN_DEFAULT",
		"IS_NULLABLE",
		"DATA_TYPE",
		"CHARACTER_MAXIMUM_LENGTH",
		"CHARACTER_OCTET_LENGTH",
		"NUMERIC_PRECISION",
		"NUMERIC_PRECISION_RADIX",
		"NUMERIC_SCALE",
		"DATETIME_PRECISION",
		"CHARACTER_SET_CATALOG",
		"CHARACTER_SET_SCHEMA",
		"CHARACTER_SET_NAME",
		"COLLATION_CATALOG",
		"COLLATION_SCHEMA",
		"COLLATION_NAME",
		"DOMAIN_CATALOG",
		"DOMAIN_SCHEMA",
		"DOMAIN_NAME"
	
	FROM information_schema_tsql.columns_internal;

GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;

/*
 * DOMAINS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.domains AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
		CAST(t.typname AS sys.sysname) AS "DOMAIN_NAME",
		CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",

		CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_MAXIMUM_LENGTH",

		CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_OCTET_LENGTH",

		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

		/* Returns Babelfish specific collation name. */
		CAST(
			CASE co.collname
				WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
				ELSE co.collname
			END
		AS sys.nvarchar(128)) AS "COLLATION_NAME",

		CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
		CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",
		/*
		 * TODO: We need to first create mapping of collation name to char-set name;
		 * Until then return null.
		 */
		CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

		CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.typbasetype, t.typtypmod)
			AS sys.tinyint)
		AS "NUMERIC_PRECISION",

		CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, t.typbasetype, t.typtypmod)
			AS smallint)
		AS "NUMERIC_PRECISION_RADIX",

		CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.typbasetype, t.typtypmod)
			AS int)
		AS "NUMERIC_SCALE",

		CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, t.typtypmod)
			AS smallint)
		AS "DATETIME_PRECISION",

		CAST(case when is_tbl_type THEN NULL ELSE t.typdefault END AS sys.nvarchar(4000)) AS "DOMAIN_DEFAULT"

		FROM (pg_type t JOIN sys.pg_namespace_ext nc ON t.typnamespace = nc.oid)
		LEFT JOIN pg_collation co ON t.typcollation = co.oid
		LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
		sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_type_name,
		sys.is_table_type(t.typrelid) as is_tbl_type

		WHERE (pg_has_role(t.typowner, 'USAGE')
			OR has_type_privilege(t.oid, 'USAGE'))
		AND (t.typtype = 'd' OR is_tbl_type)
		AND ext.dbid = sys.db_id();

GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;

/*
 * TABLES view
 */

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
	WITH tt_internal AS MATERIALIZED (
		SELECT * FROM sys.table_types_internal
	)
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
				c.relname)
			AS sys._ci_sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS sys.varchar(10)) COLLATE sys.database_default AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
		   LEFT JOIN tt_internal tt ON c.oid = tt.typrelid

	WHERE c.relkind IN ('r', 'v', 'p')
		AND c.relispartition = false
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid IS NULL
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

CREATE OR REPLACE FUNCTION information_schema_tsql.table_constraints_internal()
RETURNS TABLE (
    "CONSTRAINT_CATALOG" sys.nvarchar(128),
    "CONSTRAINT_SCHEMA" sys.nvarchar(128),
    "CONSTRAINT_NAME" sys.sysname,
    "TABLE_CATALOG" sys.nvarchar(128),
    "TABLE_SCHEMA" sys.nvarchar(128),
    "TABLE_NAME" sys.sysname,
    "CONSTRAINT_TYPE" sys.varchar(11),
    "IS_DEFERRABLE" sys.varchar(2),
    "INITIALLY_DEFERRED" sys.varchar(2)
)
AS
$$
BEGIN
    RETURN QUERY
    SELECT CAST(db_name AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(db_name AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) COLLATE sys.database_default AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"
    FROM 
        pg_constraint c
        INNER JOIN pg_class r ON c.conrelid = r.oid
        INNER JOIN pg_namespace nsp ON r.relnamespace = nsp.oid
        INNER JOIN sys.babelfish_namespace_ext ext ON nsp.nspname = ext.nspname AND ext.dbid = sys.db_id()
        , sys.db_name() AS db_name
    WHERE 
        c.contype IN ('c', 'f', 'p', 'u')
          AND r.relkind IN ('r', 'p')
          AND relispartition = false
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') );
END;
$$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

/*
 * TABLE_CONSTRAINTS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.table_constraints AS
    SELECT 
        CAST("CONSTRAINT_CATALOG" AS sys.nvarchar(128)),
        CAST("CONSTRAINT_SCHEMA" AS sys.nvarchar(128)),
        CAST("CONSTRAINT_NAME" AS sys.sysname),
        CAST("TABLE_CATALOG" AS sys.nvarchar(128)),
        CAST("TABLE_SCHEMA" AS sys.nvarchar(128)),
        CAST("TABLE_NAME" AS sys.sysname),
        CAST("CONSTRAINT_TYPE" AS sys.varchar(11)),
        CAST("IS_DEFERRABLE" AS sys.varchar(2)),
        CAST("INITIALLY_DEFERRED" AS sys.varchar(2))
    FROM information_schema_tsql.table_constraints_internal();

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;

/*
 * VIEWS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.views AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS  "TABLE_SCHEMA",
			CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
			CAST(vd.definition AS sys.nvarchar(4000)) AS "VIEW_DEFINITION",

			CAST(
				CASE WHEN 'check_option=cascaded' = ANY (c.reloptions)
					THEN 'CASCADE'
					ELSE 'NONE' END
				AS sys.varchar(7)) COLLATE sys.database_default AS "CHECK_OPTION",

			CAST('NO' AS sys.varchar(2)) AS "IS_UPDATABLE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext
			ON (nc.nspname = ext.nspname COLLATE sys.database_default)
		LEFT OUTER JOIN sys.babelfish_view_def vd
			ON ext.dbid = vd.dbid
				AND (ext.orig_name = vd.schema_name COLLATE sys.database_default)
				AND (CAST(c.relname AS sys.nvarchar(128)) = vd.object_name COLLATE sys.database_default)
		LEFT JOIN sys.shipped_objects_not_in_sys nis on (nis.name = c.relname and nis.schemaid = nc.oid and nis.type = 'V')

	WHERE c.relkind = 'v'
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND nis.name is null
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id();

GRANT SELECT ON information_schema_tsql.views TO PUBLIC;

/*
 * CHECK_CONSTRAINTS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
	    CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
	    CAST(sys.tsql_get_constraintdef(c.oid) AS sys.nvarchar(4000)) AS "CHECK_CLAUSE"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nc.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND r.relispartition = false
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
		  AND  extc.dbid = sys.db_id();

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;

/*
 * CONSTARINT_COLUMN_USAGE
 */

CREATE OR REPLACE VIEW information_schema_tsql.CONSTRAINT_COLUMN_USAGE AS
SELECT    CAST(tblcat AS sys.nvarchar(128)) AS "TABLE_CATALOG",
          CAST(tblschema AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
          CAST(tblname AS sys.nvarchar(128)) AS "TABLE_NAME" ,
          CAST(colname AS sys.nvarchar(128)) AS "COLUMN_NAME",
          CAST(cstrcat AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
          CAST(cstrschema AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
          CAST(cstrname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME"

FROM (
        /* check constraints */
   SELECT DISTINCT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r, pg_depend d

     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND d.refclassid = 'pg_catalog.pg_class'::regclass
          AND d.refobjid = r.oid
          AND d.refobjsubid = a.attnum
          AND d.classid = 'pg_catalog.pg_constraint'::regclass
          AND d.objid = c.oid
          AND c.connamespace = nc.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND r.relispartition = false
          AND NOT a.attisdropped
	  AND (pg_has_role(r.relowner, 'USAGE')
		OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
		OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

       UNION ALL

        /* unique/primary key/foreign key constraints */
   SELECT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r
     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND nc.oid = c.connamespace
          AND r.oid = c.conrelid
          AND a.attnum = ANY (c.conkey)
          AND NOT a.attisdropped
          AND c.contype IN ('p', 'u', 'f')
          AND r.relkind IN ('r', 'p')
          AND r.relispartition = false
	  AND (pg_has_role(r.relowner, 'USAGE')
		OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
		OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

      ) AS x (tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat);

GRANT SELECT ON information_schema_tsql.CONSTRAINT_COLUMN_USAGE TO PUBLIC;

/*
* COLUMN_DOMAIN_USAGE
*/

CREATE OR REPLACE VIEW information_schema_tsql.COLUMN_DOMAIN_USAGE AS
    SELECT isc_col."DOMAIN_CATALOG",
           isc_col."DOMAIN_SCHEMA" ,
           CAST(isc_col."DOMAIN_NAME" AS sys.sysname),
           isc_col."TABLE_CATALOG",
           isc_col."TABLE_SCHEMA",
           CAST(isc_col."TABLE_NAME" AS sys.sysname),
           CAST(isc_col."COLUMN_NAME" AS sys.sysname)

    FROM information_schema_tsql.columns_internal AS isc_col
    WHERE isc_col."DOMAIN_NAME" IS NOT NULL;

GRANT SELECT ON information_schema_tsql.COLUMN_DOMAIN_USAGE TO PUBLIC;

/*
 *ISC routines view
 */
CREATE OR REPLACE VIEW information_schema_tsql.routines AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SPECIFIC_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "SPECIFIC_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "SPECIFIC_NAME",
           CAST(nc.dbname AS sys.nvarchar(128)) AS "ROUTINE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "ROUTINE_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "ROUTINE_NAME",
           CAST(CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END
           	 AS sys.nvarchar(20)) AS "ROUTINE_TYPE",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_NAME",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_NAME",
	   CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
           CAST(information_schema_tsql._pgtsql_char_max_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_MAXIMUM_LENGTH",
           CAST(information_schema_tsql._pgtsql_char_octet_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_OCTET_LENGTH",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_SCHEMA",
           CAST(
                 CASE co.collname
                       WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
                       ELSE co.collname
                 END
            AS sys.nvarchar(128)) AS "COLLATION_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
	    /*
                 * TODO: We need to first create mapping of collation name to char-set name;
                 * Until then return null.
            */
	    CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
	    CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION",
	    CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_SCALE",
            CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
                        AS smallint)
            AS "DATETIME_PRECISION",
	    CAST(NULL AS sys.nvarchar(30)) AS "INTERVAL_TYPE",
            CAST(NULL AS smallint) AS "INTERVAL_PRECISION",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_NAME",
            CAST(NULL AS bigint) AS "MAXIMUM_CARDINALITY",
            CAST(NULL AS sys.nvarchar(128)) AS "DTD_IDENTIFIER",
            CAST(CASE WHEN l.lanname = 'sql' THEN 'SQL' WHEN l.lanname = 'pltsql' THEN 'SQL' ELSE 'EXTERNAL' END AS sys.nvarchar(30)) AS "ROUTINE_BODY",
            CAST(f.definition AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
	    CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
	    inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT)
		LEFT JOIN sys.babelfish_function_ext f ON p.proname = f.funcname AND sch.schema_id::regnamespace::name = f.nspname
			AND sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature COLLATE "C",
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
	    sys.is_table_type(t.typrelid) as is_tbl_type

       WHERE
            (case p.prokind 
	       when 'p' then true 
	       when 'a' then false
               else 
    	           (case format_type(p.prorettype, null) 
	   	      when 'trigger' then false 
	   	      else true 
   		    end) 
            end)  
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND has_function_privilege(p.oid, 'EXECUTE')
            AND (pg_has_role(t.typowner, 'USAGE')
            OR has_type_privilege(t.oid, 'USAGE'))
            AND ext.dbid = sys.db_id()
	    AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid
	    AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.SEQUENCES AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SEQUENCE_CATALOG",
            CAST(extc.orig_name AS sys.nvarchar(128)) AS "SEQUENCE_SCHEMA",
            CAST(r.relname AS sys.nvarchar(128)) AS "SEQUENCE_NAME",
            CAST(CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype) ELSE tsql_type_name END
                    AS sys.nvarchar(128))AS "DATA_TYPE",  -- numeric and decimal data types are converted into bigint which is due to Postgres inherent implementation
            CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, -1)
                        AS smallint) AS "NUMERIC_PRECISION",
            CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, -1)
                        AS smallint) AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, -1)
                        AS int) AS "NUMERIC_SCALE",
            CAST(s.seqstart AS sys.sql_variant) AS "START_VALUE",
            CAST(s.seqmin AS sys.sql_variant) AS "MINIMUM_VALUE",
            CAST(s.seqmax AS sys.sql_variant) AS "MAXIMUM_VALUE",
            CAST(s.seqincrement AS sys.sql_variant) AS "INCREMENT",
            CAST( CASE WHEN s.seqcycle = 't' THEN 1 ELSE 0 END AS int) AS "CYCLE_OPTION",
            CAST(NULL AS sys.nvarchar(128)) AS "DECLARED_DATA_TYPE",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_PRECISION",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_SCALE"
        FROM sys.pg_namespace_ext nc JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
            pg_sequence s join pg_class r on s.seqrelid = r.oid join pg_type t on s.seqtypid=t.oid,
            sys.translate_pg_type_to_tsql(s.seqtypid) AS tsql_type_name
        WHERE nc.oid = r.relnamespace
        AND extc.dbid = sys.db_id()
            AND r.relkind = 'S'
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND (pg_has_role(r.relowner, 'USAGE')
                OR has_sequence_privilege(r.oid, 'SELECT, UPDATE, USAGE'));

GRANT SELECT ON information_schema_tsql.sequences TO PUBLIC; 

CREATE OR REPLACE VIEW information_schema_tsql.key_column_usage AS
	SELECT
		CAST(db_name AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
		CAST(c.conname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME",
		CAST(db_name AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		CAST(r.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
		CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
		CAST(ord AS int) AS "ORDINAL_POSITION"	
	FROM
		pg_constraint c 
		JOIN pg_class r ON r.oid = c.conrelid AND c.contype in ('p','u','f') AND r.relkind in ('r','p') AND r.relispartition = false
		JOIN pg_namespace nsp ON r.relnamespace = nsp.oid
		JOIN sys.babelfish_namespace_ext ext ON ext.nspname = nsp.nspname AND ext.dbid = sys.db_id()
		CROSS JOIN unnest(c.conkey) WITH ORDINALITY AS ak(j,ord) 
		LEFT JOIN pg_attribute a ON a.attrelid = r.oid AND a.attnum = ak.j
		, sys.db_name() AS db_name
	WHERE
		pg_has_role(r.relowner, 'USAGE'::text) 
  		OR has_column_privilege(r.oid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
	;
GRANT SELECT ON information_schema_tsql.key_column_usage TO PUBLIC;

/*
 * SCHEMATA view
 */
CREATE OR REPLACE VIEW information_schema_tsql.schemata AS
	SELECT CAST(sys.db_name() AS sys.sysname) AS "CATALOG_NAME",
	CAST(CASE WHEN np.nspname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN PG_CATALOG.RIGHT(np.nspname, LENGTH(np.nspname) - LENGTH(sys.db_name()) - 1)
	     ELSE np.nspname END AS sys.nvarchar(128)) AS "SCHEMA_NAME",
	-- For system-defined schemas, schema-owner name will be same as schema_name
	-- For user-defined schemas having default owner, schema-owner will be dbo
	-- For user-defined schemas with explicit owners, rolname contains dbname followed
	-- by owner name, so need to extract the owner name from rolname always.
	CAST(CASE WHEN sys.bbf_is_shared_schema(np.nspname) = TRUE THEN np.nspname
		  WHEN r.rolname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN
			CASE WHEN PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) = 'db_owner' THEN 'dbo'
			     ELSE PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) END ELSE 'dbo' END
			AS sys.nvarchar(128)) AS "SCHEMA_OWNER",
	CAST(null AS sys.varchar(6)) AS "DEFAULT_CHARACTER_SET_CATALOG",
	CAST(null AS sys.varchar(3)) AS "DEFAULT_CHARACTER_SET_SCHEMA",
	-- TODO: We need to first create mapping of collation name to char-set name;
	-- Until then return null for DEFAULT_CHARACTER_SET_NAME
	CAST(null AS sys.sysname) AS "DEFAULT_CHARACTER_SET_NAME"
	FROM ((pg_catalog.pg_namespace np LEFT JOIN sys.pg_namespace_ext nc on np.nspname = nc.nspname)
		LEFT JOIN pg_catalog.pg_roles r on r.oid = nc.nspowner) LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
	WHERE (ext.dbid = sys.db_id() OR np.nspname in ('sys', 'information_schema_tsql')) AND
	      (pg_has_role(np.nspowner, 'USAGE') OR has_schema_privilege(np.oid, 'CREATE, USAGE'))
	ORDER BY nc.nspname, np.nspname;

GRANT SELECT ON information_schema_tsql.schemata TO PUBLIC;

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Recreate sys.types (collation lookup uses orig_name)
create or replace view sys.types As
with RECURSIVE type_code_list as
(
    select distinct  pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
),
tt_internal as MATERIALIZED
(
  select * from sys.table_types_internal
)
-- For System types
select
  CAST(ti.tsql_type_name as sys.sysname) as name
  , cast(t.oid as int) as system_type_id
  , cast(t.oid as int) as user_type_id
  , cast(s.oid as int) as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(ti.tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , sys.tsql_type_precision_helper(ti.tsql_type_name, t.typtypmod) as precision
  , sys.tsql_type_scale_helper(ti.tsql_type_name, t.typtypmod, false) as scale
  , CASE
    WHEN t.typcollation = 0 THEN CAST(NULL as sys.sysname)
    ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE orig_name = db_name() collate database_default) as sys.sysname)
    END as collation_name
  , case when typnotnull then cast(0 as sys.bit) else cast(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_user_defined
  , CASE ti.tsql_type_name
    -- CLR UDT have is_assembly_type = 1
    WHEN 'geometry' THEN CAST(1 as sys.bit)
    WHEN 'geography' THEN CAST(1 as sys.bit)
    ELSE  CAST(0 as sys.bit)
    END as is_assembly_type
  , CAST(0 as int) as default_object_id
  , CAST(0 as int) as rule_object_id
  , CAST(0 as sys.bit) as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
inner join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
where
ti.tsql_type_name IS NOT NULL
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as sys.sysname) as name
  , cast(t.typbasetype as int) as system_type_id
  , cast(t.oid as int) as user_type_id
  , cast(t.typnamespace as int) as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) end as precision
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) end as scale
  , CASE
    WHEN t.typcollation = 0 THEN CAST(NULL as sys.sysname)
    ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE orig_name = db_name() collate database_default) as sys.sysname)
    END as collation_name
  , case when tt.typrelid is not null then cast(0 as sys.bit)
         else case when typnotnull then cast(0 as sys.bit) else cast(1 as sys.bit) end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , CAST(1 as sys.bit) as is_user_defined
  , CASE tsql_base_type_name
    -- CLR UDT have is_assembly_type = 1
    WHEN 'geometry' THEN CAST(1 as sys.bit)
    WHEN 'geography' THEN CAST(1 as sys.bit)
    ELSE  CAST(0 as sys.bit)
    END as is_assembly_type
  , CAST(0 as int) as default_object_id
  , CAST(0 as int) as rule_object_id
  , CAST(tt.typrelid is not null AS sys.bit) as is_table_type
from pg_type t
join sys.schemas sch on t.typnamespace = sch.schema_id
left join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
left join tt_internal tt on t.typrelid = tt.typrelid
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
-- we want to show details of user defined datatypes created under babelfish database
where 
 ti.tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    tt.typrelid is not null  
  );
GRANT SELECT ON sys.types TO PUBLIC;

-- Recreate sys.db_name (uses bbf_cur_db)
CREATE OR REPLACE FUNCTION sys.db_name() RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE STABLE;
;


-- Recreate sys.sp_helpuser (uses bbf_cur_db and Bsdb.dbid)
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
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
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
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.dbid = sys.db_id()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default
		AND Ext1.type != 'R'
		AND ((Ext2.orig_username IS NULL AND Base2.oid IS NULL) OR Ext2.type = 'R') -- We should only show public if user has no members i.e. Base2.oid is NULL
		AND Ext1.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
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
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
					AND database_name = sys.bbf_cur_db() collate database_default
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
		WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default
		AND Ext2.database_name = sys.bbf_cur_db() collate database_default
		AND Ext1.type = 'R'
		AND Ext2.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
		ORDER BY Role_name, Users_in_role;
	END
	-- If the security account is a user
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
					AND database_name = sys.bbf_cur_db() collate database_default
					AND type != 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public' 
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
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
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.dbid = sys.db_id()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default
		AND Ext1.type != 'R'
		AND ((Ext2.orig_username IS NULL AND Base2.oid IS NULL) OR Ext2.type = 'R') -- We should only show public if user has no members i.e. Base2.oid is NULL
		AND Ext1.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
		ORDER BY UserName, RoleName;
	END
	-- If the security account is not valid
	ELSE 
		RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_helpuser TO PUBLIC;

-- Recreate sys.sp_helprole (uses bbf_cur_db)
CREATE OR REPLACE PROCEDURE sys.sp_helprole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = sys.bbf_cur_db() collate database_default
		AND Ext.type = 'R'
		ORDER BY RoleName;
	END
	-- If a valid role is specified, return its info
	ELSE IF EXISTS (SELECT 1 
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@rolename))
					AND database_name = sys.bbf_cur_db() collate database_default
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = sys.bbf_cur_db() collate database_default
		AND Ext.type = 'R'
		AND (Ext.orig_username = @rolename OR pg_catalog.lower(Ext.orig_username) = pg_catalog.lower(@rolename))
		ORDER BY RoleName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprole TO PUBLIC;

-- Recreate sys.sp_helprolemember (uses bbf_cur_db)
CREATE OR REPLACE PROCEDURE sys.sp_helprolemember("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles that have at least
	-- one member in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default
		AND Ext2.database_name = sys.bbf_cur_db() collate database_default
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		ORDER BY RoleName, MemberName;
	END
	-- If a valid role is specified, return its member info
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@rolename))
					AND database_name = sys.bbf_cur_db() collate database_default
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default
		AND Ext2.database_name = sys.bbf_cur_db() collate database_default
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @rolename OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@rolename))
		ORDER BY RoleName, MemberName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprolemember TO PUBLIC;

-- Recreate sys.babelfish_sp_rename_word_parse (uses bbf_cur_db)
CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_word_parse(
	IN "@input" sys.nvarchar(776),
	IN "@objtype" sys.varchar(13),
	INOUT "@subname" sys.nvarchar(776),
	INOUT "@curr_relname" sys.nvarchar(776),
	INOUT "@schemaname" sys.nvarchar(776),
	INOUT "@dbname" sys.nvarchar(776)
)
AS $$
BEGIN
	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row, * 
	INTO #sp_rename_temptable 
	FROM sys.babelfish_split_identifier(@input) ORDER BY row DESC;

	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as id, * 
	INTO #sp_rename_temptable2 
	FROM #sp_rename_temptable;
	
	DECLARE @row_count INT;
	SELECT @row_count = COUNT(*) FROM #sp_rename_temptable2;

	IF @objtype = 'COLUMN' OR @objtype = 'INDEX'
		BEGIN
			IF @row_count = 1
				BEGIN
					IF @objtype = 'COLUMN'
						BEGIN
							THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.', 1;
						END;
					ELSE
						BEGIN
							THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (INDEX) is wrong.', 1;
						END
				END
			ELSE IF @row_count > 4
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					IF @row_count > 1
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SELECT @curr_relname = value FROM #sp_rename_temptable2 WHERE id = 2;
							SET @schemaname = sys.schema_name();

						END
					IF @row_count > 2
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 3;
						END
					IF @row_count > 3
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 4;
							IF @dbname != sys.db_name() collate database_default
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
	ELSE
		BEGIN
			IF @row_count > 3
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					SET @curr_relname = NULL;
					IF @row_count > 0
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SET @schemaname = sys.schema_name();
						END
					IF @row_count > 1
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 2;
						END
					IF @row_count > 2
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 3;
							IF @dbname != sys.db_name() collate database_default
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_word_parse(IN sys.nvarchar(776), IN sys.varchar(13), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776)) TO PUBLIC;

-- Recreate sys.sp_changedbowner (uses bbf_cur_db)
CREATE OR REPLACE PROCEDURE sys.sp_changedbowner(
	IN "@loginame" sys.sysname,
	IN "@map"      sys.VARCHAR(5) DEFAULT NULL) -- this parameter is ignored in T-SQL
LANGUAGE 'pltsql'
AS $$
BEGIN
	DECLARE @cmd sys.NVARCHAR(300)
	DECLARE @db  sys.sysname = DB_NAME() collate database_default

	-- For a NULL login name, do nothing
	IF @loginame IS NULL
	BEGIN
		RETURN
	END

	IF (@db = 'master') OR (@db = 'tempdb')
	BEGIN
		RAISERROR('Cannot change the owner of the master or tempdb database.', 16, 1)
		RETURN
	END

	IF SUSER_ID(@loginame) IS NULL
	BEGIN
		RAISERROR('Cannot find the principal ''%s'', because it does not exist or you do not have permission.', 16, 1, @loginame)
		RETURN
	END

	-- Compose the ALTER ATHORIZATION statement:
	SET @cmd = 'ALTER AUTHORIZATION ON DATABASE::[' + @db + '] TO [' + SUSER_NAME(SUSER_ID(@loginame)) + ']'
	EXECUTE(@cmd)
END
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_changedbowner(IN sys.sysname, IN sys.VARCHAR(5)) TO PUBLIC;

-- Recreate sys.sp_procedure_params_100_managed (uses bbf_cur_db)
CREATE OR REPLACE PROCEDURE sys.sp_procedure_params_100_managed(IN "@procedure_name" sys.sysname, 
                                                                IN "@group_number" integer DEFAULT 1, 
                                                                IN "@procedure_schema" sys.sysname DEFAULT NULL, 
                                                                IN "@parameter_name" sys.sysname DEFAULT NULL)
AS $$
BEGIN
	IF @procedure_schema IS NULL OR @procedure_schema = ''
		BEGIN
			SELECT @procedure_schema = default_schema_name from sys.babelfish_authid_user_ext WHERE orig_username = user_name() AND database_name = sys.bbf_cur_db() collate database_default;
		END

        SELECT 	v.column_name AS [PARAMETER_NAME],
		CAST (CASE v.column_type
			WHEN 5 THEN 4
                        WHEN 3 THEN 4
                        ELSE v.column_type END
                     	AS smallint) AS [PARAMETER_TYPE],
        	CAST (CASE v.type_name
			WHEN 'int' THEN 8
                        WHEN 'nchar' THEN 10
                        WHEN 'char' THEN 3
                        WHEN 'date' THEN 31
                        WHEN 'nvarchar' THEN 12
                        WHEN 'varchar' THEN 22
                        WHEN 'table' THEN 23
                        WHEN 'datetime' THEN 4
                        WHEN 'datetime2' THEN 33
                        WHEN 'datetimeoffset' THEN 34
                        WHEN 'smalldatetime' THEN 15
			WHEN 'time' THEN 32
                        WHEN 'decimal' THEN 5
			WHEN 'numeric' THEN 5
                        WHEN 'float' THEN 6
                        WHEN 'real' THEN 13
                        WHEN 'nchar' THEN 10
                        WHEN 'flag' THEN 2
                        WHEN 'money' THEN 9
                        WHEN 'smallmoney' THEN 17
                        WHEN 'tinyint' THEN 20
                        WHEN 'smallint' THEN 16
                        WHEN 'bigint' THEN 0
                        WHEN 'bit' THEN 2
			WHEN 'text' THEN 18
			WHEN 'ntext' THEN 11
			WHEN 'binary' THEN 1
			WHEN 'varbinary' THEN 21
			WHEN 'image' THEN 7
                        ELSE 0 END
                	AS smallint) AS [MANAGED_DATA_TYPE],
        	CAST (CASE 
			WHEN v.type_name IN (N'nchar', N'nvarchar') AND p.max_length <> -1 THEN p.max_length / 2
			WHEN v.type_name IN (N'char', N'varchar', N'binary', N'varbinary') AND p.max_length <> -1 THEN p.max_length
			WHEN v.type_name IN (N'nvarchar', N'varchar', N'varbinary') AND p.max_length = -1 THEN 0
                	WHEN v.type_name IN (N'text', N'image') THEN 2147483647
                	WHEN v.type_name = 'ntext' THEN 1073741823
                	ELSE NULL END 
			AS INT) AS [CHARACTER_MAXIMUM_LENGTH],
        	CAST(CASE 
			WHEN v.type_name IN (N'int', N'smallint', N'bigint', N'tinyint', N'float', N'real', N'decimal', N'numeric', N'money', N'smallmoney') 
				THEN v.PRECISION
			ELSE NULL END 
			AS smallint) AS [NUMERIC_PRECISION],
        	CAST(CASE 
			WHEN v.type_name IN (N'decimal', N'numeric') THEN v.SCALE 
			ELSE NULL END 
			AS smallint ) AS [NUMERIC_SCALE],
        	CAST(NULL AS sys.nvarchar(128)) AS [TYPE_CATALOG_NAME],
        	CAST(NULL AS sys.nvarchar(128)) AS [TYPE_SCHEMA_NAME],
        	CAST(v.TYPE_NAME AS sys.nvarchar(128)) AS [TYPE_NAME],
        	CAST(NULL AS sys.nvarchar(128)) AS XML_CATALOGNAME,
        	CAST(NULL AS sys.nvarchar(128)) AS XML_SCHEMANAME,
        	CAST(NULL AS sys.nvarchar(128)) AS XML_SCHEMACOLLECTIONNAME,
        	CAST(CASE
			WHEN v.type_name = 'datetime' THEN 3
                    	WHEN v.type_name IN (N'datetime2', N'datetimeoffset', N'time') THEN 7
			WHEN v.type_name IN (N'date', N'smalldatetime') THEN 0
                    	ELSE NULL END AS int) AS [SS_DATETIME_PRECISION]
   	FROM sys.sp_sproc_columns_view v
   	LEFT OUTER JOIN sys.all_parameters AS p 
	ON v.column_name = p.name AND p.object_id = object_id(PG_CATALOG.CONCAT(@procedure_schema, '.', @procedure_name))
   	WHERE v.original_procedure_name = @procedure_name
    	AND v.procedure_owner = @procedure_schema
	AND (@parameter_name IS NULL OR column_name = @parameter_name)
	AND @group_number = 1
    	ORDER BY PROCEDURE_OWNER, PROCEDURE_NAME, ORDINAL_POSITION;
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.sp_procedure_params_100_managed TO PUBLIC;

-- Recreate sys.database_principals (uses bbf_cur_db)
CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
-- PG reserves these oid > 16383 AND oid < 16400 for PG specific internal roles.
-- Any change here in the oid should be reflected in sys.database_role_members view as well.
CAST(
  CASE Ext.orig_username
    WHEN 'db_owner' THEN 16384
    WHEN 'db_accessadmin' THEN 16385
    WHEN 'db_securityadmin' THEN 16386
    WHEN 'db_ddladmin' THEN 16387
    WHEN 'db_datareader' THEN 16390
    WHEN 'db_datawriter' THEN 16391
    ELSE Base.oid
  END AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CASE Ext.orig_username
    WHEN 'dbo' THEN CAST(CAST(Base3.oid AS INT) AS SYS.VARBINARY(85))
    WHEN 'guest' THEN CAST(0 AS SYS.VARBINARY(85))
    -- these are SIDs which are constant for all the fixed roles used across databases 
    -- hence we are hardcoding these SIDs
    WHEN 'db_owner' THEN CAST('\x01050000000000090400000000000000000000000000000000400000'::bytea AS SYS.VARBINARY(85)) 
    WHEN 'db_accessadmin' THEN CAST('\x01050000000000090400000000000000000000000000000001400000'::bytea AS SYS.VARBINARY(85))    
    WHEN 'db_securityadmin' THEN CAST('\x01050000000000090400000000000000000000000000000002400000'::bytea AS SYS.VARBINARY(85))  
    WHEN 'db_ddladmin' THEN CAST('\x01050000000000090400000000000000000000000000000003400000'::bytea AS SYS.VARBINARY(85))       
    WHEN 'db_backupoperator' THEN CAST('\x01050000000000090400000000000000000000000000000005400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datareader' THEN CAST('\x01050000000000090400000000000000000000000000000006400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datawriter' THEN CAST('\x01050000000000090400000000000000000000000000000007400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatareader' THEN CAST('\x01050000000000090400000000000000000000000000000008400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatawriter' THEN CAST('\x01050000000000090400000000000000000000000000000009400000'::bytea AS SYS.VARBINARY(85))
    ELSE CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85))
END AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
LEFT OUTER JOIN sys.babelfish_sysdatabases AS Db
ON Ext.database_name COLLATE sys.database_default = Db.name
LEFT OUTER JOIN pg_catalog.pg_roles AS Base3
ON Db.owner = Base3.rolname
WHERE Ext.database_name = sys.bbf_cur_db() collate database_default
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin', 'guest') -- system users should always be visible
  OR bbf_is_role_member(current_user, Ext.rolname)) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(
  CASE name
    WHEN 'public' THEN 1
    WHEN 'INFORMATION_SCHEMA' THEN 3
    WHEN 'sys' THEN 4
  END AS INT) AS principal_id,
CAST(type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN type = 'S' THEN 'SQL_USER'
    WHEN type = 'R' THEN 'DATABASE_ROLE'
    WHEN type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_schema_name,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(-1 AS INT) AS owning_principal_id,
CAST(CAST(0 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(0 AS SYS.BIT) AS is_fixed_role,
CAST(-1 AS INT) AS authentication_type,
CAST(NULL AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(-1 AS INT) AS default_language_lcid,
CAST(0 AS SYS.BIT) AS allow_encrypted_value_modifications
FROM (VALUES ('public', 'R'), ('sys', 'S'), ('INFORMATION_SCHEMA', 'S')) as dummy_principals(name, type);

GRANT SELECT ON sys.database_principals TO PUBLIC;

-- Recreate sys.user_token (uses bbf_cur_db)
CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CASE Ext.orig_username
    WHEN 'dbo' THEN CAST(CAST(Base3.oid AS INT) AS SYS.VARBINARY(85))
    WHEN 'guest' THEN CAST(0 AS SYS.VARBINARY(85))
    -- these are SIDs which are constant for all the fixed roles used across databases 
    -- hence we are hardcoding these SIDs
    WHEN 'db_owner' THEN CAST('\x01050000000000090400000000000000000000000000000000400000'::bytea AS SYS.VARBINARY(85)) 
    WHEN 'db_accessadmin' THEN CAST('\x01050000000000090400000000000000000000000000000001400000'::bytea AS SYS.VARBINARY(85))    
    WHEN 'db_securityadmin' THEN CAST('\x01050000000000090400000000000000000000000000000002400000'::bytea AS SYS.VARBINARY(85))  
    WHEN 'db_ddladmin' THEN CAST('\x01050000000000090400000000000000000000000000000003400000'::bytea AS SYS.VARBINARY(85))       
    WHEN 'db_backupoperator' THEN CAST('\x01050000000000090400000000000000000000000000000005400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datareader' THEN CAST('\x01050000000000090400000000000000000000000000000006400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_datawriter' THEN CAST('\x01050000000000090400000000000000000000000000000007400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatareader' THEN CAST('\x01050000000000090400000000000000000000000000000008400000'::bytea AS SYS.VARBINARY(85))
    WHEN 'db_denydatawriter' THEN CAST('\x01050000000000090400000000000000000000000000000009400000'::bytea AS SYS.VARBINARY(85))
    ELSE CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85))
END AS SID,
CAST(Ext.orig_username AS SYS.NVARCHAR(128)) AS NAME,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
WHEN Ext.type = 'R' THEN 'ROLE'
ELSE 'SQL USER' END
AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
LEFT OUTER JOIN sys.babelfish_sysdatabases AS Db
ON Ext.database_name COLLATE sys.database_default = Db.name
LEFT OUTER JOIN pg_catalog.pg_roles AS Base3
ON Db.owner = Base3.rolname
WHERE Ext.database_name = sys.bbf_cur_db() collate database_default
AND ((Ext.rolname = CURRENT_USER AND Ext.type in ('S','U')) OR
((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo' AND Ext.type = 'R' AND pg_has_role(current_user, Ext.rolname, 'MEMBER')))
UNION ALL
SELECT
CAST(1 AS INT) AS principal_id,
CAST(CAST(1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

-- Recreate sys.sysusers (uses bbf_cur_db)
CREATE OR REPLACE VIEW sys.sysusers AS SELECT
Dbp.principal_id AS uid,
CAST(0 AS INT) AS status,
Dbp.name AS name,
Dbp.sid AS sid,
CAST(NULL AS SYS.VARBINARY(2048)) AS roles,
Dbp.create_date AS createdate,
Dbp.modify_date AS updatedate,
CAST(0 AS INT) AS altuid,
CAST(NULL AS SYS.VARBINARY(256)) AS password,
CAST(0 AS INT) AS gid,
CAST(NULL AS SYS.VARCHAR(85)) AS environ,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.type_desc = 'DATABASE_ROLE'
    THEN 0
  WHEN (Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER') AND Ext.user_can_connect = 1 THEN 1
  ELSE 0
END AS hasdbaccess,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.name = 'guest'
    OR Dbp.name = 'dbo' 
    THEN 1
  WHEN Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER' THEN 1
  ELSE 0
END AS islogin,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntname,
CAST(0 AS INT) AS isntgroup,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntuser,
CASE WHEN Dbp.type_desc = 'SQL_USER' THEN 1 ELSE 0 END AS issqluser,
CAST(0 AS INT) AS isaliased,
CASE WHEN Dbp.type_desc = 'DATABASE_ROLE' THEN 1 ELSE 0 END AS issqlrole,
CAST(0 AS INT) AS isapprole
FROM sys.database_principals AS Dbp LEFT JOIN 
  (SELECT orig_username, user_can_connect FROM sys.babelfish_authid_user_ext 
    WHERE database_name = sys.bbf_cur_db() collate database_default) AS Ext
ON Dbp.name = Ext.orig_username;
 
GRANT SELECT ON sys.sysusers TO PUBLIC;

-- Recreate sys.database_role_members (uses bbf_cur_db)
CREATE OR REPLACE VIEW sys.database_role_members AS
SELECT
CAST(
  CASE Ext1.orig_username
    WHEN 'db_owner' THEN 16384
    WHEN 'db_accessadmin' THEN 16385
    WHEN 'db_securityadmin' THEN 16386
    WHEN 'db_ddladmin' THEN 16387
    WHEN 'db_datareader' THEN 16390
    WHEN 'db_datawriter' THEN 16391
    ELSE Auth1.oid
  END AS INT) AS role_principal_id,
CAST(
  CASE Ext2.orig_username
    WHEN 'db_owner' THEN 16384
    WHEN 'db_accessadmin' THEN 16385
    WHEN 'db_securityadmin' THEN 16386
    WHEN 'db_ddladmin' THEN 16387
    WHEN 'db_datareader' THEN 16390
    WHEN 'db_datawriter' THEN 16391
    ELSE Auth2.oid
  END AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_roles AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_roles AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = sys.bbf_cur_db() collate database_default 
AND Ext2.database_name = sys.bbf_cur_db() collate database_default
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';

GRANT SELECT ON sys.database_role_members TO PUBLIC;

-- Recreate sys.babelfish_helpdb (uses orig_name)
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb()
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C STABLE;

-- internal table function for helpdb with dbname as input
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb(varchar)
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C STABLE;
-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
