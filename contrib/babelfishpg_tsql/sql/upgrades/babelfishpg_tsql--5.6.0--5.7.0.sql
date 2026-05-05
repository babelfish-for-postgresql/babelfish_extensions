-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.7.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.columns_internal() RENAME TO columns_internal_deprecated_in_5_7_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE VIEW sys.columns_internal AS
SELECT CAST(c.oid AS int) AS out_object_id,
	CAST(a.attname AS sys.sysname) AS out_name,
	CAST(a.attnum AS int) AS out_column_id,
	CASE 
	WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
    -- either tsql or PG base type 
		CAST(a.atttypid AS int)
	ELSE 
		CAST(t.typbasetype AS int)
	END AS out_system_type_id,
	CAST(a.atttypid AS int) AS out_user_type_id,
	CASE
	WHEN a.atttypmod != -1 THEN 
		CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) AS smallint)
	ELSE 
		CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod) AS smallint)
	END AS out_max_length,
	CASE
	WHEN a.atttypmod != -1 THEN 
		CAST(sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod) AS sys.tinyint)
	ELSE 
		CAST(sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod) AS sys.tinyint)
	END AS out_precision,
	CASE
	WHEN a.atttypmod != -1 THEN 
		CAST(sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false) AS sys.tinyint)
	ELSE 
		CAST(sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false) AS sys.tinyint)
	END AS out_scale,
	CAST(coll.collname AS sys.sysname) AS out_collation_name,
	CAST(a.attcollation AS int) AS out_collation_id,
	CAST(a.attnum AS smallint) AS out_offset,
	CAST(case when a.attnotnull then 0 else 1 end AS sys.bit) AS out_is_nullable,
	CAST(t.typname in ('bpchar', 'nchar', 'binary') AS sys.bit) AS out_is_ansi_padded,
	CAST(0 AS sys.bit) AS out_is_rowguidcol,
	CAST(a.attidentity <> ''::"char" AS sys.bit) AS out_is_identity,
	CAST(a.attgenerated <> ''::"char" AS sys.bit) AS out_is_computed,
	CAST(0 AS sys.bit) AS out_is_filestream,
	CAST(0 AS sys.bit) AS out_is_replicated,
	CAST(0 AS sys.bit) AS out_is_non_sql_subscribed,
	CAST(0 AS sys.bit) AS out_is_merge_published,
	CAST(0 AS sys.bit) AS out_is_dts_replicated,
	CAST(0 AS sys.bit) AS out_is_xml_document,
	CAST(0 AS int) AS out_xml_collection_id,
	CAST(coalesce(d.oid, 0) AS int) AS out_default_object_id,
	CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
				and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int) AS out_rule_object_id,
	CAST(0 AS sys.bit) AS out_is_sparse,
	CAST(0 AS sys.bit) AS out_is_column_set,
	CAST(0 AS sys.tinyint) AS out_generated_always_type,
	CAST('NOT_APPLICABLE' AS sys.nvarchar) AS out_generated_always_type_desc,
	CAST(null AS int) AS out_encryption_type,
	CAST(null AS sys.nvarchar) AS out_encryption_type_desc,
	CAST(null AS sys.sysname) AS out_encryption_algorithm_name,
	CAST(null AS int) AS out_column_encryption_key_id,
	CAST(null AS sys.sysname) AS out_column_encryption_key_database_name,
	CAST(0 AS sys.bit) AS out_is_hidden,
	CAST(0 AS sys.bit) AS out_is_masked,
	CAST(null AS int) AS out_graph_type,
	CAST(null AS sys.nvarchar) AS out_graph_type_desc
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
	CAST('NOT_APPLICABLE' AS sys.nvarchar),
	CAST(null AS int),
	CAST(null AS sys.nvarchar),
	CAST(null AS sys.sysname),
	CAST(null AS int),
	CAST(null AS sys.sysname),
	CAST(0 AS sys.bit),
	CAST(0 AS sys.bit),
	CAST(null AS int),
	CAST(null AS sys.nvarchar)
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
GRANT SELECT ON sys.columns_internal TO PUBLIC;

create or replace view sys.columns AS
select out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
from sys.columns_internal;
GRANT SELECT ON sys.columns TO PUBLIC;

CREATE OR replace view sys.identity_columns AS
SELECT 
  CAST(out_object_id AS INT) AS object_id
  , CAST(out_name AS SYSNAME) AS name
  , CAST(out_column_id AS INT) AS column_id
  , CAST(out_system_type_id AS TINYINT) AS system_type_id
  , CAST(out_user_type_id AS INT) AS user_type_id
  , CAST(out_max_length AS SMALLINT) AS max_length
  , CAST(out_precision AS TINYINT) AS precision
  , CAST(out_scale AS TINYINT) AS scale
  , CAST(out_collation_name AS SYSNAME) AS collation_name
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
  , CAST(out_generated_always_type AS TINYINT) AS generated_always_type
  , CAST(out_generated_always_type_desc AS NVARCHAR(60)) AS generated_always_type_desc
  , CAST(out_encryption_type AS INT) AS encryption_type
  , CAST(out_encryption_type_desc AS NVARCHAR(60)) AS encryption_type_desc
  , CAST(out_encryption_algorithm_name AS SYSNAME) AS encryption_algorithm_name
  , CAST(out_column_encryption_key_id AS INT) column_encryption_key_id
  , CAST(out_column_encryption_key_database_name AS SYSNAME) AS column_encryption_key_database_name
  , CAST(out_is_hidden AS sys.BIT) AS is_hidden
  , CAST(out_is_masked AS sys.BIT) AS is_masked
  , CAST(sys.ident_seed(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS seed_value
  , CAST(sys.ident_incr(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS increment_value
  , CAST(sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) AS SQL_VARIANT) AS last_value
  , CAST(0 as sys.BIT) as is_not_for_replication
FROM sys.columns_internal sc
INNER JOIN pg_attribute a ON a.attrelid = sc.out_object_id AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.computed_columns
AS
SELECT out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar) AS definition
  , 1::sys.bit AS uses_database_collation
  , 1::sys.bit AS is_persisted
FROM sys.columns_internal sc
INNER JOIN pg_attribute a ON sc.out_object_id = a.attrelid AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscolumns AS
SELECT out_name as name
  , out_object_id as id
  , out_system_type_id as xtype
  , 0::sys.tinyint as typestat
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as xusertype
  , out_max_length as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , out_column_id::smallint as colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , out_default_object_id::int as cdefault
  , out_rule_object_id::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , out_offset as offset
  , out_collation_id as collationid
  , (case out_is_nullable::int when 1 then 8    else 0 end +
     case out_is_identity::int when 1 then 128  else 0 end)::sys.tinyint as status
  , out_system_type_id as type
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as usertype
  , null::sys.varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal
union all
SELECT p.name
  , p.id
  , p.xtype
  , 0::sys.tinyint as typestat
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as xusertype
  , null as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , p.colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , null::int as cdefault
  , null::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , 0::smallint as offset
  , collationid
  , (case p.isoutparam when 1 then 64 else 0 end)::sys.tinyint as status
  , p.xtype type
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , p.prec
  , p.scale
  , 0::int as iscomputed
  , p.isoutparam
  , 1::int as isnullable
  , p.collation
FROM sys.proc_param_helper() as p;
GRANT SELECT ON sys.syscolumns TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'columns_internal_deprecated_in_5_7_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
