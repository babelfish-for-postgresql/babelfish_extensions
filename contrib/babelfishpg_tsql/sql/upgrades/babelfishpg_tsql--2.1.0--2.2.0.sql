-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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
GRANT SELECT ON msdb_dbo.syspolicy_system_health_state TO sysadmin;

CREATE OR REPLACE FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled()
RETURNS INTEGER
AS 
$fn_body$    
    SELECT 0;
$fn_body$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW msdb_dbo.syspolicy_configuration
AS
    SELECT
        CAST(NULL AS sys.SYSNAME) AS name,
        CAST(NULL AS sys.sql_variant) AS current_value
    WHERE FALSE; -- Condition will result in view with an empty result set
GRANT SELECT ON msdb_dbo.syspolicy_configuration TO sysadmin;

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

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);
DROP PROCEDURE sys.babelfish_remove_object_from_extension(varchar, varchar);
DROP PROCEDURE sys.babelfish_drop_deprecated_function(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
