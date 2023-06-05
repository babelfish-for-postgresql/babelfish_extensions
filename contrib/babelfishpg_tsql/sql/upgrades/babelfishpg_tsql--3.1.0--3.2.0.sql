-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.2.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

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

CREATE TABLE sys.babelfish_server_options (
	servername sys.SYSNAME NOT NULL PRIMARY KEY COLLATE "C",
	query_timeout INT
);
GRANT SELECT ON sys.babelfish_server_options TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_server_options', '');

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
ALTER FUNCTION sys.nestlevel() RENAME TO nestlevel_deprecated_in_3_2_0;

CREATE OR REPLACE FUNCTION sys.nestlevel() RETURNS INTEGER AS
$$
DECLARE
    stack text;
    result integer;
BEGIN
    GET DIAGNOSTICS stack = PG_CONTEXT;
    result := array_length(string_to_array(stack, 'function'), 1) - 3; 
    IF result < -1 THEN
        RAISE EXCEPTION 'Invalid output, check stack trace %', stack;
    ELSE
        RETURN result;
    END IF;
END;
$$
LANGUAGE plpgsql STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'nestlevel_deprecated_in_3_2_0');

-- SYSUSERS
CREATE OR REPLACE VIEW sys.sysusers AS SELECT
Dbp.principal_id AS uid,
CAST(0 AS INT) AS status,
Dbp.name AS name,
Dbp.sid AS sid,
CAST(NULL AS SYS.VARBINARY(2048)) AS roles,
Dbp.create_date AS createdate,
Dbp.modify_date AS updatedate,
CAST(0 AS INT) AS altuid,
CAST(NULL AS SYS.VARBINARY(256)) AS password,
CAST(0 AS INT) AS gid,
CAST(NULL AS SYS.VARCHAR(85)) AS environ,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.type_desc = 'DATABASE_ROLE'
    THEN 0
  WHEN (Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER') AND Ext.user_can_connect = 1 THEN 1
  ELSE 0
END AS hasdbaccess,
CASE
  WHEN Dbp.name = 'INFORMATION_SCHEMA'
    OR Dbp.name = 'sys'
    OR Dbp.name = 'guest'
    OR Dbp.name = 'dbo' 
    THEN 1
  WHEN Dbp.type_desc = 'WINDOWS_USER' OR Dbp.type_desc = 'SQL_USER' THEN 1
  ELSE 0
END AS islogin,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntname,
CAST(0 AS INT) AS isntgroup,
CASE WHEN Dbp.type_desc = 'WINDOWS_USER' THEN 1 ELSE 0 END AS isntuser,
CASE WHEN Dbp.type_desc = 'SQL_USER' THEN 1 ELSE 0 END AS issqluser,
CAST(0 AS INT) AS isaliased,
CASE WHEN Dbp.type_desc = 'DATABASE_ROLE' THEN 1 ELSE 0 END AS issqlrole,
CAST(0 AS INT) AS isapprole
FROM sys.database_principals AS Dbp LEFT JOIN 
  (SELECT orig_username, user_can_connect FROM sys.babelfish_authid_user_ext 
    WHERE database_name = DB_NAME()) AS Ext
ON Dbp.name = Ext.orig_username;
 
GRANT SELECT ON sys.sysusers TO PUBLIC;

CREATE OR REPLACE VIEW sys.syslanguages
AS
SELECT
    lang_id AS langid,
    CAST(lower(lang_data_jsonb ->> 'date_format'::TEXT) AS SYS.NCHAR(3)) AS dateformat,
    CAST(lang_data_jsonb -> 'date_first'::TEXT AS SYS.TINYINT) AS datefirst,
    CAST(NULL AS INT) AS upgrade,
    CAST(coalesce(lang_name_mssql, lang_name_pg) AS SYS.SYSNAME) AS name,
    CAST(coalesce(lang_alias_mssql, lang_alias_pg) AS SYS.SYSNAME) AS alias,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_names'::TEXT)), ',') AS SYS.NVARCHAR(372)) AS months,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_shortnames'::TEXT)),',') AS SYS.NVARCHAR(132)) AS shortmonths,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'days_shortnames'::TEXT)),',') AS SYS.NVARCHAR(217)) AS days,
    CAST(NULL AS INT) AS lcid,
    CAST(NULL AS SMALLINT) AS msglangid
FROM sys.babelfish_syslanguages;
GRANT SELECT ON sys.syslanguages TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
  SELECT 
  CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,

  CASE WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp'
    THEN 8
    ELSE
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
  END AS PRECISION,

  CASE WHEN a.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
  END AS LENGTH,


  CASE WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
  END AS SCALE,


  CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
  case
    when t4."IS_NULLABLE" = 'YES' then CAST(1 AS smallint)
    else CAST(0 AS smallint)
  end AS NULLABLE,

  CAST(NULL AS varchar(254)) AS remarks,
  CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,

  CASE WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' THEN 8000::INT
    WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,

  CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
  CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME

  FROM pg_catalog.pg_class t1
     JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
     JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
     JOIN information_schema_tsql.columns t4 ON (t1.relname::sys.nvarchar(128) = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)) OR (t4."DATA_TYPE" = 'bytea' AND t5.TYPE_NAME = 'image'))
    AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.columns AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
			CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
			CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
			CAST(a.attnum AS int) AS "ORDINAL_POSITION",
			CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
			CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
				AS varchar(3))
				AS "IS_NULLABLE",

			CAST(
				CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
				WHEN tsql_type_name.tsql_type_name IS NULL THEN format_type(t.oid, NULL::integer)
				ELSE tsql_type_name END
				AS sys.nvarchar(128))
				AS "DATA_TYPE",

			CAST(
				information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_MAXIMUM_LENGTH",

			CAST(
				information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_OCTET_LENGTH",

			CAST(
				/* Handle Tinyint separately */
				information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
				AS sys.tinyint)
				AS "NUMERIC_PRECISION",

			CAST(
				information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
				AS smallint)
				AS "NUMERIC_PRECISION_RADIX",

			CAST(
				information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
				AS int)
				AS "NUMERIC_SCALE",

			CAST(
				information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
				AS smallint)
				AS "DATETIME_PRECISION",

			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
			/*
			 * TODO: We need to first create mapping of collation name to char-set name;
			 * Until then return null.
			 */
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

			/* Returns Babelfish specific collation name. */
			CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN nc.dbname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN ext.orig_name ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN t.typname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_NAME"

	FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
		JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
		JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
		LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
			ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
		LEFT JOIN pg_collation co on co.oid = a.attcollation
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
		information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
		information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
		sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

	WHERE (NOT pg_is_other_temp_schema(nc.oid))
		AND a.attnum > 0 AND NOT a.attisdropped
		AND c.relkind IN ('r', 'v', 'p')
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg anyelement) RETURNS TEXT AS 
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::sys.DATETIME, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::sys.DATETIME, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END 
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(IN datepart PG_CATALOG.TEXT, IN arg anyelement,IN df_tz INTEGER DEFAULT 0) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	first_day DATE;
	first_week_end INTEGER;
	day INTEGER;
    datapart_date sys.DATETIME;
BEGIN
    IF pg_typeof(arg) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,'sys.decimal'::regtype,'numeric'::regtype,
     'float'::regtype, 'double precision'::regtype, 'real'::regtype, 'sys.money'::regtype,'sys.smallmoney'::regtype,'sys.bit'::regtype) THEN
        datapart_date = CAST(arg AS sys.DATETIME);
        CASE datepart
        WHEN 'dow' THEN
            result = (date_part(datepart, datapart_date)::INTEGER - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1;
        WHEN 'tsql_week' THEN
            first_day = make_date(date_part('year', datapart_date)::INTEGER, 1, 1);
            first_week_end = 8 - sys.datepart_internal('dow', first_day)::INTEGER;
            day = date_part('doy', datapart_date)::INTEGER;
            IF day <= first_week_end THEN
                result = 1;
            ELSE
                result = 2 + (day - first_week_end - 1) / 7;
            END IF;
        WHEN 'second' THEN
            result = TRUNC(date_part(datepart, datapart_date))::INTEGER;
        WHEN 'millisecond' THEN
            result = right(date_part(datepart, datapart_date)::TEXT, 3)::INTEGER;
        WHEN 'microsecond' THEN
            result = right(date_part(datepart, datapart_date)::TEXT, 6)::INTEGER;
        WHEN 'nanosecond' THEN
            -- Best we can do - Postgres does not support nanosecond precision
            result = right(date_part('microsecond', datapart_date)::TEXT, 6)::INTEGER * 1000;
        ELSE
            result = date_part(datepart, datapart_date)::INTEGER;
        END CASE;
        RETURN result;
    END IF;
	CASE datepart
	WHEN 'dow' THEN
		result = (date_part(datepart, arg)::INTEGER - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1;
	WHEN 'tsql_week' THEN
		first_day = make_date(date_part('year', arg)::INTEGER, 1, 1);
		first_week_end = 8 - sys.datepart_internal('dow', first_day)::INTEGER;
		day = date_part('doy', arg)::INTEGER;
		IF day <= first_week_end THEN
			result = 1;
		ELSE
			result = 2 + (day - first_week_end - 1) / 7;
		END IF;
	WHEN 'second' THEN
		result = TRUNC(date_part(datepart, arg))::INTEGER;
	WHEN 'millisecond' THEN
		result = right(date_part(datepart, arg)::TEXT, 3)::INTEGER;
	WHEN 'microsecond' THEN
		result = right(date_part(datepart, arg)::TEXT, 6)::INTEGER;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		result = right(date_part('microsecond', arg)::TEXT, 6)::INTEGER * 1000;
	WHEN 'tzoffset' THEN
		-- timezone for datetimeoffset
		result = df_tz;
	ELSE
		result = date_part(datepart, arg)::INTEGER;
	END CASE;
	RETURN result;
EXCEPTION WHEN invalid_parameter_value or feature_not_supported THEN
    -- date_part() throws an exception when trying to get day/month/year etc. from
	-- TIME, so we just need to catch the exception in this case
	-- date_part() returns 0 when trying to get hour/minute/second etc. from
	-- DATE, which is the desirable behavior for datepart() as well.
    -- If the date argument data type does not have the specified datepart,
    -- date_part() will return the default value for that datepart.
    CASE datepart
	-- Case for datepart is year, yy and yyyy, all mappings are defined in gram.y.
    WHEN 'year' THEN RETURN 1900;
    -- Case for datepart is quater, qq and q
    WHEN 'quarter' THEN RETURN 1;
    -- Case for datepart is month, mm and m
    WHEN 'month' THEN RETURN 1;
    -- Case for datepart is day, dd and d
    WHEN 'day' THEN RETURN 1;
    -- Case for datepart is dayofyear, dy
    WHEN 'doy' THEN RETURN 1;
    -- Case for datepart is y(also refers to dayofyear)
    WHEN 'y' THEN RETURN 1;
    -- Case for datepart is week, wk and ww
    WHEN 'tsql_week' THEN RETURN 1;
    -- Case for datepart is iso_week, isowk and isoww
    WHEN 'week' THEN RETURN 1;
    -- Case for datepart is tzoffset and tz
    WHEN 'tzoffset' THEN RETURN 0;
    -- Case for datepart is weekday and dw, return dow according to datefirst
    WHEN 'dow' THEN
        RETURN (1 - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1 ;
	ELSE
        RAISE EXCEPTION '''%'' is not a recognized datepart option', datepart;
        RETURN -1;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate sys.bit) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate numeric) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate real) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate double precision) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_numeric_representation_helper(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS DATETIME AS $$
DECLARE
    digit_to_startdate DATETIME;
BEGIN
    IF pg_typeof(startdate) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,'sys.decimal'::regtype,
    'numeric'::regtype, 'float'::regtype,'double precision'::regtype, 'real'::regtype, 'sys.money'::regtype,'sys.smallmoney'::regtype,'sys.bit'::regtype) THEN
        digit_to_startdate := CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(startdate as sys.DATETIME);
    END IF;

    CASE datepart
	WHEN 'year' THEN
		RETURN digit_to_startdate + make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN digit_to_startdate + make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN digit_to_startdate + make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'day' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'week' THEN
		RETURN digit_to_startdate + make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'hour' THEN
		RETURN digit_to_startdate + make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN digit_to_startdate + make_interval(mins => num);
	WHEN 'second' THEN
		RETURN digit_to_startdate + make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN digit_to_startdate + make_interval(secs => (num::numeric) * 0.001);
	ELSE
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    DIGITREPRESENT_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\-?\d+\.?(?:\d+)?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{6}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{8}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))) AND
             v_res_datatype = 'DATETIME2')
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_timepart := trim(substring(v_datetimestring, HHMMSSFS_PART_REGEXP));
    v_datestring := trim(regexp_replace(v_datetimestring, HHMMSSFS_PART_REGEXP, '', 'gi'));

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF ((v_style IN (127, 130, 131) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
            (v_style IN (130, 131) AND v_res_datatype = 'DATETIME2'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF ((v_datestring ~* pg_catalog.replace(DEFMASK1_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK2_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK3_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK4_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK5_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK6_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK7_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11, 12) AND v_res_datatype = 'DATETIME2'))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10) AND v_date_format <> 'MDY' AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10, 22) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                (v_style IN (1, 10, 22) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   (v_style IN (0, 2, 11) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   (v_style IN (0, 3, 4, 5) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF (v_style = 0 AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'YDM')
            THEN
                IF (v_res_datatype = 'DATETIME2') THEN
                    RAISE character_not_in_repertoire;
                END IF;

                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            ELSE
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
                v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME') THEN
                RAISE invalid_character_value_for_cast;
            END IF;

            v_year := v_rightpart;
            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;

                ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (101, 110) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                       (v_style IN (0, 101, 110) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSE
                    IF (v_res_datatype = 'DATETIME2') THEN
                        RAISE invalid_datetime_format;
                    END IF;

                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
            v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT <= 12) OR v_res_datatype = 'DATETIME2')
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 23, 25, 101, 102, 110, 111, 120, 121, 126, 127) AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM'))
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
            END IF;
        ELSIF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT > 12)
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM')) OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                   (v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_res_datatype <> 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* DIGITREPRESENT_REGEXP)
    THEN
        v_resdatetime = CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + v_datetimestring::NUMERIC;
        RETURN v_resdatetime;
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datetimestring ~* HHMMSSFS_PART_REGEXP AND v_res_datatype = 'DATETIME2') OR
        (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP OR
          v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP OR v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR1_0_REGEXP)) AND
        v_style IN (130, 131))
    THEN
        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
    v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
    v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
    v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

    IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') OR
         (v_res_datatype = 'DATETIME2' AND v_timepart !~* HHMMSSFS_DOT_PART_REGEXP)) AND
        char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        IF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                                 v_hours, v_minutes, v_seconds,
                                                                 rpad(v_fseconds, 3, '0'));
            IF (v_res_datatype = 'SMALLDATETIME' AND
                to_char(v_resdatetime, 'SS') <> '00')
            THEN
                IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
                    v_resdatetime := v_resdatetime + INTERVAL '1 minute';
                END IF;

                v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSIF (v_res_datatype = 'DATETIME2')
        THEN
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);
            v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN datetime_field_overflow THEN
            RAISE invalid_datetime_format;
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_character_value_for_cast;
        END IF;
    END;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_datetime function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to %s.', v_style, v_res_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to SMALLDATETIME data type.'
                                  ELSE 'Conversion failed when converting date and time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a VARCHAR data type to a DATETIME data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date and time.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

-- Mark babelfish_authid_user_ext as configuration table
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_user_ext', '');

-- Function to unmark a configuration table.
-- Currently PG has not exposed this as a function so we have implemented
-- the following function as a wrapper over original PG function.
CREATE OR REPLACE FUNCTION sys.pg_extension_config_remove(IN tableoid REGCLASS)
RETURNS VOID
AS 'babelfishpg_tsql', 'pg_extension_config_remove'
LANGUAGE C VOLATILE;

-- Unmark babelfish_configurations as configuration table
SELECT sys.pg_extension_config_remove('sys.babelfish_configurations');

CREATE AGGREGATE sys.STDEV(float8) (
    SFUNC = float8_accum,
    FINALFUNC = float8_stddev_samp,
    STYPE = float8[],
    COMBINEFUNC = float8_combine,
    PARALLEL = SAFE,
    INITCOND = '{0,0,0}'
);

CREATE AGGREGATE sys.STDEVP(float8) (
    SFUNC = float8_accum,
    FINALFUNC = float8_stddev_pop,
    STYPE = float8[],
    COMBINEFUNC = float8_combine,
    PARALLEL = SAFE,
    INITCOND = '{0,0,0}'
);

CREATE AGGREGATE sys.VAR(float8) (
    SFUNC = float8_accum,
    FINALFUNC = float8_var_samp,
    STYPE = float8[],
    COMBINEFUNC = float8_combine,
    PARALLEL = SAFE,
    INITCOND = '{0,0,0}'
);

CREATE AGGREGATE sys.VARP(float8) (
    SFUNC = float8_accum,
    FINALFUNC = float8_var_pop,
    STYPE = float8[],
    COMBINEFUNC = float8_combine,
    PARALLEL = SAFE,
    INITCOND = '{0,0,0}'
);

CREATE OR REPLACE FUNCTION sys.rowcount_big()
RETURNS BIGINT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

ALTER FUNCTION sys.parsename(VARCHAR,INT) RENAME TO parsename_deprecated_in_3_2_0;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.VARCHAR, object_piece int)
RETURNS sys.SYSNAME
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_2_0');

CREATE OR REPLACE FUNCTION sys.database_principal_id(IN user_name sys.sysname)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION sys.database_principal_id()
RETURNS OID
AS 'babelfishpg_tsql', 'user_id_noarg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

ALTER FUNCTION sys.user_id(TEXT) RENAME TO user_id_deprecated_in_3_2_0;

CREATE OR REPLACE FUNCTION sys.user_id(IN user_name sys.sysname)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION sys.user_id()
RETURNS OID
AS 'babelfishpg_tsql', 'user_id_noarg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'user_id_deprecated_in_3_2_0');

ALTER FUNCTION sys.tsql_stat_get_activity(text) RENAME TO tsql_stat_get_activity_deprecated_in_3_2_0;
CREATE OR REPLACE FUNCTION sys.tsql_stat_get_activity_deprecated_in_3_2_0(
  IN view_name text,
  OUT procid int,
  OUT client_version int,
  OUT library_name VARCHAR(32),
  OUT language VARCHAR(128),
  OUT quoted_identifier bool,
  OUT arithabort bool,
  OUT ansi_null_dflt_on bool,
  OUT ansi_defaults bool,
  OUT ansi_warnings bool,
  OUT ansi_padding bool,
  OUT ansi_nulls bool,
  OUT concat_null_yields_null bool,
  OUT textsize int,
  OUT datefirst int,
  OUT lock_timeout int,
  OUT transaction_isolation int2,
  OUT client_pid int,
  OUT row_count bigint,
  OUT error int,
  OUT trancount int,
  OUT protocol_version int,
  OUT packet_size int,
  OUT encrypyt_option VARCHAR(40),
  OUT database_id int2,
  OUT host_name varchar(128))
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_stat_get_activity_deprecated_in_3_2_0'
LANGUAGE C VOLATILE STRICT;
CREATE OR REPLACE FUNCTION sys.tsql_stat_get_activity(
  IN view_name text,
  OUT procid int,
  OUT client_version int,
  OUT library_name VARCHAR(32),
  OUT language VARCHAR(128),
  OUT quoted_identifier bool,
  OUT arithabort bool,
  OUT ansi_null_dflt_on bool,
  OUT ansi_defaults bool,
  OUT ansi_warnings bool,
  OUT ansi_padding bool,
  OUT ansi_nulls bool,
  OUT concat_null_yields_null bool,
  OUT textsize int,
  OUT datefirst int,
  OUT lock_timeout int,
  OUT transaction_isolation int2,
  OUT client_pid int,
  OUT row_count bigint,
  OUT error int,
  OUT trancount int,
  OUT protocol_version int,
  OUT packet_size int,
  OUT encrypyt_option VARCHAR(40),
  OUT database_id int2,
  OUT host_name varchar(128),
  OUT context_info bytea)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_stat_get_activity'
LANGUAGE C VOLATILE STRICT;

ALTER VIEW sys.sysprocesses RENAME TO sysprocesses_deprecated_in_3_2_0;
create or replace view sys.sysprocesses_deprecated_in_3_2_0 as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , a.state as status
  , null::bytea as sid
  , CAST(t.host_name AS sys.nchar(128)) as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , null::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity_deprecated_in_3_2_0('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database(); /* current physical database will always be babelfish database */
GRANT SELECT ON sys.sysprocesses_deprecated_in_3_2_0 TO PUBLIC;
create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , a.state as status
  , null::bytea as sid
  , CAST(t.host_name AS sys.nchar(128)) as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , t.context_info::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database(); /* current physical database will always be babelfish database */
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

ALTER VIEW sys.dm_exec_sessions RENAME TO dm_exec_sessions_deprecated_in_3_2_0;
create or replace view sys.dm_exec_sessions_deprecated_in_3_2_0
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , d.host_name::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , null::sys.nvarchar(128) as context_info
    , null::integer as cpu_time
    , null::integer as memory_usage
    , null::integer as total_scheduled_time
    , null::integer as total_elapsed_time
    , a.client_port as endpoint_id
    , a.query_start::sys.datetime as last_request_start_time
    , a.state_change::sys.datetime as last_request_end_time
    , null::bigint as "reads"
    , null::bigint as "writes"
    , null::bigint as logical_reads
    , case when a.client_port > 0 then 1::sys.bit else 0::sys.bit end as is_user_process
    , d.textsize as text_size
    , d.language::sys.nvarchar(128) as language
    , 'ymd'::sys.nvarchar(3) as date_format-- Bld 173 lacks support for SET DATEFORMAT and always expects ymd
    , d.datefirst::smallint as date_first -- Bld 173 lacks support for SET DATEFIRST and always returns 7
    , CAST(CAST(d.quoted_identifier as integer) as sys.bit) as quoted_identifier
    , CAST(CAST(d.arithabort as integer) as sys.bit) as arithabort
    , CAST(CAST(d.ansi_null_dflt_on as integer) as sys.bit) as ansi_null_dflt_on
    , CAST(CAST(d.ansi_defaults as integer) as sys.bit) as ansi_defaults
    , CAST(CAST(d.ansi_warnings as integer) as sys.bit) as ansi_warnings
    , CAST(CAST(d.ansi_padding as integer) as sys.bit) as ansi_padding
    , CAST(CAST(d.ansi_nulls as integer) as sys.bit) as ansi_nulls
    , CAST(CAST(d.concat_null_yields_null as integer) as sys.bit) as concat_null_yields_null
    , d.transaction_isolation::smallint as transaction_isolation_level
    , d.lock_timeout as lock_timeout
    , 0 as deadlock_priority
    , d.row_count as row_count
    , d.error as prev_error
    , null::sys.varbinary(85) as original_security_id
    , a.usename::sys.nvarchar(128) as original_login_name
    , null::sys.datetime as last_successful_logon
    , null::sys.datetime as last_unsuccessful_logon
    , null::bigint as unsuccessful_logons
    , null::int as group_id
    , d.database_id::smallint as database_id
    , 0 as authenticating_database_id
    , d.trancount as open_transaction_count
  from pg_catalog.pg_stat_activity AS a
  RIGHT JOIN sys.tsql_stat_get_activity_deprecated_in_3_2_0('sessions') AS d ON (a.pid = d.procid);
GRANT SELECT ON sys.dm_exec_sessions_deprecated_in_3_2_0 TO PUBLIC;
create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , d.host_name::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , d.context_info::sys.varbinary(128) as context_info
    , null::integer as cpu_time
    , null::integer as memory_usage
    , null::integer as total_scheduled_time
    , null::integer as total_elapsed_time
    , a.client_port as endpoint_id
    , a.query_start::sys.datetime as last_request_start_time
    , a.state_change::sys.datetime as last_request_end_time
    , null::bigint as "reads"
    , null::bigint as "writes"
    , null::bigint as logical_reads
    , case when a.client_port > 0 then 1::sys.bit else 0::sys.bit end as is_user_process
    , d.textsize as text_size
    , d.language::sys.nvarchar(128) as language
    , 'ymd'::sys.nvarchar(3) as date_format-- Bld 173 lacks support for SET DATEFORMAT and always expects ymd
    , d.datefirst::smallint as date_first -- Bld 173 lacks support for SET DATEFIRST and always returns 7
    , CAST(CAST(d.quoted_identifier as integer) as sys.bit) as quoted_identifier
    , CAST(CAST(d.arithabort as integer) as sys.bit) as arithabort
    , CAST(CAST(d.ansi_null_dflt_on as integer) as sys.bit) as ansi_null_dflt_on
    , CAST(CAST(d.ansi_defaults as integer) as sys.bit) as ansi_defaults
    , CAST(CAST(d.ansi_warnings as integer) as sys.bit) as ansi_warnings
    , CAST(CAST(d.ansi_padding as integer) as sys.bit) as ansi_padding
    , CAST(CAST(d.ansi_nulls as integer) as sys.bit) as ansi_nulls
    , CAST(CAST(d.concat_null_yields_null as integer) as sys.bit) as concat_null_yields_null
    , d.transaction_isolation::smallint as transaction_isolation_level
    , d.lock_timeout as lock_timeout
    , 0 as deadlock_priority
    , d.row_count as row_count
    , d.error as prev_error
    , null::sys.varbinary(85) as original_security_id
    , a.usename::sys.nvarchar(128) as original_login_name
    , null::sys.datetime as last_successful_logon
    , null::sys.datetime as last_unsuccessful_logon
    , null::bigint as unsuccessful_logons
    , null::int as group_id
    , d.database_id::smallint as database_id
    , 0 as authenticating_database_id
    , d.trancount as open_transaction_count
  from pg_catalog.pg_stat_activity AS a
  RIGHT JOIN sys.tsql_stat_get_activity('sessions') AS d ON (a.pid = d.procid);
GRANT SELECT ON sys.dm_exec_sessions TO PUBLIC;

create or replace view sys.dm_exec_connections
 as
 select a.pid as session_id
   , a.pid as most_recent_session_id
   , a.backend_start::sys.datetime as connect_time
   , 'TCP'::sys.nvarchar(40) as net_transport
   , 'TSQL'::sys.nvarchar(40) as protocol_type
   , d.protocol_version as protocol_version
   , 4 as endpoint_id
   , d.encrypyt_option::sys.nvarchar(40) as encrypt_option
   , null::sys.nvarchar(40) as auth_scheme
   , null::smallint as node_affinity
   , null::int as num_reads
   , null::int as num_writes
   , null::sys.datetime as last_read
   , null::sys.datetime as last_write
   , d.packet_size as net_packet_size
   , a.client_addr::varchar(48) as client_net_address
   , a.client_port as client_tcp_port
   , null::varchar(48) as local_net_address
   , null::int as local_tcp_port
   , null::sys.uniqueidentifier as connection_id
   , null::sys.uniqueidentifier as parent_connection_id
   , a.pid::sys.varbinary(64) as most_recent_sql_handle
 from pg_catalog.pg_stat_activity AS a
 RIGHT JOIN sys.tsql_stat_get_activity('connections') AS d ON (a.pid = d.procid);
GRANT SELECT ON sys.dm_exec_connections TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sysprocesses_deprecated_in_3_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'dm_exec_sessions_deprecated_in_3_2_0');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_stat_get_activity_deprecated_in_3_2_0');

CREATE OR REPLACE FUNCTION sys.bbf_get_context_info()
RETURNS sys.VARBINARY(128) AS 'babelfishpg_tsql', 'bbf_get_context_info' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.context_info()
RETURNS sys.VARBINARY(128)
AS '{"version_num": "1", "typmod_array": ["128"], "original_probin": ""}',
$$
BEGIN
    return sys.bbf_get_context_info()
END;
$$
LANGUAGE pltsql STABLE;

CREATE OR REPLACE PROCEDURE sys.bbf_set_context_info(IN context_info sys.VARBINARY(128))
AS 'babelfishpg_tsql' LANGUAGE C;

ALTER FUNCTION sys.json_modify RENAME TO json_modify_deprecated_in_3_2_0;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'json_modify_deprecated_in_3_2_0');

/*
 * JSON MODIFY
 * This function is used to update the value of a property in a JSON string and returns the updated JSON string.
 * It has been implemented in three parts:
 *  1) Set the append and create_if_missing flag as postgres functions do not directly take append and lax/strict mode in the jsonb_path.
 *  2) To convert the input path into the expected jsonb_path.
 *  3) To implement the main logic of the JSON_MODIFY function by dividing it into 8 different cases.
 */
CREATE OR REPLACE FUNCTION sys.json_modify(in expression sys.NVARCHAR,in path_json TEXT, in new_value ANYELEMENT, in escape bool)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    json_path TEXT;
    json_path_convert TEXT;
    new_jsonb_path TEXT[];
    key_value_type TEXT;
    path_split_array TEXT[];
    comparison_string TEXT COLLATE "C";
    len_array INTEGER;
    word_count INTEGER;
    create_if_missing BOOL = TRUE;
    append_modifier BOOL = FALSE;
    key_exists BOOL;
    key_value JSONB;
    json_expression JSONB = expression::JSONB;
    json_new_value JSONB;
    result_json sys.NVARCHAR;
BEGIN
    path_split_array = regexp_split_to_array(TRIM(path_json) COLLATE "C",'\s+');
    word_count = array_length(path_split_array,1);
    /*
     * This if else block is added to set the create_if_missing and append_modifier flags.
     * These flags will be used to know the mode and if the optional modifier append is present in the input path_json.
     * It is necessary as postgres functions do not directly take append and lax/strict mode in the jsonb_path.
     * Comparisons for comparison_string are case-sensitive.
     */
    IF word_count = 1 THEN
        json_path = path_split_array[1];
        create_if_missing = TRUE;
        append_modifier = FALSE;
    ELSIF word_count = 2 THEN
        json_path = path_split_array[2];
        comparison_string = path_split_array[1]; -- append or lax/strict mode
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSIF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSIF word_count = 3 THEN
        json_path = path_split_array[3];
        comparison_string = path_split_array[1]; -- append mode
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
        comparison_string = path_split_array[2]; -- lax/strict mode
        IF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSE
        RAISE invalid_json_text;
    END IF;

    -- To convert input jsonpath to the required jsonb_path format
    json_path_convert = regexp_replace(json_path, '\$\.|]|\$\[' , '' , 'ig'); -- To remove "$." and "]" sign from the string 
    json_path_convert = regexp_replace(json_path_convert, '\.|\[' , ',' , 'ig'); -- To replace "." and "[" with "," to change into required format
    new_jsonb_path = CONCAT('{',json_path_convert,'}'); -- Final required format of path by jsonb_set

    key_exists = jsonb_path_exists(json_expression,json_path::jsonpath); -- To check if key exist in the given path

    IF escape THEN
        json_new_value = new_value::JSONB;
    ELSE
        json_new_value = to_jsonb(new_value);
    END IF;

    --This if else block is to call the jsonb_set function based on the create_if_missing and append_modifier flags
    IF append_modifier THEN
        IF key_exists THEN
            key_value = jsonb_path_query_first(json_expression,json_path::jsonpath); -- To get the value of the key
            key_value_type = jsonb_typeof(key_value);
            IF key_value_type = 'array' THEN
                len_array = jsonb_array_length(key_value);
                /*
                 * As jsonb_insert requires the index of the value to be inserted, so the below FORMAT function changes the path format into the required jsonb_insert path format.
                 * Eg: JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure'); -> converts the path from '$.skills' to '{skills,2}' instead of '{skills}'
                 */
                new_jsonb_path = FORMAT('%s,%s}',TRIM('}' FROM new_jsonb_path::TEXT),len_array);
                IF new_value IS NULL THEN
                    result_json = jsonb_insert(json_expression,new_jsonb_path,'null'); -- This needs to be done because "to_jsonb(coalesce(new_value, 'null'))" does not result in a JSON NULL
                ELSE
                    result_json = jsonb_insert(json_expression,new_jsonb_path,json_new_value);
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_array_not_found;
                ELSE
                    result_json = json_expression;
                END IF;
            END IF;
        ELSE
            IF NOT create_if_missing THEN
                RAISE sql_json_object_not_found;
            ELSE
                result_json = jsonb_insert(json_expression,new_jsonb_path,to_jsonb(array_agg(new_value))); -- array_agg is used to convert the new_value text into array format as we append functionality is being used
            END IF;
        END IF;
    ELSE --When no append modifier is present
        IF new_value IS NOT NULL THEN
            IF key_exists OR create_if_missing THEN
                result_json = jsonb_set_lax(json_expression,new_jsonb_path,json_new_value,create_if_missing);
            ELSE
                RAISE sql_json_object_not_found;
            END IF;
        ELSE
            IF key_exists THEN
                IF NOT create_if_missing THEN
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,json_new_value);
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,json_new_value,create_if_missing,'delete_key');
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_object_not_found;
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,json_new_value,FALSE);
                END IF;
            END IF;
        END IF;
    END IF;  -- If append_modifier block ends here
    RETURN result_json;
EXCEPTION
    WHEN invalid_json_text THEN
            RAISE USING MESSAGE = 'JSON path is not properly formatted',
                        DETAIL = FORMAT('Unexpected keyword "%s" is found.',comparison_string),
                        HINT = 'Change "modifier/mode" parameter to the proper value and try again.';
    WHEN sql_json_array_not_found THEN
            RAISE USING MESSAGE = 'array cannot be found in the specified JSON path',
                        HINT = 'Change JSON path to target array property and try again.';
    WHEN sql_json_object_not_found THEN
            RAISE USING MESSAGE = 'property cannot be found on the specified JSON path';
END;
$BODY$
LANGUAGE plpgsql STABLE;

/*
    This function is needed when input date is datetimeoffset type. When running the following query in postgres using tsql dialect, it failed.
        select dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset);
    We tried to merge this function with sys.dateadd_internal by using '+' when adding interval to datetimeoffset, 
    but the error shows : operator does not exist: sys.datetimeoffset + interval. As the result, we should not use '+' directly
    but should keep using OPERATOR(sys.+) when input date is in datetimeoffset type.
*/
CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset) RETURNS datetimeoffset AS $$
DECLARE
	timezone INTEGER;
BEGIN
	timezone = sys.babelfish_get_datetimeoffset_tzoffset(startdate)::INTEGER * 2;
	startdate = startdate OPERATOR(sys.+) make_interval(mins => timezone);
	CASE datepart
	WHEN 'year' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.001);
	WHEN 'microsecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.000001);
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		RETURN startdate OPERATOR(sys.+) make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
	ELSE
		RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

-- DATABASE_PRINCIPALS: Include Hard coded public, sys, INFORMATION_SCHEMA users
ALTER VIEW sys.database_principals RENAME TO database_principals_deprecated_3_2_0;

CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME()
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(-1 AS INT) AS principal_id,
CAST(type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN type = 'S' THEN 'SQL_USER'
    WHEN type = 'R' THEN 'DATABASE_ROLE'
    WHEN type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_schema_name,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(-1 AS INT) AS owning_principal_id,
CAST(CAST(0 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(0 AS SYS.BIT) AS is_fixed_role,
CAST(-1 AS INT) AS authentication_type,
CAST(NULL AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(-1 AS INT) AS default_language_lcid,
CAST(0 AS SYS.BIT) AS allow_encrypted_value_modifications
FROM (VALUES ('public', 'R'), ('sys', 'S'), ('INFORMATION_SCHEMA', 'S')) as dummy_principals(name, type);

GRANT SELECT ON sys.database_principals TO PUBLIC;
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'database_principals_deprecated_3_2_0');

-- SYSLOGINS
CREATE OR REPLACE VIEW sys.syslogins
AS SELECT 
Base.sid AS sid,
CAST(9 AS SYS.TINYINT) AS status,
Base.create_date AS createdate,
Base.modify_date AS updatedate,
Base.create_date AS accdate,
CAST(0 AS INT) AS totcpu,
CAST(0 AS INT) AS totio,
CAST(0 AS INT) AS spacelimit,
CAST(0 AS INT) AS timelimit,
CAST(0 AS INT) AS resultlimit,
Base.name AS name,
Base.default_database_name AS dbname,
Base.default_language_name AS default_language_name,
CAST(Base.name AS SYS.NVARCHAR(128)) AS loginname,
CAST(NULL AS SYS.NVARCHAR(128)) AS password,
CAST(0 AS INT) AS denylogin,
CAST(1 AS INT) AS hasaccess,
CAST( 
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' OR Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
AS INT) AS isntname,
CAST(
   CASE 
    WHEN Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
  AS INT) AS isntgroup,
CAST(
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' THEN 1 
    ELSE 0
  END
AS INT) AS isntuser,
CAST(
    CASE
        WHEN is_srvrolemember('sysadmin', Base.name) = 1 THEN 1
        ELSE 0
    END
AS INT) AS sysadmin,
CAST(0 AS INT) AS securityadmin,
CAST(0 AS INT) AS serveradmin,
CAST(0 AS INT) AS setupadmin,
CAST(0 AS INT) AS processadmin,
CAST(0 AS INT) AS diskadmin,
CAST(0 AS INT) AS dbcreator,
CAST(0 AS INT) AS bulkadmin
FROM sys.server_principals AS Base
WHERE Base.type in ('S', 'U');

GRANT SELECT ON sys.syslogins TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id         AS object_id,
        o.schema_id         AS schema_id,
        c.column_id         AS colid,
        CASE WHEN p.attoptions[1] LIKE 'bbf_original_name=%' THEN CAST(split_part(p.attoptions[1], '=', 2) AS sys.VARCHAR)
			ELSE c.name COLLATE sys.database_default END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname COLLATE sys.database_default AND c.object_id = p.attrelid)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;

CREATE OR REPLACE VIEW sys.sp_databases_view AS
	SELECT CAST(database_name AS sys.SYSNAME),
	-- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
	CASE WHEN (sum(table_size)::NUMERIC/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
		ELSE CAST((sum(table_size)::NUMERIC/1024.0) AS int) END as database_size,
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
		LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid where pg_catalog.pg_class.relkind = 'r'
	) t
	GROUP BY database_name
	ORDER BY database_name;

CREATE OR REPLACE PROCEDURE sys.sp_serveroption( IN "@server" sys.sysname,
                                                    IN "@optname" sys.varchar(35),
                                                    IN "@optvalue" sys.varchar(10))
AS 'babelfishpg_tsql', 'sp_serveroption_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_serveroption( IN "@server" sys.sysname,
                                                    IN "@optname" sys.varchar(35),
                                                    IN "@optvalue" sys.varchar(10))
TO PUBLIC;

ALTER FUNCTION sys.datetime2fromparts(NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC) RENAME TO datetime2fromparts_deprecated_3_2;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datetime2fromparts_deprecated_3_2');

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_day NUMERIC,
                                                                IN p_hour NUMERIC,
                                                                IN p_minute NUMERIC,
                                                                IN p_seconds NUMERIC,
                                                                IN p_fractions NUMERIC,
                                                                IN p_precision NUMERIC)
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
   v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
   v_precision := p_precision::SMALLINT;

   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
       (p_month::SMALLINT NOT BETWEEN 1 AND 12) OR
       (p_day::SMALLINT NOT BETWEEN 1 AND 31) OR
       (p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
       (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
       (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > v_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := pg_catalog.format('%s.%s',
                            floor(p_seconds)::SMALLINT,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, v_precision))::NUMERIC;

   v_resdatetime := make_timestamp(floor(p_year)::SMALLINT,
                         floor(p_month)::SMALLINT,
                         floor(p_day)::SMALLINT,
                         floor(p_hour)::SMALLINT,
                         floor(p_minute)::SMALLINT,
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
      v_err_message := upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                  HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour NUMERIC,
                                                           IN p_minute NUMERIC,
                                                           IN p_seconds NUMERIC,
                                                           IN p_fractions NUMERIC,
                                                           IN p_precision NUMERIC)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_fractions VARCHAR;
    v_precision SMALLINT;
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
BEGIN
    v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF ((p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
           (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
           (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > v_precision))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;

    v_calc_seconds := pg_catalog.format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, v_precision))::NUMERIC;

    RETURN make_time(floor(p_hour)::SMALLINT,
                     floor(p_minute)::SMALLINT,
                     v_calc_seconds);
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
        RAISE USING MESSAGE := 'Cannot construct data type time, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                    HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_word_parse(
	IN "@input" sys.nvarchar(776),
	IN "@objtype" sys.varchar(13),
	INOUT "@subname" sys.nvarchar(776),
	INOUT "@curr_relname" sys.nvarchar(776),
	INOUT "@schemaname" sys.nvarchar(776),
	INOUT "@dbname" sys.nvarchar(776)
)
AS $$
BEGIN
	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row, * 
	INTO #sp_rename_temptable 
	FROM STRING_SPLIT(@input, '.') ORDER BY row DESC;

	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as id, * 
	INTO #sp_rename_temptable2 
	FROM #sp_rename_temptable;
	
	DECLARE @row_count INT;
	SELECT @row_count = COUNT(*) FROM #sp_rename_temptable2;

	IF @objtype = 'COLUMN'
		BEGIN
			IF @row_count = 1
				BEGIN
					THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.', 1;
				END
			ELSE IF @row_count > 4
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					IF @row_count > 1
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SELECT @curr_relname = value FROM #sp_rename_temptable2 WHERE id = 2;
							SET @schemaname = sys.schema_name();

						END
					IF @row_count > 2
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 3;
						END
					IF @row_count > 3
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 4;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
	ELSE
		BEGIN
			IF @row_count > 3
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					SET @curr_relname = NULL;
					IF @row_count > 0
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SET @schemaname = sys.schema_name();
						END
					IF @row_count > 1
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 2;
						END
					IF @row_count > 2
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 3;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_word_parse(IN sys.nvarchar(776), IN sys.varchar(13), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776)) TO PUBLIC;

ALTER PROCEDURE sys.babelfish_sp_rename_internal RENAME TO babelfish_sp_rename_internal_deprecated_in_3_2_0;
ALTER PROCEDURE sys.sp_rename RENAME TO sp_rename_deprecated_in_3_2_0;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_internal(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@schemaname" sys.nvarchar(776),
	IN "@objtype" char(2) DEFAULT NULL,
	IN "@curr_relname" sys.nvarchar(776) DEFAULT NULL
) AS 'babelfishpg_tsql', 'sp_rename_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776) = NULL,
	IN "@newname" sys.SYSNAME = NULL,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	ELSE IF @objtype = 'INDEX'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Index', 1;
		END
	ELSE IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
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
					SELECT @col_count = COUNT(*)FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @curr_relname and COLUMN_NAME = @subname;
					IF @col_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'CO';
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
					WHERE s1.name = @schemaname AND o1.name = @subname;
					SELECT @count = COUNT(*) FROM #tempTable;

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
							SELECT @physical_schema_name = nspname FROM sys.babelfish_namespace_ext WHERE dbid = cast(sys.db_id() as oid) AND orig_name = @schemaname;
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

CREATE OR REPLACE VIEW sys.servers
AS
SELECT
  CAST(f.oid as int) AS server_id,
  CAST(f.srvname as sys.sysname) AS name,
  CAST('' as sys.sysname) AS product,
  CAST('tds_fdw' as sys.sysname) AS provider,
  CAST((select string_agg(
                  case
                  when option like 'servername=%%' then substring(option, 12)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
  CAST(NULL as sys.nvarchar(4000)) AS location,
  CAST(NULL as sys.nvarchar(4000)) AS provider_string,
  CAST((select string_agg(
                  case
                  when option like 'database=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
  CAST(0 as int) AS connect_timeout,
  CAST(s.query_timeout as int) AS query_timeout,
  CAST(1 as sys.bit) AS is_linked,
  CAST(0 as sys.bit) AS is_remote_login_enabled,
  CAST(0 as sys.bit) AS is_rpc_out_enabled,
  CAST(1 as sys.bit) AS is_data_access_enabled,
  CAST(0 as sys.bit) AS is_collation_compatible,
  CAST(1 as sys.bit) AS uses_remote_collation,
  CAST(NULL as sys.sysname) AS collation_name,
  CAST(0 as sys.bit) AS lazy_schema_validation,
  CAST(0 as sys.bit) AS is_system,
  CAST(0 as sys.bit) AS is_publisher,
  CAST(0 as sys.bit) AS is_subscriber,
  CAST(0 as sys.bit) AS is_distributor,
  CAST(0 as sys.bit) AS is_nonsql_subscriber,
  CAST(1 as sys.bit) AS is_remote_proc_transaction_promotion_enabled,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_rda_server
FROM pg_foreign_server AS f
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
LEFT JOIN sys.babelfish_server_options AS s on f.srvname = s.servername
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.openquery_internal(
IN linked_server text,
IN query text)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'openquery_internal'
LANGUAGE C VOLATILE;

CALL sys.babelfish_drop_deprecated_object('procedure', 'sys', 'babelfish_sp_rename_internal_deprecated_in_3_2_0');
CALL sys.babelfish_drop_deprecated_object('procedure', 'sys', 'sp_rename_deprecated_in_3_2_0');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'openquery');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
DROP FUNCTION sys.pg_extension_config_remove(REGCLASS);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
