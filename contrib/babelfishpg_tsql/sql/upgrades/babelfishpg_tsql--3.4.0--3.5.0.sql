-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.4.0'" to load this file. \quit

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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */


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
LANGUAGE plpgsql IMMUTABLE
RENAME TO datepart_internal_deprecated_3_5;



CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datepart_internal_deprecated_3_5');


CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.BIT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.SMALLMONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_money'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.TINYINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date SMALLINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date date ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_date'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.datetime ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_datetime'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.datetime2 ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_datetime'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.smalldatetime ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_smalldatetime'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.DATETIMEOFFSET ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_datetimeoffset'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date time ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_time'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INTERVAL ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_interval'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.DECIMAL ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_decimal'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date REAL ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_real'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date NUMERIC ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_numeric'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date FLOAT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_float'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date BIGINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.MONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_money'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
