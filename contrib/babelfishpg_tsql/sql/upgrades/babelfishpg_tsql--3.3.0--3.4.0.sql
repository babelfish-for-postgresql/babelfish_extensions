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

-- Matches and returns column length of the corresponding column of the given table
CREATE OR REPLACE FUNCTION sys.COL_LENGTH(IN object_name TEXT, IN column_name TEXT)
RETURNS SMALLINT AS $BODY$
    DECLARE
        col_name TEXT;
        object_id oid;
        column_id INT;
        column_length INT;
        column_data_type TEXT;
        column_precision INT;
    BEGIN
        -- Get the object ID for the provided object_name
        object_id = sys.OBJECT_ID(object_name);
        IF object_id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Truncate and normalize the column name
        col_name = sys.babelfish_truncate_identifier(sys.babelfish_remove_delimiter_pair(lower(column_name)));

        -- Get the column ID for the provided column_name
        SELECT attnum INTO column_id FROM pg_attribute 
        WHERE attrelid = object_id AND lower(attname) = col_name 
        COLLATE sys.database_default;

        IF column_id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Retrieve the data type, precision, scale, and column length in characters
        SELECT a.atttypid::regtype, 
               CASE 
                   WHEN a.atttypmod > 0 THEN ((a.atttypmod - 4) >> 16) & 65535
                   ELSE NULL
               END,
               CASE
                   WHEN a.atttypmod > 0 THEN ((a.atttypmod - 4) & 65535)
                   ELSE a.atttypmod
               END
        INTO column_data_type, column_precision, column_length
        FROM pg_attribute a
        WHERE a.attrelid = object_id AND a.attnum = column_id;

        -- Remove delimiters
        column_data_type := sys.babelfish_remove_delimiter_pair(column_data_type);

        IF column_data_type IS NOT NULL THEN
            column_length := CASE
                -- Columns declared with max specifier case
                WHEN column_length = -1 AND column_data_type IN ('varchar', 'nvarchar', 'varbinary')
                THEN -1
                WHEN column_data_type = 'xml'
                THEN -1
                WHEN column_data_type IN ('tinyint', 'bit') 
                THEN 1
                WHEN column_data_type = 'smallint'
                THEN 2
                WHEN column_data_type = 'date'
                THEN 3
                WHEN column_data_type IN ('int', 'integer', 'real', 'smalldatetime', 'smallmoney') 
                THEN 4
                WHEN column_data_type IN ('time', 'time without time zone')
                THEN 5
                WHEN column_data_type IN ('double precision', 'bigint', 'datetime', 'datetime2', 'money') 
                THEN 8
                WHEN column_data_type = 'datetimeoffset'
                THEN 10
                WHEN column_data_type IN ('uniqueidentifier', 'text', 'image', 'ntext')
                THEN 16
                WHEN column_data_type = 'sysname'
                THEN 256
                WHEN column_data_type = 'sql_variant'
                THEN 8016
                WHEN column_data_type IN ('bpchar', 'char', 'varchar', 'binary', 'varbinary') 
                THEN column_length
                WHEN column_data_type IN ('nchar', 'nvarchar') 
                THEN column_length * 2
                WHEN column_data_type IN ('numeric', 'decimal')
                THEN 
                    CASE
                        WHEN column_precision IS NULL 
                        THEN NULL
                        ELSE ((column_precision + 8) / 9 * 4 + 1)
                    END
                ELSE NULL
            END;
        END IF;

        RETURN column_length::SMALLINT;
    END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
STRICT;

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

-- BABELFISH_SCHEMA
CREATE TABLE IF NOT EXISTS sys.babelfish_schema (
  db_name NAME NOT NULL,
  schema_name NAME NOT NULL,
  object_name NAME NOT NULL,
  permission NAME NOT NULL,
  grantee NAME NOT NULL,
  PRIMARY KEY(db_name, schema_name, object_name, permission, grantee)
);
GRANT SELECT ON sys.babelfish_schema TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
