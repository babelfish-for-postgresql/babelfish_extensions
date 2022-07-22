-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- SERVER_PRINCIPALS
CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
  CAST(Base.rolname AS sys.SYSNAME) AS name,
  CAST(Base.oid As INT) AS principal_id,
  CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
  CAST(Ext.type AS CHAR(1)) as type,
  CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
  WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
  ELSE NULL END AS NVARCHAR(60)) AS type_desc,
  CAST(Ext.is_disabled AS INT) AS is_disabled,
  CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
  CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
  CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
  CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
  CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
  CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
  CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_view(schema_name varchar, view_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop view %s.%s', schema_name, view_name);
    query2 := format('drop view %s.%s', schema_name, view_name);
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

-- Drops a function if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_function(schema_name varchar, func_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop function %s.%s', schema_name, func_name);
    query2 := format('drop function %s.%s', schema_name, func_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop function' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- Drops a table if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_table(schema_name varchar, func_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop table %s.%s', schema_name, func_name);
    query2 := format('drop table %s.%s', schema_name, func_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop function' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- Removes a member object from the extension. The object is not dropped, only disassociated from the extension.
-- It is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
CREATE OR REPLACE PROCEDURE babelfish_remove_object_from_extension(obj_type varchar, qualified_obj_name varchar) AS
$$
DECLARE
    error_msg text;
    query text;
BEGIN
    query := format('alter extension babelfishpg_tsql drop %s %s', obj_type, qualified_obj_name);
    execute query;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
END
$$
LANGUAGE plpgsql;

-- please add your SQL here
CREATE OR REPLACE FUNCTION sys.tsql_get_constraintdef(IN constraint_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_constraintdef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

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
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
		  AND  extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;

ALTER VIEW sys.foreign_keys RENAME TO foreign_keys_deprecated;

CREATE OR REPLACE VIEW information_schema_tsql.COLUMN_DOMAIN_USAGE AS
    SELECT isc_col."DOMAIN_CATALOG",
           isc_col."DOMAIN_SCHEMA" ,
           CAST(isc_col."DOMAIN_NAME" AS sys.sysname),
           isc_col."TABLE_CATALOG",
           isc_col."TABLE_SCHEMA",
           CAST(isc_col."TABLE_NAME" AS sys.sysname),
           CAST(isc_col."COLUMN_NAME" AS sys.sysname)

    FROM information_schema_tsql.columns AS isc_col
    WHERE isc_col."DOMAIN_NAME" IS NOT NULL;

GRANT SELECT ON information_schema_tsql.COLUMN_DOMAIN_USAGE TO PUBLIC;

CREATE OR replace view sys.foreign_keys AS
SELECT
  CAST(c.conname AS sys.SYSNAME) AS name
, CAST(c.oid AS INT) AS object_id
, CAST(NULL AS INT) AS principal_id
, CAST(sch.schema_id AS INT) AS schema_id
, CAST(c.conrelid AS INT) AS parent_object_id
, CAST('F' AS CHAR(2)) AS type
, CAST('FOREIGN_KEY_CONSTRAINT' AS NVARCHAR(60)) AS type_desc
, CAST(NULL AS sys.DATETIME) AS create_date
, CAST(NULL AS sys.DATETIME) AS modify_date
, CAST(0 AS sys.BIT) AS is_ms_shipped
, CAST(0 AS sys.BIT) AS is_published
, CAST(0 AS sys.BIT) as is_schema_published
, CAST(c.confrelid AS INT) AS referenced_object_id
, CAST(c.conindid AS INT) AS key_index_id
, CAST(0 AS sys.BIT) AS is_disabled
, CAST(0 AS sys.BIT) AS is_not_for_replication
, CAST(0 AS sys.BIT) AS is_not_trusted
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END) 
    AS sys.TINYINT) AS delete_referential_action
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END) 
    AS sys.NVARCHAR(60)) AS delete_referential_action_desc
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS update_referential_action
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) update_referential_action_desc
, CAST(1 AS sys.BIT) AS is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(p.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(NULL as sys.datetime) AS create_date,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(
      CASE WHEN tr.tgenabled = 'D'
      THEN 1
      ELSE 0
      END
      AS sys.bit
  )	AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;

ALTER VIEW sys.key_constraints RENAME TO key_constraints_deprecated;

CREATE OR replace view sys.key_constraints AS
SELECT
    CAST(c.conname AS SYSNAME) AS name
  , CAST(c.oid AS INT) AS object_id
  , CAST(0 AS INT) AS principal_id
  , CAST(sch.schema_id AS INT) AS schema_id
  , CAST(c.conrelid AS INT) AS parent_object_id
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PK'
      WHEN 'u' THEN 'UQ'
    END) 
    AS CHAR(2)) AS type
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PRIMARY_KEY_CONSTRAINT'
      WHEN 'u' THEN 'UNIQUE_CONSTRAINT'
    END)
    AS NVARCHAR(60)) AS type_desc
  , CAST(NULL AS DATETIME) AS create_date
  , CAST(NULL AS DATETIME) AS modify_date
  , CAST(c.conindid AS INT) AS unique_index_id
  , CAST(0 AS sys.BIT) AS is_ms_shipped
  , CAST(0 AS sys.BIT) AS is_published
  , CAST(0 AS sys.BIT) AS is_schema_published
  , CAST(1 as sys.BIT) as is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype IN ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;

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
    , CAST('PK' as char(2)) as type
    , CAST('PRIMARY_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
where p.type = 'PK'
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
    , CAST(p.pronamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_proc p on p.oid = tr.object_id
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
    CAST(p.relname as sys.sysname) as name
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
and has_schema_privilege(s.schema_id, 'USAGE')
union all
select
    CAST(('TT_' || tt.name || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt;
GRANT SELECT ON sys.objects TO PUBLIC;

CALL sys.babelfish_drop_deprecated_view('sys', 'key_constraints_deprecated');
CALL sys.babelfish_drop_deprecated_view('sys', 'foreign_keys_deprecated');

ALTER FUNCTION OBJECTPROPERTY(INT, SYS.VARCHAR) RENAME TO objectproperty_deprecated_2_1_0;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT
AS $$
BEGIN

    IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
    THEN
        RETURN NULL;
    END IF;

    property := RTRIM(LOWER(COALESCE(property, '')));

    IF property = 'ownerid' -- OwnerId
    THEN
        RETURN (
                SELECT CAST(COALESCE(t1.principal_id, pn.nspowner) AS INT)
                FROM sys.all_objects t1
                INNER JOIN pg_catalog.pg_namespace pn ON pn.oid = t1.schema_id
                WHERE t1.object_id = id);

    ELSEIF property = 'isdefaultcnst' -- IsDefaultCnst
    THEN
        RETURN (SELECT count(distinct dc.object_id) FROM sys.default_constraints dc WHERE dc.object_id = id);

    ELSEIF property = 'execisquotedidenton' -- ExecIsQuotedIdentOn
    THEN
        RETURN (SELECT CAST(sm.uses_quoted_identifier as int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'tablefulltextpopulatestatus' -- TableFullTextPopulateStatus
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'tablehasvardecimalstorageformat' -- TableHasVarDecimalStorageFormat
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'ismsshipped' -- IsMSShipped
    THEN
        RETURN (SELECT CAST(ao.is_ms_shipped AS int) FROM sys.all_objects ao WHERE ao.object_id = id);

    ELSEIF property = 'isschemabound' -- IsSchemaBound
    THEN
        RETURN (SELECT CAST(sm.is_schema_bound AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'execisansinullson' -- ExecIsAnsiNullsOn
    THEN
        RETURN (SELECT CAST(sm.uses_ansi_nulls AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'isdeterministic' -- IsDeterministic
    THEN
        RETURN 0;
    
    ELSEIF property = 'isprocedure' -- IsProcedure
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'P');

    ELSEIF property = 'istable' -- IsTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IT', 'TT', 'U', 'S'));

    ELSEIF property = 'isview' -- IsView
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'V');
    
    ELSEIF property = 'isusertable' -- IsUserTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'U' and is_ms_shipped = 0);
    
    ELSEIF property = 'istablefunction' -- IsTableFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF', 'TF', 'FT'));
    
    ELSEIF property = 'isinlinefunction' -- IsInlineFunction
    THEN
        RETURN 0;
    
    ELSEIF property = 'isscalarfunction' -- IsScalarFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('FN', 'FS'));

    ELSEIF property = 'isprimarykey' -- IsPrimaryKey
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'PK');
    
    ELSEIF property = 'isindexed' -- IsIndexed
    THEN
        RETURN (SELECT count(distinct object_id) from sys.indexes WHERE object_id = id and index_id > 0);

    ELSEIF property = 'isdefault' -- IsDefault
    THEN
        RETURN 0;

    ELSEIF property = 'isrule' -- IsRule
    THEN
        RETURN 0;
    
    ELSEIF property = 'istrigger' -- IsTrigger
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('TA', 'TR'));
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CALL sys.babelfish_drop_deprecated_function('sys', 'objectproperty_deprecated_2_1_0');

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

ALTER TABLE sys.assembly_types RENAME TO assembly_types_deprecated_2_1_0;

CREATE OR REPLACE VIEW sys.assembly_types
AS
SELECT
   CAST(t.name as sys.sysname) AS name,
   -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
   -- This is because the IDs of generated SQL Server system type values generated by B
   -- Babelfish installation will exceed the size of TINYINT.
   CAST(t.system_type_id as int) AS system_type_id,
   CAST(t.user_type_id as int) AS user_type_id,
   CAST(t.schema_id as int) AS schema_id,
   CAST(t.principal_id as int) AS principal_id,
   CAST(t.max_length as smallint) AS max_length,
   CAST(t.precision as sys.tinyint) AS precision,
   CAST(t.scale as sys.tinyint) AS scale,
   CAST(t.collation_name as sys.sysname) AS collation_name,
   CAST(t.is_nullable as sys.bit) AS is_nullable,
   CAST(t.is_user_defined as sys.bit) AS is_user_defined,
   CAST(t.is_assembly_type as sys.bit) AS is_assembly_type,
   CAST(t.default_object_id as int) AS default_object_id,
   CAST(t.rule_object_id as int) AS rule_object_id,
   CAST(NULL as int) AS assembly_id,
   CAST(NULL as sys.sysname) AS assembly_class,
   CAST(NULL as sys.bit) AS is_binary_ordered,
   CAST(NULL as sys.bit) AS is_fixed_length,
   CAST(NULL as sys.nvarchar(40)) AS prog_id,
   CAST(NULL as sys.nvarchar(4000)) AS assembly_qualified_name,
   CAST(t.is_table_type as sys.bit) AS is_table_type
FROM sys.types t
WHERE t.is_assembly_type = 1;
GRANT SELECT ON sys.assembly_types TO PUBLIC;

CALL sys.babelfish_drop_deprecated_table('sys', 'assembly_types_deprecated_2_1_0');

CREATE OR REPLACE VIEW sys.hash_indexes
AS
SELECT 
  si.object_id,
  si.name,
  si.index_id,
  si.type,
  si.type_desc,
  si.is_unique,
  si.data_space_id,
  si.ignore_dup_key,
  si.is_primary_key,
  si.is_unique_constraint,
  si.fill_factor,
  si.is_padded,
  si.is_disabled,
  si.is_hypothetical,
  si.allow_row_locks,
  si.allow_page_locks,
  si.has_filter,
  si.filter_definition,
  CAST(0 as INT) AS bucket_count,
  si.auto_created
FROM sys.indexes si
WHERE FALSE;
GRANT SELECT ON sys.hash_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT)  AS index_id
  , CAST(idx.type AS sys.tinyint) AS type
  , CAST(idx.type_desc AS sys.nvarchar(60)) AS type_desc
  , CAST(idx.is_unique AS sys.bit) AS is_unique
  , CAST(idx.data_space_id AS int) AS data_space_id
  , CAST(idx.ignore_dup_key AS sys.bit) AS ignore_dup_key
  , CAST(idx.is_primary_key AS sys.bit) AS is_primary_key
  , CAST(idx.is_unique_constraint AS sys.bit) AS is_unique_constraint
  , CAST(idx.fill_factor AS sys.tinyint) AS fill_factor
  , CAST(idx.is_padded AS sys.bit) AS is_padded
  , CAST(idx.is_disabled AS sys.bit) AS is_disabled
  , CAST(idx.is_hypothetical AS sys.bit) AS is_hypothetical
  , CAST(idx.allow_row_locks AS sys.bit) AS allow_row_locks
  , CAST(idx.allow_page_locks AS sys.bit) AS allow_page_locks
  , CAST(idx.has_filter AS sys.bit) AS has_filter
  , CAST(idx.filter_definition AS sys.nvarchar(4000)) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS char(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM  sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_cluster
AS
SELECT
   CAST('' as sys.nvarchar(128)) as cluster_name
  ,CAST(0 as sys.tinyint) as quorum_type
  ,CAST('NODE_MAJORITY' as sys.nvarchar(50)) as quorum_type_desc
  ,CAST(0 as sys.tinyint) as quorum_state
  ,CAST('NORMAL_QUORUM' as sys.nvarchar(50)) as quorum_state_desc;
GRANT SELECT ON sys.dm_hadr_cluster TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetable_system_defined_objects
AS
SELECT 
  CAST(0 as INT) AS object_id,
  CAST(0 as INT) AS parent_object_id
  WHERE FALSE;
GRANT SELECT ON sys.filetable_system_defined_objects TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_filestream_options
AS
SELECT
  CAST(0 as INT) AS database_id,
  CAST('' as NVARCHAR(255)) AS directory_name,
  CAST(0 as TINYINT) AS non_transacted_access,
  CAST('' as NVARCHAR(60)) AS non_transacted_access_desc
WHERE FALSE;
GRANT SELECT ON sys.database_filestream_options TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sid_binary(IN login sys.nvarchar)
RETURNS SYS.VARBINARY
AS $$
    SELECT CAST(NULL AS SYS.VARBINARY);
$$ 
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.tsql_get_functiondef(IN function_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_functiondef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_returnTypmodValue(IN function_id OID DEFAULT NULL)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_get_returnTypmodValue'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647
                WHEN type = 'ntext'
                THEN 1073741823
                WHEN type = 'sysname'
                THEN 128
                WHEN type = 'xml'
                THEN -1
                WHEN type = 'sql_variant'
                THEN 0
                ELSE null
        END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1 /* default typmod */
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('nchar', 'nvarchar')
                THEN CASE WHEN typmod = -1 /* default typmod */
                        THEN 2
                        ELSE (typmod - 4) * 2
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647 /* 2^30 + 1 */
                WHEN type = 'ntext'
                THEN 2147483646 /* 2^30 */
                WHEN type = 'sysname'
                THEN 256
                WHEN type = 'sql_variant'
                THEN 0
                WHEN type = 'xml'
                THEN -1
           ELSE null
  END$$;	

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
           CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN 'NULL' ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
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
	    CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE 'NULL' END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
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
            CAST(sys.tsql_get_functiondef(p.oid) AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
	    CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(0 AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace,
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
	    tsql_get_returnTypmodValue(p.oid) AS true_typmod,
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
            AND ext.dbid = cast(sys.db_id() as oid)
            AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid;      

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;
	
CREATE OR REPLACE FUNCTION sys.system_user()
RETURNS sys.nvarchar(128) AS
$BODY$
	SELECT SESSION_USER;
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE VIEW msdb_dbo.syspolicy_system_health_state
AS
SELECT 
    CAST(0 as BIGINT) AS health_state_id,
    CAST(0 as INT) AS policy_id,
    CAST(NULL AS sys.DATETIME) AS last_run_date,
    CAST('' AS sys.NVARCHAR(400)) AS target_query_expression_with_id,
    CAST('' AS sys.NVARCHAR) AS target_query_expression,
    CAST(1 as sys.BIT) AS result
WHERE FALSE;
GRANT SELECT ON msdb_dbo.syspolicy_system_health_state TO PUBLIC;
ALTER VIEW msdb_dbo.syspolicy_system_health_state OWNER TO sysadmin;

CREATE OR REPLACE FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled()
RETURNS INTEGER
AS 
$fn_body$    
    SELECT 0;
$fn_body$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
ALTER FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled() OWNER TO sysadmin;

CREATE OR REPLACE VIEW msdb_dbo.syspolicy_configuration
AS
SELECT
    CAST(NULL AS sys.SYSNAME) AS name,
    CAST(NULL AS sys.sql_variant) AS current_value
WHERE FALSE; -- Condition will result in view with an empty result set
GRANT SELECT ON msdb_dbo.syspolicy_configuration TO PUBLIC;
ALTER VIEW msdb_dbo.syspolicy_configuration OWNER TO sysadmin;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values 
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on t.schema_name = ns.nspname

union all 

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid  as schemaid from
(
  values 
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name=b.orig_name
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

-- Disassociate msdb objects from the extension
CALL sys.babelfish_remove_object_from_extension('view', 'msdb_dbo.sysdatabases');
CALL sys.babelfish_remove_object_from_extension('schema', 'msdb_dbo');
CALL sys.babelfish_remove_object_from_extension('view', 'msdb_dbo.syspolicy_system_health_state');
CALL sys.babelfish_remove_object_from_extension('view', 'msdb_dbo.syspolicy_configuration');
CALL sys.babelfish_remove_object_from_extension('function', 'msdb_dbo.fn_syspolicy_is_automation_enabled');
-- Disassociate procedures under master_dbo schema from the extension
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.xp_qv(sys.nvarchar, sys.nvarchar)');
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.xp_instance_regread(sys.nvarchar, sys.sysname, sys.nvarchar, int)');
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.xp_instance_regread(sys.nvarchar, sys.sysname, sys.nvarchar, sys.nvarchar)');

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision(type text, typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$
	SELECT
	CASE typid
		WHEN 21 /*int2*/ THEN 5
		WHEN 23 /*int4*/ THEN 10
		WHEN 20 /*int8*/ THEN 19
		WHEN 1700 /*numeric*/ THEN
			CASE WHEN typmod = -1 THEN null
				ELSE ((typmod - 4) >> 16) & 65535
			END
		WHEN 700 /*float4*/ THEN 24
		WHEN 701 /*float8*/ THEN 53
		ELSE
			CASE WHEN type = 'tinyint' THEN 3
				WHEN type = 'money' THEN 19
				WHEN type = 'smallmoney' THEN 10
				WHEN type = 'decimal'	THEN
					CASE WHEN typmod = -1 THEN null
						ELSE ((typmod - 4) >> 16) & 65535
					END
				ELSE null
			END
	END
$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_scale(type text, typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$
	SELECT
	CASE WHEN typid IN (21, 23, 20) THEN 0
		WHEN typid IN (1700) THEN
			CASE WHEN typmod = -1 THEN null
				ELSE (typmod - 4) & 65535
			END
		WHEN type = 'tinyint' THEN 0
		WHEN type IN ('money', 'smallmoney') THEN 4
		WHEN type = 'decimal' THEN
			CASE WHEN typmod = -1 THEN NULL
				ELSE (typmod - 4) & 65535
			END
		ELSE null
	END
$$;

ALTER VIEW sys.all_views RENAME TO all_views_deprecated_2_1_0;

create or replace view sys.all_views as
select
    CAST(t.name as sys.SYSNAME) AS name
  , CAST(t.object_id as int) AS object_id
  , CAST(t.principal_id as int) AS principal_id
  , CAST(t.schema_id as int) AS schema_id
  , CAST(t.parent_object_id as int) AS parent_object_id
  , CAST(t.type as sys.bpchar(2)) AS type
  , CAST(t.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(t.create_date as sys.datetime) AS create_date
  , CAST(t.modify_date as sys.datetime) AS modify_date
  , CAST(t.is_ms_shipped as sys.BIT) AS is_ms_shipped
  , CAST(t.is_published as sys.BIT) AS is_published
  , CAST(t.is_schema_published as sys.BIT) AS is_schema_published 
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
from sys.all_objects t
INNER JOIN pg_namespace ns ON t.schema_id = ns.oid
INNER JOIN information_schema.views v ON t.name = v.table_name AND ns.nspname = v.table_schema
where t.type = 'V';
GRANT SELECT ON sys.all_views TO PUBLIC;

CALL sys.babelfish_drop_deprecated_view('sys', 'all_views_deprecated_2_1_0');

CREATE OR REPLACE VIEW sys.assembly_modules
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS assembly_id,
   CAST('' AS SYSNAME) AS assembly_class,
   CAST('' AS SYSNAME) AS assembly_method,
   CAST(0 AS sys.BIT) AS null_on_null_input,
   CAST(0 as INT) AS execute_as_principal_id
   WHERE FALSE;
GRANT SELECT ON sys.assembly_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.change_tracking_databases
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(0 as sys.BIT) AS is_auto_cleanup_on,
   CAST(0 as INT) AS retention_period,
   CAST('' as NVARCHAR(60)) AS retention_period_units_desc,
   CAST(0 as TINYINT) AS retention_period_units
WHERE FALSE;
GRANT SELECT ON sys.change_tracking_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_recovery_status
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(NULL as UNIQUEIDENTIFIER) AS database_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS family_guid,
   CAST(0 as NUMERIC(25,0)) AS last_log_backup_lsn,
   CAST(NULL as UNIQUEIDENTIFIER) AS recovery_fork_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS first_recovery_fork_guid,
   CAST(0 as NUMERIC(25,0)) AS fork_point_lsn
WHERE FALSE;
GRANT SELECT ON sys.database_recovery_status TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_languages
AS
SELECT 
   CAST(0 as INT) AS lcid,
   CAST('' as SYSNAME) AS name
WHERE FALSE;
GRANT SELECT ON sys.fulltext_languages TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_index_columns
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS column_id,
   CAST(0 as INT) AS type_column_id,
   CAST(0 as INT) AS language_id,
   CAST(0 as INT) AS statistical_semantics
WHERE FALSE;
GRANT SELECT ON sys.fulltext_index_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.selective_xml_index_paths
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS index_id,
   CAST(0 as INT) AS path_id,
   CAST('' as NVARCHAR(4000)) AS path,
   CAST('' as SYSNAME) AS name,
   CAST(0 as TINYINT) AS path_type,
   CAST(0 as SYSNAME) AS path_type_desc,
   CAST(0 as INT) AS xml_component_id,
   CAST('' as NVARCHAR(4000)) AS xquery_type_description,
   CAST(0 as sys.BIT) AS is_xquery_type_inferred,
   CAST(0 as SMALLINT) AS xquery_max_length,
   CAST(0 as sys.BIT) AS is_xquery_max_length_inferred,
   CAST(0 as sys.BIT) AS is_node,
   CAST(0 as TINYINT) AS system_type_id,
   CAST(0 as TINYINT) AS user_type_id,
   CAST(0 as SMALLINT) AS max_length,
   CAST(0 as TINYINT) AS precision,
   CAST(0 as TINYINT) AS scale,
   CAST('' as SYSNAME) AS collation_name,
   CAST(0 as sys.BIT) AS is_singleton
WHERE FALSE;
GRANT SELECT ON sys.selective_xml_index_paths TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_indexes
AS
SELECT 
   object_id,
   name,
   index_id,
   type,
   type_desc,
   is_unique,
   data_space_id,
   ignore_dup_key,
   is_primary_key,
   is_unique_constraint,
   fill_factor,
   is_padded,
   is_disabled,
   is_hypothetical,
   allow_row_locks,
   allow_page_locks,
   CAST(1 as TINYINT) AS spatial_index_type,
   CAST('' as NVARCHAR(60)) AS spatial_index_type_desc,
   CAST('' as SYSNAME) AS tessellation_scheme,
   has_filter,
   filter_definition,
   auto_created
FROM sys.indexes WHERE FALSE;
GRANT SELECT ON sys.spatial_indexes TO PUBLIC;

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
          AND NOT a.attisdropped

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

      ) AS x (tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat)

WHERE pg_has_role(x.tblowner, 'USAGE');

GRANT SELECT ON information_schema_tsql.CONSTRAINT_COLUMN_USAGE TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetables
AS
SELECT 
   CAST(0 AS INT) AS object_id,
   CAST(0 AS sys.BIT) AS is_enabled,
   CAST('' AS VARCHAR(255)) AS directory_name,
   CAST(0 AS INT) AS filename_collation_id,
   CAST('' AS VARCHAR) AS filename_collation_name
   WHERE FALSE;
GRANT SELECT ON sys.filetables TO PUBLIC;

CREATE OR REPLACE VIEW sys.registered_search_property_lists
AS
SELECT 
   CAST(0 AS INT) AS property_list_id,
   CAST('' AS SYSNAME) AS name,
   CAST(NULL AS DATETIME) AS create_date,
   CAST(NULL AS DATETIME) AS modify_date,
   CAST(0 AS INT) AS principal_id
WHERE FALSE;
GRANT SELECT ON sys.registered_search_property_lists TO PUBLIC;

ALTER VIEW sys.identity_columns RENAME TO identity_columns_deprecated;

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
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

CALL sys.babelfish_drop_deprecated_view('sys', 'identity_columns_deprecated');

CREATE OR REPLACE VIEW sys.filegroups
AS
SELECT 
   ds.name,
   ds.data_space_id,
   ds.type,
   ds.type_desc,
   ds.is_default,
   ds.is_system,
   CAST(NULL as UNIQUEIDENTIFIER) AS filegroup_guid,
   CAST(0 as INT) AS log_filegroup_id,
   CAST(0 as sys.BIT) AS is_read_only,
   CAST(0 as sys.BIT) AS is_autogrow_all_files
FROM sys.data_spaces ds WHERE type = 'FG';
GRANT SELECT ON sys.filegroups TO PUBLIC;

CREATE OR REPLACE VIEW sys.master_files
AS
SELECT
    CAST(0 as INT) AS database_id,
    CAST(0 as INT) AS file_id,
    CAST(NULL as UNIQUEIDENTIFIER) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as SYSNAME) AS name,
    CAST('' as NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS differential_base_guid,
    CAST(NULL as DATETIME) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn,
    CAST(0 as INT) AS credential_id
WHERE FALSE;
GRANT SELECT ON sys.master_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.stats
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST('' as SYSNAME) AS name,
   CAST(0 as INT) AS stats_id,
   CAST(0 as sys.BIT) AS auto_created,
   CAST(0 as sys.BIT) AS user_created,
   CAST(0 as sys.BIT) AS no_recompute,
   CAST(0 as sys.BIT) AS has_filter,
   CAST('' as sys.NVARCHAR(4000)) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;
GRANT SELECT ON sys.stats TO PUBLIC;

CREATE OR REPLACE VIEW sys.change_tracking_tables
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as sys.BIT) AS is_track_columns_updated_on,
   CAST(0 AS sys.BIGINT) AS begin_version,
   CAST(0 AS sys.BIGINT) AS cleanup_version,
   CAST(0 AS sys.BIGINT) AS min_valid_version
   WHERE FALSE;
GRANT SELECT ON sys.change_tracking_tables TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_catalogs
AS
SELECT 
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST('' as SYSNAME) AS name,
   CAST('' as NVARCHAR(260)) AS path,
   CAST(0 as sys.BIT) AS is_default,
   CAST(0 as sys.BIT) AS is_accent_sensitivity_on,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS file_id,
   CAST(0 as INT) AS principal_id,
   CAST(2 as sys.BIT) AS is_importing
WHERE FALSE;
GRANT SELECT ON sys.fulltext_catalogs TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_stoplists
AS
SELECT 
   CAST(0 as INT) AS stoplist_id,
   CAST('' as SYSNAME) AS name,
   CAST(NULL as DATETIME) AS create_date,
   CAST(NULL as DATETIME) AS modify_date,
   CAST(0 as INT) AS Principal_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_stoplists TO PUBLIC;

alter view sys.databases rename to databases_deprecated_2_1_0;

create or replace view sys.databases as
select
  CAST(d.name as SYS.SYSNAME) as name
  , CAST(sys.db_id(d.name) as INT) as database_id
  , CAST(NULL as INT) as source_database_id
  , cast(cast(r.oid as INT) as SYS.VARBINARY(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(120 AS SYS.TINYINT) as compatibility_level
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
 from sys.babelfish_sysdatabases d LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname
 LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = d.owner;

GRANT SELECT ON sys.databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT 
CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()
WHERE has_schema_privilege(s1.schema_id, 'USAGE')

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM    pg_catalog.pg_namespace n 
JOIN    pg_catalog.pg_proc p 
ON      pronamespace = n.oid   
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

GRANT SELECT ON sys.sp_stored_procedures_view TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view AS
-- Get parameters (if any) for a user-defined stored procedure/function
(SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 AS smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') AS sys.sysname) AS TYPE_NAME,
	CAST(t6.precision AS int) AS PRECISION,
	CAST(t6.max_length AS int) AS LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable AS smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		ON proc.specific_schema = args.specific_schema AND proc.specific_name = args.specific_name
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id =ext.dbid
	INNER JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
			ON t7.name = t5.type_name
		ON (args.data_type != 'USER-DEFINED' AND args.udt_name = t5.pg_type_name AND t6.name = t7.name)
		OR (args.data_type='USER-DEFINED' AND args.udt_name = t6.name)
	WHERE coalesce(args.parameter_name, '') LIKE '@%'
		AND ext.dbid = sys.db_id()
		AND has_schema_privilege(proc.specific_schema, 'USAGE')

UNION ALL

-- Create row describing return type for a user-defined stored procedure/function
SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 as smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type like '%TABLE%' then CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

	FROM information_schema.routines proc
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id = ext.dbid
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
		ON t7.name = t5.type_name
	ON (proc.data_type != 'USER-DEFINED' 
			AND proc.type_udt_name = t5.pg_type_name 
			AND t6.name = t7.name)
		OR (proc.data_type = 'USER-DEFINED' 
			AND proc.type_udt_name = t6.name),
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE ext.dbid = sys.db_id() AND has_schema_privilege(proc.specific_schema, 'USAGE'))

UNION ALL 

-- Get parameters (if any) for a system stored procedure/function
(SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(args.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 as smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') as sys.sysname) as TYPE_NAME,
	CAST(t6.precision as int) as PRECISION,
	CAST(t6.max_length as int) as LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable as smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		on proc.specific_schema = args.specific_schema
		and proc.specific_name = args.specific_name 
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
		ON args.udt_name = t5.pg_type_name OR args.udt_name = t5.type_name
	WHERE args.specific_schema ='sys' 
		AND coalesce(args.parameter_name, '') LIKE '@%' 
		AND (args.specific_name LIKE 'sp\_%' 
			OR args.specific_name LIKE 'xp\_%'
			OR args.specific_name LIKE 'dm\_%'
			OR  args.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
		
UNION ALL

-- Create row describing return type for a system stored procedure/function
SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(proc.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 AS smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
	ON proc.type_udt_name = t5.pg_type_name OR proc.type_udt_name = t5.type_name, 
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE proc.specific_schema = 'sys' 
		AND (proc.specific_name LIKE 'sp\_%' 
			OR proc.specific_name LIKE 'xp\_%' 
			OR proc.specific_name LIKE 'dm\_%'
			OR  proc.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
	);	
GRANT SELECT ON sys.sp_sproc_columns_view TO PUBLIC;

alter view sys.database_mirroring rename to database_mirroring_deprecated_2_1_0;

CREATE OR REPLACE VIEW sys.database_mirroring
AS
SELECT 
      CAST(database_id AS int) AS database_id,
      CAST(NULL AS sys.uniqueidentifier) AS mirroring_guid,
      CAST(NULL AS sys.tinyint) AS mirroring_state,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_state_desc,
      CAST(NULL AS sys.tinyint) AS mirroring_role,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_role_desc,
      CAST(NULL AS int) AS mirroring_role_sequence,
      CAST(NULL AS sys.tinyint) as mirroring_safety_level,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_safety_level_desc,
      CAST(NULL AS int) as mirroring_safety_sequence,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_name,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_instance,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_witness_name,
      CAST(NULL AS sys.tinyint) AS mirroring_witness_state,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_witness_state_desc,
      CAST(NULL AS numeric(25,0)) AS mirroring_failover_lsn,
      CAST(NULL AS int) AS mirroring_connection_timeout,
      CAST(NULL AS int) AS mirroring_redo_queue,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_redo_queue_type,
      CAST(NULL AS numeric(25,0)) AS mirroring_end_of_log_lsn,
      CAST(NULL AS numeric(25,0)) AS mirroring_replication_lsn
FROM sys.databases;
GRANT SELECT ON sys.database_mirroring TO PUBLIC;

call babelfish_drop_deprecated_view('sys', 'databases_deprecated_2_1_0');
call babelfish_drop_deprecated_view('sys', 'database_mirroring_deprecated_2_1_0');

CREATE OR REPLACE VIEW sys.fulltext_indexes
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS unique_index_id,
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST(0 as sys.BIT) AS is_enabled,
   CAST('O' as CHAR(1)) AS change_tracking_state,
   CAST('' as NVARCHAR(60)) AS change_tracking_state_desc,
   CAST(0 as sys.BIT) AS has_crawl_completed,
   CAST('' as CHAR(1)) AS crawl_type,
   CAST('' as NVARCHAR(60)) AS crawl_type_desc,
   CAST(NULL as DATETIME) AS crawl_start_date,
   CAST(NULL as DATETIME) AS crawl_end_date,
   CAST(NULL as BINARY(8)) AS incremental_timestamp,
   CAST(0 as INT) AS stoplist_id,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS property_list_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.synonyms
AS
SELECT 
    CAST(obj.name as sys.sysname) AS name
    , CAST(obj.object_id as int) AS object_id
    , CAST(obj.principal_id as int) AS principal_id
    , CAST(obj.schema_id as int) AS schema_id
    , CAST(obj.parent_object_id as int) AS parent_object_id
    , CAST(obj.type as sys.bpchar(2)) AS type
    , CAST(obj.type_desc as sys.nvarchar(60)) AS type_desc
    , CAST(obj.create_date as sys.datetime) as create_date
    , CAST(obj.modify_date as sys.datetime) as modify_date
    , CAST(obj.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(obj.is_published as sys.bit) as is_published
    , CAST(obj.is_schema_published as sys.bit) as is_schema_published
    , CAST('' as sys.nvarchar(1035)) AS base_object_name
FROM sys.objects obj
WHERE type='SN';
GRANT SELECT ON sys.synonyms TO PUBLIC;

CREATE OR REPLACE VIEW sys.plan_guides
AS
SELECT 
    CAST(0 as int) AS plan_guide_id
    , CAST(NULL as sys.sysname) AS name
    , CAST(NULL as sys.datetime) as create_date
    , CAST(NULL as sys.datetime) as modify_date
    , CAST(0 as sys.bit) as is_disabled
    , CAST('' as sys.nvarchar(4000)) AS query_text
    , CAST(0 as sys.tinyint) AS scope_type
    , CAST('' as sys.nvarchar(60)) AS scope_type_desc
    , CAST(0 as int) AS scope_type_id
    , CAST('' as sys.nvarchar(4000)) AS scope_batch
    , CAST('' as sys.nvarchar(4000)) AS parameters
    , CAST('' as sys.nvarchar(4000)) AS hints
WHERE FALSE;
GRANT SELECT ON sys.plan_guides TO PUBLIC;

ALTER FUNCTION OBJECTPROPERTYEX(INT, SYS.VARCHAR) RENAME TO objectpropertyex_deprecated_2_1_0;

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(
    id INT,
    property SYS.VARCHAR
)
RETURNS SYS.SQL_VARIANT
AS $$
BEGIN
	property := RTRIM(LOWER(COALESCE(property, '')));
	
	IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
	THEN
		RETURN NULL;
	END IF;

	IF property = 'basetype' -- BaseType
	THEN
		RETURN (SELECT CAST(ao.type AS SYS.SQL_VARIANT) 
                FROM sys.all_objects ao
                WHERE ao.object_id = id
                LIMIT 1
                );
    END IF;

    RETURN CAST(OBJECTPROPERTY(id, property) AS SYS.SQL_VARIANT);
END
$$
LANGUAGE plpgsql;

CALL sys.babelfish_drop_deprecated_function('sys', 'objectpropertyex_deprecated_2_1_0');

ALTER FUNCTION sys.suser_name RENAME TO suser_name_deprecated_2_1_0;
ALTER FUNCTION sys.suser_sname RENAME TO suser_sname_deprecated_2_1_0;
ALTER FUNCTION sys.suser_id RENAME TO suser_id_deprecated_2_1_0;
ALTER FUNCTION sys.suser_sid RENAME TO suser_sid_deprecated_2_1_0;

CREATE OR REPLACE FUNCTION sys.suser_name_internal(IN server_user_id OID)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID)
RETURNS sys.NVARCHAR(128) AS $$
    SELECT CASE 
        WHEN server_user_id IS NULL THEN NULL
        ELSE sys.suser_name_internal(server_user_id)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but 
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85))
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sname()
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name();
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id_internal(IN login TEXT)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT)
RETURNS OID AS $$
    SELECT CASE
        WHEN login IS NULL THEN NULL
        ELSE sys.suser_id_internal(login)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id()
RETURNS OID
AS $$
    SELECT sys.suser_id_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but 
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = '' 
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE 
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sid()
RETURNS SYS.VARBINARY(85)
AS $$
    SELECT CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CALL sys.babelfish_drop_deprecated_function('sys', 'suser_name_deprecated_2_1_0');
CALL sys.babelfish_drop_deprecated_function('sys', 'suser_sname_deprecated_2_1_0');
CALL sys.babelfish_drop_deprecated_function('sys', 'suser_id_deprecated_2_1_0');
CALL sys.babelfish_drop_deprecated_function('sys', 'suser_sid_deprecated_2_1_0');
	  
INSERT INTO sys.babelfish_configurations
VALUES
  (
    1534,
    'user options',
    0,
    0,
    32767,
    0,
    'user options',
    sys.bitin('1'),
    sys.bitin('0'),
    'user options',
    'user options'
  ),
  (
    115,
    'nested triggers',
    1,
    0,
    1,
    1,
    'Allow triggers to be invoked within triggers',
    sys.bitin('1'),
    sys.bitin('0'),
    'Allow triggers to be invoked within triggers',
    'Allow triggers to be invoked within triggers'
  ),
  (
    124,
    'default language',
    0,
    0,
    9999,
    0,
    'default language',
    sys.bitin('1'),
    sys.bitin('0'),
    'default language',
    'default language'
  ),
  (
    1126,               
    'default full-text language',
    1033,
    0,
    2147483647,
    1033,
    'default full-text language',
    sys.bitin('1'),
    sys.bitin('1'),
    'default full-text language',
    'default full-text language'
  ),
  (
    1127,
    'two digit year cutoff',
    2049,
    1753,
    9999,
    2049,
    'two digit year cutoff',
    sys.bitin('1'),
    sys.bitin('1'),
    'two digit year cutoff',
    'two digit year cutoff'
  ),
  (
    1555,
    'transform noise words',
    0,
    0,
    1,
    0,
    'Transform noise words for full-text query',
    sys.bitin('1'),
    sys.bitin('1'),
    'Transform noise words for full-text query',
    'Transform noise words for full-text query'
  );

CREATE OR REPLACE VIEW sys.spatial_index_tessellations 
AS
SELECT 
    CAST(0 as int) AS object_id
    , CAST(0 as int) AS index_id
    , CAST('' as sys.sysname) AS tessellation_scheme
    , CAST(0 as float(53)) AS bounding_box_xmin
    , CAST(0 as float(53)) AS bounding_box_ymin
    , CAST(0 as float(53)) AS bounding_box_xmax
    , CAST(0 as float(53)) AS bounding_box_ymax
    , CAST(0 as smallint) as level_1_grid
    , CAST('' as sys.nvarchar(60)) AS level_1_grid_desc
    , CAST(0 as smallint) as level_2_grid
    , CAST('' as sys.nvarchar(60)) AS level_2_grid_desc
    , CAST(0 as smallint) as level_3_grid
    , CAST('' as sys.nvarchar(60)) AS level_3_grid_desc
    , CAST(0 as smallint) as level_4_grid
    , CAST('' as sys.nvarchar(60)) AS level_4_grid_desc
    , CAST(0 as int) as cells_per_object
WHERE FALSE;
GRANT SELECT ON sys.spatial_index_tessellations TO PUBLIC;
create or replace view sys.all_objects as
select 
    cast (name as sys.sysname) 
  , cast (object_id as integer) 
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , cast (type as char(2))
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , cast (case when (schema_id::regnamespace::text = 'sys') then 1
          when name in (select name from sys.shipped_objects_not_in_sys nis 
                        where nis.name = name and nis.schemaid = schema_id and nis.type = type) then 1 
          else 0 end as sys.bit) as is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- details of user defined and system tables
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U' as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F' as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'f'
union all
-- details of user defined and system primary key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK' as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'p'
union all
-- details of user defined and system defined procedures
select
    p.proname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null 
  		       then tr.tgrelid 
  		       else 0 end as int) 
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'::varchar(2)
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'::varchar(60)
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
union all
-- details of all default constraints
select
    ('DF_' || o.relname || '_' || d.oid)::name as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
where a.atthasdef = 't' and a.attgenerated = ''
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::name
  , c.oid::integer as object_id
  , NULL::integer as principal_id 
  , c.connamespace::integer as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'c' and c.conrelid != 0
union all
-- details of user defined and system defined sequence objects
select
  p.relname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where p.relkind = 'S'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
union all
-- details of user defined table types
select
    ('TT_' || tt.name || '_' || tt.type_table_object_id)::name as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::varchar(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If server role is not specified, return info for all server roles
	IF @srvrolename IS NULL
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_login_ext
					WHERE (rolname = @srvrolename
					OR lower(rolname) = lower(@srvrolename))
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		AND (Ext1.rolname = @srvrolename OR lower(Ext1.rolname) = lower(@srvrolename))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_ai', N'Estonian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_as', N'Estonian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_cs_as', N'Estonian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_ai', N'Greek, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_as', N'Greek, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_cs_as', N'Greek, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_ai', N'Hebrew, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_as', N'Hebrew, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitives');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_cs_as', N'Hebrew, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_ai', N'Japanese, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_as', N'Japanese, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_cs_as', N'Japanese, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_ai', N'Mongolian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_as', N'Mongolian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_cs_as', N'Mongolian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_ci_as', N'Virtual, default locale, code page 874, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_cs_as', N'Virtual, default locale, code page 874, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');


ALTER VIEW sys.sysobjects RENAME TO sysobjects_deprecated_2_1_0;

create or replace view sys.sysobjects as
select
  CAST(s.name as sys._ci_sysname)
  , CAST(s.object_id as int) as id
  , CAST(s.type as sys.bpchar(2)) as xtype

  -- 'uid' is specified as type INT here, and not SMALLINT per SQL Server documentation.
  -- This is because if you routinely drop and recreate databases, it is possible for the
  -- dbo schema which relies on pg_catalog oid values to exceed the size of a smallint. 
  , CAST(s.schema_id as int) as uid
  , CAST(0 as smallint) as info
  , CAST(0 as int) as status
  , CAST(0 as int) as base_schema_ver
  , CAST(0 as int) as replinfo
  , CAST(s.parent_object_id as int) as parent_obj
  , CAST(s.create_date as sys.datetime) as crdate
  , CAST(0 as smallint) as ftcatid
  , CAST(0 as int) as schema_ver
  , CAST(0 as int) as stats_schema_ver
  , CAST(s.type as sys.bpchar(2)) as type
  , CAST(0 as smallint) as userstat
  , CAST(0 as smallint) as sysstat
  , CAST(0 as smallint) as indexdel
  , CAST(s.modify_date as sys.datetime) as refdate
  , CAST(0 as int) as version
  , CAST(0 as int) as deltrig
  , CAST(0 as int) as instrig
  , CAST(0 as int) as updtrig
  , CAST(0 as int) as seltrig
  , CAST(0 as int) as category
  , CAST(0 as smallint) as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

CALL sys.babelfish_drop_deprecated_view('sys', 'sysobjects_deprecated_2_1_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);
DROP PROCEDURE sys.babelfish_remove_object_from_extension(varchar, varchar);
DROP PROCEDURE sys.babelfish_drop_deprecated_function(varchar, varchar);
DROP PROCEDURE sys.babelfish_drop_deprecated_table(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

CREATE OR REPLACE FUNCTION sys.language()
RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C;
