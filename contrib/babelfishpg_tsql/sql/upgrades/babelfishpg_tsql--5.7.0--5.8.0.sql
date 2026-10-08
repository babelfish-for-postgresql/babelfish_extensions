-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.8.0'" to load this file. \quit
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

CREATE OR REPLACE PROCEDURE sys.analyze_babelfish_catalogs()
LANGUAGE plpgsql
AS $$ 
DECLARE 
	babelfish_catalog RECORD;
	schema_name varchar = 'sys';
	error_msg text;
BEGIN
	FOR babelfish_catalog IN (
		SELECT relname as name FROM pg_catalog.pg_class t 
		INNER JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
		WHERE t.relkind = 'r' AND n.nspname = schema_name
		)
	LOOP
		BEGIN
			EXECUTE pg_catalog.format('ANALYZE %I.%I', schema_name, babelfish_catalog.name);
		EXCEPTION WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
			RAISE WARNING 'ANALYZE for babelfish catalog %.% failed with error: %s', schema_name, babelfish_catalog.name, error_msg;
		END;
	END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
	reserved_roles varchar[] := ARRAY['sysadmin', 'securityadmin', 'dbcreator',
									  'master_dbo', 'master_guest', 'master_db_owner',
									  'master_db_accessadmin', 'master_db_securityadmin',
									  'master_db_datareader', 'master_db_datawriter', 'master_db_ddladmin',
									  'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner', 
									  'tempdb_db_accessadmin', 'tempdb_db_securityadmin',
									  'tempdb_db_datareader', 'tempdb_db_datawriter', 'tempdb_db_ddladmin',
									  'msdb_dbo', 'msdb_guest', 'msdb_db_owner',
									  'msdb_db_accessadmin', 'msdb_db_securityadmin',
									  'msdb_db_datareader', 'msdb_db_datawriter', 'msdb_db_ddladmin'];
	user_id  oid := -1;
	db_name  name := NULL;
	role_name varchar;
	dba_name varchar;
BEGIN
	-- check reserved roles
	FOREACH role_name IN ARRAY reserved_roles LOOP
	BEGIN
		SELECT oid INTO user_id FROM pg_catalog.pg_roles WHERE rolname = role_name;
		IF user_id > 0 THEN
			SELECT datname INTO db_name FROM pg_catalog.pg_shdepend AS s INNER JOIN pg_catalog.pg_database AS d ON s.dbid = d.oid WHERE s.refobjid = user_id;
			IF db_name IS NOT NULL THEN
				RAISE E'Could not initialize babelfish in current database: Reserved role % used in database %.\nIf babelfish was initialized in %, please remove babelfish and try again.', role_name, db_name, db_name;
			ELSE
				RAISE E'Could not initialize babelfish in current database: Reserved role % exists. \nPlease rename or drop existing role and try again ', role_name;
			END IF;
		END IF;
	END;
	END LOOP;

	SELECT pg_catalog.pg_get_userbyid(datdba) INTO dba_name FROM pg_catalog.pg_database WHERE datname = pg_catalog.current_database();
	IF sa_name <> dba_name THEN
		RAISE E'Could not initialize babelfish with given role name: % is not the DB owner of current database.', sa_name;
	END IF;

	EXECUTE pg_catalog.format('CREATE ROLE securityadmin CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('CREATE ROLE dbcreator CREATEDB INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('CREATE ROLE bbf_role_admin CREATEDB CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE pg_catalog.format('GRANT CREATE ON DATABASE %s TO bbf_role_admin', pg_catalog.current_database());
	EXECUTE pg_catalog.format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', sa_name);
	EXECUTE pg_catalog.format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
	EXECUTE pg_catalog.format('GRANT sysadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT securityadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT dbcreator TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_function_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_scheme_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE pg_catalog.format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', pg_catalog.current_database());
	EXECUTE pg_catalog.format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', pg_catalog.current_database());
	EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
	CALL sys.babel_initialize_logins(sa_name);
	CALL sys.babel_initialize_logins('sysadmin');
	CALL sys.babel_initialize_logins('bbf_role_admin');
	CALL sys.babel_initialize_logins('securityadmin');
	CALL sys.babel_initialize_logins('dbcreator');
	CALL sys.babel_create_builtin_dbs(sa_name);
	CALL sys.initialize_babel_extras();
	-- run analyze for all babelfish catalog
	CALL sys.analyze_babelfish_catalogs();
END
$$;

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
	CALL sys.babel_drop_all_dbs();
	CALL sys.babel_drop_all_logins();
	EXECUTE pg_catalog.format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', pg_catalog.current_database());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_function_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_scheme_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
	DROP OWNED BY bbf_role_admin;
	DROP ROLE bbf_role_admin;
	DROP OWNED BY securityadmin;
	DROP ROLE securityadmin;
	DROP OWNED BY dbcreator;
	DROP ROLE dbcreator;
END
$$;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
