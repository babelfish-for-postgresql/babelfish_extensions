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
  , cast(
		coalesce(
			(select pg_catalog.string_agg(
				case
					when option like 'bbf_original_rel_name=%' then substring(option, 23 /* prefix length */)
					else null
				end, ',')
			from unnest(I.reloptions) as option),
			I.relname)
		AS sys.sysname) AS name
  , cast(case when X.indisclustered then 1 when am.amname = 'gist' and exists (select 1 from pg_attribute a2 join pg_type t2 on t2.oid = a2.atttypid where a2.attrelid = X.indrelid and a2.attnum = X.indkey[0] and t2.typname in ('geometry', 'geography')) then 4 else 2 end as sys.tinyint) as type
  , cast(case when X.indisclustered then 'CLUSTERED' when am.amname = 'gist' and exists (select 1 from pg_attribute a2 join pg_type t2 on t2.oid = a2.atttypid where a2.attrelid = X.indrelid and a2.attnum = X.indkey[0] and t2.typname in ('geometry', 'geography')) then 'SPATIAL' else 'NONCLUSTERED' end as sys.nvarchar(60)) as type_desc
  , cast(X.indisunique as sys.bit) as is_unique
  , cast(case when ps.scheme_id is null then 1 else ps.scheme_id end as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(X.indisprimary as sys.bit) as is_primary_key
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
inner join pg_class I on I.oid = X.indexrelid
inner join pg_am am ON am.oid = I.relam
inner join pg_class ptbl on ptbl.oid = X.indrelid and ptbl.relispartition = false
inner join pg_namespace nsp on nsp.oid = I.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.babelfish_partition_depend pd on
  (ext.orig_name  = pd.schema_name COLLATE sys.database_default
   and CAST(ptbl.relname AS sys.nvarchar(128)) = pd.table_name COLLATE sys.database_default and pd.dbid = sys.db_id() and ptbl.relkind = 'p')
left join sys.babelfish_partition_scheme ps on (ps.partition_scheme_name = pd.partition_scheme_name and ps.dbid = sys.db_id())
-- check if index is a unique constraint
left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
where 
-- index is active
X.indislive 
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
  , cast(case when ps.scheme_id is null then 1 else ps.scheme_id end as int) as data_space_id
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
left join sys.babelfish_partition_depend pd on
  (ext.orig_name = pd.schema_name COLLATE sys.database_default
   and CAST(t.relname AS sys.nvarchar(128)) = pd.table_name COLLATE sys.database_default and pd.dbid = sys.db_id())
left join sys.babelfish_partition_scheme ps on (ps.partition_scheme_name = pd.partition_scheme_name and ps.dbid = sys.db_id())
where (t.relkind = 'r' or t.relkind = 'p')
and t.relispartition = false
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;


CREATE OR REPLACE VIEW sys.spatial_indexes
AS
WITH index_id_map AS MATERIALIZED (
    SELECT indexrelid,
           CASE WHEN indisclustered THEN 1
                ELSE 1 + row_number() OVER (PARTITION BY indrelid ORDER BY indexrelid)
           END AS index_id
    FROM pg_index
)
SELECT 
   i.indrelid::integer AS object_id,
   COALESCE(
       (SELECT string_agg(
           CASE WHEN option ~~ 'bbf_original_rel_name=%' 
                THEN substring(option, 23) 
                ELSE NULL 
           END, ',') 
        FROM unnest(ic.reloptions) option), 
       ic.relname::text
   )::sys.sysname AS name,
   imap.index_id::integer AS index_id,
   CAST(4 AS sys.tinyint) AS type,
   CAST('SPATIAL' AS sys.nvarchar(60)) AS type_desc,
   CAST(0 AS sys.bit) AS is_unique,
   CAST(1 AS integer) AS data_space_id,
   CAST(0 AS sys.bit) AS ignore_dup_key,
   CAST(0 AS sys.bit) AS is_primary_key,
   CAST(0 AS sys.bit) AS is_unique_constraint,
   CAST(0 AS sys.tinyint) AS fill_factor,
   CAST(0 AS sys.bit) AS is_padded,
   CAST(0 AS sys.bit) AS is_disabled,
   CAST(0 AS sys.bit) AS is_hypothetical,
   CAST(1 AS sys.bit) AS allow_row_locks,
   CAST(1 AS sys.bit) AS allow_page_locks,
   CAST(
       CASE 
           WHEN t.typname = 'geometry' THEN 1
           WHEN t.typname = 'geography' THEN 2
           ELSE 1
       END AS sys.tinyint
   ) AS spatial_index_type,
   CAST(
       CASE 
           WHEN t.typname = 'geometry' THEN 'GEOMETRY'
           WHEN t.typname = 'geography' THEN 'GEOGRAPHY'
           ELSE 'GEOMETRY'
       END AS sys.nvarchar(60)
   ) AS spatial_index_type_desc,
   CAST(
       CASE 
           WHEN t.typname = 'geometry' THEN 'GEOMETRY_GRID'
           WHEN t.typname = 'geography' THEN 'GEOGRAPHY_GRID'
           ELSE 'GEOMETRY_GRID'
       END AS sys.sysname
   ) AS tessellation_scheme,
   CAST(0 AS sys.bit) AS has_filter,
   CAST(NULL AS sys.nvarchar(4000)) AS filter_definition,
   CAST(0 AS sys.bit) AS auto_created
FROM pg_catalog.pg_index i
JOIN index_id_map imap ON imap.indexrelid = i.indexrelid
JOIN pg_catalog.pg_class ic ON ic.oid = i.indexrelid
JOIN pg_catalog.pg_class tc ON tc.oid = i.indrelid
JOIN pg_catalog.pg_am am ON am.oid = ic.relam
JOIN pg_catalog.pg_attribute a ON a.attrelid = i.indrelid 
    AND a.attnum = i.indkey[0]
JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
JOIN pg_catalog.pg_namespace tn ON tn.oid = tc.relnamespace
LEFT JOIN sys.babelfish_namespace_ext ext ON (tn.nspname = ext.nspname AND ext.dbid = sys.db_id())
WHERE am.amname = 'gist'
  AND t.typname IN ('geometry', 'geography')
  AND (tn.nspname = 'sys' OR ext.nspname IS NOT NULL);
GRANT SELECT ON sys.spatial_indexes TO PUBLIC;


CREATE OR REPLACE VIEW sys.spatial_index_tessellations
AS
WITH index_id_map AS MATERIALIZED (
    SELECT indexrelid,
           CASE WHEN indisclustered THEN 1
                ELSE 1 + row_number() OVER (PARTITION BY indrelid ORDER BY indexrelid)
           END AS index_id
    FROM pg_index
)
SELECT 
   i.indrelid::integer AS object_id,
   imap.index_id::integer AS index_id,
   CAST(
       CASE 
           WHEN t.typname = 'geometry' THEN 'GEOMETRY_GRID'
           WHEN t.typname = 'geography' THEN 'GEOGRAPHY_GRID'
           ELSE 'GEOMETRY_GRID'
       END AS sys.sysname
   ) AS tessellation_scheme,
   CAST(NULL AS float(53)) AS bounding_box_xmin,
   CAST(NULL AS float(53)) AS bounding_box_ymin,
   CAST(NULL AS float(53)) AS bounding_box_xmax,
   CAST(NULL AS float(53)) AS bounding_box_ymax,
   CAST(NULL AS smallint) AS level_1_grid,
   CAST(NULL AS sys.nvarchar(60)) AS level_1_grid_desc,
   CAST(NULL AS smallint) AS level_2_grid,
   CAST(NULL AS sys.nvarchar(60)) AS level_2_grid_desc,
   CAST(NULL AS smallint) AS level_3_grid,
   CAST(NULL AS sys.nvarchar(60)) AS level_3_grid_desc,
   CAST(NULL AS smallint) AS level_4_grid,
   CAST(NULL AS sys.nvarchar(60)) AS level_4_grid_desc,
   CAST(NULL AS integer) AS cells_per_object
FROM pg_catalog.pg_index i
JOIN index_id_map imap ON imap.indexrelid = i.indexrelid
JOIN pg_catalog.pg_class ic ON ic.oid = i.indexrelid
JOIN pg_catalog.pg_class tc ON tc.oid = i.indrelid
JOIN pg_catalog.pg_am am ON am.oid = ic.relam
JOIN pg_catalog.pg_attribute a ON a.attrelid = i.indrelid 
    AND a.attnum = i.indkey[0]
JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
JOIN pg_catalog.pg_namespace tn ON tn.oid = tc.relnamespace
LEFT JOIN sys.babelfish_namespace_ext ext ON (tn.nspname = ext.nspname AND ext.dbid = sys.db_id())
WHERE am.amname = 'gist'
  AND t.typname IN ('geometry', 'geography')
  AND (tn.nspname = 'sys' OR ext.nspname IS NOT NULL);
GRANT SELECT ON sys.spatial_index_tessellations TO PUBLIC;


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

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
