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



-- BABEL-5975: Long Identifier Handling Upgrade

-- Create babelfish_identifier_mapping catalog if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'babelfish_identifier_mapping' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sys')) THEN
        CREATE TABLE sys.babelfish_identifier_mapping (
            nspname NAME NOT NULL,
            pg_catalog_type OID NOT NULL,
            truncated_identifier_name NAME NOT NULL,
            original_identifier_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
            parent_name NAME NOT NULL DEFAULT '',
            PRIMARY KEY (truncated_identifier_name, nspname, pg_catalog_type, parent_name)
        );
        GRANT SELECT ON sys.babelfish_identifier_mapping TO PUBLIC;
    END IF;
END $$;



-- Recreate constraint and object views to resolve original names from babelfish_identifier_mapping
-- These use CREATE OR REPLACE since column types/collations are unchanged.
CREATE OR REPLACE VIEW sys.foreign_keys AS
SELECT
  CAST(COALESCE(
      case when octet_length(c.conname) >= 60
        then (select m.original_identifier_name from sys.babelfish_identifier_mapping m
          where m.truncated_identifier_name = c.conname
          and m.nspname = c.connamespace::regnamespace::name
          and m.pg_catalog_type = 'pg_constraint'::regclass::oid)
      end,
      c.conname::text) AS sys.sysname) AS name
, CAST(c.oid AS INT) AS object_id
, CAST(NULL AS INT) AS principal_id
, CAST(sch.schema_id AS INT) AS schema_id
, CAST(c.conrelid AS INT) AS parent_object_id
, CAST('F' AS sys.bpchar(2)) AS type
, CAST('FOREIGN_KEY_CONSTRAINT' AS sys.nvarchar(60)) AS type_desc
, CAST(NULL AS sys.datetime) AS create_date
, CAST(NULL AS sys.datetime) AS modify_date
, CAST(0 AS sys.bit) AS is_ms_shipped
, CAST(0 AS sys.bit) AS is_published
, CAST(0 AS sys.bit) AS is_schema_published
, CAST(c.confrelid AS INT) AS referenced_object_id
, CAST(c.conindid AS INT) AS key_index_id
, CAST(0 AS sys.bit) AS is_disabled
, CAST(0 AS sys.bit) AS is_not_for_replication
, CAST(0 AS sys.bit) AS is_not_trusted
, CAST(
    (CASE c.confdeltype
      WHEN 'a' THEN 0
      WHEN 'r' THEN 0
      WHEN 'c' THEN 1
      WHEN 'n' THEN 2
      WHEN 'd' THEN 3
    END)
    AS sys.tinyint) AS delete_referential_action
, CAST(
    (CASE c.confdeltype
      WHEN 'a' THEN 'NO_ACTION'
      WHEN 'r' THEN 'RESTRICT'
      WHEN 'c' THEN 'CASCADE'
      WHEN 'n' THEN 'SET_NULL'
      WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.nvarchar(60)) AS delete_referential_action_desc
, CAST(
    (CASE c.confupdtype
      WHEN 'a' THEN 0
      WHEN 'r' THEN 0
      WHEN 'c' THEN 1
      WHEN 'n' THEN 2
      WHEN 'd' THEN 3
    END)
    AS sys.tinyint) AS update_referential_action
, CAST(
    (CASE c.confupdtype
      WHEN 'a' THEN 'NO_ACTION'
      WHEN 'r' THEN 'RESTRICT'
      WHEN 'c' THEN 'CASCADE'
      WHEN 'n' THEN 'SET_NULL'
      WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.nvarchar(60)) AS update_referential_action_desc
, CAST(1 AS sys.bit) AS is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;


-- Recreate sys.key_constraints (resolve original constraint names)
CREATE OR replace view sys.key_constraints AS
SELECT
    CAST(COALESCE(
      case when octet_length(c.conname) >= 60
        then (select m.original_identifier_name from sys.babelfish_identifier_mapping m
          where m.truncated_identifier_name = c.conname
          and m.nspname = c.connamespace::regnamespace::name
          and m.pg_catalog_type = 'pg_constraint'::regclass::oid)
      end,
      c.conname::text) AS sys.sysname) AS name
  , CAST(c.oid AS INT) AS object_id
  , CAST(0 AS INT) AS principal_id
  , CAST(sch.schema_id AS INT) AS schema_id
  , CAST(c.conrelid AS INT) AS parent_object_id
  , CAST(
    (CASE contype
      WHEN 'p' THEN CAST('PK' as sys.bpchar(2))
      WHEN 'u' THEN CAST('UQ' as sys.bpchar(2))
    END) 
    AS sys.bpchar(2)) AS type
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PRIMARY_KEY_CONSTRAINT'
      WHEN 'u' THEN 'UNIQUE_CONSTRAINT'
    END)
    AS sys.nvarchar(60)) AS type_desc
  , CAST(NULL AS sys.datetime) AS create_date
  , CAST(NULL AS sys.datetime) AS modify_date
  , CAST(c.conindid AS INT) AS unique_index_id
  , CAST(0 AS sys.BIT) AS is_ms_shipped
  , CAST(0 AS sys.BIT) AS is_published
  , CAST(0 AS sys.BIT) AS is_schema_published
  , CAST(1 as sys.BIT) as is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE 
c.contype IN ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;

-- Recreate sys.check_constraints (resolve original constraint names)
CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(COALESCE(
      case when octet_length(c.conname) >= 60
        then (select m.original_identifier_name from sys.babelfish_identifier_mapping m
          where m.truncated_identifier_name = c.conname
          and m.nspname = c.connamespace::regnamespace::name
          and m.pg_catalog_type = 'pg_constraint'::regclass::oid)
      end,
      c.conname::text) as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as sys.bpchar(2)) as type
  , CAST('CHECK_CONSTRAINT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.bit) as is_disabled
  , CAST(0 as sys.bit) as is_not_for_replication
  , CAST(0 as sys.bit) as is_not_trusted
  , CAST(c.conkey[1] as integer) AS parent_column_id
  , CAST(sys.tsql_get_constraintdef(c.oid) as sys.nvarchar) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE 
c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;


-- NOTE: sys.all_objects also needs recreation to resolve original names.
-- Due to its size (350+ lines), it is included in the base 6.2.0 script
-- and will be applied on fresh installs. For upgrades, the view definition

create or replace view sys.types As
with RECURSIVE type_code_list as
(
    select distinct pg_typname as pg_type_name, tsql_typname as tsql_type_name
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
    ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE name = db_name() COLLATE "C") as sys.sysname)
    END as collation_name
  , case when typnotnull then cast(0 as sys.bit) else cast(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_user_defined
  , CASE ti.tsql_type_name
    -- CLR UDT have is_assembly_type = 1
    WHEN 'geometry' THEN CAST(1 as sys.bit)
    WHEN 'geography' THEN CAST(1 as sys.bit)
    ELSE CAST(0 as sys.bit)
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
select cast(coalesce(
    case when octet_length(t.typname) >= 60
      then (select ti.original_identifier_name from sys.babelfish_identifier_mapping ti
       where ti.truncated_identifier_name = t.typname
         and ti.nspname = t.typnamespace::regnamespace::name
         and ti.pg_catalog_type = 1247)
    end,
    t.typname::text) as sys.sysname) as name
  , cast(t.typbasetype as int) as system_type_id
  , cast(t.oid as int) as user_type_id
  , cast(t.typnamespace as int) as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) end as precision
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) end as scale
  , CASE
    WHEN t.typcollation = 0 THEN CAST(NULL as sys.sysname)
    ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE name = db_name() COLLATE "C") as sys.sysname)
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
    ELSE CAST(0 as sys.bit)
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

CREATE OR REPLACE VIEW sys.all_parameters
AS
SELECT
    CAST(ss.p_oid AS INT) AS object_id
  , CAST(COALESCE(
      case when octet_length(ss.proargnames[(ss.x).n]) >= 60
        then (SELECT ti.original_identifier_name FROM sys.babelfish_identifier_mapping ti
         WHERE ti.truncated_identifier_name = ss.proargnames[(ss.x).n]
           AND ti.pg_catalog_type = 'pg_proc'::regclass::oid)
      end,
      ss.proargnames[(ss.x).n], '') AS sys.SYSNAME) AS name
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 0 -- param_id = 0 for output of scalar function
        ELSE (ss.x).n
      END
    AS INT) AS parameter_id
  -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
  -- This is because the IDs of system type values generated by
  -- Babelfish installation will exceed the size of TINYINT
  , CAST(st.system_type_id AS INT) AS system_type_id
  , CAST(st.user_type_id AS INT) AS user_type_id
  , CAST(
      CASE
        WHEN CAST(st.is_table_type AS int) = 1 THEN -1 -- TVP case
        WHEN CAST(st.is_user_defined AS int) = 1 THEN st.max_length -- UDT case
        ELSE sys.tsql_type_max_length_helper(st.name, t.typlen, typmod, true, true)
      END
    AS smallint) AS max_length
  , CAST(
      CASE
        WHEN CAST(st.is_table_type AS int) = 1 THEN 0 -- TVP case
        WHEN CAST(st.is_user_defined AS int) = 1 THEN st.precision -- UDT case
        ELSE sys.tsql_type_precision_helper(st.name, typmod)
      END
    AS sys.tinyint) AS precision
  , CAST(
      CASE
        WHEN CAST(st.is_table_type AS int) = 1 THEN 0 -- TVP case
        WHEN CAST(st.is_user_defined AS int) = 1 THEN st.scale
        ELSE sys.tsql_type_scale_helper(st.name, typmod,false)
      END
    AS sys.tinyint) AS scale
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 1 -- Output of a scalar function
        WHEN ss.proargmodes[(ss.x).n] in ('o', 'b', 't') THEN 1
        ELSE 0
      END
    AS sys.bit) AS is_output
  , CAST(0 AS sys.bit) AS is_cursor_ref
  , CAST(0 AS sys.bit) AS has_default_value
  , CAST(0 AS sys.bit) AS is_xml_document
  , CAST(NULL AS sys.sql_variant) AS default_value
  , CAST(0 AS int) AS xml_collection_id
  , CAST(0 AS sys.bit) AS is_readonly
  , CAST(1 AS sys.bit) AS is_nullable
  , CAST(NULL AS int) AS encryption_type
  , CAST(NULL AS sys.nvarchar(64)) AS encryption_type_desc
  , CAST(NULL AS sys.sysname) AS encryption_algorithm_name
  , CAST(NULL AS int) AS column_encryption_key_id
  , CAST(NULL AS sys.sysname) AS column_encryption_key_database_name
FROM pg_type t
  INNER JOIN sys.types st ON st.user_type_id = t.oid
  INNER JOIN
  (
    SELECT
      p.oid AS p_oid,
      p.proargnames,
      p.proargmodes,
      p.prokind,
      json_extract_path(CAST(p.probin as json), 'typmod_array') AS typmod_array,
      information_schema._pg_expandarray(
      COALESCE(p.proallargtypes,
        CASE
          WHEN p.prokind = 'f' THEN (CAST( p.proargtypes AS oid[]) || p.prorettype) -- Adds return type if not present on proallargtypes
          ELSE CAST(p.proargtypes AS oid[])
        END
      )) AS x
    FROM pg_proc p
    WHERE (
      p.pronamespace in (select schema_id from sys.schemas union all select oid from pg_namespace where nspname = 'sys')
      AND (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND p.probin like '{%typmod_array%}') -- Needs to have a typmod array in JSON format
  ) ss ON t.oid = (ss.x).x,
  COALESCE(pg_get_function_result(ss.p_oid), '') AS return_type,
  CAST(ss.typmod_array->>(ss.x).n-1 AS INT) AS typmod,
  CAST(
    CASE
      WHEN ss.prokind = 'f' AND ss.proargnames[(ss.x).n] IS NULL THEN 1 -- checks if param is output of scalar function
      ELSE 0
    END
  AS INT) AS is_out_scalar
WHERE ( -- If it is a Table function, we only want the inputs
      return_type NOT LIKE 'TABLE(%' OR
      (return_type LIKE 'TABLE(%' AND ss.proargmodes[(ss.x).n] = 'i'));
GRANT SELECT ON sys.all_parameters TO PUBLIC;


-- Recreate sys.all_objects (includes constraint name resolution)
create or replace view sys.all_objects as
WITH tt_internal AS MATERIALIZED (
  SELECT typrelid FROM sys.table_types_internal
)
select
    name collate sys.database_default
  , cast (object_id as integer)
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , type collate sys.database_default
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- Currently for pg_class, pg_proc UNIONs, we separated user defined objects and system objects because the
-- optimiser will be able to make a better estimation of number of rows(in case the query contains a filter on
-- is_ms_shipped column) and in turn chooses a better query plan.

-- details of system tables
select
    t.relname::sys.sysname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U'::char(2) as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
left join tt_internal tt on t.oid = tt.typrelid
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = t.relname and nis.schemaid = s.oid and nis.type = 'U'
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.nspname = 'sys' or (nis.name is not null and ext.nspname is not null))
and tt.typrelid is null
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

union all
-- details of user defined tables
select
    t.relname::sys.sysname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U'::char(2) as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
left join tt_internal tt on t.oid = tt.typrelid
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = t.relname and nis.schemaid = s.oid and nis.type = 'U'
where t.relpersistence in ('p', 'u', 't')
and (t.relkind = 'r' or t.relkind = 'p')
and t.relispartition = false
and s.nspname <> 'sys' and nis.name is null
and ext.nspname is not null
and tt.typrelid is null
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

union all
-- details of system views
select
    t.relname::sys.sysname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::char(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = t.relname and nis.schemaid = s.oid and nis.type = 'V'
where t.relkind = 'v'
and (s.nspname = 'sys' or (nis.name is not null and ext.nspname is not null))
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- Details of user defined views
select
    t.relname::sys.sysname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::char(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = t.relname and nis.schemaid = s.oid and nis.type = 'V'
where t.relkind = 'v'
and s.nspname <> 'sys' and nis.name is null
and ext.nspname is not null
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = c.connamespace::regnamespace::name and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end,
      c.conname::text)::sys.sysname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F'::char(2) as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , CAST ((s.nspname = 'sys' or nis.name is not null) as sys.bit ) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = c.conname and nis.schemaid = s.oid and nis.type = 'F'
where
c.contype = 'f'
and (s.nspname = 'sys' or ext.nspname is not null)
union all
-- details of user defined and system primary key constraints
select
    COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = c.connamespace::regnamespace::name and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end,
      c.conname::text)::sys.sysname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK'::char(2) as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , CAST ((s.nspname = 'sys' or nis.name is not null) as sys.bit) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = c.conname and nis.schemaid = s.oid and nis.type = 'PK'
where
c.contype = 'p'
and (s.nspname = 'sys' or ext.nspname is not null)
union all
-- details of system defined procedures
select
    p.proname::sys.sysname as name
  , case
    when t.typname = 'trigger' then tr.oid else p.oid
  end as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null
           then tr.tgrelid
           else 0 end as int)
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::char(2)
      when 'a' then 'AF'::char(2)
      else
        case
          when t.typname = 'trigger'
            then 'TR'::char(2)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'TF'::char(2)
              else 'IF'::char(2)
            end
          else 'FN'::char(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case
          when t.typname = 'trigger'
            then 'SQL_TRIGGER'::varchar(60)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'SQL_TABLE_VALUED_FUNCTION'::varchar(60)
              else 'SQL_INLINE_TABLE_VALUED_FUNCTION'::varchar(60)
            end
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
inner join pg_catalog.pg_type t on t.oid = p.prorettype
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = p.proname and nis.schemaid = s.oid
and nis.type = (case p.prokind
      when 'p' then 'P'::char(2)
      when 'a' then 'AF'::char(2)
      else
        case
          when t.typname = 'trigger'
            then 'TR'::char(2)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'TF'::char(2)
              else 'IF'::char(2)
            end
          else 'FN'::char(2)
        end
    end)
where (s.nspname = 'sys' or (nis.name is not null and ext.nspname is not null))
and has_function_privilege(p.oid, 'EXECUTE')
and p.proname != 'pltsql_call_handler'

union all
-- details of user defined procedures
select
    p.proname::sys.sysname as name
  , case
      when t.typname = 'trigger' then tr.oid else p.oid
    end as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null
           then tr.tgrelid
           else 0 end as int)
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::char(2)
      when 'a' then 'AF'::char(2)
      else
        case
          when t.typname = 'trigger'
            then 'TR'::char(2)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'TF'::char(2)
              else 'IF'::char(2)
            end
          else 'FN'::char(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case
          when t.typname = 'trigger'
            then 'SQL_TRIGGER'::varchar(60)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'SQL_TABLE_VALUED_FUNCTION'::varchar(60)
              else 'SQL_INLINE_TABLE_VALUED_FUNCTION'::varchar(60)
            end
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0::sys.bit as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
inner join pg_catalog.pg_type t on t.oid = p.prorettype
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = p.proname and nis.schemaid = s.oid
and nis.type = (case p.prokind
      when 'p' then 'P'::char(2)
      when 'a' then 'AF'::char(2)
      else
        case
          when t.typname = 'trigger'
            then 'TR'::char(2)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'TF'::char(2)
              else 'IF'::char(2)
            end
          else 'FN'::char(2)
        end
    end)
where s.nspname <> 'sys' and nis.name is null
and ext.nspname is not null
and has_function_privilege(p.oid, 'EXECUTE')

union all
-- details of all default constraints
select
    ('DF_' || o.relname || '_' || d.oid)::sys.sysname as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , CAST ((s.nspname = 'sys' or nis.name is not null) as sys.bit) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = ('DF_' || o.relname || '_' || d.oid) and nis.schemaid = s.oid and nis.type = 'D'
where a.atthasdef = 't' and a.attgenerated = ''
and (s.nspname = 'sys' or ext.nspname is not null)
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = c.connamespace::regnamespace::name and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end,
      c.conname::text)::sys.sysname
  , c.oid::integer as object_id
  , NULL::integer as principal_id
  , s.oid as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , CAST ((s.nspname = 'sys' or nis.name is not null) as sys.bit) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = c.conname and nis.schemaid = s.oid and nis.type = 'C'
where
c.contype = 'c' and c.conrelid != 0
and (s.nspname = 'sys' or ext.nspname is not null)
union all
-- details of user defined and system defined sequence objects
select
  COALESCE(case when octet_length(p.relname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = p.relname and m.nspname = p.relnamespace::regnamespace::name and m.pg_catalog_type = 'pg_class'::regclass::oid and m.parent_name = '') end, p.relname::text)::sys.sysname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::char(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , CAST ((s.nspname = 'sys' or nis.name is not null) as sys.bit ) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.shipped_objects_not_in_sys nis on nis.name = p.relname and nis.schemaid = s.oid and nis.type = 'SO'
where p.relkind = 'S'
and (s.nspname = 'sys' or ext.nspname is not null)
union all
-- details of user defined table types
select
    ('TT_' || tt.name || '_' || tt.type_table_object_id)::sys.sysname as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::char(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , CAST ((tt.schema_id::regnamespace::text = 'sys' or nis.name is not null) as sys.bit ) as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
left join sys.shipped_objects_not_in_sys nis on nis.name = ('TT_' || tt.name || '_' || tt.type_table_object_id)::name and nis.schemaid = tt.schema_id and nis.type = 'TT'
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776) = NULL,
	IN "@newname" sys.SYSNAME = NULL,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET @objtype = sys.TRIM(@objtype);
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	ELSE IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
		END
	ELSE IF @objtype = 'DATABASE'
		BEGIN
			exec sys.sp_renamedb @objname, @newname;
		END
	ELSE
		BEGIN
			DECLARE @subname sys.nvarchar(776);
			DECLARE @schemaname sys.nvarchar(776);
			DECLARE @dbname sys.nvarchar(776);
			DECLARE @curr_relname sys.nvarchar(776);
			
			EXEC sys.babelfish_sp_rename_word_parse @objname, @objtype, @subname OUT, @curr_relname OUT, @schemaname OUT, @dbname OUT;

			DECLARE @currtype char(2);

			IF @objtype = 'COLUMN'
				BEGIN
					DECLARE @col_count INT;
					SELECT @col_count = COUNT(*)FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = sys.babelfish_truncate_identifier(pg_catalog.lower(@curr_relname)) and COLUMN_NAME = sys.babelfish_truncate_identifier(pg_catalog.lower(@subname));
					IF @col_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'CO';
				END
			ELSE IF @objtype = 'INDEX'
				BEGIN
					DECLARE @relid INT = 0;
					DECLARE @index_count INT;
					SELECT @relid = object_id FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
						WHERE s1.name = @schemaname AND o1.name = sys.babelfish_truncate_identifier(pg_catalog.lower(@curr_relname));
					IF @relid = 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SELECT @index_count = COUNT(*) FROM pg_index i JOIN pg_class c ON i.indexrelid = c.oid
						WHERE i.indrelid = @relid AND c.relname = sys.babelfish_construct_unique_index_name(sys.babelfish_truncate_identifier(pg_catalog.lower(@subname)), sys.babelfish_truncate_identifier(pg_catalog.lower(@curr_relname)));
					IF @index_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'IX';
				END
			ELSE IF @objtype = 'USERDATATYPE'
				BEGIN
					DECLARE @alias_count INT;
					SELECT @alias_count = COUNT(*) FROM sys.types t1 INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND t1.name = @subname;
					IF @alias_count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @alias_count < 1
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'AL';				
				END
			ELSE IF @objtype = 'OBJECT'
				BEGIN
					DECLARE @count INT;
					SELECT type INTO #tempTable FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND (o1.name = @subname OR o1.object_id = OBJECT_ID(sys.babelfish_truncate_identifier(pg_catalog.lower(@schemaname)) + '.' + sys.babelfish_truncate_identifier(pg_catalog.lower(@subname))));
					SELECT @count = COUNT(*) FROM #tempTable;

					IF @count < 1
						BEGIN
							-- sys.objects does not show routines which current user cannot execute but
							-- roles like db_ddladmin allow renaming a procedure even though they cannot
							-- execute it, so search again in pg_proc if count is zero
							DROP TABLE #tempTable;
							SELECT CAST(CASE 
											WHEN p.prokind = 'p' THEN 'P'
											WHEN p.prokind = 'a' THEN 'AF'
											WHEN format_type(p.prorettype, NULL) = 'trigger' THEN 'TR'
											ELSE 'FN'
										END as sys.bpchar(2)) AS type INTO #tempTable
							FROM pg_proc p INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id
							WHERE s1.name = @schemaname AND CAST(p.proname AS sys.sysname) = sys.babelfish_truncate_identifier(pg_catalog.lower(@subname));
							SELECT @count = COUNT(*) FROM #tempTable;
						END
					IF @count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @count < 1
						BEGIN
							-- TABLE TYPE: check if there is a match in sys.table_types (if we cannot alter sys.objects table_type naming)
							SELECT @count = COUNT(*) FROM sys.table_types tt1 INNER JOIN sys.schemas s1 ON tt1.schema_id = s1.schema_id 
							WHERE s1.name = @schemaname AND tt1.name = @subname;
							IF @count > 1
								BEGIN
									THROW 33557097, N'There are multiple objects with the given @objname.', 1;
								END
							ELSE IF @count < 1
								BEGIN
									THROW 33557097, N'There is no object with the given @objname.', 1;
								END
							ELSE
								BEGIN
									SET @currtype = 'TT'
								END
						END
					IF @currtype IS NULL
						BEGIN
							SELECT @currtype = type from #tempTable;
						END
					IF @currtype = 'TR' OR @currtype = 'TA'
						BEGIN
							DECLARE @physical_schema_name sys.nvarchar(776) = '';
							SELECT @physical_schema_name = nspname FROM sys.babelfish_namespace_ext WHERE dbid = sys.db_id() AND orig_name = @schemaname;
							SELECT @curr_relname = relname FROM pg_catalog.pg_trigger tr LEFT JOIN pg_catalog.pg_class c ON tr.tgrelid = c.oid LEFT JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid 
							WHERE tr.tgname = @subname AND n.nspname = @physical_schema_name;
						END
				END
			ELSE
				BEGIN
					THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
				END
			EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype, @curr_relname;
			PRINT 'Caution: Changing any part of an object name could break scripts and stored procedures.';
		END
END;
$$;
GRANT EXECUTE on PROCEDURE sys.sp_rename(IN sys.nvarchar(776), IN sys.SYSNAME, IN sys.varchar(13)) TO PUBLIC;
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
           COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = nsp.nspname and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end, c.conname::text)::sys.sysname AS "CONSTRAINT_NAME",
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







CREATE OR REPLACE VIEW information_schema_tsql.key_column_usage AS
 SELECT
  CAST(db_name AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
  CAST(ext.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
  COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = nsp.nspname and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end, c.conname::text)::sys.nvarchar(128) AS "CONSTRAINT_NAME",
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


-- Recreate sys.objects (includes sequence name resolution from babelfish_identifier_mapping)
create or replace view sys.objects as
select
      CAST(t.name as sys.sysname) as name 
    , CAST(t.object_id as int) as object_id
    , CAST(t.principal_id as int) as principal_id
    , CAST(t.schema_id as int) as schema_id
    , CAST(t.parent_object_id as int) as parent_object_id
    , CAST('U' as char(2)) as type
    , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
    , CAST(t.create_date as sys.datetime) as create_date
    , CAST(t.modify_date as sys.datetime) as modify_date
    , CAST(t.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(t.is_published as sys.bit) as is_published
    , CAST(t.is_schema_published as sys.bit) as is_schema_published
from  sys.tables t
union all
select
      CAST(v.name as sys.sysname) as name
    , CAST(v.object_id as int) as object_id
    , CAST(v.principal_id as int) as principal_id
    , CAST(v.schema_id as int) as schema_id
    , CAST(v.parent_object_id as int) as parent_object_id
    , CAST('V' as char(2)) as type
    , CAST('VIEW' as sys.nvarchar(60)) as type_desc
    , CAST(v.create_date as sys.datetime) as create_date
    , CAST(v.modify_date as sys.datetime) as modify_date
    , CAST(v.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(v.is_published as sys.bit) as is_published
    , CAST(v.is_schema_published as sys.bit) as is_schema_published
from  sys.views v
union all
select
      CAST(f.name as sys.sysname) as name
    , CAST(f.object_id as int) as object_id
    , CAST(f.principal_id as int) as principal_id
    , CAST(f.schema_id as int) as schema_id
    , CAST(f.parent_object_id as int) as parent_object_id
    , CAST('F' as char(2)) as type
    , CAST('FOREIGN_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(f.create_date as sys.datetime) as create_date
    , CAST(f.modify_date as sys.datetime) as modify_date
    , CAST(f.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(f.is_published as sys.bit) as is_published
    , CAST(f.is_schema_published as sys.bit) as is_schema_published
 from sys.foreign_keys f
union all
select
      CAST(p.name as sys.sysname) as name
    , CAST(p.object_id as int) as object_id
    , CAST(p.principal_id as int) as principal_id
    , CAST(p.schema_id as int) as schema_id
    , CAST(p.parent_object_id as int) as parent_object_id
    , CAST(p.type as char(2)) as type
    , CAST(
        CASE p.type
        WHEN 'PK' THEN 'PRIMARY_KEY_CONSTRAINT'
        WHEN 'UQ' THEN 'UNIQUE_CONSTRAINT'
        END
      as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
union all
select
      CAST(pr.name as sys.sysname) as name
    , CAST(pr.object_id as int) as object_id
    , CAST(pr.principal_id as int) as principal_id
    , CAST(pr.schema_id as int) as schema_id
    , CAST(pr.parent_object_id as int) as parent_object_id
    , CAST(pr.type as char(2)) as type
    , CAST(pr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(pr.create_date as sys.datetime) as create_date
    , CAST(pr.modify_date as sys.datetime) as modify_date
    , CAST(pr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(pr.is_published as sys.bit) as is_published
    , CAST(pr.is_schema_published as sys.bit) as is_schema_published
 from sys.procedures pr
union all
select
      CAST(tr.name as sys.sysname) as name
    , CAST(tr.object_id as int) as object_id
    , CAST(NULL as int) as principal_id
    , CAST(p.relnamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_class p on p.oid = tr.parent_id
union all 
select
    CAST(def.name as sys.sysname) as name
  , CAST(def.object_id as int) as object_id
  , CAST(def.principal_id as int) as principal_id
  , CAST(def.schema_id as int) as schema_id
  , CAST(def.parent_object_id as int) as parent_object_id
  , CAST(def.type as char(2)) as type
  , CAST(def.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(def.create_date as sys.datetime) as create_date
  , CAST(def.modified_date as sys.datetime) as modify_date
  , CAST(def.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(def.is_published as sys.bit) as is_published
  , CAST(def.is_schema_published as sys.bit) as is_schema_published
  from sys.default_constraints def
union all
select
    CAST(chk.name as sys.sysname) as name
  , CAST(chk.object_id as int) as object_id
  , CAST(chk.principal_id as int) as principal_id
  , CAST(chk.schema_id as int) as schema_id
  , CAST(chk.parent_object_id as int) as parent_object_id
  , CAST(chk.type as char(2)) as type
  , CAST(chk.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(chk.create_date as sys.datetime) as create_date
  , CAST(chk.modify_date as sys.datetime) as modify_date
  , CAST(chk.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(chk.is_published as sys.bit) as is_published
  , CAST(chk.is_schema_published as sys.bit) as is_schema_published
  from sys.check_constraints chk
union all
select
    CAST(COALESCE(
      case when octet_length(p.relname) >= 60
        then (select m.original_identifier_name from sys.babelfish_identifier_mapping m
          where m.truncated_identifier_name = p.relname
          and m.nspname = p.relnamespace::regnamespace::name
          and m.pg_catalog_type = 'pg_class'::regclass::oid
          and m.parent_name = '')
      end,
      p.relname::text) as sys.sysname) as name
  , CAST(p.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(s.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('SO' as char(2)) as type
  , CAST('SEQUENCE_OBJECT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
union all
select
    CAST(('TT_' || tt.name collate "C" || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select PG_CATALOG.string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select PG_CATALOG.string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt
inner join pg_class c on tt.type_table_object_id = c.oid;
GRANT SELECT ON sys.objects TO PUBLIC;


-- Recreate sys.sp_pkeys_view (constraint name resolution)
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

-- Recreate information_schema_tsql.check_constraints
CREATE OR REPLACE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
     CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           COALESCE(case when octet_length(c.conname) >= 60 then (select m.original_identifier_name from sys.babelfish_identifier_mapping m where m.truncated_identifier_name = c.conname and m.nspname = nc.nspname and m.pg_catalog_type = 'pg_constraint'::regclass::oid) end, c.conname::text)::sys.sysname AS "CONSTRAINT_NAME",
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

-- Recreate information_schema_tsql.constraint_column_usage
CREATE OR REPLACE VIEW information_schema_tsql.constraint_column_usage AS  SELECT (tblcat)::sys.nvarchar(128) AS "TABLE_CATALOG",
    tblschema AS "TABLE_SCHEMA",
    (tblname)::sys.nvarchar(128) AS "TABLE_NAME",
    (colname)::sys.nvarchar(128) AS "COLUMN_NAME",
    (cstrcat)::sys.nvarchar(128) AS "CONSTRAINT_CATALOG",
    cstrschema AS "CONSTRAINT_SCHEMA",
    (cstrname)::sys.nvarchar(128) AS "CONSTRAINT_NAME"
   FROM ( SELECT DISTINCT extr.orig_name,
            r.relname,
            r.relowner,
            a.attname,
            extc.orig_name,
            c.conname,
            nr.dbname,
            nc.dbname
           FROM (sys.pg_namespace_ext nc
             LEFT JOIN sys.babelfish_namespace_ext extc ON ((nc.nspname = extc.nspname))),
            (sys.pg_namespace_ext nr
             LEFT JOIN sys.babelfish_namespace_ext extr ON ((nr.nspname = extr.nspname))),
            pg_attribute a,
            pg_constraint c,
            pg_class r,
            pg_depend d
          WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (d.refclassid = ('pg_class'::regclass)::oid) AND (d.refobjid = r.oid) AND (d.refobjsubid = a.attnum) AND (d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = c.oid) AND (c.connamespace = nc.oid) AND (c.contype = 'c'::"char") AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (r.relispartition = false) AND (NOT a.attisdropped) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)))
        UNION ALL
         SELECT extr.orig_name,
            r.relname,
            r.relowner,
            a.attname,
            extc.orig_name,
            c.conname,
            nr.dbname,
            nc.dbname
           FROM (sys.pg_namespace_ext nc
             LEFT JOIN sys.babelfish_namespace_ext extc ON ((nc.nspname = extc.nspname))),
            (sys.pg_namespace_ext nr
             LEFT JOIN sys.babelfish_namespace_ext extr ON ((nr.nspname = extr.nspname))),
            pg_attribute a,
            pg_constraint c,
            pg_class r
          WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (nc.oid = c.connamespace) AND (r.oid = c.conrelid) AND (a.attnum = ANY (c.conkey)) AND (NOT a.attisdropped) AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (r.relispartition = false) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)))) x(tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat);; GRANT SELECT ON information_schema_tsql.constraint_column_usage TO PUBLIC;

-- Recreate sys.babelfish_construct_unique_index_name
CREATE OR REPLACE FUNCTION sys.babelfish_construct_unique_index_name(index_name TEXT, table_name TEXT)
RETURNS TEXT AS 'babelfishpg_tsql', 'bbf_construct_unique_index_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Register babelfish_identifier_mapping for pg_dump
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_identifier_mapping', '');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
