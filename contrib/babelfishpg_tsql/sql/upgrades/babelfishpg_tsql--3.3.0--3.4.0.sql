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


CREATE OR REPLACE VIEW sys.asymmetric_keys
AS
SELECT 
    CAST('' as sys.sysname) AS name
  , CAST(0 as sys.int) AS principal_id
  , CAST(0 as sys.int) AS asymmetric_key_id
  , CAST('a' as sys.bpchar(2)) AS pvt_key_encryption_type
  , CAST('' as sys.nvarchar(60)) AS pvt_key_encryption_type_desc
  , CAST(null as sys.varbinary(32)) as thumbprint
  , CAST('a' as sys.bpchar(2)) AS algorithm
  , CAST('' as sys.nvarchar(60)) AS algorithm_desc
  , CAST(0 as sys.int) AS key_length
  , CAST(null as sys.varbinary(85)) as sid
  , CAST('' as sys.nvarchar(128)) AS string_sid
  , CAST(NULL as sys.varbinary(8000)) AS public_key
  , CAST('' as sys.nvarchar(260)) AS attested_by
  , CAST('' as sys.nvarchar(120)) AS provider_type
  , CAST(NULL as sys.UNIQUEIDENTIFIER) as cryptographic_provider_guid
  , CAST(NULL AS sys.sql_variant) AS cryptographic_provider_algid
  
WHERE FALSE;
GRANT SELECT ON sys.asymmetric_keys TO PUBLIC;

CREATE OR REPLACE VIEW sys.certificates
AS
SELECT 
    CAST('' as sys.sysname) AS name
  , CAST(0 as sys.int) AS principal_id
  , CAST(0 as sys.int) AS asymmetric_key_id
  , CAST('a' as sys.bpchar(2)) AS pvt_key_encryption_type
  , CAST('' as sys.nvarchar(60)) AS pvt_key_encryption_type_desc
  , CAST(0 as sys.bit) AS is_active_for_begin_dialog
  , CAST('' as sys.nvarchar(442)) AS issuer_name
  , CAST('' as sys.nvarchar(64)) AS cert_serial_number
  , CAST(null as sys.varbinary(85)) as sid
  , CAST('' as sys.nvarchar(128)) AS string_sid
  , CAST('' as sys.nvarchar(4000)) AS subject
  , CAST('' as sys.datetime) AS expiry_date
  , CAST('' as sys.datetime) AS start_date
  , CAST(null as sys.varbinary(32)) as thumbprint
  , CAST('' as sys.nvarchar(260)) as attested_by
  , CAST('' as sys.datetime) AS pvt_key_last_backup_date
  , CAST(0 AS sys.int) AS key_length
  
WHERE FALSE;
GRANT SELECT ON sys.certificates TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_permissions
AS
SELECT
    CAST(0 as sys.tinyint) AS class,
    CAST('' as sys.NVARCHAR(60)) AS class_desc,
    CAST(0 as sys.int) AS major_id,
    CAST(0 as sys.int) AS minor_id,
    CAST(0 as sys.int) AS grantee_principal_id,
    CAST(0 as sys.int) AS grantor_principal_id,
    CAST('a' as sys.bpchar(4)) AS type,
    CAST('' as sys.NVARCHAR(128)) AS permission_name,
    CAST('G' as sys.bpchar(1)) AS state,
    CAST('' as sys.NVARCHAR(60)) AS state_desc
WHERE FALSE;
GRANT SELECT ON sys.database_permissions TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.key_column_usage AS
	SELECT
		CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
		CAST(c.conname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME",
		CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		CAST(r.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
		CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
		CAST(ord AS int) AS "ORDINAL_POSITION"	
	FROM
		pg_constraint c 
		JOIN pg_class r ON r.oid = c.conrelid AND c.contype in ('p','u','f') AND r.relkind in ('r','p')
		JOIN sys.pg_namespace_ext nc ON nc.oid = c.connamespace AND r.relnamespace = nc.oid 
		JOIN sys.babelfish_namespace_ext ext ON ext.nspname = nc.nspname AND ext.dbid = sys.db_id()
		CROSS JOIN unnest(c.conkey) WITH ORDINALITY AS ak(j,ord) 
		LEFT JOIN pg_attribute a ON a.attrelid = r.oid AND a.attnum = ak.j		
	WHERE
		pg_has_role(r.relowner, 'USAGE'::text) 
  		OR has_column_privilege(r.oid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
		AND NOT pg_is_other_temp_schema(nc.oid)
	;
GRANT SELECT ON information_schema_tsql.key_column_usage TO PUBLIC;

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

-- Update data-type of information_schema_tsql.TABLE_TYPE to sys.varchar if it's data-type is pg_catalog.varchar
DO
$$
BEGIN  

    IF EXISTS(
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema='information_schema_tsql'
            AND table_name='tables'
            AND column_name='TABLE_TYPE'
            AND udt_schema='pg_catalog'
            AND udt_name='varchar'
    ) THEN
        ALTER VIEW information_schema_tsql.tables RENAME TO tables_deprecated_in_3_4_0;

        CREATE OR REPLACE VIEW information_schema_tsql.tables AS
            SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
                CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
                CAST(
                    CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
                        ELSE c.relname END
                    AS sys._ci_sysname) AS "TABLE_NAME",

                CAST(
                    CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
                        WHEN c.relkind = 'v' THEN 'VIEW'
                        ELSE null END
                    AS sys.varchar(10)) COLLATE sys.database_default AS "TABLE_TYPE"

            FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
                LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

            WHERE c.relkind IN ('r', 'v', 'p')
                AND (NOT pg_is_other_temp_schema(nc.oid))
                AND (pg_has_role(c.relowner, 'USAGE')
                    OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
                    OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
                AND ext.dbid = cast(sys.db_id() as oid)
                AND (NOT c.relname = 'sysdatabases');

        GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

        CALL sys.babelfish_drop_deprecated_object('view', 'information_schema_tsql', 'tables_deprecated_in_3_4_0');
    END IF;
END
$$
LANGUAGE plpgsql;


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

-- BABELFISH_SCHEMA_PERMISSIONS
CREATE TABLE IF NOT EXISTS sys.babelfish_schema_permissions (
  dbid smallint NOT NULL,
  schema_name NAME NOT NULL,
  object_name NAME NOT NULL,
  permission NAME NOT NULL,
  grantee NAME NOT NULL,
  object_type NAME,
  PRIMARY KEY(dbid, schema_name, object_name, permission, grantee)
);

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
        if LEFT(tz_diff,1) <> '-' THEN
        tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := left(tz_diff,6);
        input_expr_tx := concat(input_expr_tx,tz_offset);
        return cast(input_expr_tx as sys.datetimeoffset);
    ELSIF  pg_typeof(input_expr) = 'sys.DATETIMEOFFSET'::regtype THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;
        result := (SELECT input_expr_tmz  AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if LEFT(tz_diff,1) <> '-' THEN
        tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := left(tz_diff,6);
        result := concat(result,tz_offset);
        return cast(result as sys.datetimeoffset);
    ELSE
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
    END IF;
       
END;
$BODY$
LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (statement_timestamp()::text::datetime2 AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', ((statement_timestamp()::text::datetime2 AT TIME ZONE 'UTC'::pg_catalog.text)::pg_catalog.text::pg_catalog.TIMESTAMP))::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC;

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
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
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
            offset_string = right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            RETURN concat(result_date, ' ', offset_string)::sys.datetimeoffset;
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
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
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

CREATE OR REPLACE PROCEDURE sys.analyze_babelfish_catalogs()
LANGUAGE plpgsql
AS $$ 
DECLARE 
	babelfish_catalog RECORD;
	schema_name varchar = 'sys';
BEGIN
	FOR babelfish_catalog IN (
		SELECT relname as name from pg_class t 
		INNER JOIN pg_namespace n on n.oid = t.relnamespace
		WHERE t.relkind = 'r' and n.nspname = schema_name
		)
	LOOP
	EXECUTE format('ANALYZE %I.%I', schema_name, babelfish_catalog.name);
	END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
	-- ignore all exceptions and return control to calling block
		NULL;
END
$$;

-- This is a temporary procedure which is called during upgrade to update guest schema
-- for the guest users in the already existing databases
CREATE OR REPLACE PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema()
LANGUAGE C
AS 'babelfishpg_tsql', 'update_user_catalog_for_guest_schema';

CALL sys.babelfish_update_user_catalog_for_guest_schema();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema();


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Always run analyze after upgrade for all babelfish catalog.
-- It will not block upgrade in case of any failure.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);


