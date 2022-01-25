-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.1.0'" to load this file. \quit

DROP VIEW IF EXISTS sys.columns CASCADE;
-- Drop cascades to sys.spt_columns_view_managed

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
		LEFT JOIN pg_collation coll ON coll.oid = t.typcollation
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
and has_schema_privilege(s.oid, 'USAGE');
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
LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;
