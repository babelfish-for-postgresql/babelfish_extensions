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

ALTER FUNCTION sys.power(IN arg1 BIGINT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 INT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 SMALLINT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 TINYINT, IN arg2 NUMERIC) STRICT;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Matches and returns column name of the corresponding table
CREATE OR REPLACE FUNCTION sys.COL_NAME(IN table_id INT, IN column_id INT)
RETURNS sys.SYSNAME AS $$
    DECLARE
        column_name TEXT;
    BEGIN
        SELECT attname INTO STRICT column_name 
        FROM pg_attribute 
        WHERE attrelid = table_id AND attnum = column_id AND attnum > 0;
        
        RETURN column_name::sys.SYSNAME;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END; 
$$
LANGUAGE plpgsql IMMUTABLE
STRICT;

CREATE OR REPLACE FUNCTION sys.SWITCHOFFSET(IN input_expr PG_CATALOG.TEXT,
                                                               IN tz_offset PG_CATALOG.TEXT)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    p_year INTEGER;
    p_month INTEGER;
    p_day INTEGER;
    p_hour INTEGER;
    p_minute INTEGER;
    p_seconds INTEGER;
    p_nanosecond PG_CATALOG.TEXT;
    p_tzoffset INTEGER;
    f_tzoffset INTEGER;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
    offset_str PG_CATALOG.TEXT;
    v_resdatetimeupdated TIMESTAMP WITHOUT TIME ZONE;
    tzfm INTEGER;
    str_hr PG_CATALOG.TEXT;
    str_mi PG_CATALOG.TEXT;
    v_hr INTEGER;
    v_mi INTEGER;
    sign_flag INTEGER;
    v_string pg_catalog.text;
    isoverflow pg_catalog.text;
BEGIN

    BEGIN
    p_year := date_part('year',input_expr::TIMESTAMP);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;

    if p_year <1 or p_year > 9999 THEN
    RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END IF;


    BEGIN
    input_expr:= cast(input_expr AS datetimeoffset);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END; 

    IF input_expr IS NULL or tz_offset IS NULL THEN 
    RETURN NULL;
    END IF;


    IF tz_offset LIKE '+__:__' THEN
        str_hr := SUBSTRING(tz_offset,2,2);
        str_mi := SUBSTRING(tz_offset,5,2);
        sign_flag := 1;
    ELSIF tz_offset LIKE '-__:__' THEN
        str_hr := SUBSTRING(tz_offset,2,2);
        str_mi := SUBSTRING(tz_offset,5,2);
        sign_flag := -1;
    ELSE
        RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END IF;

    

    BEGIN
    v_hr := str_hr::INTEGER;
    v_mi := str_mi::INTEGER;
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END;

    if v_hr > 14 or (v_hr = 14 and v_mi > 0) THEN
       RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END IF; 

    tzfm := sign_flag*((v_hr*60)+v_mi);

    p_year := date_part('year',input_expr::TIMESTAMP);
    p_month := date_part('month',input_expr::TIMESTAMP);
    p_day := date_part('day',input_expr::TIMESTAMP);
    p_hour := date_part('hour',input_expr::TIMESTAMP);
    p_minute := date_part('minute',input_expr::TIMESTAMP);
    p_seconds := TRUNC(date_part('second', input_expr::TIMESTAMP))::INTEGER;
    p_tzoffset := -1*sys.babelfish_get_datetimeoffset_tzoffset(cast(input_expr as sys.datetimeoffset))::integer;

    p_nanosecond := split_part(input_expr COLLATE "C",'.',2);
    p_nanosecond := split_part(p_nanosecond COLLATE "C",' ',1);


    f_tzoffset := p_tzoffset + tzfm;

    v_resdatetime := make_timestamp(p_year,p_month,p_day,p_hour,p_minute,p_seconds);
    v_resdatetimeupdated := v_resdatetime + make_interval(mins => f_tzoffset);

    isoverflow := split_part(v_resdatetimeupdated::TEXT COLLATE "C",' ',3);

    v_string := CONCAT(v_resdatetimeupdated::pg_catalog.text,'.',p_nanosecond::text,tz_offset);
    p_year := split_part(v_string COLLATE "C",'-',1)::INTEGER;
    

    if p_year <1 or p_year > 9999 or isoverflow = 'BC' THEN
    RAISE USING MESSAGE := 'The timezone provided to builtin function switchoffset would cause the datetimeoffset to overflow the range of valid date range in either UTC or local time.';
    END IF;

    BEGIN
    RETURN cast(v_string AS sys.datetimeoffset);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;

END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.SWITCHOFFSET(IN input_expr PG_CATALOG.TEXT,
                                                               IN tz_offset anyelement)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    p_year INTEGER;
    p_month INTEGER;
    p_day INTEGER;
    p_hour INTEGER;
    p_minute INTEGER;
    p_seconds INTEGER;
    p_nanosecond PG_CATALOG.TEXT;
    p_tzoffset INTEGER;
    f_tzoffset INTEGER;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
    offset_str PG_CATALOG.TEXT;
    v_resdatetimeupdated TIMESTAMP WITHOUT TIME ZONE;
    tzfm INTEGER;
    str_hr PG_CATALOG.TEXT;
    str_mi PG_CATALOG.TEXT;
    v_hr INTEGER;
    v_mi INTEGER;
    sign_flag INTEGER;
    v_string pg_catalog.text;
    v_sign PG_CATALOG.TEXT;
    tz_offset_smallint smallint;
    isoverflow pg_catalog.text;
BEGIN

    IF pg_typeof(tz_offset) NOT IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,'sys.decimal'::regtype,
    'numeric'::regtype, 'float'::regtype,'double precision'::regtype, 'real'::regtype, 'sys.money'::regtype,'sys.smallmoney'::regtype,'sys.bit'::regtype,'varbinary'::regtype ) THEN
        RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END IF;

    BEGIN
    p_year := date_part('year',input_expr::TIMESTAMP);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;
    

    if p_year <1 or p_year > 9999 THEN
    RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END IF;

    BEGIN
    input_expr:= cast(input_expr AS datetimeoffset);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;

    BEGIN
    IF pg_typeof(tz_offset) NOT IN ('varbinary'::regtype) THEN
        tz_offset := FLOOR(tz_offset);
    END IF;
    tz_offset_smallint := cast(tz_offset AS smallint);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type smallint.';
    END;  

    IF input_expr IS NULL THEN 
    RETURN NULL;
    END IF;

    if tz_offset_smallint > 840 or tz_offset_smallint < -840 THEN
       RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END IF; 

    v_hr := tz_offset_smallint/60;
    v_mi := tz_offset_smallint%60;
    

    p_year := date_part('year',input_expr::TIMESTAMP);
    p_month := date_part('month',input_expr::TIMESTAMP);
    p_day := date_part('day',input_expr::TIMESTAMP);
    p_hour := date_part('hour',input_expr::TIMESTAMP);
    p_minute := date_part('minute',input_expr::TIMESTAMP);
    p_seconds := TRUNC(date_part('second', input_expr::TIMESTAMP))::INTEGER;
    p_tzoffset := -1*sys.babelfish_get_datetimeoffset_tzoffset(cast(input_expr as sys.datetimeoffset))::integer;

    v_sign := (
        SELECT CASE
            WHEN (tz_offset_smallint) >= 0
                THEN '+'    
            ELSE '-'
        END
    );

    p_nanosecond := split_part(input_expr COLLATE "C",'.',2);
    p_nanosecond := split_part(p_nanosecond COLLATE "C",' ',1);

    f_tzoffset := p_tzoffset + tz_offset_smallint;
    v_resdatetime := make_timestamp(p_year,p_month,p_day,p_hour,p_minute,p_seconds);
    v_resdatetimeupdated := v_resdatetime + make_interval(mins => f_tzoffset);

    isoverflow := split_part(v_resdatetimeupdated::TEXT COLLATE "C",' ',3);

    v_string := CONCAT(v_resdatetimeupdated::pg_catalog.text,'.',p_nanosecond::text,v_sign,abs(v_hr)::TEXT,':',abs(v_mi)::TEXT);

    p_year := split_part(v_string COLLATE "C",'-',1)::INTEGER;

    if p_year <1 or p_year > 9999 or isoverflow = 'BC' THEN
    RAISE USING MESSAGE := 'The timezone provided to builtin function switchoffset would cause the datetimeoffset to overflow the range of valid date range in either UTC or local time.';
    END IF;
    

    BEGIN
    RETURN cast(v_string AS sys.datetimeoffset);
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;

END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

-- Another definition of date_bucket() with arg PG_CATALOG.TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date PG_CATALOG.TEXT, IN origin PG_CATALOG.TEXT default NULL) RETURNS PG_CATALOG.TEXT 
AS 
$body$
DECLARE
BEGIN
    IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond') THEN
        RAISE EXCEPTION '% is not a recognized date_bucket option.', datepart;
    ELSIF number IS NULL THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 2 of date_bucket function.';
    ELSIF date IS NULL THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 3 of date_bucket function.';
    ELSE
        RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of date_bucket function.', pg_typeof(date);
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
    millisec_trunc_diff_interval INTERVAL;
BEGIN
    BEGIN
        -- Check for supported datepart by date_bucket function
        IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION '% is not a recognized date_bucket option.', datepart;

        -- Check for NULL or negative value of number argument
        ELSIF number IS NULL THEN
            RAISE EXCEPTION 'Argument data type NULL is invalid for argument 2 of date_bucket function.';
        ELSIF number <= 0 THEN
            RAISE EXCEPTION 'Invalid bucket width value passed to date_bucket function. Only positive values are allowed.';

        -- Raise exception if any unsupported datatype for date is provided. 
        -- For example throw exception if INT datatype is provided in date. 
        ELSIF pg_typeof(date) NOT IN ('sys.datetime'::regtype, 'sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype, 'date'::regtype, 'time'::regtype) THEN
            RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of date_bucket function.', pg_typeof(date);

        -- Raise exception if any unsupported datepart for given date datatype is provided. 
        -- Date does not support hour, minute, second, millisecond datepart
        -- Time does not support year, month, quarter, day, week datepart
        ELSIF pg_typeof(date) = 'date'::regtype AND datepart IN ('hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type date.', datepart;
        ELSIF pg_typeof(date) = 'time'::regtype AND datepart IN ('year', 'quarter', 'month', 'day', 'week') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type time.', datepart;

        -- If optional argument origin's value is not provided by user then set it's default value of valid datatype.
        ELSIF origin IS NULL THEN
                IF pg_typeof(date) = 'sys.datetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF pg_typeof(date) = 'sys.datetime2'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF pg_typeof(date) = 'sys.datetimeoffset'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF pg_typeof(date) = 'sys.smalldatetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSIF pg_typeof(date) = 'date'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSIF pg_typeof(date) = 'time'::regtype THEN
                    origin := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        ELSE
                IF pg_typeof(origin) != pg_typeof(date) THEN
                    RAISE EXCEPTION 'Argument data type % is invalid for argument 4 of date_bucket function.', pg_typeof(origin);
                END IF;
        END IF;
    END;

    /* support of date_bucket() for different-different date datatype start here */
    -- support of date_bucket() when date is of 'time' datatype
    IF pg_typeof(date) = 'time'::regtype THEN
        -- Find interval between date and origin and extract hour, minute, second, millisecond from the interval
        date_difference_interval := date_trunc('millisecond', date) - date_trunc('millisecond', origin);
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := FLOOR(EXTRACT('millisecond' from date_difference_interval))::INT;
        CASE datepart
        WHEN 'hour' THEN
            -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in whcih our date falls.
            -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. (Ex. 'date_bucket(hour, 2, '01:00:00', '08:00:00')') 
            -- For comparision we are trunceting the result_time to milliseconds
            required_bucket := hours_diff/number;
            result_time := origin + concat(required_bucket * number, ' ', 'hours')::interval;
            IF date_trunc('millisecond', result_time) > date THEN
                RETURN result_time - concat(number, ' ', 'hours')::interval;
            END IF;
            RETURN result_time;

        WHEN 'minute' THEN
            required_bucket := (hours_diff * 60 + minutes_diff)/number;
            result_time := origin + concat(required_bucket * number, ' ', 'minutes')::interval;
            IF date_trunc('millisecond', result_time) > date THEN
                RETURN result_time - concat(number, ' ', 'minutes')::interval;
            END IF;
            RETURN result_time;

        WHEN 'second' THEN
            required_bucket := ((hours_diff * 60 + minutes_diff) * 60 + seconds_diff)/number;
            result_time := origin + concat(required_bucket * number, ' ', 'seconds')::interval;
            IF date_trunc('millisecond', result_time) > date THEN
                RETURN result_time - concat(number, ' ', 'seconds')::interval;
            END IF;
            RETURN result_time;

        WHEN 'millisecond' THEN
            required_bucket := (((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff)/number;
            result_time := origin + concat(required_bucket * number, ' ', 'milliseconds')::interval;
            IF date_trunc('millisecond', result_time) > date THEN
                RETURN result_time - concat(number, ' ', 'milliseconds')::interval;
            END IF;
            RETURN result_time;
        END CASE;

    -- support of date_bucket() when date is of {'datetime2', 'datetimeoffset'} datatype
    -- handling separately because both the datatypes have precision in milliseconds
    ELSIF pg_typeof(date) IN ('sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype) THEN
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
            WHEN 'year' THEN
                -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in whcih our date falls.
                -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. (Ex. date_bucket(year, 2, '2010-01-01', '2019-01-01')) 
                required_bucket := years_diff/number;
                result_date := origin::timestamp + concat(required_bucket * number, ' ', 'years')::interval;
                IF result_date > date THEN
                    result_date = result_date - concat(number, ' ', 'years')::interval;
                END IF;

            WHEN 'month' THEN
                required_bucket := (12 * years_diff + months_diff)/number;
                result_date := origin::timestamp + concat(required_bucket * number, ' ', 'months')::interval;
                IF result_date > date THEN
                    result_date = result_date - concat(number, ' ', 'months')::interval;
                END IF;

            WHEN 'quarter' THEN
                years_diff := (12 * years_diff + months_diff)/3;
                required_bucket := years_diff/number;
                result_date := origin::timestamp + concat(required_bucket * number * 3, ' ', 'months')::interval;
                IF result_date > date THEN
                    result_date = result_date - concat(number*3, ' ', 'months')::interval;
                END IF;
            END CASE;  
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function. 
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            millisec_trunc_diff_interval := (origin - date_trunc('millisecond', origin::timestamp))::interval;
            result_date = date_bin(date_difference_interval, date::TIMESTAMP, date_trunc('millisecond', origin::timestamp)) + millisec_trunc_diff_interval;

            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result. (Ex. query #4 of DATE_BUCKET_vu_prepare_v15) 
            IF result_date + concat(number, ' ', datepart)::INTERVAL <= date::TIMESTAMP THEN
                result_date = result_date + concat(number, ' ', datepart)::INTERVAL;
            END IF;
        END IF;

        -- All the above operations are performed by converting every date datatype into TIMESTAMPS. 
        -- datetimeoffset is also typecasted into TIMESTAMPS. Ex. '2023-02-23 09:19:21.23 +10:12'::sys.datetimeoffset::timestamp => '2023-02-22 23:07:21.23'
        -- As the output of date_bucket() for datetimeoffset datatype will always be in the same time-zone as of provided date argument. 
        -- Here, converting TIMESTAMP into datetimeoffset with the same timezone as of date argument.
        IF pg_typeof(date) = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            RETURN concat(result_date, ' ', offset_string)::sys.datetimeoffset;
        ELSE
            RETURN result_date;
        END IF;

    -- support of date_bucket() when date is of {'date', 'datetime', 'smalldatetime'} datatype
    ELSE
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
            WHEN 'year' THEN
                -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in whcih our date falls.
                -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. (Ex. date_bucket(year, 2, '2010-01-01', '2019-01-01')) 
                required_bucket := years_diff/number;
                result_date := origin::timestamp + concat(required_bucket * number, ' ', 'years')::interval;
                IF result_date > date THEN
                    result_date = result_date - concat(number, ' ', 'years')::interval;
                END IF;

            WHEN 'month' THEN
                required_bucket := (12 * years_diff + months_diff)/number;
                result_date := origin::timestamp + concat(required_bucket * number, ' ', 'months')::interval;
                RAISE NOTICE 'result_date = % , origin = %', result_date, origin;
                IF result_date > date THEN
                    result_date = result_date - concat(number, ' ', 'months')::interval;
                END IF;

            WHEN 'quarter' THEN
                years_diff := (12 * years_diff + months_diff)/3;
                required_bucket := years_diff/number;
                result_date := origin::timestamp + concat(required_bucket * number * 3, ' ', 'months')::interval;
                IF result_date > date THEN
                    result_date = result_date - concat(number * 3, ' ', 'months')::interval;
                END IF;
            END CASE;
            RETURN result_date;
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function.
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            result_date = date_bin(date_difference_interval, date::TIMESTAMP, origin::TIMESTAMP);
            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result. (Ex. query #4 of DATE_BUCKET_vu_prepare_v15) 
            IF result_date + concat(number, ' ', datepart)::INTERVAL <= date::TIMESTAMP THEN
                result_date = result_date + concat(number, ' ', datepart)::INTERVAL;
            END IF;
            RETURN result_date;
        END IF;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
