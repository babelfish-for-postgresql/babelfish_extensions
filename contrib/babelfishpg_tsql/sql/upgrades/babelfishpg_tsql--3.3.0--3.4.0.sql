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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
