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



CREATE OR REPLACE FUNCTION sys.DATETIMEOFFSETFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER,
                                                               IN p_seconds INTEGER,
                                                               IN p_fractions INTEGER,
                                                               IN p_hour_offset INTEGER,
                                                               IN p_minute_offset INTEGER,
                                                               IN p_precision NUMERIC)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_err_message SYS.VARCHAR;
    v_fractions SYS.VARCHAR;
    v_precision SMALLINT;
    v_calc_seconds NUMERIC; 
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    v_sign pg_catalog.text;
BEGIN
    v_fractions := p_fractions::SYS.VARCHAR;
    IF p_precision IS NULL THEN
        RAISE EXCEPTION 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions.';
    END IF;
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR p_fractions IS NULL
            OR p_hour_offset IS NULL OR p_minute_offset is NULL THEN
        RETURN NULL;
    END IF;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;

    -- Check if arguments are out of range
    ELSIF ((p_year NOT BETWEEN 0001 AND 9999) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59) OR
        (p_seconds NOT BETWEEN 0 AND 59) OR
        (p_hour_offset NOT BETWEEN -14 AND 14) OR
        (p_minute_offset NOT BETWEEN -59 AND 59) OR
        (p_hour_offset * p_minute_offset < 0) OR
        (p_hour_offset = 14 AND p_minute_offset != 0) OR
        (p_hour_offset = -14 AND p_minute_offset != 0) OR
        (p_fractions != 0 AND char_length(v_fractions) > p_precision::SMALLINT))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;
    v_calc_seconds := format('%s.%s',
                             p_seconds,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    v_resdatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    v_calc_seconds);
    v_sign := (
        SELECT CASE
            WHEN (p_hour_offset) > 0
                THEN '+'
            WHEN (p_hour_offset) = 0 AND (p_minute_offset) >= 0
                THEN '+'    
            ELSE '-'
        END
    );
    v_string := CONCAT(v_resdatetime::pg_catalog.text,v_sign,abs(p_hour_offset)::SMALLINT::text,':',
                                                          abs(p_minute_offset)::SMALLINT::text);
    BEGIN
    RETURN cast(v_string AS sys.datetimeoffset);
    exception
        WHEN others THEN
            RAISE invalid_datetime_format;
    END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';    
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetimeoffset, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := format('Specified scale % is invalid.', p_fractions),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.TODATETIMEOFFSET(IN input_expr PG_CATALOG.TEXT , IN tz_offset TEXT)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    v_string pg_catalog.text;
    v_sign pg_catalog.text;
    str_hr TEXT;
    str_mi TEXT;
    precision_str TEXT;
    sign_flag INTEGER;
    v_hr INTEGER;
    v_mi INTEGER;
    v_precision INTEGER;
    input_expr_datetime2 datetime2;
BEGIN

    BEGIN
    input_expr_datetime2 := cast(input_expr as sys.datetime2);
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
    v_mi := str_mi ::INTEGER;
    exception
        WHEN others THEN
            RAISE USING MESSAGE := 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END;

    
    if v_hr > 14 or (v_hr = 14 and v_mi > 0) THEN
       RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
    END IF; 

    v_hr := v_hr * sign_flag;

    v_string := CONCAT(input_expr_datetime2::pg_catalog.text , tz_offset);

    BEGIN
    RETURN cast(v_string as sys.datetimeoffset);
    exception
        WHEN others THEN
                RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;


END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;


CREATE OR REPLACE FUNCTION sys.TODATETIMEOFFSET(IN input_expr PG_CATALOG.TEXT , IN tz_offset anyelement)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    v_string pg_catalog.text;
    v_sign pg_catalog.text;
    hr INTEGER;
    mi INTEGER;
    tz_sign INTEGER;
    tz_offset_smallint INTEGER;
    input_expr_datetime2 datetime2;
BEGIN

        BEGIN
        input_expr_datetime2:= cast(input_expr as sys.datetime2);
        exception
            WHEN others THEN
                RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
        END;


        IF pg_typeof(tz_offset) NOT IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,'sys.decimal'::regtype,'numeric'::regtype,
            'float'::regtype, 'double precision'::regtype, 'real'::regtype, 'sys.money'::regtype,'sys.smallmoney'::regtype,'sys.bit'::regtype ,'varbinary'::regtype) THEN
            RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
        END IF;

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
    
        IF tz_offset_smallint < 0 THEN
            tz_sign := 1;
        ELSE 
            tz_sign := 0;
        END IF;

        IF tz_offset_smallint > 840 or tz_offset_smallint < -840  THEN
            RAISE EXCEPTION 'The timezone provided to builtin function todatetimeoffset is invalid.';
        END IF;

        hr := tz_offset_smallint / 60;
        mi := tz_offset_smallint % 60;

        v_sign := (
        SELECT CASE
            WHEN (tz_sign) = 1
                THEN '-'
            WHEN (tz_sign) = 0
                THEN '+'    
        END
    );

    
        v_string := CONCAT(input_expr_datetime2::pg_catalog.text,v_sign,abs(hr)::SMALLINT::text,':',
                                                          abs(mi)::SMALLINT::text);

        BEGIN
        RETURN cast(v_string as sys.datetimeoffset);
        exception
            WHEN others THEN
                RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
        END;
    
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

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

CREATE OR REPLACE FUNCTION sys.timezone( IN tzzone PG_CATALOG.TEXT , IN input_expr PG_CATALOG.TEXT)
RETURNS sys.datetimeoffset
AS
$BODY$
BEGIN
    IF input_expr = 'NULL' THEN
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.';
    END IF;

    IF input_expr IS NULL OR tzzone IS NULL THEN 
    RETURN NULL;
    END IF;

    RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.timezone(IN tzzone PG_CATALOG.TEXT , IN input_expr anyelement)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    tz_offset PG_CATALOG.TEXT;
    tz_name PG_CATALOG.TEXT;
    prev_res PG_CATALOG.TEXT;
    result PG_CATALOG.TEXT;
    is_dstt bool;
    tz_diff PG_CATALOG.TEXT;
BEGIN
    IF input_expr IS NULL OR tzzone IS NULL THEN 
    RETURN NULL;
    END IF;
    RAISE LOG 'tmz(any,text)';
    IF NOT EXISTS (Select utc_offset from pg_timezone_names where name = (Select pgtzname from babelfish_timezone_mapping where stdname = tzzone)) THEN
        RAISE USING MESSAGE := format('Argument data type or the parameter %s provided to AT TIME ZONE clause is invalid.', tzzone);
    END IF;

    tz_name := (Select pgtzname from babelfish_timezone_mapping where stdname = tzzone);
    tz_offset := (Select utc_offset from pg_timezone_names where name = tz_name);

    IF pg_typeof(input_expr) IN ('sys.smalldatetime'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype) THEN
        result := (SELECT input_expr::TEXT::TIMESTAMPTZ AT TIME ZONE tz_name::TEXT)::TEXT;
        tz_diff := (SELECT result::TEXT::TIMESTAMPTZ - input_expr::TEXT::TIMESTAMPTZ)::TEXT;
        RAISE LOG 'Diff Interval %',tz_diff;
        if LEFT(tz_diff,1) <> '-' THEN
        tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := concat(split_part(tz_diff COLLATE "C",':',1),':',split_part(tz_diff COLLATE "C",':',2));
        return todatetimeoffset(input_expr::TEXT,tz_offset);
    ELSIF  pg_typeof(input_expr) = 'sys.DATETIMEOFFSET'::regtype THEN
        result := (SELECT input_expr::TEXT::TIMESTAMPTZ AT TIME ZONE tz_name::TEXT);
        tz_diff := (SELECT result::TEXT::TIMESTAMPTZ - input_expr::TEXT::TIMESTAMPTZ)::TEXT;
        RAISE LOG 'Diff Interval %',tz_diff;
        if LEFT(tz_diff,1) <> '-' THEN
        tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := concat(split_part(tz_diff COLLATE "C",':',1),':',split_part(tz_diff COLLATE "C",':',2));
        return todatetimeoffset(result::TEXT,tz_offset);
    ELSE
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
    END IF;
       
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE VIEW babelfish_timezone_mapping
AS
SELECT t.stdname,t.dstname,t.pgtzname FROM
(
  VALUES
    (
        /* (UTC+04:30) Kabul */
        'Afghanistan Standard Time', 'Afghanistan Daylight Time',
        'Asia/Kabul'
    ),
    (
        /* (UTC-09:00) Alaska */
        'Alaskan Standard Time', 'Alaskan Daylight Time',
        'America/Anchorage'
    ),
    (
        /* (UTC-10:00) Aleutian Islands */
        'Aleutian Standard Time', 'Aleutian Daylight Time',
        'America/Adak'
    ),
    (
        /* (UTC+07:00) Barnaul, Gorno-Altaysk */
        'Altai Standard Time', 'Altai Daylight Time',
        'Asia/Barnaul'
    ),
    (
        /* (UTC+03:00) Kuwait, Riyadh */
        'Arab Standard Time', 'Arab Daylight Time',
        'Asia/Riyadh'
    ),
    (
        /* (UTC+04:00) Abu Dhabi, Muscat */
        'Arabian Standard Time', 'Arabian Daylight Time',
        'Asia/Dubai'
    ),
    (
        /* (UTC+03:00) Baghdad */
        'Arabic Standard Time', 'Arabic Daylight Time',
        'Asia/Baghdad'
    ),
    (
        /* (UTC-03:00) City of Buenos Aires */
        'Argentina Standard Time', 'Argentina Daylight Time',
        'America/Buenos_Aires'
    ),
    (
        /* (UTC+04:00) Baku, Tbilisi, Yerevan */
        'Armenian Standard Time', 'Armenian Daylight Time',
        'Asia/Yerevan'
    ),
    (
        /* (UTC+04:00) Astrakhan, Ulyanovsk */
        'Astrakhan Standard Time', 'Astrakhan Daylight Time',
        'Europe/Astrakhan'
    ),
    (
        /* (UTC-04:00) Atlantic Time (Canada) */
        'Atlantic Standard Time', 'Atlantic Daylight Time',
        'America/Halifax'
    ),
    (
        /* (UTC+09:30) Darwin */
        'AUS Central Standard Time', 'AUS Central Daylight Time',
        'Australia/Darwin'
    ),
    (
        /* (UTC+08:45) Eucla */
        'Aus Central W. Standard Time', 'Aus Central W. Daylight Time',
        'Australia/Eucla'
    ),
    (
        /* (UTC+10:00) Canberra, Melbourne, Sydney */
        'AUS Eastern Standard Time', 'AUS Eastern Daylight Time',
        'Australia/Sydney'
    ),
    (
        /* (UTC+04:00) Baku */
        'Azerbaijan Standard Time', 'Azerbaijan Daylight Time',
        'Asia/Baku'
    ),
    (
        /* (UTC-01:00) Azores */
        'Azores Standard Time', 'Azores Daylight Time',
        'Atlantic/Azores'
    ),
    (
        /* (UTC-03:00) Salvador */
        'Bahia Standard Time', 'Bahia Daylight Time',
        'America/Bahia'
    ),
    (
        /* (UTC+06:00) Dhaka */
        'Bangladesh Standard Time', 'Bangladesh Daylight Time',
        'Asia/Dhaka'
    ),
    (
        /* (UTC+03:00) Minsk */
        'Belarus Standard Time', 'Belarus Daylight Time',
        'Europe/Minsk'
    ),
    (
        /* (UTC+11:00) Bougainville Island */
        'Bougainville Standard Time', 'Bougainville Daylight Time',
        'Pacific/Bougainville'
    ),
    (
        /* (UTC-01:00) Cabo Verde Is. */
        'Cabo Verde Standard Time', 'Cabo Verde Daylight Time',
        'Atlantic/Cape_Verde'
    ),
    (
        /* (UTC-06:00) Saskatchewan */
        'Canada Central Standard Time', 'Canada Central Daylight Time',
        'America/Regina'
    ),
    (
        /* (UTC-01:00) Cape Verde Is. */
        'Cape Verde Standard Time', 'Cape Verde Daylight Time',
        'Atlantic/Cape_Verde'
    ),
    (
        /* (UTC+04:00) Yerevan */
        'Caucasus Standard Time', 'Caucasus Daylight Time',
        'Asia/Yerevan'
    ),
    (
        /* (UTC+09:30) Adelaide */
        'Cen. Australia Standard Time', 'Cen. Australia Daylight Time',
        'Australia/Adelaide'
    ),
    (
        /* (UTC-06:00) Central America */
        'Central America Standard Time', 'Central America Daylight Time',
        'America/Guatemala'
    ),
    (
        /* (UTC+06:00) Astana */
        'Central Asia Standard Time', 'Central Asia Daylight Time',
        'Asia/Almaty'
    ),
    (
        /* (UTC-04:00) Cuiaba */
        'Central Brazilian Standard Time', 'Central Brazilian Daylight Time',
        'America/Cuiaba'
    ),
    (
        /* (UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague */
        'Central Europe Standard Time', 'Central Europe Daylight Time',
        'Europe/Budapest'
    ),
    (
        /* (UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb */
        'Central European Standard Time', 'Central European Daylight Time',
        'Europe/Warsaw'
    ),
    (
        /* (UTC+11:00) Solomon Is., New Caledonia */
        'Central Pacific Standard Time', 'Central Pacific Daylight Time',
        'Pacific/Guadalcanal'
    ),
    (
        /* (UTC-06:00) Central Time (US & Canada) */
        'Central Standard Time', 'Central Daylight Time',
        'America/Chicago'
    ),
    (
        /* (UTC-06:00) Guadalajara, Mexico City, Monterrey */
        'Central Standard Time (Mexico)', 'Central Daylight Time (Mexico)',
        'America/Mexico_City'
    ),
    (
        /* (UTC+12:45) Chatham Islands */
        'Chatham Islands Standard Time', 'Chatham Islands Daylight Time',
        'Pacific/Chatham'
    ),
    (
        /* (UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi */
        'China Standard Time', 'China Daylight Time',
        'Asia/Shanghai'
    ),
    (
        /* (UTC) Coordinated Universal Time */
        'Coordinated Universal Time', 'Coordinated Universal Time',
        'UTC'
    ),
    (
        /* (UTC-05:00) Havana */
        'Cuba Standard Time', 'Cuba Daylight Time',
        'America/Havana'
    ),
    (
        /* (UTC-12:00) International Date Line West */
        'Dateline Standard Time', 'Dateline Daylight Time',
        'Etc/GMT+12'
    ),
    (
        /* (UTC+03:00) Nairobi */
        'E. Africa Standard Time', 'E. Africa Daylight Time',
        'Africa/Nairobi'
    ),
    (
        /* (UTC+10:00) Brisbane */
        'E. Australia Standard Time', 'E. Australia Daylight Time',
        'Australia/Brisbane'
    ),
    (
        /* (UTC+02:00) Chisinau */
        'E. Europe Standard Time', 'E. Europe Daylight Time',
        'Europe/Chisinau'
    ),
    (
        /* (UTC-03:00) Brasilia */
        'E. South America Standard Time', 'E. South America Daylight Time',
        'America/Sao_Paulo'
    ),
    (
        /* (UTC-06:00) Easter Island */
        'Easter Island Standard Time', 'Easter Island Daylight Time',
        'Pacific/Easter'
    ),
    (
        /* (UTC-05:00) Eastern Time (US & Canada) */
        'Eastern Standard Time', 'Eastern Daylight Time',
        'America/New_York'
    ),
    (
        /* (UTC-05:00) Chetumal */
        'Eastern Standard Time (Mexico)', 'Eastern Daylight Time (Mexico)',
        'America/Cancun'
    ),
    (
        /* (UTC+02:00) Cairo */
        'Egypt Standard Time', 'Egypt Daylight Time',
        'Africa/Cairo'
    ),
    (
        /* (UTC+05:00) Ekaterinburg */
        'Ekaterinburg Standard Time', 'Ekaterinburg Daylight Time',
        'Asia/Yekaterinburg'
    ),
    (
        /* (UTC+12:00) Fiji */
        'Fiji Standard Time', 'Fiji Daylight Time',
        'Pacific/Fiji'
    ),
    (
        /* (UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius */
        'FLE Standard Time', 'FLE Daylight Time',
        'Europe/Kiev'
    ),
    (
        /* (UTC+04:00) Tbilisi */
        'Georgian Standard Time', 'Georgian Daylight Time',
        'Asia/Tbilisi'
    ),
    (
        /* (UTC+00:00) Dublin, Edinburgh, Lisbon, London */
        'GMT Standard Time', 'GMT Daylight Time',
        'Europe/London'
    ),
    (
        /* (UTC-03:00) Greenland */
        'Greenland Standard Time', 'Greenland Daylight Time',
        'America/Godthab'
    ),
    (
        /*
         * Windows uses this zone name in various places that lie near the
         * prime meridian, but are not in the UK.  However, most people
         * probably think that 'Greenwich' means UK civil time, or maybe even
         * straight-up UTC.  Atlantic/Reykjavik is a decent match for that
         * interpretation because Iceland hasn't observed DST since 1968.
         */
        /* (UTC+00:00) Monrovia, Reykjavik */
        'Greenwich Standard Time', 'Greenwich Daylight Time',
        'Atlantic/Reykjavik'
    ),
    (
        /* (UTC+02:00) Athens, Bucharest */
        'GTB Standard Time', 'GTB Daylight Time',
        'Europe/Bucharest'
    ),
    (
        /* (UTC-05:00) Haiti */
        'Haiti Standard Time', 'Haiti Daylight Time',
        'America/Port-au-Prince'
    ),
    (
        /* (UTC-10:00) Hawaii */
        'Hawaiian Standard Time', 'Hawaiian Daylight Time',
        'Pacific/Honolulu'
    ),
    (
        /* (UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi */
        'India Standard Time', 'India Daylight Time',
        'Asia/Calcutta'
    ),
    (
        /* (UTC+03:30) Tehran */
        'Iran Standard Time', 'Iran Daylight Time',
        'Asia/Tehran'
    ),
    (
        /* (UTC+02:00) Jerusalem */
        'Israel Standard Time', 'Israel Daylight Time',
        'Asia/Jerusalem'
    ),
    (
        /* (UTC+02:00) Jerusalem (old spelling of zone name) */
        'Jerusalem Standard Time', 'Jerusalem Daylight Time',
        'Asia/Jerusalem'
    ),
    (
        /* (UTC+02:00) Amman */
        'Jordan Standard Time', 'Jordan Daylight Time',
        'Asia/Amman'
    ),
    (
        /* (UTC+02:00) Kaliningrad */
        'Kaliningrad Standard Time', 'Kaliningrad Daylight Time',
        'Europe/Kaliningrad'
    ),
    (
        /* (UTC+12:00) Petropavlovsk-Kamchatsky - Old */
        'Kamchatka Standard Time', 'Kamchatka Daylight Time',
        'Asia/Kamchatka'
    ),
    (
        /* (UTC+09:00) Seoul */
        'Korea Standard Time', 'Korea Daylight Time',
        'Asia/Seoul'
    ),
    (
        /* (UTC+02:00) Tripoli */
        'Libya Standard Time', 'Libya Daylight Time',
        'Africa/Tripoli'
    ),
    (
        /* (UTC+14:00) Kiritimati Island */
        'Line Islands Standard Time', 'Line Islands Daylight Time',
        'Pacific/Kiritimati'
    ),
    (
        /* (UTC+10:30) Lord Howe Island */
        'Lord Howe Standard Time', 'Lord Howe Daylight Time',
        'Australia/Lord_Howe'
    ),
    (
        /* (UTC+11:00) Magadan */
        'Magadan Standard Time', 'Magadan Daylight Time',
        'Asia/Magadan'
    ),
    (
        /* (UTC-03:00) Punta Arenas */
        'Magallanes Standard Time', 'Magallanes Daylight Time',
        'America/Punta_Arenas'
    ),
    (
        /* (UTC+08:00) Kuala Lumpur, Singapore */
        'Malay Peninsula Standard Time', 'Malay Peninsula Daylight Time',
        'Asia/Kuala_Lumpur'
    ),
    (
        /* (UTC-09:30) Marquesas Islands */
        'Marquesas Standard Time', 'Marquesas Daylight Time',
        'Pacific/Marquesas'
    ),
    (
        /* (UTC+04:00) Port Louis */
        'Mauritius Standard Time', 'Mauritius Daylight Time',
        'Indian/Mauritius'
    ),
    (
        /* (UTC-06:00) Guadalajara, Mexico City, Monterrey */
        'Mexico Standard Time', 'Mexico Daylight Time',
        'America/Mexico_City'
    ),
    (
        /* (UTC-07:00) Chihuahua, La Paz, Mazatlan */
        'Mexico Standard Time 2', 'Mexico Daylight Time 2',
        'America/Chihuahua'
    ),
    (
        /* (UTC-02:00) Mid-Atlantic - Old */
        'Mid-Atlantic Standard Time', 'Mid-Atlantic Daylight Time',
        'Atlantic/South_Georgia'
    ),
    (
        /* (UTC+02:00) Beirut */
        'Middle East Standard Time', 'Middle East Daylight Time',
        'Asia/Beirut'
    ),
    (
        /* (UTC-03:00) Montevideo */
        'Montevideo Standard Time', 'Montevideo Daylight Time',
        'America/Montevideo'
    ),
    (
        /* (UTC+01:00) Casablanca */
        'Morocco Standard Time', 'Morocco Daylight Time',
        'Africa/Casablanca'
    ),
    (
        /* (UTC-07:00) Mountain Time (US & Canada) */
        'Mountain Standard Time', 'Mountain Daylight Time',
        'America/Denver'
    ),
    (
        /* (UTC-07:00) Chihuahua, La Paz, Mazatlan */
        'Mountain Standard Time (Mexico)', 'Mountain Daylight Time (Mexico)',
        'America/Chihuahua'
    ),
    (
        /* (UTC+06:30) Yangon (Rangoon) */
        'Myanmar Standard Time', 'Myanmar Daylight Time',
        'Asia/Rangoon'
    ),
    (
        /* (UTC+07:00) Novosibirsk */
        'N. Central Asia Standard Time', 'N. Central Asia Daylight Time',
        'Asia/Novosibirsk'
    ),
    (
        /* (UTC+02:00) Windhoek */
        'Namibia Standard Time', 'Namibia Daylight Time',
        'Africa/Windhoek'
    ),
    (
        /* (UTC+05:45) Kathmandu */
        'Nepal Standard Time', 'Nepal Daylight Time',
        'Asia/Katmandu'
    ),
    (
        /* (UTC+12:00) Auckland, Wellington */
        'New Zealand Standard Time', 'New Zealand Daylight Time',
        'Pacific/Auckland'
    ),
    (
        /* (UTC-03:30) Newfoundland */
        'Newfoundland Standard Time', 'Newfoundland Daylight Time',
        'America/St_Johns'
    ),
    (
        /* (UTC+11:00) Norfolk Island */
        'Norfolk Standard Time', 'Norfolk Daylight Time',
        'Pacific/Norfolk'
    ),
    (
        /* (UTC+08:00) Irkutsk */
        'North Asia East Standard Time', 'North Asia East Daylight Time',
        'Asia/Irkutsk'
    ),
    (
        /* (UTC+07:00) Krasnoyarsk */
        'North Asia Standard Time', 'North Asia Daylight Time',
        'Asia/Krasnoyarsk'
    ),
    (
        /* (UTC+09:00) Pyongyang */
        'North Korea Standard Time', 'North Korea Daylight Time',
        'Asia/Pyongyang'
    ),
    (
        /* (UTC+07:00) Novosibirsk */
        'Novosibirsk Standard Time', 'Novosibirsk Daylight Time',
        'Asia/Novosibirsk'
    ),
    (
        /* (UTC+06:00) Omsk */
        'Omsk Standard Time', 'Omsk Daylight Time',
        'Asia/Omsk'
    ),
    (
        /* (UTC-04:00) Santiago */
        'Pacific SA Standard Time', 'Pacific SA Daylight Time',
        'America/Santiago'
    ),
    (
        /* (UTC-08:00) Pacific Time (US & Canada) */
        'Pacific Standard Time', 'Pacific Daylight Time',
        'America/Los_Angeles'
    ),
    (
        /* (UTC-08:00) Baja California */
        'Pacific Standard Time (Mexico)', 'Pacific Daylight Time (Mexico)',
        'America/Tijuana'
    ),
    (
        /* (UTC+05:00) Islamabad, Karachi */
        'Pakistan Standard Time', 'Pakistan Daylight Time',
        'Asia/Karachi'
    ),
    (
        /* (UTC-04:00) Asuncion */
        'Paraguay Standard Time', 'Paraguay Daylight Time',
        'America/Asuncion'
    ),
    (
        /* (UTC+05:00) Qyzylorda */
        'Qyzylorda Standard Time', 'Qyzylorda Daylight Time',
        'Asia/Qyzylorda'
    ),
    (
        /* (UTC+01:00) Brussels, Copenhagen, Madrid, Paris */
        'Romance Standard Time', 'Romance Daylight Time',
        'Europe/Paris'
    ),
    (
        /* (UTC+04:00) Izhevsk, Samara */
        'Russia Time Zone 3', 'Russia Time Zone 3',
        'Europe/Samara'
    ),
    (
        /* (UTC+11:00) Chokurdakh */
        'Russia Time Zone 10', 'Russia Time Zone 10',
        'Asia/Srednekolymsk'
    ),
    (
        /* (UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky */
        'Russia Time Zone 11', 'Russia Time Zone 11',
        'Asia/Kamchatka'
    ),
    (
        /* (UTC+02:00) Kaliningrad */
        'Russia TZ 1 Standard Time', 'Russia TZ 1 Daylight Time',
        'Europe/Kaliningrad'
    ),
    (
        /* (UTC+03:00) Moscow, St. Petersburg */
        'Russia TZ 2 Standard Time', 'Russia TZ 2 Daylight Time',
        'Europe/Moscow'
    ),
    (
        /* (UTC+04:00) Izhevsk, Samara */
        'Russia TZ 3 Standard Time', 'Russia TZ 3 Daylight Time',
        'Europe/Samara'
    ),
    (
        /* (UTC+05:00) Ekaterinburg */
        'Russia TZ 4 Standard Time', 'Russia TZ 4 Daylight Time',
        'Asia/Yekaterinburg'
    ),
    (
        /* (UTC+06:00) Novosibirsk (RTZ 5) */
        'Russia TZ 5 Standard Time', 'Russia TZ 5 Daylight Time',
        'Asia/Novosibirsk'
    ),
    (
        /* (UTC+07:00) Krasnoyarsk */
        'Russia TZ 6 Standard Time', 'Russia TZ 6 Daylight Time',
        'Asia/Krasnoyarsk'
    ),
    (
        /* (UTC+08:00) Irkutsk */
        'Russia TZ 7 Standard Time', 'Russia TZ 7 Daylight Time',
        'Asia/Irkutsk'
    ),
    (
        /* (UTC+09:00) Yakutsk */
        'Russia TZ 8 Standard Time', 'Russia TZ 8 Daylight Time',
        'Asia/Yakutsk'
    ),
    (
        /* (UTC+10:00) Vladivostok */
        'Russia TZ 9 Standard Time', 'Russia TZ 9 Daylight Time',
        'Asia/Vladivostok'
    ),
    (
        /* (UTC+11:00) Chokurdakh */
        'Russia TZ 10 Standard Time', 'Russia TZ 10 Daylight Time',
        'Asia/Magadan'
    ),
    (
        /* (UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky */
        'Russia TZ 11 Standard Time', 'Russia TZ 11 Daylight Time',
        'Asia/Anadyr'
    ),
    (
        /* (UTC+03:00) Moscow, St. Petersburg */
        'Russian Standard Time', 'Russian Daylight Time',
        'Europe/Moscow'
    ),
    (
        /* (UTC-03:00) Cayenne, Fortaleza */
        'SA Eastern Standard Time', 'SA Eastern Daylight Time',
        'America/Cayenne'
    ),
    (
        /* (UTC-05:00) Bogota, Lima, Quito, Rio Branco */
        'SA Pacific Standard Time', 'SA Pacific Daylight Time',
        'America/Bogota'
    ),
    (
        /* (UTC-04:00) Georgetown, La Paz, Manaus, San Juan */
        'SA Western Standard Time', 'SA Western Daylight Time',
        'America/La_Paz'
    ),
    (
        /* (UTC-03:00) Saint Pierre and Miquelon */
        'Saint Pierre Standard Time', 'Saint Pierre Daylight Time',
        'America/Miquelon'
    ),
    (
        /* (UTC+11:00) Sakhalin */
        'Sakhalin Standard Time', 'Sakhalin Daylight Time',
        'Asia/Sakhalin'
    ),
    (
        /* (UTC+13:00) Samoa */
        'Samoa Standard Time', 'Samoa Daylight Time',
        'Pacific/Apia'
    ),
    (
        /* (UTC+00:00) Sao Tome */
        'Sao Tome Standard Time', 'Sao Tome Daylight Time',
        'Africa/Sao_Tome'
    ),
    (
        /* (UTC+04:00) Saratov */
        'Saratov Standard Time', 'Saratov Daylight Time',
        'Europe/Saratov'
    ),
    (
        /* (UTC+07:00) Bangkok, Hanoi, Jakarta */
        'SE Asia Standard Time', 'SE Asia Daylight Time',
        'Asia/Bangkok'
    ),
    (
        /* (UTC+08:00) Kuala Lumpur, Singapore */
        'Singapore Standard Time', 'Singapore Daylight Time',
        'Asia/Singapore'
    ),
    (
        /* (UTC+02:00) Harare, Pretoria */
        'South Africa Standard Time', 'South Africa Daylight Time',
        'Africa/Johannesburg'
    ),
    (
        /* (UTC+02:00) Juba */
        'South Sudan Standard Time', 'South Sudan Daylight Time',
        'Africa/Juba'
    ),
    (
        /* (UTC+05:30) Sri Jayawardenepura */
        'Sri Lanka Standard Time', 'Sri Lanka Daylight Time',
        'Asia/Colombo'
    ),
    (
        /* (UTC+02:00) Khartoum */
        'Sudan Standard Time', 'Sudan Daylight Time',
        'Africa/Khartoum'
    ),
    (
        /* (UTC+02:00) Damascus */
        'Syria Standard Time', 'Syria Daylight Time',
        'Asia/Damascus'
    ),
    (
        /* (UTC+08:00) Taipei */
        'Taipei Standard Time', 'Taipei Daylight Time',
        'Asia/Taipei'
    ),
    (
        /* (UTC+10:00) Hobart */
        'Tasmania Standard Time', 'Tasmania Daylight Time',
        'Australia/Hobart'
    ),
    (
        /* (UTC-03:00) Araguaina */
        'Tocantins Standard Time', 'Tocantins Daylight Time',
        'America/Araguaina'
    ),
    (
        /* (UTC+09:00) Osaka, Sapporo, Tokyo */
        'Tokyo Standard Time', 'Tokyo Daylight Time',
        'Asia/Tokyo'
    ),
    (
        /* (UTC+07:00) Tomsk */
        'Tomsk Standard Time', 'Tomsk Daylight Time',
        'Asia/Tomsk'
    ),
    (
        /* (UTC+13:00) Nuku'alofa */
        'Tonga Standard Time', 'Tonga Daylight Time',
        'Pacific/Tongatapu'
    ),
    (
        /* (UTC+09:00) Chita */
        'Transbaikal Standard Time', 'Transbaikal Daylight Time',
        'Asia/Chita'
    ),
    (
        /* (UTC+03:00) Istanbul */
        'Turkey Standard Time', 'Turkey Daylight Time',
        'Europe/Istanbul'
    ),
    (
        /* (UTC-05:00) Turks and Caicos */
        'Turks And Caicos Standard Time', 'Turks And Caicos Daylight Time',
        'America/Grand_Turk'
    ),
    (
        /* (UTC+08:00) Ulaanbaatar */
        'Ulaanbaatar Standard Time', 'Ulaanbaatar Daylight Time',
        'Asia/Ulaanbaatar'
    ),
    (
        /* (UTC-05:00) Indiana (East) */
        'US Eastern Standard Time', 'US Eastern Daylight Time',
        'America/Indianapolis'
    ),
    (
        /* (UTC-07:00) Arizona */
        'US Mountain Standard Time', 'US Mountain Daylight Time',
        'America/Phoenix'
    ),
    (
        /* (UTC) Coordinated Universal Time */
        'UTC', 'UTC',
        'UTC'
    ),
    (
        /* (UTC+12:00) Coordinated Universal Time+12 */
        'UTC+12', 'UTC+12',
        'Etc/GMT-12'
    ),
    (
        /* (UTC+13:00) Coordinated Universal Time+13 */
        'UTC+13', 'UTC+13',
        'Etc/GMT-13'
    ),
    (
        /* (UTC-02:00) Coordinated Universal Time-02 */
        'UTC-02', 'UTC-02',
        'Etc/GMT+2'
    ),
    (
        /* (UTC-08:00) Coordinated Universal Time-08 */
        'UTC-08', 'UTC-08',
        'Etc/GMT+8'
    ),
    (
        /* (UTC-09:00) Coordinated Universal Time-09 */
        'UTC-09', 'UTC-09',
        'Etc/GMT+9'
    ),
    (
        /* (UTC-11:00) Coordinated Universal Time-11 */
        'UTC-11', 'UTC-11',
        'Etc/GMT+11'
    ),
    (
        /* (UTC-04:00) Caracas */
        'Venezuela Standard Time', 'Venezuela Daylight Time',
        'America/Caracas'
    ),
    (
        /* (UTC+10:00) Vladivostok */
        'Vladivostok Standard Time', 'Vladivostok Daylight Time',
        'Asia/Vladivostok'
    ),
    (
        /* (UTC+04:00) Volgograd */
        'Volgograd Standard Time', 'Volgograd Daylight Time',
        'Europe/Volgograd'
    ),
    (
        /* (UTC+08:00) Perth */
        'W. Australia Standard Time', 'W. Australia Daylight Time',
        'Australia/Perth'
    ),
    (
        /* (UTC+01:00) West Central Africa */
        'W. Central Africa Standard Time', 'W. Central Africa Daylight Time',
        'Africa/Lagos'
    ),
    (
        /* (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna */
        'W. Europe Standard Time', 'W. Europe Daylight Time',
        'Europe/Berlin'
    ),
    (
        /* (UTC+07:00) Hovd */
        'W. Mongolia Standard Time', 'W. Mongolia Daylight Time',
        'Asia/Hovd'
    ),
    (
        /* (UTC+05:00) Ashgabat, Tashkent */
        'West Asia Standard Time', 'West Asia Daylight Time',
        'Asia/Tashkent'
    ),
    (
        /* (UTC+02:00) Gaza, Hebron */
        'West Bank Gaza Standard Time', 'West Bank Gaza Daylight Time',
        'Asia/Gaza'
    ),
    (
        /* (UTC+02:00) Gaza, Hebron */
        'West Bank Standard Time', 'West Bank Daylight Time',
        'Asia/Hebron'
    ),
    (
        /* (UTC+10:00) Guam, Port Moresby */
        'West Pacific Standard Time', 'West Pacific Daylight Time',
        'Pacific/Port_Moresby'
    ),
    (
        /* (UTC+09:00) Yakutsk */
        'Yakutsk Standard Time', 'Yakutsk Daylight Time',
        'Asia/Yakutsk'
    ),
    (
        /* (UTC-07:00) Yukon */
        'Yukon Standard Time', 'Yukon Daylight Time',
        'America/Whitehorse'
    ),
    (
    
        NULL, NULL, NULL
    )
) t(stdname,dstname,pgtzname);
GRANT SELECT ON babelfish_timezone_mapping TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
