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

-- BABEL-5975: mark babelfish_truncate_identifier PARALLEL SAFE. It is a pure,
-- deterministic string function (already IMMUTABLE) used per-row in the
-- sp_columns / sp_tables / sp_statistics filters and system views; without the
-- PARALLEL SAFE marker it disables parallelism (and forces poor plans) for
-- every query that references it, causing timeouts on large/upgraded catalogs.
CREATE OR REPLACE FUNCTION sys.babelfish_truncate_identifier(IN object_name TEXT)
RETURNS text
AS 'babelfishpg_tsql', 'pltsql_truncate_identifier_func' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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
    c.conname::sys.sysname as name
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
    c.conname::sys.sysname as name
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
where a.attgenerated = ''
and (s.nspname = 'sys' or ext.nspname is not null)
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::sys.sysname
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
  p.relname::sys.sysname as name
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

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as sys.bpchar(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  , CAST(tsql_get_expr(d.adbin, d.adrelid) as sys.nvarchar) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.attgenerated = ''
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

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



-- BABEL-5975:Store original names in options for tables, views, columns

-- Helper function for extracting original (untruncated) relation name from reloptions.
-- Only checks reloptions when relname is potentially truncated (>= 60 bytes).
CREATE OR REPLACE FUNCTION sys.bbf_get_truncated_rel_original_name(rel_reloptions text[], rel_relname name)
RETURNS text
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
RETURN COALESCE(
    CASE WHEN octet_length(rel_relname) >= 60 THEN
        (SELECT substring(opt, 23)
         FROM unnest(rel_reloptions) opt
         WHERE opt LIKE 'bbf_original_rel_name=%'
         LIMIT 1)
    END,
    rel_relname::text);

CREATE OR REPLACE FUNCTION sys.bbf_get_truncated_att_original_name(att_attoptions text[], att_attname name)
RETURNS text
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
RETURN COALESCE(
    CASE WHEN octet_length(att_attname) >= 60 THEN
        (SELECT substring(opt, 19)
         FROM unnest(att_attoptions) opt
         WHERE opt LIKE 'bbf_original_name=%'
         LIMIT 1)
    END,
    att_attname::text);


-- Recreate sys.tables
create or replace view sys.tables as
with tt_internal as MATERIALIZED
(
  select * from sys.table_types_internal
)
select
  CAST(sys.bbf_get_truncated_rel_original_name(t.reloptions, t.relname) as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(t.relnamespace as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as sys.bpchar(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , CAST(NULL as int) as filestream_data_space_id
  , CAST(relnatts as int) as max_column_id_used
  , CAST(0 as sys.bit) as lock_on_bulk_load
  , CAST(1 as sys.bit) as uses_ansi_nulls
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as has_replication_filter
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_sync_tran_subscribed
  , CAST(0 as sys.bit) as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , CAST(0 as sys.bit) as large_value_types_out_of_row
  , CAST(0 as sys.bit) as is_tracked_by_cdc
  , CAST(0 as sys.tinyint) as lock_escalation
  , CAST('TABLE' as sys.nvarchar(60)) as lock_escalation_desc
  , CAST(0 as sys.bit) as is_filetable
  , CAST(0 as sys.tinyint) as durability
  , CAST('SCHEMA_AND_DATA' as sys.nvarchar(60)) as durability_desc
  , CAST(0 as sys.bit) is_memory_optimized
  , case relpersistence when 't' then CAST(2 as sys.tinyint) else CAST(0 as sys.tinyint) end as temporal_type
  , case relpersistence when 't' then CAST('SYSTEM_VERSIONED_TEMPORAL_TABLE' as sys.nvarchar(60)) else CAST('NON_TEMPORAL_TABLE' as sys.nvarchar(60)) end as temporal_type_desc
  , CAST(null as integer) as history_table_id
  , CAST(0 as sys.bit) as is_remote_data_archive_enabled
  , CAST(0 as sys.bit) as is_external
from pg_class t
inner join sys.schemas sch on sch.schema_id = t.relnamespace
left join tt_internal tt on t.oid = tt.typrelid
where tt.typrelid is null
and (t.relkind = 'r' or t.relkind = 'p')
and t.relispartition = false
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;


-- Recreate sys.views
create or replace view sys.views as
select
  CAST(sys.bbf_get_truncated_rel_original_name(t.reloptions, t.relname) as sys.sysname) as name
  , t.oid::int as object_id
  , null::integer as principal_id
  , sch.schema_id::int as schema_id
  , 0 as parent_object_id
  , 'V'::sys.bpchar(2) as type
  , 'VIEW'::sys.nvarchar(60) as type_desc
  , vd.create_date::sys.datetime as create_date
  , vd.create_date::sys.datetime as modify_date
  , CAST(0 as sys.BIT) as is_ms_shipped
  , CAST(0 as sys.BIT) as is_published
  , CAST(0 as sys.BIT) as is_schema_published
  , CAST(0 as sys.BIT) as with_check_option
  , CAST(0 as sys.BIT) as is_date_correlation_view
  , CAST(0 as sys.BIT) as is_tracked_by_cdc
from pg_class t inner join sys.schemas sch on (t.relnamespace = sch.schema_id)
left join sys.shipped_objects_not_in_sys nis on (nis.name = t.relname and nis.schemaid = sch.schema_id and nis.type = 'V')
left outer join sys.babelfish_view_def vd on t.relname::sys.sysname = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id()
where t.relkind = 'v'
and nis.name is null
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

-- Recreate sys.all_views
create or replace view sys.all_views as
SELECT
    CAST(sys.bbf_get_truncated_rel_original_name(c.reloptions, c.relname) AS sys.SYSNAME) as name
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
-- Recreate sys.all_objects for BABEL-5975 long identifiers

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
    sys.bbf_get_truncated_rel_original_name(t.reloptions, t.relname)::sys.sysname as name
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
    sys.bbf_get_truncated_rel_original_name(t.reloptions, t.relname)::sys.sysname as name
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
    c.conname::sys.sysname as name
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
    c.conname::sys.sysname as name
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
    c.conname::sys.sysname
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
  p.relname::sys.sysname as name
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




-- Recreate sys.columns_internal()
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
			CAST(sys.bbf_get_truncated_att_original_name(a.attoptions, a.attname) AS sys.sysname),
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




-- Recreate sys.all_columns
create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(sys.bbf_get_truncated_att_original_name(a.attoptions, a.attname) as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(a.attidentity <> ''::"char" AS sys.bit) as is_identity
  , CAST(a.attgenerated <> ''::"char" AS sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join sys.babelfish_namespace_ext ext on (s.nspname = ext.nspname and ext.dbid = sys.db_id())
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.nspname = 'sys' or ext.nspname is not null)
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and c.relispartition = false
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar) AS definition
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
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
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
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


-- Recreate information_schema_tsql.views
CREATE OR REPLACE VIEW information_schema_tsql.views AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
   CAST(COALESCE((select substring(opt, 23) from unnest(c.reloptions) opt where opt like 'bbf_original_rel_name=%' limit 1), c.relname::text) AS sys.nvarchar(128)) AS "TABLE_NAME",
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


-- Recreate sys.sp_tables_view (uses COALESCE with reloptions for TABLE_NAME)
ALTER VIEW sys.sp_tables_view RENAME TO sp_tables_view_deprecated_in_6_3_0;
CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
CAST(t3.name AS name) AS TABLE_OWNER,
sys.bbf_get_truncated_rel_original_name(t1.reloptions, t1.relname)::sys.sysname AS TABLE_NAME,
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

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sp_tables_view_deprecated_in_6_3_0');



-- Recreate sys.sp_columns_100 procedure
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
		where (table_name like @table_name COLLATE database_default ESCAPE '\' -- '  adding quote in comment to suppress build warning
			   or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) like @table_name COLLATE database_default ESCAPE '\') -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_owner,'') = '' or table_owner like @table_owner collate database_default ESCAPE '\') -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_qualifier,'') = '' or table_qualifier like @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name like @column_name collate database_default
				 or sys.babelfish_truncate_identifier(pg_catalog.lower(column_name)) like @column_name collate database_default)
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
			where (table_name = @table_name collate database_default
				   or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = @table_name collate database_default)
			and (coalesce(@table_owner, '') = '' or table_owner = @table_owner collate database_default)
			and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name = @column_name collate database_default
				 or sys.babelfish_truncate_identifier(pg_catalog.lower(column_name)) = @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;



-- Recreate sys.sp_statistics_view
CREATE OR REPLACE VIEW sys.sp_statistics_view AS
SELECT
CAST(t3."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t3."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(NULL AS smallint) AS NON_UNIQUE,
CAST(NULL AS sys.sysname) AS INDEX_QUALIFIER,
CAST(NULL AS sys.sysname) AS INDEX_NAME,
CAST(0 AS smallint) AS TYPE,
CAST(NULL AS smallint) AS SEQ_IN_INDEX,
CAST(NULL AS sys.sysname) AS COLUMN_NAME,
CAST(NULL AS sys.varchar(1)) AS COLLATION,
CAST(t1.reltuples AS int) AS CARDINALITY,
CAST(t1.relpages AS int) AS PAGES,
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN information_schema_tsql.columns_internal t3 ON (t1.oid = t3."TABLE_OID")
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
UNION
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(sys.bbf_get_truncated_rel_original_name(t1.reloptions, t1.relname) AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
COALESCE((SELECT pg_catalog.string_agg(CASE WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23) ELSE NULL END, ',') FROM unnest(t6.reloptions) AS option), t6.relname::text)::sys.sysname 
AS INDEX_NAME,
CASE
WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
ELSE CAST(3 AS smallint)
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.n_distinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	JOIN pg_catalog.pg_namespace nsp ON (t1.relnamespace = nsp.oid)
	LEFT JOIN pg_catalog.pg_stats t7 ON (t1.relname = t7.tablename AND t7.schemaname = nsp.nspname)
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;



-- Recreate sys.sp_fkeys_view
CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
sys.bbf_get_truncated_rel_original_name(c2.reloptions, c2.relname)::sys.sysname AS PKTABLE_NAME,
CAST(COALESCE(split_part(a2.attoptions[1] COLLATE "C", '=', 2),a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
sys.bbf_get_truncated_rel_original_name(c.reloptions, c.relname)::sys.sysname AS FKTABLE_NAME,
CAST(COALESCE(split_part(a.attoptions[1] COLLATE "C", '=', 2),a.attname::text) AS sys.sysname) AS FKCOLUMN_NAME,
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


-- Recreate sys.sp_special_columns_view
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
CAST(coalesce (split_part(a.attoptions[1] COLLATE "C", '=', 2) ,a.attname::text) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
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
sys.bbf_get_truncated_rel_original_name(C.reloptions, C.relname)::sys.sysname AS TABLE_NAME,

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



CREATE OR REPLACE PROCEDURE sys.sp_columns (
 "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '',
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
 "@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
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
  where (table_name like @table_name COLLATE database_default
         or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) like @table_name COLLATE database_default)
   and (coalesce(@table_owner,'') = '' or table_owner like @table_owner collate database_default)
   and (coalesce(@table_qualifier,'') = '' or table_qualifier like @table_qualifier collate database_default)
	and (coalesce(@column_name,'') = '' or column_name like @column_name collate database_default
			or sys.babelfish_truncate_identifier(pg_catalog.lower(column_name)) like @column_name collate database_default)
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
   where (table_name = @table_name collate database_default
          or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = @table_name collate database_default)
   and (coalesce(@table_owner, '') = '' or table_owner = @table_owner collate database_default)
   and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier collate database_default)
	 and (coalesce(@column_name,'') = '' or column_name = @column_name collate database_default
			or sys.babelfish_truncate_identifier(pg_catalog.lower(column_name)) = @column_name collate database_default)
  order by table_qualifier,
     table_owner,
     table_name,
     ordinal_position;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns TO PUBLIC;

-- Recreate sys.OBJECT_DEFINITION to use all_sql_modules_internal (avoids timeout from heavy all_objects)
CREATE OR REPLACE FUNCTION sys.OBJECT_DEFINITION(IN object_id INT)
RETURNS sys.NVARCHAR
AS $$
DECLARE
    definition sys.NVARCHAR;
BEGIN

    definition = (SELECT cc.definition FROM sys.check_constraints cc WHERE cc.object_id = $1);
    IF (definition IS NULL)
    THEN
        definition = (SELECT dc.definition FROM sys.default_constraints dc WHERE dc.object_id = $1);
        IF (definition IS NULL)
        THEN
            definition = (SELECT asm.definition FROM sys.all_sql_modules_internal asm WHERE asm.object_id = $1);
            IF (definition IS NULL)
            THEN
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    RETURN definition;
END;
$$
LANGUAGE plpgsql STABLE;


-- BABEL-5321: recreate sp_tables, sp_pkeys, sp_statistics, sp_statistics_100
-- so they match both the original and the truncated (physical) identifier.
CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = NULL,
    "@table_owner" sys.nvarchar(384) = NULL, 
    "@table_qualifier" sys.sysname = NULL,
    "@table_type" sys.nvarchar(100) = NULL,
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN

	-- Temporary variable to hold the current database name
	DECLARE @current_db_name sys.sysname;

	-- Handle special case: Enumerate all databases when name and owner are blank but qualifier is '%'
	IF (@table_qualifier = '%' AND @table_owner = '' AND @table_name = '')
	BEGIN
		SELECT
			d.name AS TABLE_QUALIFIER,
			CAST(NULL AS sys.sysname) AS TABLE_OWNER,
			CAST(NULL AS sys.sysname) AS TABLE_NAME,
			CAST(NULL AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(NULL AS sys.varchar(254)) AS REMARKS
		FROM sys.databases d ORDER BY TABLE_QUALIFIER;
		
		RETURN;
	END;

	SELECT @current_db_name = sys.db_name();

	IF (@table_qualifier != '' AND pg_catalog.lower(@table_qualifier) != pg_catalog.lower(@current_db_name))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF (@fusepattern = 1)
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view 
		WHERE (@table_name IS NULL OR table_name LIKE @table_name collate database_default
			   or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) LIKE @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner LIKE @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier LIKE @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
	ELSE
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view
		WHERE (@table_name IS NULL OR table_name = @table_name collate database_default
			   or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner = @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier = @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = 'dbo',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select * from sys.sp_pkeys_view
	where (table_name = @table_name
		or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = @table_name)
		and table_owner = coalesce(@table_owner, 'dbo') 
		and ((SELECT
		         coalesce(@table_qualifier, '')) = '' or
		         table_qualifier = @table_qualifier )
	order by table_qualifier,
	         table_owner,
		 table_name,
		 key_seq;
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_statistics(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where (@table_name = table_name
		or @table_name = sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)))
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((pg_catalog.UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (pg_catalog.UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics TO PUBLIC;

-- same as sp_statistics
CREATE OR REPLACE PROCEDURE sys.sp_statistics_100(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where (@table_name = table_name
		or @table_name = sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)))
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((pg_catalog.UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (pg_catalog.UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

-- BABEL-5321: recreate system objects so they resolve long identifiers by
-- both the original and the truncated (physical) name, and display the
-- original (full) name. Covers table/view/column/index-related procedures.

CREATE OR REPLACE FUNCTION sys.sp_column_privileges_internal()
RETURNS TABLE (
    TABLE_QUALIFIER sys.sysname,
    TABLE_OWNER sys.sysname,
    TABLE_NAME sys.sysname,
    COLUMN_NAME sys.sysname,
    GRANTOR sys.sysname,
    GRANTEE sys.sysname,
    PRIVILEGE sys.varchar(32),
    IS_GRANTABLE sys.varchar(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
        CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
        CAST(sys.bbf_get_truncated_rel_original_name(t1.reloptions, t1.relname) AS sys.sysname) AS TABLE_NAME,
        CAST(COALESCE(SPLIT_PART(t6.attoptions[1], '=', 2), t5.column_name) AS sys.sysname) AS COLUMN_NAME,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t5.grantor::name) AS sys.sysname) AS GRANTOR,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t5.grantee::name) AS sys.sysname) AS GRANTEE,
        CAST(t5.privilege_type AS sys.varchar(32)) COLLATE sys.database_default AS PRIVILEGE,
        CAST(t5.is_grantable AS sys.varchar(3)) COLLATE sys.database_default AS IS_GRANTABLE
    FROM pg_catalog.pg_class t1 
        JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
        JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
        JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
        JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sp_table_privileges_internal()
RETURNS TABLE (
    TABLE_QUALIFIER sys.sysname,
    TABLE_OWNER sys.sysname,
    TABLE_NAME sys.sysname,
    GRANTOR sys.sysname,
    GRANTEE sys.sysname,
    PRIVILEGE sys.sysname,
    IS_GRANTABLE sys.sysname
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
        CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
        CAST(sys.bbf_get_truncated_rel_original_name(t1.reloptions, t1.relname) AS sys.sysname) AS TABLE_NAME,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
        CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
        CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
    FROM pg_catalog.pg_class t1 
        JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
        JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
        JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
    WHERE t4.privilege_type = 'DELETE';
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.sp_column_privileges(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
    "@column_name" sys.nvarchar(384) = ''
)
AS $$
BEGIN
    IF (@table_qualifier != '') AND (pg_catalog.lower(@table_qualifier) != pg_catalog.lower(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
 	
	IF (COALESCE(@table_owner, '') = '')
	BEGIN
		SELECT
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		COLUMN_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE
		FROM sys.sp_column_privileges_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND (pg_catalog.lower('dbo')= pg_catalog.lower(table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
	END
	ELSE
	BEGIN
		SELECT 
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		COLUMN_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE
		FROM sys.sp_column_privileges_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
	END
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.sysname = '',
	"@fusepattern" sys.bit = 1
)
AS $$
BEGIN
	
	IF (@table_qualifier != '') AND (pg_catalog.lower(@table_qualifier) != pg_catalog.lower(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF @fusepattern = 1
	BEGIN
		SELECT 
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE (pg_catalog.lower(TABLE_NAME) LIKE pg_catalog.lower(@table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(TABLE_NAME)) = pg_catalog.lower(@table_name))
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(TABLE_OWNER) LIKE pg_catalog.lower(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	ELSE 
	BEGIN
		SELECT
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE (pg_catalog.lower(TABLE_NAME) = pg_catalog.lower(@table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(TABLE_NAME)) = pg_catalog.lower(@table_name))
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(TABLE_OWNER) = pg_catalog.lower(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_special_columns(
	"@table_name" sys.sysname,
	"@table_owner" sys.sysname = '',
	"@qualifier" sys.sysname = '',
	"@col_type" char(1) = 'R',
	"@scope" char(1) = 'T',
	"@nullable" char(1) = 'U',
	"@odbcver" int = 2
)
AS $$
DECLARE @special_col_type sys.sysname;
DECLARE @constraint_name sys.sysname;
BEGIN
	IF (@qualifier != '') AND (pg_catalog.lower(@qualifier) != pg_catalog.lower(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
		
	END
	
	IF (pg_catalog.lower(@col_type) = pg_catalog.lower('V'))
	BEGIN
		THROW 33557097, N'TIMESTAMP datatype is not currently supported in Babelfish', 1;
	END
	
	IF (pg_catalog.lower(@nullable) = pg_catalog.lower('O'))
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0)
		ORDER BY constraint_type, index_id;
	
		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT  
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
				
			END
			ELSE
			BEGIN
				SELECT  
				SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
		
		END
		
		ELSE 
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN  FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
		END
	END
	
	ELSE 
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier))
		ORDER BY constraint_type, index_id;

		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
			
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
		
		END
		ELSE
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name; 
			END
			
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
    
		END
	END

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_fkeys(
	"@pktable_name" sys.sysname = '',
	"@pktable_owner" sys.sysname = '',
	"@pktable_qualifier" sys.sysname = '',
	"@fktable_name" sys.sysname = '',
	"@fktable_owner" sys.sysname = '',
	"@fktable_qualifier" sys.sysname = ''
)
AS $$
BEGIN
	
	IF coalesce(@pktable_name,'') = '' AND coalesce(@fktable_name,'') = '' 
	BEGIN
		THROW 33557097, N'Primary or foreign key table name must be given.', 1;
	END
	
	IF (@pktable_qualifier != '' AND (SELECT sys.db_name()) != @pktable_qualifier) OR 
		(@fktable_qualifier != '' AND (SELECT sys.db_name()) != @fktable_qualifier) 
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
  	END
  	
  	SELECT 
	PKTABLE_QUALIFIER,
	PKTABLE_OWNER,
	PKTABLE_NAME,
	PKCOLUMN_NAME,
	FKTABLE_QUALIFIER,
	FKTABLE_OWNER,
	FKTABLE_NAME,
	FKCOLUMN_NAME,
	KEY_SEQ,
	UPDATE_RULE,
	DELETE_RULE,
	FK_NAME,
	PK_NAME,
	DEFERRABILITY
	FROM sys.sp_fkeys_view
	WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR pg_catalog.lower(pktable_name) = pg_catalog.lower(@pktable_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(pktable_name)) = pg_catalog.lower(@pktable_name))
		AND ((SELECT coalesce(@fktable_name,'')) = '' OR pg_catalog.lower(fktable_name) = pg_catalog.lower(@fktable_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(fktable_name)) = pg_catalog.lower(@fktable_name))
		AND ((SELECT coalesce(@pktable_owner,'')) = '' OR pg_catalog.lower(pktable_owner) = pg_catalog.lower(@pktable_owner))
		AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR pg_catalog.lower(pktable_qualifier) = pg_catalog.lower(@pktable_qualifier))
		AND ((SELECT coalesce(@fktable_owner,'')) = '' OR pg_catalog.lower(fktable_owner) = pg_catalog.lower(@fktable_owner))
		AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR pg_catalog.lower(fktable_qualifier) = pg_catalog.lower(@fktable_qualifier))
	ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
