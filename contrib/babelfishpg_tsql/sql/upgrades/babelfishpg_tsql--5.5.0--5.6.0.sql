-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.6.0'" to load this file. \quit
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.datetime2fromparts(NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC) RENAME TO datetime2fromparts_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datetime2fromparts_deprecated_in_5_6_0');

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year INT,
                                                                IN p_month INT,
                                                                IN p_day INT,
                                                                IN p_hour INT,
                                                                IN p_minute INT,
                                                                IN p_seconds INT,
                                                                IN p_fractions INT,
                                                                IN p_precision INT)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
   v_fractions VARCHAR;
   v_precision SMALLINT;
   v_err_message VARCHAR;
   v_calc_seconds NUMERIC;
   v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
   v_string pg_catalog.text;
BEGIN
   IF p_precision IS NULL THEN
      RAISE invalid_parameter_value USING 
         MESSAGE := 'Precision argument cannot be null.',
         DETAIL := 'The precision parameter is mandatory for DATETIME2.',
         HINT := 'Provide a valid precision value between 0 and 7.';
   END IF;

   IF p_year IS NULL OR p_month IS NULL OR p_day IS NULL OR 
      p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR 
      p_fractions IS NULL THEN
      RETURN NULL;
   END IF;

   v_fractions := p_fractions::VARCHAR;
   v_precision := p_precision::SMALLINT;

   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year NOT BETWEEN 1 AND 9999) OR
       (p_month NOT BETWEEN 1 AND 12) OR
       (p_day NOT BETWEEN 1 AND 31) OR
       (p_hour NOT BETWEEN 0 AND 23) OR
       (p_minute NOT BETWEEN 0 AND 59) OR
       (p_seconds NOT BETWEEN 0 AND 59) OR
       (p_fractions NOT BETWEEN 0 AND 9999999) OR
       (p_fractions != 0 AND char_length(v_fractions) > v_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := pg_catalog.format('%s.%s',
                            p_seconds,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, v_precision))::NUMERIC;

   v_resdatetime := make_timestamp(p_year,
                         p_month,
                         p_day,
                         p_hour,
                         p_minute,
                         v_calc_seconds);

   v_string := v_resdatetime::pg_catalog.text;

   RETURN CAST(v_string AS sys.DATETIME2);
EXCEPTION
   WHEN most_specific_type_mismatch THEN
      RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_parameter_value THEN
      RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';

   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := pg_catalog.upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                  HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.datetime2fromparts(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) RENAME TO datetime2fromparts_text_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datetime2fromparts_text_deprecated_in_5_6_0');

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    IF p_precision IS NULL THEN
        RAISE invalid_parameter_value USING 
            MESSAGE := 'Precision argument cannot be null.',
            DETAIL := 'The precision parameter is mandatory for DATETIME2.',
            HINT := 'Provide a valid precision value between 0 and 7.';
    END IF;

    IF p_year IS NULL OR p_month IS NULL OR p_day IS NULL OR 
       p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR 
       p_fractions IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN sys.datetime2fromparts(p_year::INT, p_month::INT, p_day::INT,
                                                p_hour::INT, p_minute::INT, p_seconds::INT,
                                                p_fractions::INT, p_precision::INT);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

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

-- Deprecate and drop old aggregates first (they depend on the function)

-- Deprecate and drop old aggregate (6 args) - tsql_select_for_xml_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_agg(anyelement, integer, text, boolean, text)
    RENAME TO tsql_select_for_xml_agg_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_agg_deprecated_in_5_6_0', 'anyelement, integer, text, boolean, text');
-- Deprecate and drop old aggregate (6 args) - tsql_select_for_xml_text_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_text_agg(anyelement, integer, text, boolean, text)
    RENAME TO tsql_select_for_xml_text_agg_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_text_agg_deprecated_in_5_6_0', 'anyelement, integer, text, boolean, text');
-- Deprecate and drop old function (6 args) - after aggregates are gone
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.tsql_query_to_xml_sfunc(internal, anyelement, integer, text, boolean, text)
    RENAME TO tsql_query_to_xml_sfunc_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_sfunc_deprecated_in_5_6_0');

-- Create new function with ELEMENTS parameters (8 args)
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

-- Create new aggregate with ELEMENTS parameters (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

-- Create new aggregate with ELEMENTS parameters (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

 DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.fn_varbintohexsubstring(set_prefix INT, expression sys.varbinary(128), start_offset INT, length_to_return INT) RENAME TO fn_varbintohexsubstring_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_varbintohexsubstring_deprecated_in_5_6_0');

-- Add sys.textsize() function for @@textsize support
CREATE OR REPLACE FUNCTION sys.textsize()
RETURNS integer
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value integer;
begin
    return_value := current_setting('babelfishpg_tsql.textsize');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.textsize() TO PUBLIC;

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

-- Returns pg_attribute rows for ENR temp tables.
CREATE OR REPLACE FUNCTION sys.babelfish_get_enr_temp_table_attributes()
RETURNS SETOF pg_catalog.pg_attribute
AS 'babelfishpg_tsql', 'get_enr_temp_table_attributes'
LANGUAGE C STABLE PARALLEL UNSAFE;
GRANT EXECUTE ON FUNCTION sys.babelfish_get_enr_temp_table_attributes() TO PUBLIC;

-- Permanent tables come from sys.all_columns, temp tables from ENR function and non-ENR pg_attribute.
CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        c.object_id                      AS object_id,
        CAST(p.relnamespace AS int)      AS schema_id,
        c.column_id                      AS colid,
        CAST(c.name AS sys.varchar)      AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c
        INNER JOIN pg_catalog.pg_class p ON (c.object_id = p.oid)
    WHERE
        c.is_sparse = 0
    UNION ALL
    -- ENR temp tables
    SELECT
        CAST(a.attrelid AS int)          AS object_id,
        CAST(pg_my_temp_schema() AS int) AS schema_id,
        CAST(a.attnum AS int)            AS colid,
        CAST(a.attname AS sys.varchar)   AS name,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(coll.collname AS nvarchar(128)) AS collation_28,
        CAST(coll.collname AS nvarchar(128)) AS collation_90,
        CAST(coll.collname AS nvarchar(128)) AS collation_100
    FROM
        sys.babelfish_get_enr_temp_table_attributes() a
        LEFT JOIN pg_catalog.pg_collation coll ON (a.attcollation = coll.oid)
    WHERE
        a.attnum > 0 AND NOT a.attisdropped
    UNION ALL
    -- Non-ENR temp tables
    SELECT
        CAST(a.attrelid AS int)          AS object_id,
        CAST(pg_my_temp_schema() AS int) AS schema_id,
        CAST(a.attnum AS int)            AS colid,
        CAST(a.attname AS sys.varchar)   AS name,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(coll.collname,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(coll.collname AS nvarchar(128)) AS collation_28,
        CAST(coll.collname AS nvarchar(128)) AS collation_90,
        CAST(coll.collname AS nvarchar(128)) AS collation_100
    FROM
        pg_catalog.pg_attribute a
        INNER JOIN pg_catalog.pg_class c ON a.attrelid = c.oid AND c.relnamespace = pg_my_temp_schema()
        LEFT JOIN pg_catalog.pg_collation coll ON (a.attcollation = coll.oid)
    WHERE
        a.attnum > 0 AND NOT a.attisdropped;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
