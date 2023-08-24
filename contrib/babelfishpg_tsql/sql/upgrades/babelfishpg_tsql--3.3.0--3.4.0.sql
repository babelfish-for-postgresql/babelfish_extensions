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

-- 3531 "sql/sys_functions.sql"
-- Another defination of date_bucket() to match error messages for unknown date datatype as ANYELEMNT does not support unknown datatype.
CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date PG_CATALOG.TEXT, IN origin PG_CATALOG.TEXT default NULL) RETURNS PG_CATALOG.TEXT 
AS 
$body$
DECLARE
BEGIN
    IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION '% is not a recognized Date_Bucket option.', datepart;
    END IF;
    IF (number IS NULL) THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 2 of Date_Bucket function.';
    END IF;
    IF date IS NULL THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 3 of Date_Bucket function.';
    ELSE
        RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of Date_Bucket function.', pg_typeof(date);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date ANYELEMENT, IN origin ANYELEMENT default NULL) RETURNS ANYELEMENT 
AS 
$body$
DECLARE
    required_bucket INT;
    years_diff INT;
    months_diff INT;
    hours_diff INT;
    minutes_diff INT;
    seconds_diff INT;
    milliseconds_diff INT;
    timezone INT;
    result_time time;
    result_date timestamp;
    offset_string PG_CATALOG.text;
    date_difference_interval INTERVAL;
BEGIN
    BEGIN
        /*
        * Check for supported datepart by date_bucket function
        */
        IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION '% is not a recognized Date_Bucket option.', datepart;
        END IF;

        /*
        * Check for NULL or negative value of number argument
        */
        IF (number IS NULL) THEN
            RAISE EXCEPTION 'Argument data type NULL is invalid for argument 2 of Date_Bucket function.';
        END IF;
        IF (number <= 0 ) THEN
            RAISE EXCEPTION 'Invalid bucket width value passed to date_bucket function. Only positive values are allowed.';
        END IF;

        /*
        * Raise exception if any unsupported datatype for date is provided. 
        * For example throw exception if INT datatype is provided in date. 
        */
        IF pg_typeof(date) NOT IN ('sys.datetime'::regtype, 'sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype, 'date'::regtype, 'time'::regtype) THEN
            RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of Date_Bucket function.', pg_typeof(date);
        END IF;

        /*
        * Raise Exception if any unsupported datepart for date is provided. 
        * Date does not support hour, minute, second, millisecond datepart
        * Time does not support year, month, quarter, day, week datepart
        */
        IF pg_typeof(date) = 'date'::regtype AND
            datepart IN ('hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type date.', datepart;
        END IF;
        IF pg_typeof(date) = 'time'::regtype AND
            datepart IN ('year', 'quarter', 'month', 'day', 'week') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type time.', datepart;
        END IF;

        /*
        * If optional argument origin's value is not provided by user then set it's default value of valid datatype.
        */
        IF origin IS NULL THEN
                IF pg_typeof(date) = 'sys.datetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF pg_typeof(date) = 'sys.datetime2'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF pg_typeof(date) = 'sys.datetimeoffset'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF pg_typeof(date) = 'sys.smalldatetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSEIF pg_typeof(date) = 'date'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSEIF pg_typeof(date) = 'time'::regtype THEN
                    origin := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        ELSE
                IF (pg_typeof(origin) != pg_typeof(date)) THEN
                    RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of Date_Bucket function.', pg_typeof(origin);
                END IF;
        END IF;
    END;
    -- Here date_bucket calculation for time datatype
    IF pg_typeof(date) = 'time'::regtype THEN
    -- Find interval between date and origin and extract hour, minute, second, millisecond from the interval
        date_difference_interval := date - origin;
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := FLOOR(EXTRACT('millisecond' from date_difference_interval))::INT;
        CASE datepart
        WHEN 'hour' THEN
            /*
            * The difference between date and origin in hours is hours_diff. 
            * Here we find the number of buckets between date and origin. 
            * Add the required buckets in origin to reach at date.
            * Check if the calculated result (result_time) is not exceeding date (this might happen when user provide input where date < origin)
            * Take example 'date_bucket(hour, 2, '01:00:00', '08:00:00')'
            * Interval = '-7 hours 0 minutes'
            * required_bucket = -7/2 = -3
            * result_time = '08:00:00' + '-6 hours' => '02:00:00'
            * As in the above example result_time > date, so we go back by 1 bucket. '02:00:00' - '2 hours'  => '00:00:00'
            */
            required_bucket := hours_diff / number;
            result_time := origin + (concat(required_bucket * number, ' ', 'hours')::interval);
            IF result_time > date THEN
                return result_time - (concat(number, ' ', 'hours')::interval);
            END IF;
            return result_time;

        WHEN 'minute' THEN
            /*
            * Calculate the difference between date and origin in minutes. 
            * The rest step are similar as of case where datepart is 'hour'
            */
            required_bucket := (hours_diff * 60 + minutes_diff) / number;
            result_time := origin + (concat(required_bucket * number, ' ', 'minutes')::interval);
            IF result_time > date THEN
                return result_time - (concat(number, ' ', 'minutes')::interval);
            END IF;
            return result_time;

        WHEN 'second' THEN
            /*
            * Calculate the difference between date and origin in seconds. 
            * The rest step are similar as of case where datepart is 'hour'
            */
            required_bucket := ((hours_diff * 60 + minutes_diff) * 60 + seconds_diff) / number;
            result_time := origin + (concat(required_bucket * number, ' ', 'seconds')::interval);
            IF result_time > date THEN
                return result_time - (concat(number, ' ', 'seconds')::interval);
            END IF;
            return result_time;

        WHEN 'millisecond' THEN
            /*
            * Calculate the difference between date and origin in milliseconds. 
            * The rest step are similar as of case where datepart is 'hour'
            */
            required_bucket := (((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff) / number;
            result_time := origin + (concat(required_bucket * number, ' ', 'milliseconds')::interval);
            IF result_time > date THEN
                return result_time - (concat(number, ' ', 'milliseconds')::interval);
            END IF;
            return result_time;
        END CASE;

    -- For other date datatype (date, datetime, datetime2, smalldatetime, datetimeoffset) date_bucket calculation goes here
    -- Only for datepart year, quarter, month as rest of the datepart are supported by date_bin() function below.
    ELSIF (datepart IN ('year', 'quarter', 'month')) THEN
        date_difference_interval := AGE(date :: timestamp, origin :: timestamp );
        years_diff := EXTRACT('Year' from date_difference_interval ) :: INT;
        months_diff := EXTRACT('Month' from date_difference_interval ) :: INT;
        CASE datepart
        WHEN 'year' THEN
            /*
            * The difference between date and origin in years is years_diff. 
            * Here we find the number of buckets between date and origin. 
            * Now we add the required buckets in origin to reach at date.
            * Check if the calculated result (result_time) is not exceeding date (this might happen when user provide input where date < origin)
            * Take example 'date_bucket(year, 2, '2010-01-01', '2019-01-01')'
            * Interval = '-9 years 0 months'
            * required_bucket = -9/2 = -4
            * result_time = '2019-01-01' + '-8 hours' => '2011-01-01'
            * As in the above example result_time > date, so we go back by 1 bucket. '2011-01-01' - '2 Years'  => '2009-01-01'
            */
            required_bucket := years_diff / number;
            result_date := origin::timestamp + (concat(required_bucket * number, ' ', 'years')::interval);
            IF result_date > date THEN
                result_date = result_date - (concat(number, ' ', 'years')::interval);
            END IF;

        WHEN 'month' THEN
            /*
            * Calculate the difference between date and origin in months. 
            * The rest step are similar as of case where datepart is 'year'
            */
            required_bucket := (12 * years_diff + months_diff) / number;
            result_date := origin::timestamp + (concat(required_bucket * number, ' ', 'months')::interval);
            IF result_date > date THEN
                result_date = result_date - (concat(number, ' ', 'months')::interval);
            END IF;

        WHEN 'quarter' THEN
            /*
            * Calculate the difference between date and origin in quarters. 
            * The rest step are similar as of case where datepart is 'year'
            */
            years_diff := (12 * years_diff + months_diff) / 3;
            required_bucket := years_diff / number;
            result_date := origin::timestamp + (concat(required_bucket * number * 3, ' ', 'months')::interval);
            IF result_date > date THEN
                result_date = result_date - (concat(number*3, ' ', 'months')::interval);
            END IF;
        END CASE;
        /*
        * All the above operations are performed by converting every date datatype into TIMESTAMPS. 
        * datetimeoffset is also typecasted into TIMESTAMPS. Ex. '2023-02-23 09:19:21.23'::sys.datetimeoffset::timestamp => '2023-02-23 09:19:21.23'
        * As the output of date_bucket() for datetimeoffset will always be in the same zone as of date argument. 
        * Here, converting TIMESTAMP into datetimeoffset with the same timezone as of date argument.   
        */
        IF pg_typeof(date) = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            return concat(result_date, ' ', offset_string)::sys.datetimeoffset;
        ELSE
            return result_date;
	    END IF;
    
    -- DATE_BIN() function support datepart week, day, hour, minute, second, millisecond
    -- Date_Bucket calculation goes here for every datatype except time. 
    ELSIF (datepart IN ('week', 'day', 'hour', 'minute', 'second', 'millisecond')) THEN
        date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
        /*
        * To pass in DATE_BIN() typecasts any date datatype to timestamp
        * Handling datetimeoffset datatype separately. 
        */
        result_date = date_bin(date_difference_interval, date::TIMESTAMP, origin::TIMESTAMP);
        -- Filtering for cases like 4th query of DATE_BUCKET_vu_prepare_v15. 
        IF (result_date + (concat(number, ' ', datepart)::INTERVAL) <= date::TIMESTAMP) THEN
            result_date = result_date + concat(number, ' ', datepart)::INTERVAL;
        END IF;
        IF pg_typeof(date) = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            return concat(result_date, ' ', offset_string)::sys.datetimeoffset;
	    ELSE
            RETURN result_date;
        END IF;

    ELSE
        RAISE EXCEPTION '% is not a recognized Date_Bucket option.', datepart;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
