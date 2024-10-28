-- SELECT FOR XML
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_ffunc(
    state INTERNAL
)
RETURNS XML AS
'babelfishpg_tsql', 'tsql_query_to_xml_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text_ffunc(
    state INTERNAL
)
RETURNS NTEXT AS
'babelfishpg_tsql', 'tsql_query_to_xml_text_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

CREATE OR REPLACE FUNCTION sys.tsql_select_for_xml_result(res XML)
RETURNS setof XML AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.tsql_select_for_xml_text_result(res NTEXT)
RETURNS setof NTEXT AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql IMMUTABLE;

-- SELECT FOR JSON
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_json_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_ffunc(
    state INTERNAL
)
RETURNS sys.NVARCHAR AS
'babelfishpg_tsql', 'tsql_query_to_json_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_json_agg(
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_json_sfunc,
    FINALFUNC = tsql_query_to_json_ffunc
);

CREATE OR REPLACE FUNCTION sys.tsql_select_for_json_result(res sys.NVARCHAR)
RETURNS setof sys.NVARCHAR AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql IMMUTABLE;

-- User and Login Functions
CREATE OR REPLACE FUNCTION sys.user_name(IN id OID DEFAULT NULL)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'user_name'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_constraintdef(IN constraint_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_constraintdef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_functiondef(IN function_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_functiondef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_expr(IN text_expr text DEFAULT NULL , IN function_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_expr'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_returnTypmodValue(IN function_id OID DEFAULT NULL)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_get_returnTypmodValue'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.user_id(IN user_name sys.sysname)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION sys.user_id()
RETURNS OID
AS 'babelfishpg_tsql', 'user_id_noarg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.suser_name_internal(IN server_user_id OID)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.BIT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date BIGINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.TINYINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date SMALLINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.MONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_money'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.SMALLMONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_smallmoney'
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
AS 'babelfishpg_tsql', 'datepart_internal_datetime'
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

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date NUMERIC ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_decimal'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date REAL ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_real'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date FLOAT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_float'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID)
RETURNS sys.NVARCHAR(128) AS $$
    SELECT CASE 
        WHEN server_user_id IS NULL THEN NULL
        ELSE sys.suser_name_internal(server_user_id)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but 
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85))
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sname()
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name();
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id_internal(IN login TEXT)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT)
RETURNS OID AS $$
    SELECT CASE
        WHEN login IS NULL THEN NULL
        ELSE sys.suser_id_internal(login)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id()
RETURNS OID
AS $$
    SELECT sys.suser_id_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but 
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = '' 
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE 
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sid()
RETURNS SYS.VARBINARY(85)
AS $$
    SELECT CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Matches and returns object name to Oid
CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_name'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.scope_identity()
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_scope_identity()::numeric(38,0);
$BODY$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.ident_seed(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_param(tablename, 'start'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.ident_incr(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_param(tablename, 'increment'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.ident_current(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_current(tablename)::numeric(38,0);
$BODY$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.checksum(VARIADIC arr TEXT[])
RETURNS INTEGER
AS 'babelfishpg_tsql', 'checksum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

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

    v_string := PG_CATALOG.CONCAT(input_expr_datetime2::pg_catalog.text , tz_offset);

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

    
        v_string := PG_CATALOG.CONCAT(input_expr_datetime2::pg_catalog.text,v_sign,abs(hr)::SMALLINT::text,':',
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


CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetime2fromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                                p_hour::NUMERIC, p_minute::NUMERIC, p_seconds::NUMERIC,
                                                p_fractions::NUMERIC, p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year NUMERIC,
                                                               IN p_month NUMERIC,
                                                               IN p_day NUMERIC,
                                                               IN p_hour NUMERIC,
                                                               IN p_minute NUMERIC,
                                                               IN p_seconds NUMERIC,
                                                               IN p_milliseconds NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
    v_milliseconds SMALLINT;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    -- Check if arguments are out of range
    IF ((floor(p_year)::SMALLINT NOT BETWEEN 1753 AND 9999) OR
        (floor(p_month)::SMALLINT NOT BETWEEN 1 AND 12) OR
        (floor(p_day)::SMALLINT NOT BETWEEN 1 AND 31) OR
        (floor(p_hour)::SMALLINT NOT BETWEEN 0 AND 23) OR
        (floor(p_minute)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_seconds)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_milliseconds)::SMALLINT NOT BETWEEN 0 AND 999))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_milliseconds := sys.babelfish_round_fractseconds(p_milliseconds::INTEGER);

    v_calc_seconds := pg_catalog.format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             CASE v_milliseconds
                                WHEN 1000 THEN '0'
                                ELSE lpad(v_milliseconds::VARCHAR, 3, '0')
                             END)::NUMERIC;

    v_resdatetime := make_timestamp(floor(p_year)::SMALLINT,
                                    floor(p_month)::SMALLINT,
                                    floor(p_day)::SMALLINT,
                                    floor(p_hour)::SMALLINT,
                                    floor(p_minute)::SMALLINT,
                                    v_calc_seconds);
    RETURN CASE
              WHEN (v_milliseconds != 1000) THEN v_resdatetime
              ELSE v_resdatetime + INTERVAL '1 second'
           END;
EXCEPTION
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetime, some of the arguments have values which are not valid.',
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

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year TEXT,
                                                               IN p_month TEXT,
                                                               IN p_day TEXT,
                                                               IN p_hour TEXT,
                                                               IN p_minute TEXT,
                                                               IN p_seconds TEXT,
                                                               IN p_milliseconds TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetimefromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                               p_hour::NUMERIC, p_minute::NUMERIC,
                                               p_seconds::NUMERIC, p_milliseconds::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT) RETURNS INTEGER AS
$BODY$
DECLARE 
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
	    RETURN 0;
    END IF;
    IF ($1::VARCHAR COLLATE "C" ~ '^\s*$') THEN 
	    RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
	THEN
		RETURN 1;
	END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
STABLE CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT) RETURNS INTEGER AS
$BODY$
DECLARE 
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
	    RETURN 0;
    END IF;

    -- IF ($1::VARCHAR ~ '^\s*$') THEN 
    IF (expr COLLATE "C" ~ '^\s*$') THEN 
	    RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
	THEN
		RETURN 1;
	END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
STABLE CALLED ON NULL INPUT;

-- Return the object ID given the object name. Can specify optional type.
CREATE OR REPLACE FUNCTION sys.object_id(IN object_name sys.VARCHAR, IN object_type sys.VARCHAR DEFAULT NULL)
RETURNS INTEGER AS
'babelfishpg_tsql', 'object_id'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.NVARCHAR, object_piece int)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

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

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour TEXT,
                                                           IN p_minute TEXT,
                                                           IN p_seconds TEXT,
                                                           IN p_fractions TEXT,
                                                           IN p_precision TEXT)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.timefromparts(p_hour::NUMERIC, p_minute::NUMERIC,
                                           p_seconds::NUMERIC, p_fractions::NUMERIC,
                                           p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.has_dbaccess(database_name SYSNAME) RETURNS INTEGER AS 
'babelfishpg_tsql', 'has_dbaccess'
LANGUAGE C STABLE STRICT;

-- This function performs string rewriting for the full text search CONTAINS predicate
-- in Babelfish
-- For example, a T-SQL query 
-- SELECT * FROM t WHERE CONTAINS(txt, '"good old days"')
-- is rewritten into a Postgres query 
-- SELECT * FROM t WHERE to_tsvector('fts_contains', txt) @@ to_tsquery('fts_contains', 'good <-> old <-> days')
-- In particular, the string constant '"good old days"' gets rewritten into 'good <-> old <-> days'
-- This function performs the string rewriting from '"good old days"' to 'good <-> old <-> days'
-- For prefix terms, '"word1*"' is rewritten into 'word1:*', and '"word1 word2 word3*"' is rewritten into 'word1<->word2<->word3:*'
CREATE OR REPLACE FUNCTION sys.babelfish_fts_rewrite(IN phrase text) RETURNS TEXT AS 
'babelfishpg_tsql', 'babelfish_fts_rewrite'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datefromparts(IN year INT, IN month INT, IN day INT)
RETURNS DATE AS
$BODY$
SELECT make_date(year, month, day);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.charindex(expressionToFind PG_CATALOG.TEXT,
										 expressionToSearch PG_CATALOG.TEXT,
										 start_location INTEGER DEFAULT 0)
RETURNS INTEGER AS
$BODY$
SELECT
CASE
WHEN start_location <= 0 THEN
	strpos(expressionToSearch, expressionToFind)
ELSE
	CASE
	WHEN strpos(substr(expressionToSearch, start_location), expressionToFind) = 0 THEN
		0
	ELSE
		strpos(substr(expressionToSearch, start_location), expressionToFind) + start_location - 1
	END
END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

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
    v_string := PG_CATALOG.CONCAT(v_resdatetime::pg_catalog.text,v_sign,abs(p_hour_offset)::SMALLINT::text,':',
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

create or replace function sys.babelfish_timezone_mapping(IN tmz text) returns text
AS 'babelfishpg_tsql', 'timezone_mapping'
LANGUAGE C IMMUTABLE ;

CREATE OR REPLACE FUNCTION sys.timezone(IN tzzone PG_CATALOG.TEXT ,  IN input_expr PG_CATALOG.TEXT)
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
    lower_tzn PG_CATALOG.TEXT;
    prev_res PG_CATALOG.TEXT;
    result PG_CATALOG.TEXT;
    is_dstt bool;
    tz_diff PG_CATALOG.TEXT;
    input_expr_tx PG_CATALOG.TEXT;
    input_expr_tmz TIMESTAMPTZ;
BEGIN
    IF input_expr IS NULL OR tzzone IS NULL THEN 
    	RETURN NULL;
    END IF;

    lower_tzn := lower(tzzone);
    IF lower_tzn <> 'utc' THEN
        tz_name := sys.babelfish_timezone_mapping(lower_tzn);
    ELSE
        tz_name := 'utc';
    END IF;

    IF tz_name = 'NULL' THEN
        RAISE USING MESSAGE := format('Argument data type or the parameter %s provided to AT TIME ZONE clause is invalid.', tzzone);
    END IF;

    IF pg_typeof(input_expr) IN ('sys.smalldatetime'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype) THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;

        result := (SELECT input_expr_tmz AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := PG_CATALOG.concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        input_expr_tx := PG_CATALOG.concat(input_expr_tx,tz_offset);
        return cast(input_expr_tx as sys.datetimeoffset);
    ELSIF  pg_typeof(input_expr) = 'sys.DATETIMEOFFSET'::regtype THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;
        result := (SELECT input_expr_tmz  AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := PG_CATALOG.concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        result := PG_CATALOG.concat(result,tz_offset);
        return cast(result as sys.datetimeoffset);
    ELSE
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
    END IF;
       
END;
$BODY$
LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION sys.typeproperty(
    typename sys.VARCHAR,
    property sys.VARCHAR
    )
RETURNS INT
AS $$
DECLARE
BEGIN
    RETURN NULL;
END;
$$
LANGUAGE plpgsql STABLE;


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

    v_string := PG_CATALOG.CONCAT(v_resdatetimeupdated::pg_catalog.text,'.',p_nanosecond::text,tz_offset);
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

    v_string := PG_CATALOG.CONCAT(v_resdatetimeupdated::pg_catalog.text,'.',p_nanosecond::text,v_sign,abs(v_hr)::TEXT,':',abs(v_mi)::TEXT);

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

-- wrapper functions for stuff --
CREATE OR REPLACE FUNCTION sys.stuff(expr sys.VARBINARY, start INTEGER, length INTEGER, replace_expr sys.VARCHAR)
RETURNS sys.VARBINARY
AS
$BODY$
BEGIN
    IF start IS NULL OR expr IS NULL OR length IS NULL THEN
        RETURN NULL;
    END IF;
    IF start <= 0 OR start > sys.len(expr) OR length < 0 THEN
        RETURN NULL;
    END IF;
    IF replace_expr IS NULL THEN
        RETURN (SELECT (overlay (expr::sys.VARCHAR placing '' from start for length))::sys.VARCHAR)::sys.VARBINARY;
    END IF;
    RETURN (SELECT (overlay (expr::sys.VARCHAR placing replace_expr::sys.VARCHAR from start for length))::sys.VARCHAR)::sys.VARBINARY;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.stuff(expr sys.VARCHAR, start INTEGER, length INTEGER, replace_expr sys.VARCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF start IS NULL OR expr IS NULL OR length IS NULL THEN
        RETURN NULL;
    END IF;
    IF start <= 0 OR start > length(expr) OR length < 0 THEN
        RETURN NULL;
    END IF;
    IF replace_expr IS NULL THEN
        RETURN (SELECT overlay (expr placing '' from start for length));
    END IF;
    RETURN (SELECT overlay (expr placing replace_expr from start for length));
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.stuff(expr sys.NVARCHAR, start INTEGER, length INTEGER, replace_expr sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF start IS NULL OR expr IS NULL OR length IS NULL THEN
        RETURN NULL;
    END IF;
    IF start <= 0 OR start > length(expr) OR length < 0 THEN
        RETURN NULL;
    END IF;
    IF replace_expr IS NULL THEN
        RETURN (SELECT overlay (expr placing '' from start for length));
    END IF;
    RETURN (SELECT overlay (expr placing replace_expr from start for length));
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.len(expr TEXT) RETURNS INTEGER AS
$BODY$
SELECT length(trim(trailing from expr));
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

-- Added for BABEL-1544
CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_VARBINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE c IMMUTABLE PARALLEL SAFE;

-- DATALENGTH
CREATE OR REPLACE FUNCTION sys.datalength(ANYELEMENT) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- provide both additional functions here to avoid implicit casting between string literals with/without N''
CREATE OR REPLACE FUNCTION sys.datalength(text) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.datalength(char) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- TODO: in MSSQL datalength against varchar(max) will return BIGINT instead of INTEGER. However in PG we ignore typmods in functions.
-- However this is not a critical issue so we will just leave it. We may come back to this difference later once we find out solution to typmods.

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.day(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('day', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.month(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('month', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.year(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('year', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.space(IN number INTEGER, OUT result SYS.VARCHAR) AS $$
BEGIN
    IF number < 0 THEN
        result := NULL;
    ELSE
        -- TSQL has a limitation of 8000 character spaces for space function.
        result := PG_CATALOG.repeat(' ',least(number, 8000));
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

create or replace function sys.isdate(v text)
returns integer
as
$body$
begin
    if v is NULL THEN
        return 0;
    else
        perform v::date;
        return 1;
    end if;
    EXCEPTION WHEN others THEN
    RETURN 0;
end
$body$
language 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION sys.is_collated_ci_as_internal(IN input_string TEXT) RETURNS BOOL
AS 'babelfishpg_tsql', 'is_collated_ci_as_internal'
LANGUAGE C VOLATILE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_collated_ci_as(IN input_string TEXT)
RETURNS BOOL AS
$$
	SELECT sys.is_collated_ci_as_internal(input_string);
$$
LANGUAGE SQL VOLATILE PARALLEL SAFE;

create or replace function sys.PATINDEX(in pattern varchar, in expression varchar) returns bigint as
$body$
declare
  v_find_result VARCHAR;
  v_pos bigint;
  v_regexp_pattern VARCHAR;
begin
  if pattern is null or expression is null then
    return null;
  end if;
  if PG_CATALOG.left(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"', 'i'::pg_catalog.TEXT);
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if PG_CATALOG.right(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%', 'i'::pg_catalog.TEXT);
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
  end if;
  v_find_result := substring(expression, v_regexp_pattern, '#');
  if v_find_result <> '' collate sys.database_default then
    v_pos := strpos(expression, v_find_result);
  else
    v_pos := 0;
  end if;
  return v_pos;
end;
$body$
language plpgsql immutable returns null on null input;

create or replace function sys.RAND(x in int)returns double precision
AS 'babelfishpg_tsql', 'tsql_random'
LANGUAGE C IMMUTABLE STRICT COST 1 PARALLEL RESTRICTED;

create or replace function sys.square(in x double precision) returns double precision
AS
$BODY$
DECLARE
	res double precision;
BEGIN
	res = pow(x, 2::float);
	return res;
END;
$BODY$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.atn2(IN x SYS.FLOAT, IN y SYS.FLOAT) RETURNS SYS.FLOAT
AS
$$
DECLARE
    res SYS.FLOAT;
BEGIN
    IF x = 0 AND y = 0 THEN
        RAISE EXCEPTION 'An invalid floating point operation occurred.';
    ELSE
        res = PG_CATALOG.atan2(x, y);
        RETURN res;
    END IF;
END;
$$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datepart(IN datepart PG_CATALOG.TEXT, IN arg anyelement) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Duplicate function with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datepart(IN datepart TEXT, IN arg TEXT) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSIF pg_typeof(arg) = 'pg_catalog.text'::regtype THEN
        return sys.datepart_internal(datepart, arg::sys.datetimeoffset::timestamp, sys.babelfish_get_datetimeoffset_tzoffset(arg::sys.datetimeoffset)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

-- datediff big
CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;


 -- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate TEXT) RETURNS DATETIME
AS
$body$
DECLARE
    is_date INT;
BEGIN
    is_date = sys.isdate(startdate);
    IF (is_date = 1) THEN 
        RETURN sys.dateadd_internal(datepart,num,startdate::datetime);
    ELSEIF (startdate is NULL) THEN
        RETURN NULL;
    ELSE
        RAISE EXCEPTION 'Conversion failed when converting date and/or time from character string.';
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate sys.bit) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate numeric) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;


CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate real) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate double precision) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT
AS
$body$
BEGIN
    IF pg_typeof(startdate) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.dateadd_internal_df(datepart, num,
                     startdate);
    ELSE
        return sys.dateadd_internal(datepart, num,
                     startdate);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

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
LANGUAGE plpgsql IMMUTABLE parallel safe;

/*
    This function is needed when input date is datetimeoffset type. When running the following query in postgres using tsql dialect, it faied.
        select dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset);
    We tried to merge this function with sys.dateadd_internal by using '+' when adding interval to datetimeoffset, 
    but the error shows : operator does not exist: sys.datetimeoffset + interval. As the result, we should not use '+' directly
    but should keep using OPERATOR(sys.+) when input date is in datetimeoffset type.
*/
CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset)
RETURNS datetimeoffset AS
'babelfishpg_common', 'dateadd_datetimeoffset'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'time'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 0);
	END IF;
    IF pg_typeof(startdate) = 'date'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 1);
	END IF;
    IF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 2);
    END IF;
    IF (pg_typeof(startdate) = 'sys.datetime'::regtype or pg_typeof(startdate) = 'timestamp'::regtype) THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 3);
    END IF;
    IF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 4);
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd_internal_datetime(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT, IN datetimetype INT) 
RETURNS TIMESTAMP AS
'babelfishpg_common', 'dateadd_datetime'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datediff_internal_big(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement)
RETURNS BIGINT AS
'babelfishpg_common', 'timestamp_diff_big'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement)
RETURNS INT AS
'babelfishpg_common', 'timestamp_diff'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

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

-- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg TEXT) RETURNS TEXT AS
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::date, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::date, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

-- These come from the built-in pg_catalog.count in pg_aggregate.dat
CREATE AGGREGATE sys.count(*)
(
	sfunc = int8inc,
	combinefunc = int8pl,
	msfunc = int8inc,
	minvfunc = int8dec,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	finalfunc = int4,
	mfinalfunc = int4,
	parallel = safe
);

CREATE AGGREGATE sys.count("any")
(
	sfunc = int8inc_any,
	combinefunc = int8pl,
	msfunc = int8inc_any,
	minvfunc = int8dec_any,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	finalfunc = int4,
	mfinalfunc = int4,
	parallel = safe
);

CREATE AGGREGATE sys.count_big(*)
(
	sfunc = int8inc,
	combinefunc = int8pl,
	msfunc = int8inc,
	minvfunc = int8dec,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	parallel = safe
);

CREATE AGGREGATE sys.count_big("any")
(
	sfunc = int8inc_any,
	combinefunc = int8pl,
	msfunc = int8inc_any,
	minvfunc = int8dec_any,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	parallel = safe
);

-- wrapper functions for replicate
CREATE OR REPLACE FUNCTION sys.replicate(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_arg_typeid oid;
    string_basetype oid;
BEGIN
    string_arg_typeid := pg_typeof(string)::oid;
    string_arg_datatype := sys.translate_pg_type_to_tsql(string_arg_typeid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(string_arg_typeid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for replicate function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of replicate function.', string_arg_datatype;
    END IF;

    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replicate(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that replicate with text input
-- will use following definition instead of PG replicate
CREATE OR REPLACE FUNCTION sys.replicate(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that replicate with ntext input
-- will use following definition instead of PG replicate
CREATE OR REPLACE FUNCTION sys.replicate(string NTEXT, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i < 0 THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.repeat(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- @@ functions
CREATE OR REPLACE FUNCTION sys.rowcount()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.rowcount_big()
RETURNS BIGINT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.pgerror()
	   RETURNS VARCHAR AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.trancount()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.datefirst()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.options()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.version()
        RETURNS sys.NVARCHAR(255)  AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.servername()
        RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.servicename()
        RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C STABLE;


CREATE OR REPLACE FUNCTION sys.database_principal_id(IN user_name sys.sysname)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION sys.database_principal_id()
RETURNS OID
AS 'babelfishpg_tsql', 'user_id_noarg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- In tsql @@max_precision represents max precision that server supports
-- As of now, we do not support change in max_precision. So, returning default value
CREATE OR REPLACE FUNCTION sys.max_precision()
RETURNS sys.TINYINT  AS 
$$
BEGIN
  RETURN 38;
END;
$$
LANGUAGE plpgsql;

-- not supported, only syntax support
CREATE OR REPLACE FUNCTION sys.PROCID()
	RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.spid()
RETURNS INTEGER AS
$BODY$
SELECT pg_backend_pid();
$BODY$
STRICT
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.get_current_full_xact_id()
    RETURNS XID8 AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'To use @@DBTS, set ''babelfishpg_tsql.escape_hatch_rowversion'' to ''ignore''';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql STABLE;

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

CREATE OR REPLACE FUNCTION sys.fetch_status()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.cursor_rows()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.cursor_status(text, text)
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

-- Floor for bit
CREATE OR REPLACE FUNCTION sys.floor(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Floor overloading for all int types
CREATE OR REPLACE FUNCTION sys.floor(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling for bit
CREATE OR REPLACE FUNCTION sys.ceiling(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling overloading for all int types
CREATE OR REPLACE FUNCTION sys.ceiling(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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

CREATE OR REPLACE FUNCTION sys.microsoftversion()
RETURNS INTEGER AS
$BODY$
	SELECT 201332885::INTEGER;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.APPLOCK_MODE(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS TEXT
AS 'babelfishpg_tsql', 'APPLOCK_MODE' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.APPLOCK_TEST(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
											IN "@lockmode" varchar(32),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'APPLOCK_TEST' LANGUAGE C STABLE;

-- Error handling functions
CREATE OR REPLACE FUNCTION sys.xact_state()
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'xact_state' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_line()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_line' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_message()
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'pltsql_error_message' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_number()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_number' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_procedure()
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'pltsql_error_procedure' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_severity()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_severity' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.error_state()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_state' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.rand() RETURNS FLOAT AS
$$
	SELECT random();
$$
LANGUAGE SQL STABLE STRICT PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.DEFAULT_DOMAIN()
RETURNS TEXT
AS 'babelfishpg_tsql', 'default_domain' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.db_id(sys.nvarchar(128)) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_id() RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name(int) RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name() RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.exp(IN arg DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'tsql_exp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(DOUBLE PRECISION) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg NUMERIC)
RETURNS DOUBLE PRECISION
AS
$BODY$
SELECT sys.exp(arg::DOUBLE PRECISION);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(NUMERIC) TO PUBLIC;

-- For numeric/decimal and float/double precision there is already inbuilt functions,
-- Following sign functions are for remaining datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg INT) RETURNS INT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0 THEN 1::INT
		WHEN arg < 0 THEN -1::INT
		ELSE 0::INT
	END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SMALLINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.TINYINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg BIGINT) RETURNS BIGINT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::BIGINT THEN 1::BIGINT
		WHEN arg < 0::BIGINT THEN -1::BIGINT
		ELSE 0::BIGINT
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.MONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::SYS.MONEY THEN 1::SYS.MONEY
		WHEN arg < 0::SYS.MONEY THEN -1::SYS.MONEY
		ELSE 0::SYS.MONEY
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.MONEY) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.SMALLMONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT sys.sign(arg::SYS.MONEY);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.SMALLMONEY) TO PUBLIC;

-- To handle remaining input datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg ANYELEMENT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(ANYELEMENT) TO PUBLIC;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.sign(IN arg TEXT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.lock_timeout()
RETURNS integer
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.lock_timeout');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.max_connections()
RETURNS integer
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'max_connections');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.max_connections() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.trigger_nestlevel()
RETURNS integer
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value integer;
begin
    return_value := (select pg_trigger_depth());
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.trigger_nestlevel() TO PUBLIC;

CREATE OR REPLACE VIEW babelfish_has_perms_by_name_permissions
AS
SELECT t.securable_type,t.permission_name,t.implied_dbo_permissions,t.fully_supported FROM
(
  VALUES
    ('application role', 'alter', 'f', 'f'),
    ('application role', 'any', 'f', 'f'),
    ('application role', 'control', 'f', 'f'),
    ('application role', 'view definition', 'f', 'f'),
    ('assembly', 'alter', 'f', 'f'),
    ('assembly', 'any', 'f', 'f'),
    ('assembly', 'control', 'f', 'f'),
    ('assembly', 'references', 'f', 'f'),
    ('assembly', 'take ownership', 'f', 'f'),
    ('assembly', 'view definition', 'f', 'f'),
    ('asymmetric key', 'alter', 'f', 'f'),
    ('asymmetric key', 'any', 'f', 'f'),
    ('asymmetric key', 'control', 'f', 'f'),
    ('asymmetric key', 'references', 'f', 'f'),
    ('asymmetric key', 'take ownership', 'f', 'f'),
    ('asymmetric key', 'view definition', 'f', 'f'),
    ('availability group', 'alter', 'f', 'f'),
    ('availability group', 'any', 'f', 'f'),
    ('availability group', 'control', 'f', 'f'),
    ('availability group', 'take ownership', 'f', 'f'),
    ('availability group', 'view definition', 'f', 'f'),
    ('certificate', 'alter', 'f', 'f'),
    ('certificate', 'any', 'f', 'f'),
    ('certificate', 'control', 'f', 'f'),
    ('certificate', 'references', 'f', 'f'),
    ('certificate', 'take ownership', 'f', 'f'),
    ('certificate', 'view definition', 'f', 'f'),
    ('contract', 'alter', 'f', 'f'),
    ('contract', 'any', 'f', 'f'),
    ('contract', 'control', 'f', 'f'),
    ('contract', 'references', 'f', 'f'),
    ('contract', 'take ownership', 'f', 'f'),
    ('contract', 'view definition', 'f', 'f'),
    ('database', 'administer database bulk operations', 'f', 'f'),
    ('database', 'alter', 't', 'f'),
    ('database', 'alter any application role', 'f', 'f'),
    ('database', 'alter any assembly', 'f', 'f'),
    ('database', 'alter any asymmetric key', 'f', 'f'),
    ('database', 'alter any certificate', 'f', 'f'),
    ('database', 'alter any column encryption key', 'f', 'f'),
    ('database', 'alter any column master key', 'f', 'f'),
    ('database', 'alter any contract', 'f', 'f'),
    ('database', 'alter any database audit', 'f', 'f'),
    ('database', 'alter any database ddl trigger', 'f', 'f'),
    ('database', 'alter any database event notification', 'f', 'f'),
    ('database', 'alter any database event session', 'f', 'f'),
    ('database', 'alter any database scoped configuration', 'f', 'f'),
    ('database', 'alter any dataspace', 'f', 'f'),
    ('database', 'alter any external data source', 'f', 'f'),
    ('database', 'alter any external file format', 'f', 'f'),
    ('database', 'alter any external language', 'f', 'f'),
    ('database', 'alter any external library', 'f', 'f'),
    ('database', 'alter any fulltext catalog', 'f', 'f'),
    ('database', 'alter any mask', 'f', 'f'),
    ('database', 'alter any message type', 'f', 'f'),
    ('database', 'alter any remote service binding', 'f', 'f'),
    ('database', 'alter any role', 'f', 'f'),
    ('database', 'alter any route', 'f', 'f'),
    ('database', 'alter any schema', 't', 'f'),
    ('database', 'alter any security policy', 'f', 'f'),
    ('database', 'alter any sensitivity classification', 'f', 'f'),
    ('database', 'alter any service', 'f', 'f'),
    ('database', 'alter any symmetric key', 'f', 'f'),
    ('database', 'alter any user', 't', 'f'),
    ('database', 'any', 't', 'f'),
    ('database', 'authenticate', 't', 'f'),
    ('database', 'backup database', 'f', 'f'),
    ('database', 'backup log', 'f', 'f'),
    ('database', 'checkpoint', 'f', 'f'),
    ('database', 'connect', 't', 'f'),
    ('database', 'connect replication', 'f', 'f'),
    ('database', 'control', 't', 'f'),
    ('database', 'create aggregate', 'f', 'f'),
    ('database', 'create assembly', 'f', 'f'),
    ('database', 'create asymmetric key', 'f', 'f'),
    ('database', 'create certificate', 'f', 'f'),
    ('database', 'create contract', 'f', 'f'),
    ('database', 'create database', 't', 'f'),
    ('database', 'create database ddl event notification', 'f', 'f'),
    ('database', 'create default', 'f', 'f'),
    ('database', 'create external language', 'f', 'f'),
    ('database', 'create external library', 'f', 'f'),
    ('database', 'create fulltext catalog', 'f', 'f'),
    ('database', 'create function', 't', 'f'),
    ('database', 'create message type', 'f', 'f'),
    ('database', 'create procedure', 't', 'f'),
    ('database', 'create queue', 'f', 'f'),
    ('database', 'create remote service binding', 'f', 'f'),
    ('database', 'create role', 'f', 'f'),
    ('database', 'create route', 'f', 'f'),
    ('database', 'create rule', 'f', 'f'),
    ('database', 'create schema', 't', 'f'),
    ('database', 'create service', 'f', 'f'),
    ('database', 'create symmetric key', 'f', 'f'),
    ('database', 'create synonym', 't', 'f'),
    ('database', 'create table', 't', 'f'),
    ('database', 'create type', 'f', 'f'),
    ('database', 'create view', 't', 'f'),
    ('database', 'create xml schema collection', 'f', 'f'),
    ('database', 'delete', 't', 'f'),
    ('database', 'execute', 't', 'f'),
    ('database', 'execute any external script', 'f', 'f'),
    ('database', 'insert', 't', 'f'),
    ('database', 'kill database connection', 'f', 'f'),
    ('database', 'references', 't', 'f'),
    ('database', 'select', 't', 'f'),
    ('database', 'showplan', 'f', 'f'),
    ('database', 'subscribe query notifications', 'f', 'f'),
    ('database', 'take ownership', 't', 'f'),
    ('database', 'unmask', 'f', 'f'),
    ('database', 'update', 't', 'f'),
    ('database', 'view any column encryption key definition', 'f', 'f'),
    ('database', 'view any column master key definition', 'f', 'f'),
    ('database', 'view any sensitivity classification', 'f', 'f'),
    ('database', 'view database state', 't', 'f'),
    ('database', 'view definition', 'f', 'f'),
    ('database scoped credential', 'alter', 'f', 'f'),
    ('database scoped credential', 'any', 'f', 'f'),
    ('database scoped credential', 'control', 'f', 'f'),
    ('database scoped credential', 'references', 'f', 'f'),
    ('database scoped credential', 'take ownership', 'f', 'f'),
    ('database scoped credential', 'view definition', 'f', 'f'),
    ('endpoint', 'alter', 'f', 'f'),
    ('endpoint', 'any', 'f', 'f'),
    ('endpoint', 'connect', 'f', 'f'),
    ('endpoint', 'control', 'f', 'f'),
    ('endpoint', 'take ownership', 'f', 'f'),
    ('endpoint', 'view definition', 'f', 'f'),
    ('external language', 'alter', 'f', 'f'),
    ('external language', 'any', 'f', 'f'),
    ('external language', 'control', 'f', 'f'),
    ('external language', 'execute external script', 'f', 'f'),
    ('external language', 'references', 'f', 'f'),
    ('external language', 'take ownership', 'f', 'f'),
    ('external language', 'view definition', 'f', 'f'),
    ('fulltext catalog', 'alter', 'f', 'f'),
    ('fulltext catalog', 'any', 'f', 'f'),
    ('fulltext catalog', 'control', 'f', 'f'),
    ('fulltext catalog', 'references', 'f', 'f'),
    ('fulltext catalog', 'take ownership', 'f', 'f'),
    ('fulltext catalog', 'view definition', 'f', 'f'),
    ('fulltext stoplist', 'alter', 'f', 'f'),
    ('fulltext stoplist', 'any', 'f', 'f'),
    ('fulltext stoplist', 'control', 'f', 'f'),
    ('fulltext stoplist', 'references', 'f', 'f'),
    ('fulltext stoplist', 'take ownership', 'f', 'f'),
    ('fulltext stoplist', 'view definition', 'f', 'f'),
    ('login', 'alter', 'f', 'f'),
    ('login', 'any', 'f', 'f'),
    ('login', 'control', 'f', 'f'),
    ('login', 'impersonate', 'f', 'f'),
    ('login', 'view definition', 'f', 'f'),
    ('message type', 'alter', 'f', 'f'),
    ('message type', 'any', 'f', 'f'),
    ('message type', 'control', 'f', 'f'),
    ('message type', 'references', 'f', 'f'),
    ('message type', 'take ownership', 'f', 'f'),
    ('message type', 'view definition', 'f', 'f'),
    ('object', 'alter', 't', 'f'),
    ('object', 'any', 't', 't'),
    ('object', 'control', 't', 'f'),
    ('object', 'delete', 't', 't'),
    ('object', 'execute', 't', 't'),
    ('object', 'insert', 't', 't'),
    ('object', 'receive', 'f', 'f'),
    ('object', 'references', 't', 't'),
    ('object', 'select', 't', 't'),
    ('object', 'take ownership', 'f', 'f'),
    ('object', 'update', 't', 't'),
    ('object', 'view change tracking', 'f', 'f'),
    ('object', 'view definition', 'f', 'f'),
    ('remote service binding', 'alter', 'f', 'f'),
    ('remote service binding', 'any', 'f', 'f'),
    ('remote service binding', 'control', 'f', 'f'),
    ('remote service binding', 'take ownership', 'f', 'f'),
    ('remote service binding', 'view definition', 'f', 'f'),
    ('role', 'alter', 'f', 'f'),
    ('role', 'any', 'f', 'f'),
    ('role', 'control', 'f', 'f'),
    ('role', 'take ownership', 'f', 'f'),
    ('role', 'view definition', 'f', 'f'),
    ('route', 'alter', 'f', 'f'),
    ('route', 'any', 'f', 'f'),
    ('route', 'control', 'f', 'f'),
    ('route', 'take ownership', 'f', 'f'),
    ('route', 'view definition', 'f', 'f'),
    ('schema', 'alter', 't', 'f'),
    ('schema', 'any', 't', 'f'),
    ('schema', 'control', 't', 'f'),
    ('schema', 'create sequence', 'f', 'f'),
    ('schema', 'delete', 't', 'f'),
    ('schema', 'execute', 't', 'f'),
    ('schema', 'insert', 't', 'f'),
    ('schema', 'references', 't', 'f'),
    ('schema', 'select', 't', 'f'),
    ('schema', 'take ownership', 't', 'f'),
    ('schema', 'update', 't', 'f'),
    ('schema', 'view change tracking', 'f', 'f'),
    ('schema', 'view definition', 'f', 'f'),
    ('search property list', 'alter', 'f', 'f'),
    ('search property list', 'any', 'f', 'f'),
    ('search property list', 'control', 'f', 'f'),
    ('search property list', 'references', 'f', 'f'),
    ('search property list', 'take ownership', 'f', 'f'),
    ('search property list', 'view definition', 'f', 'f'),
    ('server', 'administer bulk operations', 'f', 'f'),
    ('server', 'alter any availability group', 'f', 'f'),
    ('server', 'alter any connection', 'f', 'f'),
    ('server', 'alter any credential', 'f', 'f'),
    ('server', 'alter any database', 't', 'f'),
    ('server', 'alter any endpoint', 'f', 'f'),
    ('server', 'alter any event notification', 'f', 'f'),
    ('server', 'alter any event session', 'f', 'f'),
    ('server', 'alter any linked server', 'f', 'f'),
    ('server', 'alter any login', 'f', 'f'),
    ('server', 'alter any server audit', 'f', 'f'),
    ('server', 'alter any server role', 'f', 'f'),
    ('server', 'alter resources', 'f', 'f'),
    ('server', 'alter server state', 'f', 'f'),
    ('server', 'alter settings', 't', 'f'),
    ('server', 'alter trace', 'f', 'f'),
    ('server', 'any', 't', 'f'),
    ('server', 'authenticate server', 't', 'f'),
    ('server', 'connect any database', 't', 'f'),
    ('server', 'connect sql', 't', 'f'),
    ('server', 'control server', 't', 'f'),
    ('server', 'create any database', 't', 'f'),
    ('server', 'create availability group', 'f', 'f'),
    ('server', 'create ddl event notification', 'f', 'f'),
    ('server', 'create endpoint', 'f', 'f'),
    ('server', 'create server role', 'f', 'f'),
    ('server', 'create trace event notification', 'f', 'f'),
    ('server', 'external access assembly', 'f', 'f'),
    ('server', 'impersonate any login', 'f', 'f'),
    ('server', 'select all user securables', 't', 'f'),
    ('server', 'shutdown', 'f', 'f'),
    ('server', 'unsafe assembly', 'f', 'f'),
    ('server', 'view any database', 't', 'f'),
    ('server', 'view any definition', 'f', 'f'),
    ('server', 'view server state', 't', 'f'),
    ('server role', 'alter', 'f', 'f'),
    ('server role', 'any', 'f', 'f'),
    ('server role', 'control', 'f', 'f'),
    ('server role', 'take ownership', 'f', 'f'),
    ('server role', 'view definition', 'f', 'f'),
    ('service', 'alter', 'f', 'f'),
    ('service', 'any', 'f', 'f'),
    ('service', 'control', 'f', 'f'),
    ('service', 'send', 'f', 'f'),
    ('service', 'take ownership', 'f', 'f'),
    ('service', 'view definition', 'f', 'f'),
    ('symmetric key', 'alter', 'f', 'f'),
    ('symmetric key', 'any', 'f', 'f'),
    ('symmetric key', 'control', 'f', 'f'),
    ('symmetric key', 'references', 'f', 'f'),
    ('symmetric key', 'take ownership', 'f', 'f'),
    ('symmetric key', 'view definition', 'f', 'f'),
    ('type', 'any', 'f', 'f'),
    ('type', 'control', 'f', 'f'),
    ('type', 'execute', 'f', 'f'),
    ('type', 'references', 'f', 'f'),
    ('type', 'take ownership', 'f', 'f'),
    ('type', 'view definition', 'f', 'f'),
    ('user', 'alter', 'f', 'f'),
    ('user', 'any', 'f', 'f'),
    ('user', 'control', 'f', 'f'),
    ('user', 'impersonate', 'f', 'f'),
    ('user', 'view definition', 'f', 'f'),
    ('xml schema collection', 'alter', 'f', 'f'),
    ('xml schema collection', 'any', 'f', 'f'),
    ('xml schema collection', 'control', 'f', 'f'),
    ('xml schema collection', 'execute', 'f', 'f'),
    ('xml schema collection', 'references', 'f', 'f'),
    ('xml schema collection', 'take ownership', 'f', 'f'),
    ('xml schema collection', 'view definition', 'f', 'f')
) t(securable_type, permission_name, implied_dbo_permissions, fully_supported);
GRANT SELECT ON babelfish_has_perms_by_name_permissions TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    db_name text COLLATE sys.database_default; 
    bbf_schema_name text;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    is_cross_db boolean := false;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    userid oid;
    object_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
    cs_as_securable text COLLATE "C" := securable;
    cs_as_securable_class text COLLATE "C" := securable_class;
    cs_as_permission text COLLATE "C" := permission;
    cs_as_sub_securable text COLLATE "C" := sub_securable;
    cs_as_sub_securable_class text COLLATE "C" := sub_securable_class;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    cs_as_securable = lower(PG_CATALOG.rtrim(cs_as_securable));
    cs_as_securable_class = lower(PG_CATALOG.rtrim(cs_as_securable_class));
    cs_as_permission = lower(PG_CATALOG.rtrim(cs_as_permission));
    cs_as_sub_securable = lower(PG_CATALOG.rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(PG_CATALOG.rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, user must be evaluating column privileges.
    -- Check that inputs are valid for column privileges: sub_securable_class must 
    -- be column, securable_class must be object, and permission cannot be any.
    ELSIF cs_as_sub_securable_class IS NOT NULL 
            AND (cs_as_sub_securable_class != 'column' 
                    OR cs_as_securable_class IS NULL 
                    OR cs_as_securable_class != 'object' 
                    OR cs_as_permission = 'any') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null
    ELSIF cs_as_securable IS NULL AND cs_as_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If securable_class is null, securable must be null
    ELSIF cs_as_securable IS NOT NULL AND cs_as_securable_class IS NULL THEN
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'server' THEN
        -- SQL Server does not permit a securable_class value of 'server'.
        -- securable_class should be NULL to evaluate server permissions.
        RETURN NULL;
    ELSIF cs_as_securable_class IS NULL THEN
        -- NULL indicates a server permission. Set this variable so that we can
        -- search for the matching entry in babelfish_has_perms_by_name_permissions
        cs_as_securable_class = 'server';
    END IF;

    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported 
    INTO implied_dbo_permissions,fully_supported 
    FROM babelfish_has_perms_by_name_permissions p 
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;
    
    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name 
                    AND ext.dbid = sys.db_id()) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND
		(SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) = 'dbo' THEN
        RETURN CAST(implied_dbo_permissions AS integer);
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable class.
    -- The block above has dealt with all permissions that are not fully supported, so 
    -- if we reach this point we know the securable class is OBJECT.
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name 
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    -- If schema was not specified, use the default
    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE 
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

	IF database_id <> sys.db_id() THEN
        is_cross_db = true;
	END IF;

	userid := (
        SELECT CASE
            WHEN is_cross_db THEN sys.suser_id()
            ELSE sys.user_id()
        END);
  
    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname 
                    FROM sys.babelfish_namespace_ext ext 
                    WHERE ext.orig_name = bbf_schema_name 
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := PG_CATALOG.concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(a.attname)
                        FROM pg_attribute a
                        INNER JOIN pg_class c ON c.oid = a.attrelid
                        INNER JOIN pg_namespace s ON s.oid = c.relnamespace
                        WHERE
                        a.attname = cs_as_sub_securable COLLATE sys.database_default
                        AND c.relname = object_name COLLATE sys.database_default
                        AND s.nspname = pg_schema COLLATE sys.database_default
                        AND NOT a.attisdropped
                        AND (s.nspname IN (SELECT nspname FROM sys.babelfish_namespace_ext) OR s.nspname = 'sys')
                        -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
                        AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
                        AND a.attnum > 0) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname) 
                    FROM pg_catalog.pg_class 
                    WHERE relname = object_name COLLATE sys.database_default
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default 
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'
                
            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );
    
    -- Object was not found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;
  
    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT CAST(oid AS regprocedure) 
            INTO function_signature 
            FROM pg_catalog.pg_proc 
            WHERE proname = object_name COLLATE sys.database_default
                AND pronamespace = namespace_id;
    END IF;

    return_value := (
        SELECT CASE
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(userid, object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(userid, qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(userid, qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
        END
    );

    RETURN return_value;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME, 
    securable_class sys.nvarchar(60), 
    permission sys.SYSNAME, 
    sub_securable sys.SYSNAME,
    sub_securable_class sys.nvarchar(60)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.schema_name()
RETURNS sys.sysname
LANGUAGE plpgsql
STABLE STRICT
AS $function$
begin
    RETURN (select orig_name from sys.babelfish_namespace_ext ext  
                    where ext.nspname = (select current_schema()) and  ext.dbid::oid = sys.db_id()::oid)::sys.sysname;
EXCEPTION 
    WHEN others THEN
        RETURN NULL;
END;
$function$
;
GRANT EXECUTE ON FUNCTION sys.schema_name() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value text;
begin
	RETURN (select orig_loginname from sys.babelfish_authid_login_ext where rolname = session_user)::sys.sysname;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.original_login() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE STRICT
AS $$
DECLARE
    extra_bytes CONSTANT INTEGER := 4;
    return_value INTEGER;
BEGIN
	return_value:=
        CASE LOWER(property_name)
            WHEN 'charmaxlen' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes
                    ELSE NULL
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'allowsnull' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attnotnull THEN 0
                    ELSE 1
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'iscomputed' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attgenerated != '' THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            WHEN 'columnid' COLLATE sys.database_default THEN
                (SELECT a.attnum FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'ordinal' COLLATE sys.database_default THEN
                (SELECT b.count FROM (SELECT attname, row_number() OVER () AS count FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND attisdropped = false AND attnum > 0 ORDER BY a.attnum) AS b WHERE b.attname = property COLLATE sys.database_default)
            WHEN 'isidentity' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN char_length(a.attidentity) > 0 THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            ELSE
                NULL
        END;
    RETURN return_value::INTEGER;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT) TO PUBLIC;

COMMENT ON FUNCTION sys.columnproperty
IS 'This function returns column or parameter information. Currently only works with "charmaxlen", and "allowsnull" otherwise returns 0.';

-- substring --
CREATE OR REPLACE FUNCTION sys.substring(string TEXT, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string NTEXT, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.BPCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NVARCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARBINARY, i INTEGER, j INTEGER)
RETURNS sys.VARBINARY
AS 'babelfishpg_tsql', 'tsql_varbinary_substr' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string ANYELEMENT, i INTEGER, j INTEGER)
RETURNS sys.VARBINARY
AS
$BODY$
DECLARE
    type_oid oid;
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    type_oid := pg_typeof(string);
    string_arg_datatype := sys.translate_pg_type_to_tsql(type_oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(type_oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for substring function
    IF string_arg_datatype NOT IN ('binary', 'image') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of substring function.', string_arg_datatype;
    END IF;

    RETURN sys.substring(string::sys.VARBINARY, i, j);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- wrapper functions for upper --
-- Function to handle datatypes which are implicitly convertable to VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    type_oid oid;
    typ_base_oid oid;
    typnam text;
BEGIN
    typnam := NULL;
    type_oid := pg_typeof($1);
    typnam := sys.translate_pg_type_to_tsql(type_oid);
    IF typnam IS NULL THEN
        typ_base_oid := sys.bbf_get_immediate_base_type_of_UDT(type_oid);
        typnam := sys.translate_pg_type_to_tsql(typ_base_oid);
    END IF;
    IF typnam IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of upper function.', typnam;
    END IF;
    IF $1 IS NULL THEN
        RETURN NULL;
    END IF;
    -- Call the underlying function after preprocessing
    RETURN pg_catalog.upper($1::sys.varchar);
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle TEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(TEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NTEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(NTEXT)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for lower --
-- Function to handle datatypes which are implicitly convertable to VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    type_oid oid;
    typ_base_oid oid;
    typnam text;
BEGIN
    typnam := NULL;
    type_oid := pg_typeof($1);
    typnam := sys.translate_pg_type_to_tsql(type_oid);
    IF typnam IS NULL THEN
        typ_base_oid := sys.bbf_get_immediate_base_type_of_UDT(type_oid);
        typnam := sys.translate_pg_type_to_tsql(typ_base_oid);
    END IF;
    IF typnam IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of lower function.', typnam;
    END IF;
    IF $1 IS NULL THEN
        RETURN NULL;
    END IF;
    -- Call the underlying function after preprocessing
    RETURN pg_catalog.lower($1::sys.varchar);
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle TEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(TEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NTEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(NTEXT)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for TRIM
CREATE OR REPLACE FUNCTION sys.TRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS 
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for trim function
    IF string_arg_datatype NOT IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of Trim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.btrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Additional handling is added for TRIM function with 2 arguments, 
-- hence only following two definitions are required.
CREATE OR REPLACE FUNCTION sys.TRIM(characters sys.VARCHAR, string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string, characters);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(characters sys.VARCHAR, string sys.VARCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string, characters);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for LTRIM
CREATE OR REPLACE FUNCTION sys.LTRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for ltrim function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of ltrim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.ltrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that ltrim with text input
-- will use following definition instead of PG ltrim
CREATE OR REPLACE FUNCTION sys.LTRIM(string TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that ltrim with ntext input
-- will use following definition instead of PG ltrim
CREATE OR REPLACE FUNCTION sys.LTRIM(string NTEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for RTRIM
CREATE OR REPLACE FUNCTION sys.RTRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for rtrim function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of rtrim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.rtrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that rtrim with text input
-- will use following definition instead of PG rtrim
CREATE OR REPLACE FUNCTION sys.RTRIM(string TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that rtrim with ntext input
-- will use following definition instead of PG rtrim
CREATE OR REPLACE FUNCTION sys.RTRIM(string NTEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


-- wrapper functions for LEFT
CREATE OR REPLACE FUNCTION sys.LEFT(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for left function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of left function.', string_arg_datatype;
    END IF;

    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.BPCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.VARCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that left with text input
-- will use following definition instead of PG left
CREATE OR REPLACE FUNCTION sys.LEFT(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that left with ntext input
-- will use following definition instead of PG left
CREATE OR REPLACE FUNCTION sys.LEFT(string NTEXT, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;


-- wrapper functions for RIGHT
CREATE OR REPLACE FUNCTION sys.RIGHT(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for right function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of right function.', string_arg_datatype;
    END IF;

    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN PG_CATALOG.right(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.BPCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.VARCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that right with text input
-- will use following definition instead of PG right
CREATE OR REPLACE FUNCTION sys.RIGHT(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that right with ntext input
-- will use following definition instead of PG right
CREATE OR REPLACE FUNCTION sys.RIGHT(string NTEXT, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- wrapper functions for translate --
CREATE OR REPLACE FUNCTION sys.translate(string sys.VARCHAR, characters sys.VARCHAR, translations sys.VARCHAR)
RETURNS sys.VARCHAR
AS $$
BEGIN
    IF length(characters) != length(translations) THEN
        RAISE EXCEPTION 'The second and third arguments of the TRANSLATE built-in function must contain an equal number of characters.';
    END IF;
    
    RETURN PG_CATALOG.TRANSLATE(string, characters, translations);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.translate(string sys.NVARCHAR, characters sys.VARCHAR, translations sys.VARCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    IF length(characters) != length(translations) THEN
        RAISE EXCEPTION 'The second and third arguments of the TRANSLATE built-in function must contain an equal number of characters.';
    END IF;

    RETURN PG_CATALOG.TRANSLATE(string, characters, translations);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for concat --
CREATE OR REPLACE FUNCTION sys.concat(VARIADIC args sys.VARCHAR[] DEFAULT '{}')
RETURNS sys.VARCHAR
AS $$
DECLARE
    arr_len INTEGER;
BEGIN
    arr_len := array_length(args, 1);

    -- PG has limitation for max number of args = 100
    IF arr_len IS NULL OR arr_len < 2 OR arr_len > 100 THEN
        RAISE EXCEPTION 'The concat function requires 2 to 100 arguments.';
    END IF;

    RETURN (PG_CATALOG.ARRAY_TO_STRING(args, ''));
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.concat(VARIADIC args sys.NVARCHAR[])
RETURNS sys.NVARCHAR
AS $$
DECLARE
    arr_len INTEGER;
BEGIN
    arr_len := array_length(args, 1);

    -- PG has limitation for max number of args = 100
    IF arr_len < 2 OR arr_len > 100 THEN
        RAISE EXCEPTION 'The concat function requires 2 to 100 arguments.';
    END IF;

    RETURN (PG_CATALOG.ARRAY_TO_STRING(args, ''));
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- wrapper functions for concat_ws --
CREATE OR REPLACE FUNCTION sys.concat_ws(seperator sys.VARCHAR DEFAULT '', VARIADIC args sys.VARCHAR[] DEFAULT '{}')
RETURNS sys.VARCHAR
AS $$
DECLARE
    arr_len INTEGER;
BEGIN
    arr_len := array_length(args, 1);

    -- PG has limitation for max number of args = 100
    IF arr_len IS NULL OR arr_len < 2 OR arr_len > 99 THEN
        RAISE EXCEPTION 'The concat_ws function requires 3 to 100 arguments.';
    END IF;

    IF seperator IS NULL THEN
        RETURN (PG_CATALOG.ARRAY_TO_STRING(args, ''));
    END IF;

    RETURN (PG_CATALOG.ARRAY_TO_STRING(args, seperator));
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.concat_ws(seperator sys.NVARCHAR, VARIADIC args sys.NVARCHAR[])
RETURNS sys.NVARCHAR
AS $$
DECLARE
    arr_len INTEGER;
BEGIN
    arr_len := array_length(args, 1);

    -- PG has limitation for max number of args = 100
    IF arr_len < 2 OR arr_len > 99 THEN
        RAISE EXCEPTION 'The concat_ws function requires 3 to 100 arguments.';
    END IF;

    IF seperator IS NULL THEN
        RETURN (PG_CATALOG.ARRAY_TO_STRING(args, ''));
    END IF;

    RETURN (PG_CATALOG.ARRAY_TO_STRING(args, seperator));
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- For getting host os from PG_VERSION_STR
CREATE OR REPLACE FUNCTION sys.get_host_os()
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'host_os' LANGUAGE C IMMUTABLE PARALLEL SAFE;

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

/*
 * Table type can identified by reverse dependency between table and
 * type in pg_depend.
 * If a table is dependent upon it's row type with dependency type
 * as DEPENDENCY_INTERNAL (i) then it's a T-SQL table type.
 */
CREATE OR REPLACE FUNCTION sys.is_table_type(object_id oid) RETURNS bool AS
$BODY$
SELECT
  EXISTS(
    SELECT 1
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid AND pt.oid = dep.refobjid
    join sys.schemas sch on pt.typnamespace = sch.schema_id
    JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i' AND pt.typrelid = object_id AND pc.relkind = 'r'
    AND dep.classid = 'pg_catalog.pg_class'::regclass AND dep.refclassid = 'pg_catalog.pg_type'::regclass);
$BODY$
LANGUAGE SQL STABLE STRICT;

-- JSON Functions
CREATE OR REPLACE FUNCTION sys.isjson(json_string text)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_isjson' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_value(json_string text, path text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_json_value' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_query(json_string text, path text default '$')
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_json_query' LANGUAGE C IMMUTABLE PARALLEL SAFE;

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
    new_jsonb_path = PG_CATALOG.CONCAT('{',json_path_convert,'}'); -- Final required format of path by jsonb_set

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


CREATE OR REPLACE FUNCTION sys.openjson_object(json_string text)
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
SELECT  key,
        CASE json_typeof(value) WHEN 'null'     THEN NULL
                                ELSE            TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null'     THEN 0
                                WHEN 'string'   THEN 1
                                WHEN 'number'   THEN 2
                                WHEN 'boolean'  THEN 3
                                WHEN 'array'    THEN 4
                                WHEN 'object'   THEN 5
        END
    FROM json_each(json_string::JSON)
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_array(json_string text)
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
SELECT  (row_number() over ())-1,
        CASE json_typeof(value) WHEN 'null'     THEN NULL
                                ELSE            TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null'     THEN 0
                                WHEN 'string'   THEN 1
                                WHEN 'number'   THEN 2
                                WHEN 'boolean'  THEN 3
                                WHEN 'array'    THEN 4
                                WHEN 'object'   THEN 5
        END
    FROM json_array_elements(json_string::JSON) AS value
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_simple(json_string text, path text default '$')
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
DECLARE
    sub_json text := sys.json_query(json_string, path);
BEGIN
    IF json_typeof(sub_json::JSON) = 'array' THEN
        RETURN QUERY SELECT * FROM sys.openjson_array(sub_json);
    ELSE
        RETURN QUERY SELECT * FROM sys.openjson_object(sub_json);
    END IF;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.openjson_with(json_string text, path text, VARIADIC column_paths text[])
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_openjson_with' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sp_datatype_info_helper(
    IN odbcVer smallint,
    IN is_100 bool,
    OUT TYPE_NAME VARCHAR(20),
    OUT DATA_TYPE INT,
    OUT "PRECISION" BIGINT,
    OUT LITERAL_PREFIX VARCHAR(20),
    OUT LITERAL_SUFFIX VARCHAR(20),
    OUT CREATE_PARAMS VARCHAR(20),
    OUT NULLABLE INT,
    OUT CASE_SENSITIVE INT,
    OUT SEARCHABLE INT,
    OUT UNSIGNED_ATTRIBUTE INT,
    OUT MONEY INT,
    OUT AUTO_INCREMENT INT,
    OUT LOCAL_TYPE_NAME VARCHAR(20),
    OUT MINIMUM_SCALE INT,
    OUT MAXIMUM_SCALE INT,
    OUT SQL_DATA_TYPE INT,
    OUT SQL_DATETIME_SUB INT,
    OUT NUM_PREC_RADIX INT,
    OUT INTERVAL_PRECISION INT,
    OUT USERTYPE INT,
    OUT LENGTH INT,
    OUT SS_DATA_TYPE smallint,
-- below column is added in order to join information_schema.columns of PG for sys.sp_columns_100_view
    OUT PG_TYPE_NAME VARCHAR(20)
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'sp_datatype_info_helper'
LANGUAGE C IMMUTABLE STRICT;

-- Role member functions
CREATE OR REPLACE FUNCTION sys.is_rolemember_internal(
	IN role sys.SYSNAME,
	IN database_principal sys.SYSNAME
)
RETURNS INT AS 'babelfishpg_tsql', 'is_rolemember'
LANGUAGE C STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
DECLARE
    is_windows_grp boolean := (CHARINDEX('\', role) != 0); -- '  adding quote in comment to suppress build warning
BEGIN
    -- Always return 1 for 'public'
    IF (role = 'public')
    THEN RETURN 1;
    END IF;

    IF EXISTS (SELECT orig_loginname FROM sys.babelfish_authid_login_ext WHERE orig_loginname = role AND type != 'S') -- do not consider sql logins
    THEN
        IF ((EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type IN ('SERVER ROLE', 'SQL LOGIN'))) OR is_windows_grp) -- do not consider sql logins, server roles
        THEN RETURN NULL; -- Also return NULL if session is not a windows auth session but argument is a windows group
        ELSIF EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type NOT IN ('SERVER ROLE', 'SQL LOGIN'))
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSIF EXISTS (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE orig_username = role)
    THEN
        IF EXISTS (SELECT name FROM sys.user_token WHERE name = role)
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSIF (is_windows_grp)
        THEN RETURN NULL; -- Return NULL if session is not a windows auth session but argument is a windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSE RETURN NULL; -- Return NULL if role/group does not exist
    END IF;
END;
$$
LANGUAGE plpgsql STRICT STABLE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(IN role sys.SYSNAME)
RETURNS INT AS
$$
	SELECT sys.is_rolemember_internal(role, NULL);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(
	IN role sys.SYSNAME, 
	IN database_principal sys.SYSNAME
)
RETURNS INT AS
$$
	SELECT sys.is_rolemember_internal(role, database_principal);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replace (input_string sys.VARCHAR, pattern sys.VARCHAR, replacement sys.VARCHAR)
RETURNS sys.VARCHAR AS
$BODY$
BEGIN
   if PG_CATALOG.length(pattern) = 0 then
       return input_string;
   elsif sys.is_collated_ci_as(input_string) then
       return regexp_replace(input_string, '***=' || pattern, replacement, 'ig'::pg_catalog.TEXT);
   else
       return regexp_replace(input_string, '***=' || pattern, replacement, 'g'::pg_catalog.TEXT);
   end if;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION sys.replace (input_string sys.NVARCHAR, pattern sys.NVARCHAR, replacement sys.NVARCHAR)
RETURNS sys.NVARCHAR AS
$BODY$
BEGIN
   if PG_CATALOG.length(pattern) = 0 then
       return input_string;
   elsif sys.is_collated_ci_as(input_string) then
       return regexp_replace(input_string, '***=' || pattern, replacement, 'ig'::pg_catalog.TEXT);
   else
       return regexp_replace(input_string, '***=' || pattern, replacement, 'g'::pg_catalog.TEXT);
   end if;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT AS
'babelfishpg_tsql', 'objectproperty_internal'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(
    id INT,
    property SYS.VARCHAR
)
RETURNS SYS.SQL_VARIANT
AS $$
BEGIN
	property := PG_CATALOG.RTRIM(LOWER(COALESCE(property, '')));
	
	IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
	THEN
		RETURN NULL;
	END IF;

	IF property = 'basetype' -- BaseType
	THEN
		RETURN (SELECT CAST(ao.type AS SYS.SQL_VARIANT) 
                FROM sys.all_objects ao
                WHERE ao.object_id = id
                LIMIT 1
                );
    END IF;

    RETURN CAST(OBJECTPROPERTY(id, property) AS SYS.SQL_VARIANT);
END
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.sid_binary(IN login sys.nvarchar)
RETURNS SYS.VARBINARY
AS $$
    SELECT CAST(NULL AS SYS.VARBINARY);
$$ 
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.language()
RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.host_name()
RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.host_id()
RETURNS sys.VARCHAR(10)  AS 'babelfishpg_tsql' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.host_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.identity_into_bigint(IN typename INT, IN seed BIGINT, IN increment BIGINT)
RETURNS bigint AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.identity_into_bigint(INT, BIGINT, BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 INT)
RETURNS int AS 'babelfishpg_tsql','int_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 SMALLINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 TINYINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 INT)
RETURNS int  AS 'babelfishpg_tsql','int_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 SMALLINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 TINYINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 BIGINT, IN arg2 NUMERIC)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_power' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(BIGINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 INT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','int_power' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(INT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 SMALLINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(SMALLINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 TINYINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(TINYINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.bbf_log(IN arg1 FLOAT)
RETURNS FLOAT  AS 'babelfishpg_tsql','numeric_log_natural' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_log(IN arg1 FLOAT, IN arg2 INT)
RETURNS FLOAT  AS 'babelfishpg_tsql','numeric_log_base' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_log10(IN arg1 FLOAT)
RETURNS FLOAT  AS 'babelfishpg_tsql','numeric_log10' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128))
RETURNS INT AS
$BODY$
DECLARE
ret_val INT;
BEGIN
	index_or_statistics_name = LOWER(TRIM(index_or_statistics_name));
	property = LOWER(TRIM(property));
    SELECT INTO ret_val
    CASE
       
        WHEN (SELECT CAST(type AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default) = 3 -- is XML index
        THEN CAST(NULL AS int)
	    
        WHEN property = 'indexdepth'
        THEN CAST(0 AS int)

        WHEN property = 'indexfillfactor'
        THEN (SELECT CAST(fill_factor AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'indexid'
        THEN (SELECT CAST(index_id AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isautostatistics'
        THEN CAST(0 AS int)

        WHEN property = 'isclustered'
        THEN (SELECT CAST(CASE WHEN type = 1 THEN 1 ELSE 0 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isdisabled'
        THEN (SELECT CAST(is_disabled AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isfulltextkey'
        THEN CAST(0 AS int)
        
        WHEN property = 'ishypothetical'
        THEN (SELECT CAST(is_hypothetical AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'ispadindex'
        THEN (SELECT CAST(is_padded AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'ispagelockdisallowed'
        THEN (SELECT CAST(CASE WHEN allow_page_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isrowlockdisallowed'
        THEN (SELECT CAST(CASE WHEN allow_row_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id=$1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isstatistics'
        THEN CAST(0 AS int)
        
        WHEN property = 'isunique'
        THEN (SELECT CAST(is_unique AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'iscolumnstore'
        THEN CAST(0 AS int)
        
        WHEN property = 'isoptimizedforsequentialkey'
        THEN CAST(0 AS int)
    ELSE
        CAST(NULL AS int)
    END;
RETURN ret_val;
END;
$BODY$
LANGUAGE plpgsql STABLE;
GRANT EXECUTE ON FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128),  IN property sys.varchar(128)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.APP_NAME() RETURNS SYS.NVARCHAR(128)
AS
$$
    SELECT current_setting('application_name');
$$
LANGUAGE sql PARALLEL SAFE STABLE;

CREATE OR REPLACE FUNCTION sys.OBJECT_SCHEMA_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_schema_name'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION OBJECT_DEFINITION(IN object_id INT)
RETURNS sys.NVARCHAR(4000)
AS $$
DECLARE
    definition sys.nvarchar(4000);
BEGIN

    definition = (SELECT cc.definition FROM sys.check_constraints cc WHERE cc.object_id = $1);
    IF (definition IS NULL)
    THEN
        definition = (SELECT dc.definition FROM sys.default_constraints dc WHERE dc.object_id = $1);
        IF (definition IS NULL)
        THEN
            definition = (SELECT asm.definition FROM sys.all_sql_modules asm WHERE asm.object_id = $1);
            IF (definition IS NULL)
            THEN
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    RETURN definition;
END;
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.openquery_internal(
IN linked_server text,
IN query text)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'openquery_internal'
LANGUAGE C VOLATILE;

CREATE OR REPLACE FUNCTION sys.EOMONTH(date,int DEFAULT 0)
RETURNS date
AS 'babelfishpg_tsql', 'EOMONTH'
LANGUAGE C STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty
(
    IN "@name" sys.sysname DEFAULT NULL,
    IN "@level0type" VARCHAR(128) DEFAULT NULL,
    IN "@level0name" sys.sysname DEFAULT NULL,
    IN "@level1type" VARCHAR(128) DEFAULT NULL,
    IN "@level1name" sys.sysname DEFAULT NULL,
    IN "@level2type" VARCHAR(128) DEFAULT NULL,
    IN "@level2name" sys.sysname DEFAULT NULL,
    OUT objtype sys.sysname,
    OUT objname sys.sysname,
    OUT name sys.sysname,
    OUT value sys.sql_variant
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty TO PUBLIC;

-- Matches and returns column length of the corresponding column of the given table
CREATE OR REPLACE FUNCTION sys.COL_LENGTH(IN object_name TEXT, IN column_name TEXT)
RETURNS SMALLINT AS $BODY$
DECLARE
    col_name TEXT;
    object_id oid;
    column_id INT;
    column_length SMALLINT;
    column_data_type TEXT;
    typeid oid;
    typelen INT;
    typemod INT;
BEGIN
    -- Get the object ID for the provided object_name
    object_id := sys.OBJECT_ID(object_name, 'U');
    IF object_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Truncate and normalize the column name
    col_name := sys.babelfish_truncate_identifier(sys.babelfish_remove_delimiter_pair(lower(column_name)));

    -- Get the column ID, typeid, length, and typmod for the provided column_name
    SELECT attnum, a.atttypid, a.attlen, a.atttypmod
    INTO column_id, typeid, typelen, typemod
    FROM pg_attribute a
    WHERE attrelid = object_id AND lower(attname) = col_name COLLATE sys.database_default;

    IF column_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Get the correct data type
    column_data_type := sys.translate_pg_type_to_tsql(typeid);

    IF column_data_type = 'sysname' THEN
        column_length := 256;
    ELSIF column_data_type IS NULL THEN

        -- Check if it ia user-defined data type
        SELECT sys.translate_pg_type_to_tsql(typbasetype), typlen, typtypmod 
        INTO column_data_type, typelen, typemod
        FROM pg_type
        WHERE oid = typeid;

        IF column_data_type = 'sysname' THEN
            column_length := 256;
        ELSE 
            -- Calculate column length based on base type information
            column_length := sys.tsql_type_max_length_helper(column_data_type, typelen, typemod);
        END IF;
    ELSE
        -- Calculate column length based on base type information
        column_length := sys.tsql_type_max_length_helper(column_data_type, typelen, typemod);
    END IF;

    RETURN column_length;
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

-- internal helper function for date_bucket().
CREATE OR REPLACE FUNCTION sys.date_bucket_internal_helper(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN check_date boolean, IN origin boolean, IN date ANYELEMENT default NULL) RETURNS boolean 
AS 
$body$
DECLARE
    date_arg_datatype regtype;
BEGIN
    date_arg_datatype := pg_typeof(date);
    IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'doy', 'day', 'hour', 'minute', 'second', 'millisecond', 'microsecond', 'nanosecond') THEN
            RAISE EXCEPTION '% is not a recognized date_bucket option.', datepart;

    -- Check for NULL value of number argument
    ELSIF number IS NULL THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 2 of date_bucket function.';

    ELSIF check_date IS NULL THEN
        RAISE EXCEPTION 'Argument data type NULL is invalid for argument 3 of date_bucket function.';

    ELSIF check_date IS false THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of date_bucket function.', date_arg_datatype;
    
    ELSIF check_date IS true THEN
        IF date_arg_datatype NOT IN ('sys.datetime'::regtype, 'sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype, 'date'::regtype, 'time'::regtype) THEN
            RAISE EXCEPTION 'Argument data type % is invalid for argument 3 of date_bucket function.', date_arg_datatype;
        ELSIF datepart IN ('doy', 'microsecond', 'nanosecond') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type %.', datepart, date_arg_datatype;
        ELSIF date_arg_datatype = 'date'::regtype AND datepart IN ('hour', 'minute', 'second', 'millisecond') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type ''date''.', datepart;
        ELSIF date_arg_datatype = 'time'::regtype AND datepart IN ('year', 'quarter', 'month', 'day', 'week') THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function date_bucket for data type ''time''.', datepart;
        ELSIF origin IS false THEN
            RAISE EXCEPTION 'Argument data type varchar is invalid for argument 4 of date_bucket function.';
        ELSIF number <= 0 THEN
            RAISE EXCEPTION 'Invalid bucket width value passed to date_bucket function. Only positive values are allowed.';
        END IF;
        RETURN true;
    ELSE
        RAISE EXCEPTION 'Argument data type varchar is invalid for argument 3 of date_bucket function.';
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Another definition of date_bucket() with arg PG_CATALOG.TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date PG_CATALOG.TEXT, IN origin PG_CATALOG.TEXT default NULL) RETURNS PG_CATALOG.TEXT 
AS 
$body$
DECLARE
BEGIN
    IF date IS NULL THEN
        -- check_date is NULL when date is NULL
        -- check_date is false when we are sure that date can not be a valid datatype.
        -- check_date is true when date might be valid datatype so check is required. 
        RETURN sys.date_bucket_internal_helper(datepart, number, NULL, false, 'NULL'::text);
    ELSE
        RETURN sys.date_bucket_internal_helper(datepart, number, false, NULL, date);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Another definition of date_bucket() with arg date of type ANYELEMENT and origin of type TEXT.
CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date ANYELEMENT, IN origin PG_CATALOG.TEXT) RETURNS ANYELEMENT 
AS 
$body$
DECLARE
BEGIN
    IF date IS NULL THEN
        RETURN sys.date_bucket_internal_helper(datepart, number, NULL, NULL, 'NULL'::text);
    ELSIF pg_typeof(date) IN ('sys.datetime'::regtype, 'sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype, 'date'::regtype, 'time'::regtype) THEN
            IF origin IS NULL THEN
                RETURN sys.date_bucket(datepart, number, date);
            ELSE
                RETURN sys.date_bucket_internal_helper(datepart, number, true, false, date);
            END IF;
    ELSE
        RETURN sys.date_bucket_internal_helper(datepart, number, false, NULL, date);
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
    quarters_diff INT;
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
    date_arg_datatype regtype;
    is_valid boolean;
BEGIN
    BEGIN
        date_arg_datatype := pg_typeof(date);
        is_valid := sys.date_bucket_internal_helper(datepart, number, true, true, date);

        -- If optional argument origin's value is not provided by user then set it's default value of valid datatype.
        IF origin IS NULL THEN
                IF date_arg_datatype = 'sys.datetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF date_arg_datatype = 'sys.datetime2'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF date_arg_datatype = 'sys.smalldatetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSIF date_arg_datatype = 'date'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSIF date_arg_datatype = 'time'::regtype THEN
                    origin := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        END IF;
    END;

    /* support of date_bucket() for different kinds of date datatype starts here */
    -- support of date_bucket() when date is of 'time' datatype
    IF date_arg_datatype = 'time'::regtype THEN
        -- Find interval between date and origin and extract hour, minute, second, millisecond from the interval
        date_difference_interval := date_trunc('millisecond', date) - date_trunc('millisecond', origin);
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := FLOOR(EXTRACT('millisecond' from date_difference_interval))::INT;
        CASE datepart
            WHEN 'hour' THEN
                -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                -- For Ex. 'date_bucket(hour, 2, '01:00:00', '08:00:00')' hence check if the result_time is greater then date
                -- For comparision we are trunceting the result_time to milliseconds
                required_bucket := hours_diff/number;
                result_time := origin + make_interval(hours => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(hours => number);
                END IF;
                RETURN result_time;

            WHEN 'minute' THEN
                required_bucket := (hours_diff * 60 + minutes_diff)/number;
                result_time := origin + make_interval(mins => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(mins => number);
                END IF;
                RETURN result_time;

            WHEN 'second' THEN
                required_bucket := ((hours_diff * 60 + minutes_diff) * 60 + seconds_diff)/number;
                result_time := origin + make_interval(secs => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => number);
                END IF;
                RETURN result_time;

            WHEN 'millisecond' THEN
                required_bucket := (((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff)/number;
                result_time := origin + make_interval(secs => ((required_bucket * number)::numeric) * 0.001);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => (number::numeric) * 0.001);
                END IF;
                RETURN result_time;
        END CASE;

    -- support of date_bucket() when date is of {'datetime2', 'datetimeoffset'} datatype
    -- handling separately because both the datatypes have precision in milliseconds
    ELSIF date_arg_datatype IN ('sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype) THEN
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Ex. date_bucket(year, 2, '2010-01-01', '2019-01-01')) hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number*3);
                    END IF;
            END CASE;  
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function. 
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := PG_CATALOG.concat(number, ' ', datepart)::INTERVAL;
            millisec_trunc_diff_interval := (origin::timestamp - date_trunc('millisecond', origin::timestamp))::interval;
            result_date = date_bin(date_difference_interval, date::timestamp, date_trunc('millisecond', origin::timestamp)) + millisec_trunc_diff_interval;

            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result.
            IF result_date + date_difference_interval <= date::timestamp THEN
                result_date = result_date + date_difference_interval;
            END IF;
        END IF;

        -- All the above operations are performed by converting every date datatype into TIMESTAMPS. 
        -- datetimeoffset is typecasted into TIMESTAMPS that changes the value. 
        -- Ex. '2023-02-23 09:19:21.23 +10:12'::sys.datetimeoffset::timestamp => '2023-02-22 23:07:21.23'
        -- The output of date_bucket() for datetimeoffset datatype will always be in the same time-zone as of provided date argument. 
        -- Here, converting TIMESTAMP into datetimeoffset datatype with the same timezone as of date argument.
        IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = PG_CATALOG.right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            RETURN PG_CATALOG.concat(result_date, ' ', offset_string)::sys.datetimeoffset;
        ELSE
            RETURN result_date;
        END IF;

    -- support of date_bucket() when date is of {'date', 'datetime', 'smalldatetime'} datatype
    ELSE
        -- Round datetime to fixed bins (e.g. .000, .003, .007)
        IF date_arg_datatype = 'sys.datetime'::regtype THEN
            date := sys.babelfish_conv_string_to_datetime('DATETIME', date::TEXT)::sys.datetime;
            origin := sys.babelfish_conv_string_to_datetime('DATETIME', origin::TEXT)::sys.datetime;
        END IF;
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Example. date_bucket(year, 2, '2010-01-01', '2019-01-01') hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number * 3);
                    END IF;
            END CASE;
            RETURN result_date;
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function.
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := PG_CATALOG.concat(number, ' ', datepart)::INTERVAL;
            result_date = date_bin(date_difference_interval, date::TIMESTAMP, origin::TIMESTAMP);
            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result. 
            IF result_date + date_difference_interval <= date::TIMESTAMP THEN
                result_date = result_date + date_difference_interval;
            END IF;
            RETURN result_date;
        END IF;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION SYS.TYPE_NAME(IN type_id INT)
RETURNS SYS.NVARCHAR(128) AS
'babelfishpg_tsql', 'type_name'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION SYS.TYPE_ID(IN type_name SYS.NVARCHAR)
RETURNS INT AS
'babelfishpg_tsql', 'type_id'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DATETRUNC(IN datepart PG_CATALOG.TEXT, IN date ANYELEMENT) RETURNS ANYELEMENT AS
$body$
DECLARE
    days_offset INT;
    v_day INT;
    result_date timestamp;
    input_expr_timestamp timestamp;
    date_arg_datatype regtype;
    offset_string PG_CATALOG.TEXT;
    datefirst_value INT;
BEGIN
    BEGIN
        /* perform input validation */
        date_arg_datatype := pg_typeof(date);
        IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'tsql_week', 'hour', 'minute', 'second', 'millisecond', 'microsecond', 
                            'doy', 'day', 'nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION '''%'' is not a recognized datetrunc option.', datepart;
        ELSIF date_arg_datatype NOT IN ('date'::regtype, 'time'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype,
                                        'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype) THEN
            RAISE EXCEPTION 'Argument data type ''%'' is invalid for argument 2 of datetrunc function.', date_arg_datatype;
        ELSIF datepart IN ('nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''%''.',datepart, date_arg_datatype;
        ELSIF datepart IN ('dow') THEN
            RAISE EXCEPTION 'The datepart ''weekday'' is not supported by date function datetrunc for data type ''%''.', date_arg_datatype;
        ELSIF date_arg_datatype = 'date'::regtype AND datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''date''.', datepart;
        ELSIF date_arg_datatype = 'datetime'::regtype AND datepart IN ('microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''datetime''.', datepart;
        ELSIF date_arg_datatype = 'smalldatetime'::regtype AND datepart IN ('millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''smalldatetime''.', datepart;
        ELSIF date_arg_datatype = 'time'::regtype THEN
            IF datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'tsql_week') THEN
                RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''time''.', datepart;
            END IF;
            -- Limitation in determining if the specified fractional scale (if provided any) for time datatype is 
            -- insufficient to support provided datepart (millisecond, microsecond) value
        ELSIF date_arg_datatype IN ('datetime2'::regtype, 'datetimeoffset'::regtype) THEN
            -- Limitation in determining if the specified fractional scale (if provided any) for the above datatype is
            -- insufficient to support for provided datepart (millisecond, microsecond) value
        END IF;

        /* input validation is complete, proceed with result calculation. */
        IF date_arg_datatype = 'time'::regtype THEN
            RETURN date_trunc(datepart, date);
        ELSE
            input_expr_timestamp = date::timestamp;
            -- preserving offset_string value in the case of datetimeoffset datatype before converting it to timestamps 
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                offset_string = PG_CATALOG.RIGHT(date::PG_CATALOG.TEXT, 6);
                input_expr_timestamp := PG_CATALOG.LEFT(date::PG_CATALOG.TEXT, -6)::timestamp;
            END IF;
            CASE
                WHEN datepart IN ('year', 'quarter', 'month', 'week', 'hour', 'minute', 'second', 'millisecond', 'microsecond')  THEN
                    result_date := date_trunc(datepart, input_expr_timestamp);
                WHEN datepart IN ('doy', 'day') THEN
                    result_date := date_trunc('day', input_expr_timestamp);
                WHEN datepart IN ('tsql_week') THEN
                -- sql server datepart 'iso_week' is similar to postgres 'week' datepart
                -- handle sql server datepart 'week' here based on the value of set variable 'DATEFIRST'
                    v_day := EXTRACT(dow from input_expr_timestamp)::INT;
                    datefirst_value := current_setting('babelfishpg_tsql.datefirst')::INT;
                    IF v_day = 0 THEN
                        v_day := 7;
                    END IF;
                    result_date := date_trunc('day', input_expr_timestamp);
                    days_offset := (7 + v_day - datefirst_value)%7;
                    result_date := result_date - make_interval(days => days_offset);
            END CASE;
            -- concat offset_string to result_date in case of datetimeoffset before converting it to datetimeoffset datatype.
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                RETURN PG_CATALOG.concat(result_date, ' ', offset_string)::sys.datetimeoffset;
            ELSE
                RETURN result_date;
            END IF;
        END IF;
    END;
END;
$body$
LANGUAGE plpgsql STABLE;

-- another definition of datetrunc as anyelement can not handle unknown type.
CREATE OR REPLACE FUNCTION sys.DATETRUNC(IN datepart PG_CATALOG.TEXT, IN date PG_CATALOG.TEXT) RETURNS SYS.DATETIME2 AS
$body$
DECLARE
    input_expr_datetime2 sys.datetime2;
BEGIN
    IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'tsql_week', 'hour', 'minute', 'second', 'millisecond', 'microsecond', 
                        'doy', 'day', 'nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION '''%'' is not a recognized datetrunc option.', datepart;
    END IF;
    BEGIN
    input_expr_datetime2 := cast(date as sys.datetime2);
    exception
        WHEN others THEN
                RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.';
    END;
    IF input_expr_datetime2 IS NULL THEN
        RETURN NULL;
    ELSE
        -- input string literal is valid, call the datetrunc function with datetime2 datatype. 
        RETURN sys.DATETRUNC(datepart, input_expr_datetime2);
    END IF;
END;
$body$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.bbf_pivot(IN src_sql TEXT, IN cat_sql TEXT, IN agg_func TEXT)
RETURNS setof record
AS 'babelfishpg_tsql', 'bbf_pivot'
LANGUAGE C STABLE;

-- wrapper functions for reverse
CREATE OR REPLACE FUNCTION sys.reverse(string ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_arg_typeid oid;
    string_basetype oid;
BEGIN
    string_arg_typeid := pg_typeof(string)::oid;
    string_arg_datatype := sys.translate_pg_type_to_tsql(string_arg_typeid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(string_arg_typeid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for reverse function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of reverse function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.reverse(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.reverse(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.reverse(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.reverse(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.reverse(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that reverse with text input
-- will use following definition instead of PG reverse
CREATE OR REPLACE FUNCTION sys.reverse(string TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.reverse(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that reverse with ntext input
-- will use following definition instead of PG reverse
CREATE OR REPLACE FUNCTION sys.reverse(string NTEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.reverse(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_varchar(INTERNAL)
RETURNS sys.VARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_nvarchar(INTERNAL)
RETURNS sys.NVARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.VARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_varchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.NVARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_nvarchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

