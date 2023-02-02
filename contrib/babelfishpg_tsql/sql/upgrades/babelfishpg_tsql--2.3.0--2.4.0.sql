-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.4.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(
	object_type varchar, schema_name varchar, object_name varchar
) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := format('drop %s %s.%s', object_type, schema_name, object_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view/function/procedure' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

/*
 * SCHEMATA view
 */
CREATE OR REPLACE FUNCTION sys.bbf_is_shared_schema(IN schemaname TEXT)
RETURNS BOOL
AS 'babelfishpg_tsql', 'is_shared_schema_wrapper'
LANGUAGE C STABLE STRICT;

CREATE OR REPLACE VIEW information_schema_tsql.schemata AS
	SELECT CAST(sys.db_name() AS sys.sysname) AS "CATALOG_NAME",
	CAST(CASE WHEN np.nspname LIKE CONCAT(sys.db_name(),'%') THEN RIGHT(np.nspname, LENGTH(np.nspname) - LENGTH(sys.db_name()) - 1)
	     ELSE np.nspname END AS sys.nvarchar(128)) AS "SCHEMA_NAME",
	-- For system-defined schemas, schema-owner name will be same as schema_name
	-- For user-defined schemas having default owner, schema-owner will be dbo
	-- For user-defined schemas with explicit owners, rolname contains dbname followed
	-- by owner name, so need to extract the owner name from rolname always.
	CAST(CASE WHEN sys.bbf_is_shared_schema(np.nspname) = TRUE THEN np.nspname
		  WHEN r.rolname LIKE CONCAT(sys.db_name(),'%') THEN
			CASE WHEN RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) = 'db_owner' THEN 'dbo'
			     ELSE RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) END ELSE 'dbo' END
			AS sys.nvarchar(128)) AS "SCHEMA_OWNER",
	CAST(null AS sys.varchar(6)) AS "DEFAULT_CHARACTER_SET_CATALOG",
	CAST(null AS sys.varchar(3)) AS "DEFAULT_CHARACTER_SET_SCHEMA",
	-- TODO: We need to first create mapping of collation name to char-set name;
	-- Until then return null for DEFAULT_CHARACTER_SET_NAME
	CAST(null AS sys.sysname) AS "DEFAULT_CHARACTER_SET_NAME"
	FROM ((pg_catalog.pg_namespace np LEFT JOIN sys.pg_namespace_ext nc on np.nspname = nc.nspname)
		LEFT JOIN pg_catalog.pg_roles r on r.oid = nc.nspowner) LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
	WHERE (ext.dbid = cast(sys.db_id() as oid) OR np.nspname in ('sys', 'information_schema_tsql')) AND
	      (pg_has_role(np.nspowner, 'USAGE') OR has_schema_privilege(np.oid, 'CREATE, USAGE'))
	ORDER BY nc.nspname, np.nspname;

GRANT SELECT ON information_schema_tsql.schemata TO PUBLIC;

-- please add your SQL here
CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 INT)
RETURNS int AS 'babelfishpg_tsql','int_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 SMALLINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 TINYINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(TINYINT) TO PUBLIC;

-- deprecate old FOR XML/JSON functions
ALTER FUNCTION sys.tsql_query_to_xml(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_deprecated_in_2_4_0');

ALTER FUNCTION sys.tsql_query_to_xml_text(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_text_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_text_deprecated_in_2_4_0');

ALTER FUNCTION sys.tsql_query_to_json_text(text, int, boolean, boolean, text) RENAME TO tsql_query_to_json_text_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_json_text_deprecated_in_2_4_0');

-- SELECT FOR XML
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_ffunc(
    state INTERNAL
)
RETURNS XML AS
'babelfishpg_tsql', 'tsql_query_to_xml_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text_ffunc(
    state INTERNAL
)
RETURNS NTEXT AS
'babelfishpg_tsql', 'tsql_query_to_xml_text_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

-- SELECT FOR JSON
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_json_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_ffunc(
    state INTERNAL
)
RETURNS sys.NVARCHAR AS
'babelfishpg_tsql', 'tsql_query_to_json_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_json_agg(
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_json_sfunc,
    FINALFUNC = tsql_query_to_json_ffunc
);

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

  ANALYZE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 BIGINT, IN arg2 NUMERIC)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(BIGINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 INT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','int_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(INT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 SMALLINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(SMALLINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 TINYINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(TINYINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_get_expr(IN text_expr text DEFAULT NULL , IN function_id OID DEFAULT NULL)
RETURNS text AS 'babelfishpg_tsql', 'tsql_get_expr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.partitions AS
SELECT
 (to_char( i.object_id, 'FM9999999999' ) || to_char( i.index_id, 'FM9999999999' ) || '1')::bigint AS partition_id
 , i.object_id
 , i.index_id
 , 1::integer AS partition_number
 , 0::bigint AS hobt_id
 , c.reltuples::bigint AS "rows"
 , 0::smallint AS filestream_filegroup_id
 , 0::sys.tinyint AS data_compression
 , 'NONE'::sys.nvarchar(60) AS data_compression_desc
FROM sys.indexes AS i
INNER JOIN pg_catalog.pg_class AS c ON i.object_id = c."oid";
GRANT SELECT ON sys.partitions TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.atn2(IN x SYS.FLOAT, IN y SYS.FLOAT) RETURNS SYS.FLOAT
AS
$$
DECLARE
    res SYS.FLOAT;
BEGIN
    IF x = 0 AND y = 0 THEN
        RAISE EXCEPTION 'An invalid floating point operation occurred.';
    ELSE
        res = PG_CATALOG.atan2(x, y);
        RETURN res;
    END IF;
END;
$$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.APP_NAME() RETURNS SYS.NVARCHAR(128)
AS
$$
    SELECT current_setting('application_name');
$$
LANGUAGE sql PARALLEL SAFE STABLE;

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
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar(4000)) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as char(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  , CAST(tsql_get_expr(d.adbin, d.adrelid) as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
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
  , CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit) as is_identity
  , CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit) as is_computed
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
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.STR(IN float_expression NUMERIC, IN length INTEGER DEFAULT 10, IN decimal_point INTEGER DEFAULT 0) RETURNS VARCHAR 
AS
'babelfishpg_tsql', 'float_str' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.STR(IN NUMERIC, IN INTEGER, IN INTEGER) TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as char(2)) as type
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
  , CAST(tsql_get_constraintdef(c.oid) as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 INT)
RETURNS int  AS 'babelfishpg_tsql','int_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 SMALLINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 TINYINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(TINYINT) TO PUBLIC;

ALTER FUNCTION sys.num_days_in_date RENAME TO num_days_in_date_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'num_days_in_date_deprecated_in_2_4_0');
CREATE OR REPLACE FUNCTION sys.num_days_in_date(IN d1 BIGINT, IN m1 BIGINT, IN y1 BIGINT) RETURNS BIGINT AS $$
DECLARE
	i BIGINT;
	n1 BIGINT;
BEGIN
	n1 = y1 * 365 + d1;
	FOR i in 0 .. m1-2 LOOP
		IF (i = 0 OR i = 2 OR i = 4 OR i = 6 OR i = 7 OR i = 9 OR i = 11) THEN
			n1 = n1 + 31;
		ELSIF (i = 3 OR i = 5 OR i = 8 OR i = 10) THEN
			n1 = n1 + 30;
		ELSIF (i = 1) THEN
			n1 = n1 + 28;
		END IF;
	END LOOP;
	IF m1 <= 2 THEN
		y1 = y1 - 1;
	END IF;
	n1 = n1 + (y1/4 - y1/100 + y1/400);

	return n1;
END
$$
LANGUAGE plpgsql IMMUTABLE;

ALTER FUNCTION sys.datediff_internal_df RENAME TO datediff_internal_df_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_df_deprecated_in_2_4_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal_df(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
	y1 BIGINT;
	m1 BIGINT;
	d1 BIGINT;
	y2 BIGINT;
	m2 BIGINT;
	d2 BIGINT;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff;
	WHEN 'day' THEN
		y1 = sys.datepart('year', enddate);
		m1 = sys.datepart('month', enddate);
		d1 = sys.datepart('day', enddate);
		y2 = sys.datepart('year', startdate);
		m2 = sys.datepart('month', startdate);
		d2 = sys.datepart('day', startdate);
		result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
	WHEN 'week' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff / 7;
	WHEN 'hour' THEN
		y1 = sys.datepart('year', enddate);
		m1 = sys.datepart('month', enddate);
		d1 = sys.datepart('day', enddate);
		y2 = sys.datepart('year', startdate);
		m2 = sys.datepart('month', startdate);
		d2 = sys.datepart('day', startdate);
		day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
		hour_diff = sys.datepart('hour', enddate) - sys.datepart('hour', startdate);
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we do not need to add second_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = sys.datepart('day', enddate - startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

ALTER FUNCTION sys.datediff_internal_date RENAME TO datediff_internal_date_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_date_deprecated_in_2_4_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal_date(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = year_diff * 12 + month_diff;
	-- for all intervals smaller than month, (DATE - DATE) already returns the integer number of days
	-- between the dates, so just use that directly as the day_diff. There is no finer resolution
	-- than days with the DATE type anyways.
	WHEN 'doy', 'y' THEN
		day_diff = enddate - startdate;
		result = day_diff;
	WHEN 'day' THEN
		day_diff = enddate - startdate;
		result = day_diff;
	WHEN 'week' THEN
		day_diff = enddate - startdate;
		result = day_diff / 7;
	WHEN 'hour' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24;
	WHEN 'minute' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60;
	WHEN 'second' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we do not need to add second_diff again
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000 * 1000;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000 * 1000 * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

ALTER FUNCTION sys.datediff_internal RENAME TO datediff_internal_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_deprecated_in_2_4_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
	y1 BIGINT;
	m1 BIGINT;
	d1 BIGINT;
	y2 BIGINT;
	m2 BIGINT;
	d2 BIGINT;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = day_diff;
	WHEN 'day' THEN
		y1 = date_part('year', enddate)::BIGINT;
		m1 = date_part('month', enddate)::BIGINT;
		d1 = date_part('day', enddate)::BIGINT;
		y2 = date_part('year', startdate)::BIGINT;
		m2 = date_part('month', startdate)::BIGINT;
		d2 = date_part('day', startdate)::BIGINT;
		result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
	WHEN 'week' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = day_diff / 7;
	WHEN 'hour' THEN
		y1 = date_part('year', enddate)::BIGINT;
		m1 = date_part('month', enddate)::BIGINT;
		d1 = date_part('day', enddate)::BIGINT;
		y2 = date_part('year', startdate)::BIGINT;
		m2 = date_part('month', startdate)::BIGINT;
		d2 = date_part('day', startdate)::BIGINT;
		day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
		hour_diff = date_part('hour', enddate)::BIGINT - date_part('hour', startdate)::BIGINT;
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we do not need to add second_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal_date(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal_df(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_date(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_df(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
			 CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
                  ELSE c.relname END
			 AS sys._ci_sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS varchar(10)) AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

	WHERE c.relkind IN ('r', 'v', 'p')
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = cast(sys.db_id() as oid)
		AND (NOT c.relname = 'sysdatabases');

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.SEQUENCES AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SEQUENCE_CATALOG",
            CAST(extc.orig_name AS sys.nvarchar(128)) AS "SEQUENCE_SCHEMA",
            CAST(r.relname AS sys.nvarchar(128)) AS "SEQUENCE_NAME",
            CAST(CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype) ELSE tsql_type_name END
                    AS sys.nvarchar(128))AS "DATA_TYPE",  -- numeric and decimal data types are converted into bigint which is due to Postgres inherent implementation
            CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, -1)
                        AS smallint) AS "NUMERIC_PRECISION",
            CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, -1)
                        AS smallint) AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, -1)
                        AS int) AS "NUMERIC_SCALE",
            CAST(s.seqstart AS sys.sql_variant) AS "START_VALUE",
            CAST(s.seqmin AS sys.sql_variant) AS "MINIMUM_VALUE",
            CAST(s.seqmax AS sys.sql_variant) AS "MAXIMUM_VALUE",
            CAST(s.seqincrement AS sys.sql_variant) AS "INCREMENT",
            CAST( CASE WHEN s.seqcycle = 't' THEN 1 ELSE 0 END AS int) AS "CYCLE_OPTION",
            CAST(NULL AS sys.nvarchar(128)) AS "DECLARED_DATA_TYPE",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_PRECISION",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_SCALE"
        FROM sys.pg_namespace_ext nc JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
            pg_sequence s join pg_class r on s.seqrelid = r.oid join pg_type t on s.seqtypid=t.oid,
            sys.translate_pg_type_to_tsql(s.seqtypid) AS tsql_type_name
        WHERE nc.oid = r.relnamespace
        AND extc.dbid = cast(sys.db_id() as oid)
            AND r.relkind = 'S'
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND (pg_has_role(r.relowner, 'USAGE')
                OR has_sequence_privilege(r.oid, 'SELECT, UPDATE, USAGE'));

GRANT SELECT ON information_schema_tsql.SEQUENCES TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_has_any_privilege(
    userid oid,
    perm_target_type text,
    schema_name text,
    object_name text)
RETURNS INTEGER
AS
$BODY$
DECLARE
    relevant_permissions text[];
    namespace_id oid;
    function_signature text;
    qualified_name text;
    permission text;
BEGIN
 IF perm_target_type IS NULL OR perm_target_type COLLATE sys.database_default NOT IN('table', 'function', 'procedure')
        THEN RETURN NULL;
    END IF;

    relevant_permissions := (
        SELECT CASE
            WHEN perm_target_type = 'table' COLLATE sys.database_default
                THEN '{"select", "insert", "update", "delete", "references"}'
            WHEN perm_target_type = 'column' COLLATE sys.database_default
                THEN '{"select", "update", "references"}'
            WHEN perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
                THEN '{"execute"}'
        END
    );

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = schema_name COLLATE sys.database_default;

    IF perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
        THEN SELECT oid::regprocedure
                INTO function_signature
                FROM pg_catalog.pg_proc
                WHERE proname = object_name COLLATE sys.database_default
                    AND pronamespace = namespace_id;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', schema_name, '"."', object_name, '"');

    FOREACH permission IN ARRAY relevant_permissions
    LOOP
        IF perm_target_type = 'table' COLLATE sys.database_default AND has_table_privilege(userid, qualified_name, permission)::integer = 1
            THEN RETURN 1;
        ELSIF perm_target_type COLLATE sys.database_default IN ('function', 'procedure') AND has_function_privilege(userid, function_signature, permission)::integer = 1
            THEN RETURN 1;
        END IF;
    END LOOP;
    RETURN 0;
END
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    db_name text COLLATE sys.database_default; 
    bbf_schema_name text;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    is_cross_db boolean := false;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    userid oid;
    object_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
    cs_as_securable text COLLATE "C" := securable;
    cs_as_securable_class text COLLATE "C" := securable_class;
    cs_as_permission text COLLATE "C" := permission;
    cs_as_sub_securable text COLLATE "C" := sub_securable;
    cs_as_sub_securable_class text COLLATE "C" := sub_securable_class;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    cs_as_securable = lower(rtrim(cs_as_securable));
    cs_as_securable_class = lower(rtrim(cs_as_securable_class));
    cs_as_permission = lower(rtrim(cs_as_permission));
    cs_as_sub_securable = lower(rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, user must be evaluating column privileges.
    -- Check that inputs are valid for column privileges: sub_securable_class must 
    -- be column, securable_class must be object, and permission cannot be any.
    ELSIF cs_as_sub_securable_class IS NOT NULL 
            AND (cs_as_sub_securable_class != 'column' 
                    OR cs_as_securable_class IS NULL 
                    OR cs_as_securable_class != 'object' 
                    OR cs_as_permission = 'any') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null
    ELSIF cs_as_securable IS NULL AND cs_as_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If securable_class is null, securable must be null
    ELSIF cs_as_securable IS NOT NULL AND cs_as_securable_class IS NULL THEN
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'server' THEN
        -- SQL Server does not permit a securable_class value of 'server'.
        -- securable_class should be NULL to evaluate server permissions.
        RETURN NULL;
    ELSIF cs_as_securable_class IS NULL THEN
        -- NULL indicates a server permission. Set this variable so that we can
        -- search for the matching entry in babelfish_has_perms_by_name_permissions
        cs_as_securable_class = 'server';
    END IF;

    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported 
    INTO implied_dbo_permissions,fully_supported 
    FROM babelfish_has_perms_by_name_permissions p 
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;
    
    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name 
                    AND CAST(ext.dbid AS oid) = CAST(sys.db_id() AS oid)) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND
		(SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) = 'dbo' THEN
        RETURN CAST(implied_dbo_permissions AS integer);
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable class.
    -- The block above has dealt with all permissions that are not fully supported, so 
    -- if we reach this point we know the securable class is OBJECT.
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name 
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    -- If schema was not specified, use the default
    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE 
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

	IF database_id <> sys.db_id() THEN
        is_cross_db = true;
	END IF;

	userid := (
        SELECT CASE
            WHEN is_cross_db THEN sys.suser_id()
            ELSE sys.user_id()
        END);
  
    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname 
                    FROM sys.babelfish_namespace_ext ext 
                    WHERE ext.orig_name = bbf_schema_name 
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(a.attname)
                        FROM pg_attribute a
                        INNER JOIN pg_class c ON c.oid = a.attrelid
                        INNER JOIN pg_namespace s ON s.oid = c.relnamespace
                        WHERE
                        a.attname = cs_as_sub_securable COLLATE sys.database_default
                        AND c.relname = object_name COLLATE sys.database_default
                        AND s.nspname = pg_schema COLLATE sys.database_default
                        AND NOT a.attisdropped
                        AND (s.nspname IN (SELECT nspname FROM sys.babelfish_namespace_ext) OR s.nspname = 'sys')
                        -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
                        AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
                        AND a.attnum > 0) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname) 
                    FROM pg_catalog.pg_class 
                    WHERE relname = object_name COLLATE sys.database_default
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default 
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'
                
            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );
    
    -- Object was not found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;
  
    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT CAST(oid AS regprocedure) 
            INTO function_signature 
            FROM pg_catalog.pg_proc 
            WHERE proname = object_name COLLATE sys.database_default
                AND pronamespace = namespace_id;
    END IF;

    return_value := (
        SELECT CASE
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(userid, object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(userid, qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(userid, qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
        END
    );

    RETURN return_value;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME, 
    securable_class sys.nvarchar(60), 
    permission sys.SYSNAME, 
    sub_securable sys.SYSNAME,
    sub_securable_class sys.nvarchar(60)) TO PUBLIC;

-- For all the views created on previous versions, the definition in the catalog should be NULL.
UPDATE sys.babelfish_view_def SET definition = NULL;

-- Add one column to store definition of the function in the table.
SET allow_system_table_mods = on;
ALTER TABLE sys.babelfish_function_ext add COLUMN IF NOT EXISTS definition sys.NTEXT DEFAULT NULL;
RESET allow_system_table_mods;

GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

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
	   CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
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
	    CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
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
            CAST(f.definition AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
	    CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
	    inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT)
		LEFT JOIN sys.babelfish_function_ext f ON p.proname = f.funcname AND sch.schema_id::regnamespace::name = f.nspname
			AND sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature COLLATE "C",
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
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
            AND p.pronamespace = nc.oid
	    AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF', 'TR') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition  -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF', 'IF') THEN
        CASE WHEN p.proisstrict THEN 1
        ELSE 0 
        END
      ELSE 0
      END
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
      ao.name = bvd.object_name
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
LEFT JOIN sys.babelfish_function_ext f ON ao.name = f.funcname COLLATE "C" AND ao.schema_id::regnamespace::name = f.nspname
AND sys.babelfish_get_pltsql_function_signature(ao.object_id) = f.funcsignature COLLATE "C"
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

-- function sys.object_id(object_name, object_type) needs to change input type to sys.VARCHAR
ALTER FUNCTION sys.object_id RENAME TO object_id_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'object_id_deprecated_in_2_4_0');

CREATE OR REPLACE FUNCTION sys.object_id(IN object_name sys.VARCHAR, IN object_type sys.VARCHAR DEFAULT NULL)
RETURNS INTEGER AS
'babelfishpg_tsql', 'object_id'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'To use @@DBTS, set ''babelfishpg_tsql.escape_hatch_rowversion'' to ''ignore''';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE sys.sp_set_session_context ("@key" sys.sysname, 
	"@value" sys.SQL_VARIANT, "@read_only" sys.bit = 0)
AS 'babelfishpg_tsql', 'sp_set_session_context'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_set_session_context TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.session_context ("@key" sys.sysname)
	RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'session_context' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.session_context TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_internal(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@schemaname" sys.nvarchar(776),
	IN "@objtype" char(2) DEFAULT NULL
) AS 'babelfishpg_tsql', 'sp_rename_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	IF @objtype IS NOT NULL AND (@objtype != 'OBJECT')
		BEGIN
			THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
		END
	DECLARE @name_count INT;
	DECLARE @subname sys.nvarchar(776) = '';
	DECLARE @schemaname sys.nvarchar(776) = '';
	DECLARE @dbname sys.nvarchar(776) = '';
	SELECT @name_count = COUNT(*) FROM STRING_SPLIT(@objname, '.');
	IF @name_count > 3
		BEGIN
			THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
		END
	IF @name_count = 3
		BEGIN
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @dbname = value FROM myTableWithRows WHERE row = 1;
			PRINT 'db_name:  ';
			PRINT sys.db_name();
			IF @dbname != sys.db_name()
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @schemaname = value FROM myTableWithRows WHERE row = 2;
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @subname = value FROM myTableWithRows WHERE row = 3;
		END
	IF @name_count = 2
		BEGIN
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @schemaname = value FROM myTableWithRows WHERE row = 1;
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @subname = value FROM myTableWithRows WHERE row = 2;
		END
	IF @name_count = 1
		BEGIN
			SET @schemaname = sys.schema_name();
			SET @subname = @objname;
		END
	
	DECLARE @count INT;
	DECLARE @currtype char(2);
	SELECT @count = COUNT(*) FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
	WHERE s1.name = @schemaname AND o1.name = @subname;
	IF @count > 1
		BEGIN
			THROW 33557097, N'There are multiple objects with the given @objname.', 1;
		END
	IF @count < 1
		BEGIN
			THROW 33557097, N'There is no object with the given @objname.', 1;
		END
	SELECT @currtype = type FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
	WHERE s1.name = @schemaname AND o1.name = @subname;
	EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype;
END;
$$;
GRANT EXECUTE on PROCEDURE sys.sp_rename(IN sys.nvarchar(776), IN sys.SYSNAME, IN sys.varchar(13)) TO PUBLIC;

/* set sys functions as STABLE */
ALTER FUNCTION sys.schema_id() STABLE;
ALTER FUNCTION sys.schema_name() STABLE;
ALTER FUNCTION sys.sp_columns_100_internal(
	in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384), 
    in_table_qualifier sys.nvarchar(384),
    in_column_name sys.nvarchar(384),
	in_NameScope int,
    in_ODBCVer int,
    in_fusepattern smallint)
STABLE;
ALTER FUNCTION sys.sp_columns_managed_internal(
    in_catalog sys.nvarchar(128), 
    in_owner sys.nvarchar(128),
    in_table sys.nvarchar(128),
    in_column sys.nvarchar(128),
    in_schematype int)
STABLE;
ALTER FUNCTION sys.sp_pkeys_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384),
	in_table_qualifier sys.nvarchar(384)
)
STABLE;
ALTER FUNCTION sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname,
    in_table_qualifier sys.sysname,
    in_index_name sys.sysname,
	in_is_unique char,
	in_accuracy char
)
STABLE;
ALTER FUNCTION sys.sp_tables_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384), 
	in_table_qualifier sys.sysname,
	in_table_type sys.varchar(100),
	in_fusepattern sys.bit)
STABLE;
ALTER FUNCTION sys.trigger_nestlevel() STABLE;
ALTER FUNCTION sys.proc_param_helper() STABLE;
ALTER FUNCTION sys.original_login() STABLE; 
ALTER FUNCTION sys.objectproperty(id INT, property SYS.VARCHAR) STABLE;
ALTER FUNCTION sys.OBJECTPROPERTYEX(id INT, property SYS.VARCHAR) STABLE;
ALTER FUNCTION sys.nestlevel() STABLE;
ALTER FUNCTION sys.max_connections() STABLE;
ALTER FUNCTION sys.lock_timeout() STABLE;
ALTER FUNCTION sys.json_modify(in expression sys.NVARCHAR,in path_json TEXT, in new_value TEXT) STABLE;
ALTER FUNCTION sys.isnumeric(IN expr ANYELEMENT) STABLE;
ALTER FUNCTION sys.isnumeric(IN expr TEXT) STABLE;
ALTER FUNCTION sys.isdate(v text) STABLE;
ALTER FUNCTION sys.is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME) STABLE;
ALTER FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128)) STABLE;
ALTER FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME,
    sub_securable_class SYS.NVARCHAR(60)
)
STABLE;
ALTER FUNCTION sys.fn_listextendedproperty (
property_name varchar(128),
level0_object_type varchar(128),
level0_object_name varchar(128),
level1_object_type varchar(128),
level1_object_name varchar(128),
level2_object_type varchar(128),
level2_object_name varchar(128)
)
STABLE;
ALTER FUNCTION sys.fn_helpcollations() STABLE;
ALTER FUNCTION sys.DBTS() STABLE;
ALTER FUNCTION sys.columns_internal() STABLE;
ALTER FUNCTION sys.columnproperty(object_id oid, property name, property_name text) STABLE;
ALTER FUNCTION sys.babelfish_get_id_by_name(object_name text) STABLE;
ALTER FUNCTION sys.babelfish_get_sequence_value(in sequence_name character varying) STABLE;
ALTER FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT, IN p_dateval DATE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_dateval DATE) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day NUMERIC, IN p_month NUMERIC, IN p_year NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day TEXT, IN p_month TEXT, IN p_year TEXT) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_dateval DATE) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day NUMERIC, IN p_month NUMERIC, IN p_year NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day TEXT, IN p_month TEXT, IN p_year TEXT) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_date(IN p_datestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT, IN p_timestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_timeval TIME(6) WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_dbts() STABLE;
ALTER FUNCTION sys.babelfish_get_jobs() STABLE;
ALTER FUNCTION sys.babelfish_get_lang_metadata_json(IN p_lang_spec_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_service_setting ( IN p_service sys.service_settings.service%TYPE , IN p_setting sys.service_settings.setting%TYPE ) STABLE;
ALTER FUNCTION sys.babelfish_get_version(pComponentName VARCHAR(256)) STABLE;
ALTER FUNCTION sys.babelfish_is_ossp_present() STABLE;
ALTER FUNCTION sys.babelfish_is_spatial_present() STABLE;
ALTER FUNCTION sys.babelfish_istime(v text) STABLE;
ALTER FUNCTION babelfish_remove_delimiter_pair(IN name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_openxml(IN DocHandle BIGINT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_date(IN p_datestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_time(IN p_datatype TEXT, IN p_srctimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_ROUND3(x in numeric, y in int, z in int) STABLE;
ALTER FUNCTION sys.babelfish_sp_aws_add_jobschedule (par_job_id integer, par_schedule_id integer, out returncode integer) STABLE;
ALTER FUNCTION sys.babelfish_sp_aws_del_jobschedule (par_job_id integer, par_schedule_id integer, out returncode integer )STABLE;
ALTER FUNCTION sys.babelfish_sp_schedule_to_cron (par_job_id integer, par_schedule_id integer, out cron_expression varchar )STABLE;
ALTER FUNCTION sys.babelfish_sp_sequence_get_range(
  in par_sequence_name text,
  in par_range_size bigint,
  out par_range_first_value bigint,
  out par_range_last_value bigint,
  out par_range_cycle_count bigint,
  out par_sequence_increment bigint,
  out par_sequence_min_value bigint,
  out par_sequence_max_value bigint
)  
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job (
  par_job_id integer,
  par_name varchar,
  par_enabled smallint,
  par_start_step_id integer,
  par_category_name varchar,
  inout par_owner_sid char,
  par_notify_level_eventlog integer,
  inout par_notify_level_email integer,
  inout par_notify_level_netsend integer,
  inout par_notify_level_page integer,
  par_notify_email_operator_name varchar,
  par_notify_netsend_operator_name varchar,
  par_notify_page_operator_name varchar,
  par_delete_level integer,
  inout par_category_id integer,
  inout par_notify_email_operator_id integer,
  inout par_notify_netsend_operator_id integer,
  inout par_notify_page_operator_id integer,
  inout par_originating_server varchar,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_date (par_date integer, par_date_name varchar, out returncode integer) STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_job_name varchar,
  inout par_job_id integer,
  par_sqlagent_starting_test varchar,
  inout par_owner_sid char,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_time (
  par_time integer,
  par_time_name varchar,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_jobstep (
  par_job_id integer,
  par_step_id integer,
  par_step_name varchar,
  par_subsystem varchar,
  par_command text,
  par_server varchar,
  par_on_success_action smallint,
  par_on_success_step_id integer,
  par_on_fail_action smallint,
  par_on_fail_step_id integer,
  par_os_run_priority integer,
  par_flags integer,
  par_output_file_name varchar,
  par_proxy_id integer,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_schedule (
  par_schedule_id integer,
  par_name varchar,
  par_enabled smallint,
  par_freq_type integer,
  inout par_freq_interval integer,
  inout par_freq_subday_type integer,
  inout par_freq_subday_interval integer,
  inout par_freq_relative_interval integer,
  inout par_freq_recurrence_factor integer,
  inout par_active_start_date integer,
  inout par_active_start_time integer,
  inout par_active_end_date integer,
  inout par_active_end_time integer,
  par_owner_sid char,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_schedule_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_schedule_name varchar,
  inout par_schedule_id integer,
  inout par_owner_sid char,
  inout par_orig_server_id integer,
  par_job_id_filter integer,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_STRPOS3(p_str text, p_substr text, p_loc int) STABLE;
ALTER FUNCTION sys.babelfish_tomsbit(in_str NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_tomsbit(in_str VARCHAR) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_date_to_string(IN p_datatype TEXT, IN p_dateval DATE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_datetime_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_date(IN p_datestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_time(IN p_datatype TEXT, IN p_timestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_time_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_timeval TIME WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_date(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_date(IN arg anyelement, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_date(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_time(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_time(IN arg anyelement, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_time(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg ANYELEMENT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT, IN arg TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT, IN arg TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_date(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_time(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_datetime(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT, IN p_moneyval PG_CATALOG.MONEY, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT, IN p_floatval FLOAT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_date(IN p_datestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_time(IN p_datatype TEXT, IN p_srctimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION babelfish_get_name_delimiter_pos(name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_split_object_name(name TEXT, OUT db_name TEXT, OUT schema_name TEXT, OUT object_name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_has_any_privilege(userid oid, perm_target_type text, schema_name text, object_name text) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_smallint(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_int(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_bigint(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg TEXT, IN typmod INTEGER) STABLE;
ALTER FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg ANYELEMENT, IN typmod INTEGER) STABLE;
ALTER FUNCTION sys.sysdatetimeoffset() STABLE;
ALTER FUNCTION sys.sysutcdatetime() STABLE;
ALTER FUNCTION sys.getdate() STABLE;
ALTER FUNCTION sys.GETUTCDATE() STABLE;
ALTER FUNCTION sys.isnull(text,text) STABLE;
ALTER FUNCTION sys.isnull(boolean,boolean) STABLE;
ALTER FUNCTION sys.isnull(smallint,smallint) STABLE;
ALTER FUNCTION sys.isnull(integer,integer) STABLE;
ALTER FUNCTION sys.isnull(bigint,bigint) STABLE;
ALTER FUNCTION sys.isnull(real,real) STABLE;
ALTER FUNCTION sys.isnull(double precision, double precision) STABLE;
ALTER FUNCTION sys.isnull(numeric,numeric) STABLE;
ALTER FUNCTION sys.isnull(date, date) STABLE;
ALTER FUNCTION sys.isnull(timestamp,timestamp) STABLE;
ALTER FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) STABLE;
ALTER FUNCTION sys.is_table_type(object_id oid) STABLE;
ALTER FUNCTION sys.rand() STABLE;
ALTER FUNCTION sys.spid() STABLE;
ALTER FUNCTION sys.APPLOCK_MODE(IN "@dbprincipal" varchar(32), IN "@resource" varchar(255), IN "@lockowner" varchar(32)) STABLE;
ALTER FUNCTION sys.APPLOCK_TEST(IN "@dbprincipal" varchar(32), IN "@resource" varchar(255), IN "@lockmode" varchar(32), IN "@lockowner" varchar(32)) STABLE;
ALTER FUNCTION sys.has_dbaccess(database_name SYSNAME) STABLE;
ALTER FUNCTION sys.language() STABLE;
ALTER FUNCTION sys.rowcount() STABLE;
ALTER FUNCTION sys.error() STABLE;
ALTER FUNCTION sys.pgerror() STABLE;
ALTER FUNCTION sys.trancount() STABLE;
ALTER FUNCTION sys.datefirst() STABLE;
ALTER FUNCTION sys.options() STABLE;
ALTER FUNCTION sys.version() STABLE;
ALTER FUNCTION sys.servername() STABLE;
ALTER FUNCTION sys.servicename() STABLE;
ALTER FUNCTION sys.fetch_status() STABLE;
ALTER FUNCTION sys.cursor_rows() STABLE;
ALTER FUNCTION sys.cursor_status(text, text) STABLE;
ALTER FUNCTION sys.xact_state() STABLE;
ALTER FUNCTION sys.error_line() STABLE;
ALTER FUNCTION sys.error_message() STABLE;
ALTER FUNCTION sys.error_number() STABLE;
ALTER FUNCTION sys.error_procedure() STABLE;
ALTER FUNCTION sys.error_severity() STABLE;
ALTER FUNCTION sys.error_state() STABLE;
ALTER FUNCTION sys.babelfish_get_identity_param(IN tablename TEXT, IN optionname TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_identity_current(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_login_default_db(IN login_name TEXT) STABLE;
-- internal table function for querying the registered ENRs
ALTER FUNCTION sys.babelfish_get_enr_list() STABLE;
-- internal table function for collation_list
ALTER FUNCTION sys.babelfish_collation_list() STABLE;
-- internal table function for sp_cursor_list and sp_decribe_cursor
ALTER FUNCTION sys.babelfish_cursor_list(cursor_source integer) STABLE;
-- internal table function for sp_helpdb with no arguments
ALTER FUNCTION sys.babelfish_helpdb() STABLE;
-- internal table function for helpdb with dbname as input
ALTER FUNCTION sys.babelfish_helpdb(varchar) STABLE;

ALTER FUNCTION sys.babelfish_inconsistent_metadata(return_consistency boolean) STABLE;
ALTER FUNCTION COLUMNS_UPDATED () STABLE;
ALTER FUNCTION sys.ident_seed(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.ident_incr(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.ident_current(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.babelfish_waitfor_delay(time_to_pass TEXT) STABLE;
ALTER FUNCTION sys.babelfish_waitfor_delay(time_to_pass TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.user_name_sysname() STABLE;
ALTER FUNCTION sys.system_user() STABLE;
ALTER FUNCTION sys.session_user() STABLE;
ALTER FUNCTION UPDATE (TEXT) STABLE;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
CAST(c2.relname AS sys.sysname) AS PKTABLE_NAME,
CAST(COALESCE(split_part(a2.attoptions[1] COLLATE "C", '=', 2),a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
CAST(c.relname AS sys.sysname) AS FKTABLE_NAME,
CAST(COALESCE(split_part(a.attoptions[1] COLLATE "C", '=', 2),a.attname) AS sys.sysname) AS FKCOLUMN_NAME,
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
	WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR LOWER(pktable_name) = LOWER(@pktable_name))
		AND ((SELECT coalesce(@fktable_name,'')) = '' OR LOWER(fktable_name) = LOWER(@fktable_name))
		AND ((SELECT coalesce(@pktable_owner,'')) = '' OR LOWER(pktable_owner) = LOWER(@pktable_owner))
		AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR LOWER(pktable_qualifier) = LOWER(@pktable_qualifier))
		AND ((SELECT coalesce(@fktable_owner,'')) = '' OR LOWER(fktable_owner) = LOWER(@fktable_owner))
		AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR LOWER(fktable_qualifier) = LOWER(@fktable_qualifier))
	ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;
CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_name'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.systypes_precision_helper(IN type TEXT, IN max_length SMALLINT)
RETURNS SMALLINT
AS $$
DECLARE
	precision SMALLINT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	CASE
	WHEN v_type in ('text', 'ntext', 'image') THEN precision = CAST(NULL AS SMALLINT);
	WHEN v_type in ('nchar', 'nvarchar', 'sysname') THEN precision = max_length/2;
	WHEN v_type = 'sql_variant' THEN precision = 0;
	ELSE
		precision = max_length;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE VIEW sys.systypes AS
SELECT CAST(name as sys.sysname) as name
  , CAST(system_type_id as int) as xtype
  , CAST((case when is_nullable = 1 then 0 else 1 end) as sys.tinyint) as status
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as xusertype
  , max_length as length
  , CAST(precision as sys.tinyint) as xprec
  , CAST(scale as sys.tinyint) as xscale
  , CAST(default_object_id as int) as tdefault
  , CAST(rule_object_id as int) as domain
  , CAST((case when schema_id < 32767 then schema_id::int else null end) as smallint) as uid
  , CAST(0 as smallint) as reserved
  , CAST(sys.CollationProperty(collation_name, 'CollationId') as int) as collationid
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as usertype
  , CAST((case when (coalesce(sys.translate_pg_type_to_tsql(system_type_id), sys.translate_pg_type_to_tsql(user_type_id)) 
            in ('nvarchar', 'varchar', 'sysname', 'varbinary')) then 1 
          else 0 end) as sys.bit) as variable
  , CAST(is_nullable as sys.bit) as allownulls
  , CAST(system_type_id as int) as type
  , CAST(null as sys.varchar(255)) as printfmt
  , (case when precision <> 0::smallint then precision 
      else sys.systypes_precision_helper(sys.translate_pg_type_to_tsql(system_type_id), max_length) end) as prec
  , CAST(scale as sys.tinyint) as scale
  , CAST(collation_name as sys.sysname) as collation
FROM sys.types;
GRANT SELECT ON sys.systypes TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
CAST(coalesce (split_part(a.attoptions[1] COLLATE "C", '=', 2) ,a.attname) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS SMALLINT) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN  a.attidentity <> ''::"char" AND (t1.name = 'decimal' OR t1.name = 'numeric')
	THEN CAST(CONCAT(t1.name, '() identity') AS sys.sysname)
	WHEN  a.attidentity <> ''::"char" AND (t1.name != 'decimal' AND t1.name != 'numeric')
	THEN CAST(CONCAT(t1.name, ' identity') AS sys.sysname)
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
CAST(C.relname AS sys.sysname) AS TABLE_NAME,

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
WHERE has_schema_privilege(s1.schema_id, 'USAGE')
AND X.indislive ;
  
GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC; 

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);