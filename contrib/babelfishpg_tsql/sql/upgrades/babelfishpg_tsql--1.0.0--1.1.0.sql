-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.1.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

/* Caution: Be careful while dropping an object in a minor version upgrade
 *          script as the object might be getting used in some user defined
 *          objects and dropping it here might result in upgrade failure or
 *          even user defined objects getting dropped.
 * The following sys.sysindexes view was not working previously, so dropping
 * it here is ok.
 */
DROP VIEW IF EXISTS sys.sysindexes;

CREATE FUNCTION sys.columns_internal()
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
            CAST(a.attname AS sys.sysname),
			CAST(a.attnum AS int),
			CAST(t.oid AS int),
			CAST(t.oid AS int),
			CAST(a.attlen AS smallint),
			CAST(case when isc.datetime_precision is null then coalesce(isc.numeric_precision, 0) else isc.datetime_precision end AS sys.tinyint),
			CAST(coalesce(isc.numeric_scale, 0) AS sys.tinyint),
			CAST(coll.collname AS sys.sysname),
			CAST(a.attcollation AS int),
			CAST(a.attnum AS smallint),
			CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
			CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit),
			CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit),
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
		INNER JOIN pg_namespace s ON s.oid = c.relnamespace
		INNER JOIN information_schema.columns isc ON c.relname = isc.table_name AND s.nspname = isc.table_schema AND a.attname = isc.column_name
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		WHERE NOT a.attisdropped
		AND a.attnum > 0
		-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
		AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
		AND s.nspname NOT IN ('information_schema', 'pg_catalog', 'sys')
		AND has_schema_privilege(s.oid, 'USAGE')
		AND has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
END;
$$
language plpgsql;

create or replace view sys.columns AS
select out_object_id::oid as object_id
  , out_name::name as name
  , out_column_id::smallint as column_id
  , out_system_type_id::oid as system_type_id
  , out_user_type_id::oid as user_type_id
  , out_max_length::smallint as max_length
  , out_precision::integer as precision
  , out_scale::integer as scale
  , out_collation_name::name as collation_name
  , out_is_nullable::integer as is_nullable
  , out_is_ansi_padded::integer as is_ansi_padded
  , out_is_rowguidcol::integer as is_rowguidcol
  , out_is_identity::integer as is_identity
  , out_is_computed::integer as is_computed
  , out_is_filestream::integer as is_filestream
  , out_is_replicated::integer as is_replicated
  , out_is_non_sql_subscribed::integer as is_non_sql_subscribed
  , out_is_merge_published::integer as is_merge_published
  , out_is_dts_replicated::integer as is_dts_replicated
  , out_is_xml_document::integer as is_xml_document
  , out_xml_collection_id::integer as xml_collection_id
  , out_default_object_id::oid as default_object_id
  , out_rule_object_id::oid as rule_object_id
  , out_is_sparse::integer as is_sparse
  , out_is_column_set::integer as is_column_set
  , out_generated_always_type::integer as generated_always_type
  , out_generated_always_type_desc::varchar(60) as generated_always_type_desc
  , out_encryption_type::integer as encryption_type
  , out_encryption_type_desc::varchar(64) as encryption_type_desc
  , out_encryption_algorithm_name::varchar as encryption_algorithm_name
  , out_column_encryption_key_id::integer as column_encryption_key_id
  , out_column_encryption_key_database_name::varchar as column_encryption_key_database_name
  , out_is_hidden::integer as is_hidden
  , out_is_masked::integer as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
from sys.columns_internal();
GRANT SELECT ON sys.columns TO PUBLIC;

create or replace view sys.views as 
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
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace 
where t.relkind = 'v'
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.views TO PUBLIC;

create or replace view sys.all_columns as
select c.oid as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 0 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
where not a.attisdropped
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and has_schema_privilege(s.oid, 'USAGE')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

create or replace view sys.all_views as
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
  , 0 as with_check_option
  , 0 as is_date_correlation_view
  , 0 as is_tracked_by_cdc
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.all_views TO PUBLIC;

create or replace view sys.identity_columns as
select
  sys.babelfish_get_id_by_name(c.oid::text||a.attname) as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 1 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
  , null::bigint as seed_value
  , null::bigint as increment_value
  , sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname)) as last_value
from pg_attribute  a
left join pg_attrdef d on a.attrelid = d.adrelid and a.attnum = d.adnum
inner join pg_class c on c.oid = a.attrelid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_type t on t.oid = a.atttypid
left join pg_collation coll on coll.oid = t.typcollation
where not a.attisdropped
and pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname)  is not null
and s.nspname not in ('information_schema', 'pg_catalog')
and has_schema_privilege(s.oid, 'USAGE')
and has_sequence_privilege(pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

create or replace view sys.all_objects as
select
	t.name
    , t.object_id
    , t.principal_id
    , t.schema_id
    , t.parent_object_id
    , 'U' as type
    , 'USER_TABLE' as type_desc
    , t.create_date
    , t.modify_date
    , t.is_ms_shipped
    , t.is_published
    , t.is_schema_published
from  sys.tables t
where has_schema_privilege(t.schema_id, 'USAGE')
union all
select
	v.name
    , v.object_id
    , v.principal_id
    , v.schema_id
    , v.parent_object_id
    , 'V' as type
    , 'VIEW' as type_desc
    , v.create_date
    , v.modify_date
    , v.is_ms_shipped
    , v.is_published
    , v.is_schema_published
from  sys.all_views v
where has_schema_privilege(v.schema_id, 'USAGE')
union all
select
	f.name
    , f.object_id
    , f.principal_id
    , f.schema_id
    , f.parent_object_id
    , 'F' as type
    , 'FOREIGN_KEY_CONSTRAINT'
    , f.create_date
    , f.modify_date
    , f.is_ms_shipped
    , f.is_published
    , f.is_schema_published
 from sys.foreign_keys f
 where has_schema_privilege(f.schema_id, 'USAGE')
 union all
select
	p.name
    , p.object_id
    , p.principal_id
    , p.schema_id
    , p.parent_object_id
    , 'PK' as type
    , 'PRIMARY_KEY_CONSTRAINT' as type_desc
    , p.create_date
    , p.modify_date
    , p.is_ms_shipped
    , p.is_published
    , p.is_schema_published
 from sys.key_constraints p
 where has_schema_privilege(p.schema_id, 'USAGE')
union all
select
	pr.name
    , pr.object_id
    , pr.principal_id
    , pr.schema_id
    , pr.parent_object_id
    , pr.type
    , pr.type_desc
    , pr.create_date
    , pr.modify_date
    , pr.is_ms_shipped
    , pr.is_published
    , pr.is_schema_published
 from sys.procedures pr
 where has_schema_privilege(pr.schema_id, 'USAGE')
union all
select
  p.relname as name
  ,p.oid as object_id
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
and has_schema_privilege(s.oid, 'USAGE');
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace function sys.square(in x double precision) returns double precision
AS
$BODY$
DECLARE
 res double precision;
BEGIN
 res = pow(x, 2::float);
 return res;
END;
$BODY$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

create or replace view  sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.type::smallint as indid
  , null::binary(6) as root
  , 0::smallint as minlen
  , 1::smallint as keycnt
  , null::smallint as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0::bigint as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0::smallint as xmaxlen
  , null::smallint as maxirow
  , 90::sys.tinyint as "OrigFillFactor"
  , 0::sys.tinyint as "StatVersion"
  , 0 as reserved2
  , null::binary(6) as "FirstIAM"
  , 0::smallint as impid
  , 0::smallint as lockflags
  , 0 as pgmodctr
  , null::sys.varbinary(816) as keys
  , i.name::sys.sysname as name
  , null::sys.image as statblob
  , 0 as maxlen
  , 0 as rows
from sys.indexes i;
GRANT SELECT ON sys.sysindexes TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'tsql_exp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(DOUBLE PRECISION) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg NUMERIC)
RETURNS DOUBLE PRECISION
AS
$BODY$
SELECT sys.exp(arg::DOUBLE PRECISION);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(NUMERIC) TO PUBLIC;

-- BABEL-2259: Support sp_databases System Stored Procedure
-- Lists databases that either reside in an instance of the SQL Server or
-- are accessible through a database gateway

CREATE OR REPLACE VIEW sys.sp_databases_view AS
	SELECT CAST(database_name AS sys.SYSNAME),
	-- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
	CASE WHEN (sum(table_size)/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
		ELSE CAST((sum(table_size)/1024.0) AS int) END as database_size,
	CAST(NULL AS sys.VARCHAR(254)) as remarks
	FROM (
		SELECT pg_catalog.pg_namespace.oid as schema_oid,
		pg_catalog.pg_namespace.nspname as schema_name,
		INT.name AS database_name,
		coalesce(pg_relation_size(pg_catalog.pg_class.oid), 0) as table_size
		FROM
		sys.babelfish_namespace_ext EXT
		JOIN sys.babelfish_sysdatabases INT ON EXT.dbid = INT.dbid
		JOIN pg_catalog.pg_namespace ON pg_catalog.pg_namespace.nspname = EXT.nspname
		LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid
	) t
	GROUP BY database_name
	ORDER BY database_name;
GRANT SELECT on sys.sp_databases_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_databases ()
AS $$
BEGIN
	SELECT database_name as "DATABASE_NAME",
		database_size as "DATABASE_SIZE",
		remarks as "REMARKS" from sys.sp_databases_view;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_databases TO PUBLIC;

-- For numeric/decimal and float/double precision there is already inbuilt functions,
-- Following sign functions are for remaining datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg INT) RETURNS INT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0 THEN 1::INT
		WHEN arg < 0 THEN -1::INT
		ELSE 0::INT
	END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SMALLINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.TINYINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg BIGINT) RETURNS BIGINT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::BIGINT THEN 1::BIGINT
		WHEN arg < 0::BIGINT THEN -1::BIGINT
		ELSE 0::BIGINT
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.MONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::SYS.MONEY THEN 1::SYS.MONEY
		WHEN arg < 0::SYS.MONEY THEN -1::SYS.MONEY
		ELSE 0::SYS.MONEY
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.MONEY) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.SMALLMONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT sys.sign(arg::SYS.MONEY);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.SMALLMONEY) TO PUBLIC;

-- To handle remaining input datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg ANYELEMENT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(ANYELEMENT) TO PUBLIC;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.sign(IN arg TEXT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(TEXT) TO PUBLIC;
CREATE OR REPLACE FUNCTION sys.lock_timeout()
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
 AS $$
 declare return_value integer;
 begin
     return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'lock_timeout');
     RETURN return_value;
 EXCEPTION
     WHEN others THEN
         RETURN NULL;
 END;
 $$;
 GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.max_connections()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'max_connections');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.max_connections() TO PUBLIC;

 CREATE OR REPLACE FUNCTION sys.trigger_nestlevel()
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
 AS $$
 declare return_value integer;
 begin
     return_value := (select pg_trigger_depth());
     RETURN return_value;
 EXCEPTION
     WHEN others THEN
         RETURN NULL;
 END;
 $$;
 GRANT EXECUTE ON FUNCTION sys.trigger_nestlevel() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.schema_name()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $function$
begin
    RETURN (select orig_name from sys.babelfish_namespace_ext ext  
                    where ext.nspname = (select current_schema()) and  ext.dbid::oid = sys.db_id()::oid)::sys.sysname;
EXCEPTION 
    WHEN others THEN
        RETURN NULL;
END;
$function$
;
GRANT EXECUTE ON FUNCTION sys.schema_name() TO PUBLIC;
  
CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $$
declare return_value text;
begin
	RETURN (select session_user)::sys.sysname;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.original_login() TO PUBLIC;

 CREATE OR REPLACE FUNCTION sys.columnproperty(object_id oid, property name, property_name text)
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
 AS $$
 declare extra_bytes CONSTANT integer := 4;
 declare return_value integer;
 begin
 	return_value := (
 					select 
 						case  LOWER(property_name)
 							when 'charmaxlen' then 
 								(select CASE WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes ELSE NULL END  from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
 							when 'allowsnull' then
 								(select CASE WHEN a.attnotnull THEN 0 ELSE 1 END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
 							else
 								null
 						end
 					);
  
   RETURN return_value::integer;
 EXCEPTION 
 	WHEN others THEN
  		RETURN NULL;
 END;
 $$;
 GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id oid, property name, property_name text) TO PUBLIC;

 COMMENT ON FUNCTION sys.columnproperty 
 IS 'This function returns column or parameter information. Currently only works with "charmaxlen", and "allowsnull" otherwise returns 0.';

create or replace view sys.default_constraints
AS
select CAST(('DF_' || o.relname || '_' || d.oid) as sys.sysname) as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modified_date
  , 0::sys.bit as is_ms_shipped
  , 0::sys.bit as is_published
  , 0::sys.bit as is_schema_published
  , d.adnum::int as parent_column_id
  , pg_get_expr(d.adbin, d.adrelid) as definition
  , 1::sys.bit as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_catalog.pg_class as o on (d.adrelid = o.oid);
GRANT SELECT ON sys.default_constraints TO PUBLIC;

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
  , substring(pg_get_expr(d.adbin, d.adrelid), 1, 4000)::sys.nvarchar(4000) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

create or replace view sys.index_columns
as
select i.indrelid::integer as object_id
  , i.indexrelid::integer as index_id
  , a.attrelid::integer as index_column_id
  , a.attnum::integer as column_id
  , a.attnum::sys.tinyint as key_ordinal
  , 0::sys.tinyint as partition_ordinal
  , 0::sys.bit as is_descending_key
  , 1::sys.bit as is_included_column
from pg_index as i
inner join pg_catalog.pg_attribute a on i.indexrelid = a.attrelid;
GRANT SELECT ON sys.index_columns TO PUBLIC;
 
CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , oid::integer as object_id
  , c.connamespace::integer as principal_id 
  , c.connamespace::integer as schema_id
  , conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0::sys.bit as is_ms_shipped
  , 0::sys.bit as is_published
  , 0::sys.bit as is_schema_published
  , 0::sys.bit as is_disabled
  , 0::sys.bit as is_not_for_replication
  , 0::sys.bit as is_not_trusted
  , c.conkey[1]::integer AS parent_column_id
  , substring(pg_get_constraintdef(c.oid) from 7) AS definition
  , 1::sys.bit as uses_database_collation
  , 0::sys.bit as is_system_named
FROM pg_catalog.pg_constraint as c
WHERE c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

create or replace view sys.indexes as
select
  i.indrelid as object_id
  , c.relname as name
  , case when i.indisclustered then 1 else 2 end as type
  , case when i.indisclustered then 'CLUSTERED'::varchar(60) else 'NONCLUSTERED'::varchar(60) end as type_desc
  , case when i.indisunique then 1 else 0 end as is_unique
  , c.reltablespace as data_space_id
  , 0 as ignore_dup_key
  , case when i.indisprimary then 1 else 0 end as is_primary_key
  , case when constr.oid is null then 0 else 1 end as is_unique_constraint
  , 0 as fill_factor
  , case when i.indpred is null then 0 else 1 end as is_padded
  , case when i.indisready then 0 else 1 end is_disabled
  , 0 as is_hypothetical
  , 1 as allow_row_locks
  , 1 as allow_page_locks
  , 0 as has_filter
  , null::varchar as filter_definition
  , 0 as auto_created
  , c.oid as index_id
from pg_class c
inner join pg_namespace s on s.oid = c.relnamespace
inner join pg_index i on i.indexrelid = c.oid
left join pg_constraint constr on constr.conindid = c.oid
where c.relkind = 'i' and i.indislive
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.indexes TO PUBLIC;

-- substring --
CREATE OR REPLACE FUNCTION sys.substring(string TEXT, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NVARCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.microsoftversion()
RETURNS INTEGER AS
$BODY$
    SELECT 201332885::INTEGER;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
CREATE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
	JOIN information_schema.columns t4 ON t1.relname = t4.table_name
	JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	, generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
	AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
	AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597
create function sys.sp_pkeys_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384) = '',
	in_table_qualifier sys.nvarchar(384) = ''
)
returns table(
	out_table_qualifier sys.sysname,
	out_table_owner sys.sysname,
	out_table_name sys.sysname,
	out_column_name sys.sysname,
	out_key_seq smallint,
	out_pk_name sys.sysname
)
as $$
begin
	return query
	select * from sys.sp_pkeys_view
	where in_table_name = table_name
		and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
		and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
	order by table_qualifier, table_owner, table_name, key_seq;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select out_table_qualifier as table_qualifier,
			out_table_owner as table_owner,
			out_table_name as table_name,
			out_column_name as column_name,
			out_key_seq as key_seq,
			out_pk_name as pk_name
	from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE VIEW sys.sp_statistics_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(t1.relname AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
CASE
WHEN t8.oid > 0 THEN CAST(t6.relname AS sys.sysname)
ELSE CAST(SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname)
END AS INDEX_NAME,
CASE
WHEN t7.starelid > 0 THEN CAST(0 AS smallint)
ELSE
	CASE
	WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
	ELSE CAST(3 AS smallint)
	END
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4.dtd_identifier AS smallint) = ANY (t5.indkey)
    AND CAST(t4.dtd_identifier AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

create function sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname = '',
    in_table_qualifier sys.sysname = '',
    in_index_name sys.sysname = '',
	in_is_unique char = 'N',
	in_accuracy char = 'Q'
)
returns table(
    out_table_qualifier sys.sysname,
    out_table_owner sys.sysname,
    out_table_name sys.sysname,
	out_non_unique smallint,
	out_index_qualifier sys.sysname,
	out_index_name sys.sysname,
	out_type smallint,
	out_seq_in_index smallint,
	out_column_name sys.sysname,
	out_collation sys.varchar(1),
	out_cardinality int,
	out_pages int,
	out_filter_condition sys.varchar(128)
)
as $$
begin
    return query
    select * from sys.sp_statistics_view
    where in_table_name = table_name
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name)
		and ((in_is_unique = 'N') or (in_is_unique = 'Y' and non_unique = 0))
    order by non_unique, type, index_name, seq_in_index;
end;
$$
LANGUAGE plpgsql;

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
    select out_table_qualifier as table_qualifier,
            out_table_owner as table_owner,
            out_table_name as table_name,
			out_non_unique as non_unique,
			out_index_qualifier as index_qualifier,
			out_index_name as index_name,
			out_type as type,
			out_seq_in_index as seq_in_index,
			out_column_name as column_name,
			out_collation as collation,
			out_cardinality as cardinality,
			out_pages as pages,
			out_filter_condition as filter_condition
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
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
    select out_table_qualifier as table_qualifier,
            out_table_owner as table_owner,
            out_table_name as table_name,
			out_non_unique as non_unique,
			out_index_qualifier as index_qualifier,
			out_index_name as index_name,
			out_type as type,
			out_seq_in_index as seq_in_index,
			out_column_name as column_name,
			out_collation as collation,
			out_cardinality as cardinality,
			out_pages as pages,
			out_filter_condition as filter_condition
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

-- Duplicate function with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datepart(IN datepart PG_CATALOG.TEXT, IN arg TEXT) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

 -- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate TEXT) RETURNS DATETIME
AS
$body$
BEGIN
    IF pg_typeof(startdate) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.dateadd_internal_df(datepart, num,
                     startdate);
    ELSE
        return sys.dateadd_internal(datepart, num,
                     startdate);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg TEXT) RETURNS TEXT AS
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::date, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::date, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id         AS object_id,
        o.schema_id         AS schema_id,
        c.column_id         AS colid,
        CASE WHEN p.attoptions[1] LIKE 'bbf_original_name=%' THEN split_part(p.attoptions[1], '=', 2)
            ELSE c.name END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tablecollations_100
(
    IN "@object" nvarchar(4000)
)
AS $$
BEGIN
    select
        s_tcv.colid         AS colid,
        s_tcv.name          AS name,
        s_tcv.tds_collation_100 AS tds_collation,
        s_tcv.collation_100 AS collation
    from
        sys.spt_tablecollations_view s_tcv
    where
        s_tcv.object_id = sys.object_id(@object)
    order by colid;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.printarg(IN "@message" TEXT)
AS $$
BEGIN
  PRINT @message;
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.printarg(IN "@message" TEXT) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF sys.user_name() != 'dbo' THEN
    RAISE EXCEPTION 'user does not have permission';
  END IF;

  IF lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE VERBOSE;

  CALL printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

-- internal function that returns relevant info needed
-- by sys.syscolumns view for all procedure parameters.
-- This separate function was needed to workaround BABEL-1597
CREATE FUNCTION sys.proc_param_helper()
RETURNS TABLE (
    name sys.sysname,
    id int,
    xtype int,
    colid smallint,
    collationid int,
    prec smallint,
    scale int,
    isoutparam int,
    collation sys.sysname
)
AS
$$
BEGIN
RETURN QUERY
select params.parameter_name::sys.sysname
  , pgproc.oid::int
  , CAST(case when pgproc.proallargtypes is null then split_part(pgproc.proargtypes::varchar, ' ', params.ordinal_position)
    else split_part(btrim(pgproc.proallargtypes::text,'{}'), ',', params.ordinal_position) end AS int)
  , params.ordinal_position::smallint
  , coll.oid::int
  , params.numeric_precision::smallint
  , params.numeric_scale::int
  , case params.parameter_mode when 'OUT' then 1 when 'INOUT' then 1 else 0 end
  , params.collation_name::sys.sysname
from information_schema.routines routine
left join information_schema.parameters params
  on routine.specific_schema = params.specific_schema
  and routine.specific_name = params.specific_name
left join pg_collation coll on coll.collname = params.collation_name
/* assuming routine.specific_name is constructed by concatenating procedure name and oid */
left join pg_proc pgproc on routine.specific_name = nameconcatoid(pgproc.proname, pgproc.oid)
where routine.routine_schema not in ('pg_catalog', 'information_schema')
  and routine.routine_type = 'PROCEDURE';
END;
$$
LANGUAGE plpgsql;

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
  , null::varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal()
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
  , p.xtype as type
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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
