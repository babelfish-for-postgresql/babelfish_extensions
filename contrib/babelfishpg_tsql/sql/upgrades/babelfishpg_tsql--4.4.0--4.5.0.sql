-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.5.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
WITH base_query AS (
  SELECT t1.oid AS table_oid,
         t1.reloptions AS reloptions,
         t2.nspname,
         t4.*,
         a.attoptions,
         a.atttypid,
         a.atttypmod,
         a.attlen,
         t.typname,
         t.typtypmod,
         ext.dbid,
         t6.is_computed,
         t6.is_identity
  FROM pg_catalog.pg_class t1
  JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
  JOIN information_schema_tsql.columns_internal t4 ON t1.oid = t4."TABLE_OID"
  LEFT JOIN pg_attribute a ON a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
  LEFT JOIN pg_type t ON t.oid = a.atttypid
  LEFT JOIN sys.babelfish_namespace_ext ext ON t2.nspname = ext.nspname
  LEFT JOIN sys.columns t6 ON t1.oid = t6.object_id AND t4."ORDINAL_POSITION" = t6.column_id
  WHERE ext.dbid = sys.db_id()
)
SELECT 
  CAST(b."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(b."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  -- CAST(b."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(
    CASE WHEN b.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(b.reloptions[1], 23)
      ELSE b."TABLE_NAME" END
            AS sys.sysname) AS TABLE_NAME,
  -- CAST(b."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(
			CASE WHEN b.attoptions[1] LIKE 'bbf_original_name%' THEN substring(b.attoptions[1], 19)
			ELSE b."COLUMN_NAME" END
            AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(COALESCE(tsql_type_name, b.typname) AS sys.sysname) AS TYPE_NAME,
  CASE 
    WHEN b."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN b.atttypmod != -1 THEN CAST(COALESCE(b."NUMERIC_PRECISION", b."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(b."DATA_TYPE", b.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp' THEN 8
    ELSE CAST(COALESCE(b."NUMERIC_PRECISION", b."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(b."DATA_TYPE", b.typtypmod)) AS INT)
  END AS PRECISION,
--   CAST(sys.tsql_type_length_for_sp_columns_helper(b."DATA_TYPE", b.attlen, COALESCE(b.atttypmod, b.typtypmod)) AS int) AS LENGTH,
  CASE WHEN b.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(b."DATA_TYPE", b.attlen, b.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(b."DATA_TYPE", b.attlen, b.typtypmod) AS int)
  END AS LENGTH,
--   CAST(COALESCE(b."NUMERIC_SCALE", sys.tsql_type_scale_helper(b."DATA_TYPE", COALESCE(b.atttypmod, b.typtypmod), true)) AS smallint) AS SCALE,
  CASE WHEN b.atttypmod != -1
    THEN
    CAST(coalesce(b."NUMERIC_SCALE", sys.tsql_type_scale_helper(b."DATA_TYPE", b.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(b."NUMERIC_SCALE", sys.tsql_type_scale_helper(b."DATA_TYPE", b.typtypmod, true)) AS smallint)
  END AS SCALE,
  CAST(COALESCE(b."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(b."DATA_TYPE")) AS smallint) AS RADIX,
  CAST(CASE WHEN b."IS_NULLABLE" = 'YES' THEN 1 ELSE 0 END AS smallint) AS NULLABLE,
  CAST(NULL AS varchar(254)) AS remarks,
  CAST(b."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,
  CASE 
    WHEN b."DATA_TYPE" = 'xml' THEN 0::INT
    WHEN b."DATA_TYPE" = 'sql_variant' THEN 8000::INT
    WHEN b."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(b."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,
  CAST(b."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(b."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(b.is_computed AS smallint) AS SS_IS_COMPUTED,
  CAST(b.is_identity AS smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) AS SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) AS SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) AS SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) AS SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) AS SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) AS SS_XML_SCHEMACOLLECTION_NAME
FROM base_query b
CROSS JOIN LATERAL sys.translate_pg_type_to_tsql(b.atttypid) AS tsql_type_name
JOIN sys.spt_datatype_info_table t5 ON (b."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)) OR (b."DATA_TYPE" = 'bytea' AND t5.TYPE_NAME = 'image'));

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;
-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
