-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.1.0'" to load this file. \quit

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

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate sys.bit) RETURNS DATETIME
AS
$body$
BEGIN
        RAISE EXCEPTION 'Argument data type bit is invalid for argument 2 of dateadd function.';
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
    IF pg_typeof(startdate) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
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


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
DROP FUNCTION sys.pg_extension_config_remove(REGCLASS);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

