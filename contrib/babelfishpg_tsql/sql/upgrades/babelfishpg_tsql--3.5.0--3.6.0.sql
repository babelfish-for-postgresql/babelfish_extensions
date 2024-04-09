-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.6.0'" to load this file. \quit

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

-- BABELFISH_SCHEMA_PERMISSIONS
CREATE TABLE IF NOT EXISTS sys.babelfish_schema_permissions (
  dbid smallint NOT NULL,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  permission INT CHECK(permission > 0),
  grantee sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_type CHAR(1) NOT NULL COLLATE sys.database_default,
  function_args TEXT COLLATE "C",
  grantor sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, object_name, grantee, object_type)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_schema_permissions', '');

CREATE OR REPLACE VIEW sys.index_columns
AS
WITH index_id_map AS MATERIALIZED (
  SELECT
    indexrelid,
    CASE
      WHEN indisclustered THEN 1
      ELSE 1+row_number() OVER(PARTITION BY indrelid ORDER BY indexrelid)
    END AS index_id
  FROM pg_index
)
SELECT
    CAST(i.indrelid AS INT) AS object_id,
    -- should match index_id of sys.indexes 
    CAST(imap.index_id AS INT) AS index_id,
    CAST(a.index_column_id AS INT) AS index_column_id,
    CAST(a.attnum AS INT) AS column_id,
    CAST(CASE
            WHEN a.index_column_id <= i.indnkeyatts THEN a.index_column_id
            ELSE 0
         END AS SYS.TINYINT) AS key_ordinal,
    CAST(0 AS SYS.TINYINT) AS partition_ordinal,
    CAST(CASE
            WHEN i.indoption[a.index_column_id-1] & 1 = 1 THEN 1
            ELSE 0 
         END AS SYS.BIT) AS is_descending_key,
    CAST(CASE
            WHEN a.index_column_id > i.indnkeyatts THEN 1
            ELSE 0
         END AS SYS.BIT) AS is_included_column
FROM
    pg_index i
    INNER JOIN index_id_map imap ON imap.indexrelid = i.indexrelid
    INNER JOIN pg_class c ON i.indrelid = c.oid
    INNER JOIN pg_namespace nsp ON nsp.oid = c.relnamespace
    LEFT JOIN sys.babelfish_namespace_ext ext ON (nsp.nspname = ext.nspname AND ext.dbid = sys.db_id())
    LEFT JOIN unnest(i.indkey) WITH ORDINALITY AS a(attnum, index_column_id) ON true
WHERE
    has_schema_privilege(c.relnamespace, 'USAGE') AND
    has_table_privilege(c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') AND
    (nsp.nspname = 'sys' OR ext.nspname is not null) AND
    i.indislive;
GRANT SELECT ON sys.index_columns TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE STRICT
AS $$
DECLARE
    extra_bytes CONSTANT INTEGER := 4;
    return_value INTEGER;
BEGIN
	return_value:=
        CASE LOWER(property_name)
            WHEN 'charmaxlen' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes
                    ELSE NULL
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'allowsnull' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attnotnull THEN 0
                    ELSE 1
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'iscomputed' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attgenerated != '' THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            WHEN 'columnid' COLLATE sys.database_default THEN
                (SELECT a.attnum FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'ordinal' COLLATE sys.database_default THEN
                (SELECT b.count FROM (SELECT attname, row_number() OVER () AS count FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND attisdropped = false AND attnum > 0 ORDER BY a.attnum) AS b WHERE b.attname = property COLLATE sys.database_default)
            WHEN 'isidentity' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN char_length(a.attidentity) > 0 THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            ELSE
                NULL
        END;
    RETURN return_value::INTEGER;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT) TO PUBLIC;

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
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar(4000)) AS definition
  , 1::sys.bit AS uses_database_collation
  , 1::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_object_id = a.attrelid AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

create or replace view sys.indexes as
-- Get all indexes from all system and user tables
with index_id_map as MATERIALIZED(
  select
    indexrelid,
    case
      when indisclustered then 1
      else 1+row_number() over(partition by indrelid order by indexrelid)
    end as index_id
  from pg_index
)
select
  cast(X.indrelid as int) as object_id
  , cast(I.relname as sys.sysname) as name
  , cast(case when X.indisclustered then 1 else 2 end as sys.tinyint) as type
  , cast(case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as sys.nvarchar(60)) as type_desc
  , cast(case when X.indisunique then 1 else 0 end as sys.bit) as is_unique
  , cast(I.reltablespace as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(case when X.indisprimary then 1 else 0 end as sys.bit) as is_primary_key
  , cast(case when const.oid is null then 0 else 1 end as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(case when X.indpred is null then 0 else 1 end as sys.bit) as is_padded
  , cast(case when X.indisready then 0 else 1 end as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(imap.index_id as int) as index_id
from pg_index X 
inner join index_id_map imap on imap.indexrelid = X.indexrelid
inner join pg_class I on I.oid = X.indexrelid and I.relkind = 'i'
inner join pg_namespace nsp on nsp.oid = I.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
-- check if index is a unique constraint
left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
where has_schema_privilege(I.relnamespace, 'USAGE')
-- index is active
and X.indislive 
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)

union all 
-- Create HEAP entries for each system and user table
select
  cast(t.oid as int) as object_id
  , cast(null as sys.sysname) as name
  , cast(0 as sys.tinyint) as type
  , cast('HEAP' as sys.nvarchar(60)) as type_desc
  , cast(0 as sys.bit) as is_unique
  , cast(1 as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(0 as sys.bit) as is_primary_key
  , cast(0 as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(0 as sys.bit) as is_padded
  , cast(0 as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(0 as int) as index_id
from pg_class t
inner join pg_namespace nsp on nsp.oid = t.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
where t.relkind = 'r'
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
