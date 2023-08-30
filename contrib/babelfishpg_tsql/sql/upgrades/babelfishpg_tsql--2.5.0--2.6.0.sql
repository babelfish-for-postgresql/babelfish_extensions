-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.6.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.sysdatetime() RETURNS datetime2
    AS $$select statement_timestamp()::datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetime() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sysdatetimeoffset() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(statement_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp()::pg_catalog.timestamp)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.SMALLDATETIMEFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER
                                                               )
RETURNS sys.smalldatetime
AS
$BODY$
DECLARE
    v_ressmalldatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    p_seconds INTEGER;
BEGIN
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if arguments are out of range
    IF ((p_year NOT BETWEEN 1900 AND 2079) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59) OR (p_year = 2079 AND p_month > 6) OR (p_year = 2079 AND p_month = 6 AND p_day > 6))
    THEN
        RAISE invalid_datetime_format;
    END IF;
    p_seconds := 0;
    v_ressmalldatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    p_seconds);

    v_string := v_ressmalldatetime::pg_catalog.text;
    RETURN CAST(v_string AS sys.SMALLDATETIME);
EXCEPTION   
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type smalldatetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';
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

CREATE OR REPLACE PROCEDURE sys.sp_describe_first_result_set (
	"@tsql" sys.nvarchar(8000),
    "@params" sys.nvarchar(8000) = NULL, 
    "@browse_information_mode" sys.tinyint = 0)
AS $$
BEGIN
	select * from sys.sp_describe_first_result_set_internal(@tsql, @params,  @browse_information_mode) order by column_ordinal;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_first_result_set TO PUBLIC;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT AS
'babelfishpg_tsql', 'objectproperty_internal'
LANGUAGE C STABLE;

ALTER FUNCTION sys.replace (in input_string text, in pattern text, in replacement text) IMMUTABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
