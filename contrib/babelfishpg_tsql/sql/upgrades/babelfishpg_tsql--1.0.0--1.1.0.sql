-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.1.0'" to load this file. \quit

DROP VIEW IF EXISTS sys.columns CASCADE;
-- Drop cascades to sys.spt_columns_view_managed

DROP VIEW IF EXISTS sys.sysindexes;

CREATE FUNCTION sys.columns_internal()
RETURNS TABLE (
    out_object_id int,
    out_name sys.sysname,
    out_column_id int,
    out_system_type_id int,
    out_user_type_id int,
    out_max_length smallint,
    out_precision int,
    out_scale int,
    out_collation_name sys.sysname,
    out_is_nullable smallint,
    out_is_ansi_padded smallint,
    out_is_rowguidcol smallint,
    out_is_identity smallint,
    out_is_computed smallint,
    out_is_filestream smallint,
    out_is_replicated smallint,
    out_is_non_sql_subscribed smallint,
    out_is_merge_published smallint,
    out_is_dts_replicated smallint,
    out_is_xml_document smallint,
    out_xml_collection_id int,
    out_default_object_id int,
    out_rule_object_id int,
    out_is_sparse smallint,
    out_is_column_set smallint,
    out_generated_always_type smallint,
    out_generated_always_type_desc sys.nvarchar(60),
    out_encryption_type int,
    out_encryption_type_desc sys.nvarchar(64),
    out_encryption_algorithm_name sys.sysname,
    out_column_encryption_key_id int,
    out_column_encryption_key_database_name sys.sysname,
    out_is_hidden smallint,
    out_is_masked smallint
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
			CAST(case when isc.datetime_precision is null then coalesce(isc.numeric_precision, 0) else isc.datetime_precision end AS int),
			CAST(coalesce(isc.numeric_scale, 0) AS int),
			CAST(coll.collname AS sys.sysname),
			CAST(case when a.attnotnull then 0 else 1 end AS smallint),
			CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS smallint),
			CAST(0 AS smallint),
			CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS smallint),
			CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS int),
			CAST(coalesce(d.oid, 0) AS int),
			CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
						and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST(0 AS smallint),
			CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(64)),
			CAST(null AS sys.sysname),
			CAST(null AS int),
			CAST(null AS sys.sysname),
			CAST(0 AS smallint),
			CAST(0 AS smallint)
		FROM pg_attribute a
		INNER JOIN pg_class c ON c.oid = a.attrelid
		INNER JOIN pg_type t ON t.oid = a.atttypid
		INNER JOIN pg_namespace s ON s.oid = c.relnamespace
		INNER JOIN information_schema.columns isc ON c.relname = isc.table_name AND s.nspname = isc.table_schema AND a.attname = isc.column_name
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		WHERE NOT a.attisdropped
		-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
		AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
		AND s.nspname NOT IN ('information_schema', 'pg_catalog')
		AND has_schema_privilege(s.oid, 'USAGE')
		AND has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
END;
$$
language plpgsql;

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
from sys.columns_internal();
GRANT SELECT ON sys.columns TO PUBLIC;

CREATE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id                     AS OBJECT_ID,
    isc.table_catalog               AS TABLE_CATALOG,
    isc.table_schema                AS TABLE_SCHEMA,
    o.name                          AS TABLE_NAME,
    c.name                          AS COLUMN_NAME,
    isc.ordinal_position            AS ORDINAL_POSITION,
    isc.column_default              AS COLUMN_DEFAULT,
    isc.is_nullable                 AS IS_NULLABLE,
    isc.data_type                   AS DATA_TYPE,
    isc.character_maximum_length    AS CHARACTER_MAXIMUM_LENGTH,
    isc.character_octet_length      AS CHARACTER_OCTET_LENGTH,
    isc.numeric_precision           AS NUMERIC_PRECISION,
    isc.numeric_precision_radix     AS NUMERIC_PRECISION_RADIX,
    isc.numeric_scale               AS NUMERIC_SCALE,
    isc.datetime_precision          AS DATETIME_PRECISION,
    isc.character_set_catalog       AS CHARACTER_SET_CATALOG,
    isc.character_set_schema        AS CHARACTER_SET_SCHEMA,
    isc.character_set_name          AS CHARACTER_SET_NAME,
    isc.collation_catalog           AS COLLATION_CATALOG,
    isc.collation_schema            AS COLLATION_SCHEMA,
    c.collation_name                AS COLLATION_NAME,
    isc.domain_catalog              AS DOMAIN_CATALOG,
    isc.domain_schema               AS DOMAIN_SCHEMA,
    isc.domain_name                 AS DOMAIN_NAME,
    c.is_sparse                     AS IS_SPARSE,
    c.is_column_set                 AS IS_COLUMN_SET,
    c.is_filestream                 AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V')  -- limit columns to tables and views
        )
    LEFT JOIN information_schema.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc.table_schema and
            o.name = isc.table_name and
            c.name = isc.column_name
        )
    WHERE CAST(column_name AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');

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
left join pg_collation coll on coll.oid = t.typcollation
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
  i.object_id as id
  , null::integer as status
  , null::oid as first
  , i.type as indid
  , null::oid as root
  , 0 as minlen
  , 1 as keycnt
  , null::integer as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0 as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0 as xmaxlen
  , null::integer as maxirow
  , 90 as OrigFillFactor
  , 0 as StatVersion
  , 0 as reserved2
  , null::integer as FirstIAM
  , 0 as impid
  , 0 as lockflags
  , 0 as pgmodctr
  , null::sys.varbinary(816) as keys
  , i.name as name
  , null::sys.image as statblob
  , 0 as maxlen
  , 0 as rows
from sys.indexes i;
GRANT SELECT ON sys.sysindexes TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;
  ANALYZE VERBOSE;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_updatestats(IN VARCHAR(8)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'tsql_exp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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
DROP VIEW IF EXISTS sys.sp_databases_view CASCADE;

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
	GROUP BY database_name;
GRANT SELECT on sys.sp_databases_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_databases ()
AS $$
BEGIN
	SELECT * from sys.sp_databases_view;
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

 CREATE OR REPLACE FUNCTION sys.type_name(type_id oid)
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $$
begin
    RETURN (select format_type(type_id, null))::sys.sysname;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.type_name(type_id oid) TO PUBLIC;

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

CREATE OR REPLACE FUNCTION sys.babelfish_split_schema_object_name(delimited_name TEXT, out schema_name TEXT, out object_name TEXT)
as
$$
SELECT 
    CASE 
        WHEN a[3] is not null then null -- currently only support up to two part names
	    WHEN a[2] is null then null     -- no schema name given, only the object name
        ELSE a[1]
    END as schema_name,
       
    CASE
	    WHEN a[3] is not null then null -- currently only support up to two part names
	    WHEN a[2] is null then a[1]
        ELSE a[2]
   END as object_name
FROM (
	SELECT string_to_array(delimited_name, '.') as a
) t
$$
Language SQL;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME, 
    securable_class sys.nvarchar(60), 
    permission sys.SYSNAME
)
RETURNS integer
LANGUAGE plpgsql
CALLED ON NULL INPUT
AS $$
DECLARE 
    return_value integer;
    schema_n text;
    object_n text;
BEGIN
    return_value := NULL;
    SELECT s.schema_name, s.object_name into schema_n, object_n FROM sys.babelfish_split_schema_object_name(securable) s;
	
	-- translate schema name from bbf to postgres, e.g. dbo -> master_dbo
	schema_n := (
        select 
			case when schema_n is null then ( current_schema() )
			else 
	    		(select nspname from sys.babelfish_namespace_ext ext where ext.orig_name = schema_n and  ext.dbid::oid = sys.db_id()::oid)
			end as scheman);
	
	return_value := (
		select
		  -- check if object_n is a 'table-like' object.
		  case (select count(relname) from pg_catalog.pg_class  where relname = object_n and
                           relnamespace = (select oid from pg_catalog.pg_namespace where nspname = schema_n))
		       when 1 then
		          has_table_privilege(concat(schema_n,'.',object_n), permission)::integer
		  -- check other cases here  
          -- TODO implement functionality for other object types.
		  end
	);
	
	RETURN return_value;
	EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(securable sys.SYSNAME, securable_class sys.nvarchar(60), permission sys.SYSNAME) TO PUBLIC;

COMMENT ON FUNCTION sys.has_perms_by_name
IS 'This function returns permission information. Currently only works with "table-like" objects, otherwise returns NULL.';

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

DROP VIEW IF EXISTS sys.default_constraints;
create or replace view sys.default_constraints
AS
select 'DF_' || o.relname || '_' || d.oid as name
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
  
DROP VIEW IF EXISTS sys.computed_columns;
CREATE OR REPLACE VIEW sys.computed_columns
AS 
SELECT d.adrelid AS object_id
  , CAST(a.attname as sys.sysname) AS name
  , a.attnum::int AS column_id
  , a.atttypid AS system_type_id
  , a.atttypid AS user_type_id
  , 0::smallint AS max_length
  , null::sys.tinyint AS precision
  , null::sys.tinyint AS scale
  , null::sys.sysname AS collation_name
  , 0::sys.bit AS is_nullable
  , 0::sys.bit AS is_ansi_padded
  , 0::sys.bit AS is_rowguidcol
  , 0::sys.bit AS is_identity
  , 0::sys.bit AS is_filestream
  , 0::sys.bit AS is_replicated
  , 0::sys.bit AS is_non_sql_subscribed
  , 0::sys.bit AS is_merge_published
  , 0::sys.bit AS is_dts_replicated
  , 0::sys.bit AS is_xml_document
  , 0 AS xml_collection_id
  , 0 AS default_object_id
  , 0 AS rule_object_id
  , pg_get_expr(d.adbin, d.adrelid) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
  , 1::sys.bit AS is_computed
  , 0::sys.bit AS is_sparse
  , 0::sys.bit AS is_column_set
  , 0::sys.tinyint AS generated_always_type
  , 'NOT_APPLICABLE'::sys.nvarchar(60) as generated_always_type_desc
  , null::integer AS encryption_type
  , null::sys.nvarchar(64) AS encryption_type_desc
  , null::sys.sysname AS encryption_algorithm_name
  , null::integer AS column_encryption_key_id
  , null::sys.sysname AS column_encryption_key_database_name
  , 0::sys.bit AS is_hidden
  , 0::sys.bit AS is_masked
  , null::integer AS graph_type
  , null::sys.nvarchar(60) AS graph_type_desc
FROM pg_attrdef d
JOIN pg_attribute a ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's';
GRANT SELECT ON sys.computed_columns TO PUBLIC;
  
DROP VIEW IF EXISTS sys.index_columns;
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

DROP VIEW IF EXISTS sys.configurations;
CREATE OR REPLACE VIEW sys.configurations
AS 
SELECT CAST(row_number() OVER (ORDER BY s.category, s.name) as integer) AS configuration_id
  , s.name::sys.nvarchar(35)
  , s.setting::sys.sql_variant AS value
  , s.min_val::sys.sql_variant AS minimum
  , s.max_val::sys.sql_variant AS maximum
  , s.setting::sys.sql_variant AS value_in_use
  , s.short_desc::sys.nvarchar(255) AS description
  , CASE WHEN s.context in ('user', 'superuser', 'backend', 'superuser-backend', 'sighup') THEN 1::sys.bit ELSE 0::sys.bit END AS is_dynamic
  , 0::sys.bit AS is_advanced
FROM pg_settings s;
GRANT SELECT ON sys.configurations TO PUBLIC;
 
DROP VIEW IF EXISTS sys.check_constraints;
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
