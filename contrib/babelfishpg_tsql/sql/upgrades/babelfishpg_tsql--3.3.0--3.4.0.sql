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
CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN bucket_size INTEGER, IN bucketDate ANYELEMENT, IN originDate ANYELEMENT default NULL) RETURNS ANYELEMENT 
AS 
$body$
DECLARE
    datepart_diff INT;
    required_bucket INT;
    stride_text PG_CATALOG.TEXT;
    date_difference_interval INTERVAL;
    years_diff INT;
    months_diff INT;
    hours_diff INT;
    minutes_diff INT;
    seconds_diff INT;
    milliseconds_diff INT;
BEGIN
    BEGIN
        IF (bucket_size <= 0 ) THEN
            RAISE EXCEPTION 'Invalid bucket width value passed to date_bucket function. Only positive values are allowed for number argument.';
        END IF;
        IF pg_typeof(bucketDate) NOT IN ('sys.datetime'::regtype, 'sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype, 'date'::regtype, 'time'::regtype) THEN
            RAISE EXCEPTION '% Invalid datatype for date argument', pg_typeof(bucketDate);
        END IF;
        IF pg_typeof(bucketDate) = 'date'::regtype AND
            datepart IN ('hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type date.', datepart;
	    END IF;
        IF pg_typeof(bucketDate) = 'time'::regtype AND
            datepart IN ('year', 'quarter', 'month', 'day', 'week') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type time.', datepart;
	    END IF;
        IF originDate IS NULL THEN
                IF pg_typeof(bucketDate) = 'sys.datetime'::regtype THEN
                    originDate := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF pg_typeof(bucketDate) = 'sys.datetime2'::regtype THEN
                    originDate := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF pg_typeof(bucketDate) = 'sys.datetimeoffset'::regtype THEN
                    originDate := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF pg_typeof(bucketDate) = 'sys.smalldatetime'::regtype THEN
                    originDate := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSEIF pg_typeof(bucketDate) = 'date'::regtype THEN
                    originDate := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSEIF pg_typeof(bucketDate) = 'time'::regtype THEN
                    originDate := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        ELSE
                IF (pg_typeof(originDate) != pg_typeof(bucketDate)) THEN
                    RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of Date_Bucket function.', pg_typeof(originDate);
                END IF;
        END IF;
    END;

    IF pg_typeof(bucketDate) = 'time'::regtype THEN
        date_difference_interval := bucketDate - originDate;
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := EXTRACT('millisecond' from date_difference_interval)::INT;
        CASE datepart
        WHEN 'hour' THEN
            datepart_diff := hours_diff;
            RAISE NOTICE 'hours: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate + (concat(required_bucket * bucket_size, ' ', 'hours')::interval);
        WHEN 'minute' THEN
            datepart_diff := hours_diff * 60 + minutes_diff;
            RAISE NOTICE 'minutes: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate + (concat(required_bucket * bucket_size, ' ', 'minutes')::interval);
        WHEN 'second' THEN
            datepart_diff := (hours_diff * 60 + minutes_diff) * 60 + seconds_diff;
            RAISE NOTICE 'seconds: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate + (concat(required_bucket * bucket_size, ' ', 'seconds')::interval);
        WHEN 'millisecond' THEN
            datepart_diff := ((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff;
            RAISE NOTICE 'milliseconds: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate + (concat(required_bucket * bucket_size, ' ', 'milliseconds')::interval);
        END CASE;

    ELSIF (datepart IN ('year', 'quarter', 'month')) THEN
        date_difference_interval := AGE(bucketDate :: timestamp, originDate :: timestamp );
        years_diff := EXTRACT('Year' from date_difference_interval ) :: INT;
        months_diff := EXTRACT('Month' from date_difference_interval ) :: INT;
        CASE datepart
        WHEN 'year' THEN
            datepart_diff := years_diff;
            RAISE NOTICE 'years: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate::timestamp + (concat(required_bucket * bucket_size, ' ', 'years')::interval);
        WHEN 'month' THEN
            datepart_diff := 12 * years_diff + months_diff;
            RAISE NOTICE 'months: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate::timestamp + (concat(required_bucket * bucket_size, ' ', 'months')::interval);
        WHEN 'quarter' THEN
            datepart_diff := (12 * years_diff + months_diff) / 3;
            RAISE NOTICE 'quarter: %', datepart_diff;
            required_bucket := datepart_diff / bucket_size;
            return originDate::timestamp + (concat(required_bucket * bucket_size * 3, ' ', 'months')::interval);
        END CASE;
    
    ELSIF (datepart IN ('week', 'day', 'hour', 'minute', 'second', 'millisecond')) THEN
        stride_text := concat(bucket_size, ' ', datepart);
        RETURN date_bin(stride_text::INTERVAL, bucketDate::TIMESTAMP, originDate::TIMESTAMP);

    ELSE
        RAISE EXCEPTION 'The datepart % is not supported by date_bucket function for the datatype.', datepart;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
