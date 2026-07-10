-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.5.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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
    when undefined_function then --if 'Deprecated function does not exist'
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

DO
LANGUAGE plpgsql
$$
BEGIN
    -- Check if the GUC is empty
    IF current_setting('babelfishpg_tsql.restored_server_collation_name', true) <> '' THEN
        -- Call the function to update the collation
        EXECUTE 'SELECT sys.babelfish_update_server_collation_name()';
    END IF;
END;
$$;

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- reset babelfishpg_tsql.restored_server_collation_name GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
    end;
$$;

-- Rename the varchar overloads to mark as deprecated in 5.5.0
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_varbinary(typmod integer, arg sys."varchar", try boolean, p_style numeric) RENAME TO babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_string_to_varbinary(arg sys."varchar", p_style numeric) RENAME TO babelfish_try_conv_string_to_varbinary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_varbinary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_string_to_varbinary(IN input_value sys.VARCHAR, IN p_style NUMERIC) RENAME TO babelfish_conv_string_to_varbinary_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_varbinary_deprecated_in_5_5_0');

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_varbinary(IN input_value anyelement,
																	IN style NUMERIC DEFAULT 0)
RETURNS sys.varbinary 
AS 
$BODY$
DECLARE
    result bytea; 
BEGIN
    IF style = 0 THEN
        CASE pg_typeof(input_value)
			WHEN 'sys.nvarchar'::regtype THEN
				RETURN sys.nvarcharvarbinary(input_value, -1, true);
			WHEN 'sys.nchar'::regtype THEN
				RETURN sys.ncharvarbinary(input_value, -1, true);
			ELSE
                RETURN CAST(input_value AS sys.varbinary);
        END CASE;
    ELSIF style = 1 THEN
        -- Handle hexadecimal conversion
        IF (PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" AND PG_CATALOG.length(input_value) % 2 = 0) THEN
            result := decode(substring(input_value from 3), 'hex');
        ELSE
            RAISE EXCEPTION 'Error converting data type varchar to varbinary.';
        END IF;
    ELSIF style = 2 THEN
        IF PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" THEN
            RAISE EXCEPTION 'Error converting data type varchar to varbinary.';
        ELSE
            result := decode(input_value, 'hex');
        END IF;
    ELSE
        RAISE EXCEPTION 'The style % is not supported for conversions from varchar to varbinary.', style;
    END IF;

	RETURN CAST(result AS sys.varbinary);
END;
$BODY$ 
LANGUAGE plpgsql
IMMUTABLE
STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(IN typmod INTEGER,
																	IN arg anyelement,
																	IN try BOOL,
																	IN p_style NUMERIC DEFAULT 0)
RETURNS sys.varbinary
AS
$BODY$
DECLARE result sys.varbinary;
BEGIN
	IF try THEN
		RETURN sys.babelfish_try_conv_to_varbinary(typmod, arg, p_style);
	ELSE
		IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
			RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
		ELSE
			IF typmod = -1 THEN
				RETURN CAST(arg as sys.varbinary);
			ELSE
				EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
				RETURN result;
			END IF;
		END IF;
	END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE; 


CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varbinary(IN typmod INTEGER,
																IN arg anyelement,
																IN p_style NUMERIC DEFAULT 0)
RETURNS sys.varbinary
AS
$BODY$
DECLARE result sys.varbinary;
BEGIN
	IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
		RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
	ELSE
		IF typmod = -1 THEN
			RETURN CAST(arg as sys.varbinary);
		ELSE
			EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
			RETURN result;
		END IF;
	END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;  

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(
    IN typmod INTEGER,
    IN arg TEXT,
    IN try BOOL,
    IN p_style NUMERIC DEFAULT 0
)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_varbinary(arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_varbinary(arg::sys.varchar, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_varbinary(
    IN arg TEXT,
    IN p_style NUMERIC DEFAULT 0
)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_varbinary(arg::sys.varchar, p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

-- Rename the varchar overloads to mark as deprecated in 5.5.0
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_binary(typmod integer, arg sys."varchar", try boolean, p_style numeric) RENAME TO babelfish_conv_helper_to_binary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_binary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_string_to_binary(arg sys."varchar", p_style numeric) RENAME TO babelfish_try_conv_string_to_binary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_binary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_string_to_binary(IN input_value sys.VARCHAR, IN p_style NUMERIC) RENAME TO babelfish_conv_string_to_binary_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_binary_deprecated_in_5_5_0');

-- Binary conversion helper functions
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg anyelement,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_binary(typmod, arg, p_style);
    ELSE
        IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
            RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
        ELSE
            IF typmod = -1 THEN
                RETURN CAST(arg as sys.binary);
            ELSE
                EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
                RETURN result;
            END IF;
        END IF;
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg TEXT,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_binary(arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_binary(arg::sys.varchar, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_binary(IN arg TEXT,
                                                                   IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_binary(arg::sys.varchar, p_style);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_binary(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
        RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
    ELSE
        IF typmod = -1 THEN
            RETURN CAST(arg as sys.binary);
        ELSE
            EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
            RETURN result;
        END IF;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_binary(IN input_value ANYELEMENT, IN style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE
    result bytea;
BEGIN
    IF style = 0 THEN
        CASE pg_typeof(input_value)
			WHEN 'sys.nvarchar'::regtype THEN
				RETURN sys.nvarcharbinary(input_value, -1, true);
			WHEN 'sys.nchar'::regtype THEN
				RETURN sys.ncharbinary(input_value, -1, true);
			ELSE
                RETURN CAST(input_value AS sys.binary);
        END CASE;
    ELSIF style = 1 THEN
        IF (PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" AND PG_CATALOG.length(input_value) % 2 = 0) THEN
            result := decode(substring(input_value from 3), 'hex');
        ELSE
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        END IF;
    ELSIF style = 2 THEN
        IF PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" THEN
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        ELSE
            result := decode(input_value, 'hex');
        END IF;
    ELSE
        RAISE EXCEPTION 'The style % is not supported for conversions from varchar to binary.', style;
    END IF;

    RETURN CAST(result AS sys.binary);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
STRICT;

-- conversion to varchar
CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
	v_style SMALLINT;
BEGIN
	v_style := floor(p_style)::SMALLINT;

    CASE pg_typeof(arg)
	WHEN 'date'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg, p_style);
		END IF;
	WHEN 'time'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg);
		ELSE
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg, p_style);
		END IF;
	WHEN 'sys.datetime'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp);
		ELSE
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp, p_style);
		END IF;
	WHEN 'float'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg, p_style);
		END IF;
	WHEN 'sys.money'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4));
		ELSE
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4), p_style);
		END IF;
	WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.varbinarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
	WHEN 'sys.binary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.binarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
	ELSE
		RETURN CAST(arg AS sys.VARCHAR);
	END CASE;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.varbinarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		WHEN 'sys.binary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.binarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.VARCHAR);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg ANYELEMENT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'sys.nvarchar'::regtype THEN
			RETURN sys.nvarcharvarbinary(arg, -1, true);
		WHEN 'sys.nchar'::regtype THEN
			RETURN sys.ncharvarbinary(arg, -1, true);
		ELSE
			RETURN CAST(arg AS sys.varbinary);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg TEXT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.varbinary);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_date_to_string(IN p_datatype TEXT, IN p_dateval DATE, IN p_style NUMERIC) 
    RENAME TO babelfish_try_conv_date_to_string_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_date_to_string_deprecated_in_5_5_0');


DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_datetime_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE, IN p_style NUMERIC)
    RENAME TO babelfish_try_conv_datetime_to_string_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_datetime_to_string_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_time_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_timeval TIME(6) WITHOUT TIME ZONE, IN p_style NUMERIC )
    RENAME TO babelfish_try_conv_time_to_string_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_time_to_string_deprecated_in_5_5_0');

CREATE OR REPLACE FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT,
                                                                 IN p_dateval DATE,
                                                                 IN p_style NUMERIC DEFAULT 20)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_dateval DATE;
    v_style SMALLINT;
    v_month SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
    v_datatype := pg_catalog.upper(pg_catalog.btrim(p_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 13) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 113) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF (v_style IN (8, 24, 108)) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_dateval := CASE
                    WHEN (v_style NOT IN (130, 131)) THEN p_dateval
                    ELSE sys.babelfish_conv_greg_to_hijri(p_dateval) + 1
                 END;

    v_day := PG_CATALOG.ltrim(to_char(v_dateval, 'DD'), '0');
    v_month := to_char(v_dateval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
 RAISE NOTICE 'v_language=[%]', v_language;		  
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    v_resmask := CASE
                    WHEN (v_style IN (1, 22)) THEN 'MM/DD/YY'
                    WHEN (v_style = 101) THEN 'MM/DD/YYYY'
                    WHEN (v_style = 2) THEN 'YY.MM.DD'
                    WHEN (v_style = 102) THEN 'YYYY.MM.DD'
                    WHEN (v_style = 3) THEN 'DD/MM/YY'
                    WHEN (v_style = 103) THEN 'DD/MM/YYYY'
                    WHEN (v_style = 4) THEN 'DD.MM.YY'
                    WHEN (v_style = 104) THEN 'DD.MM.YYYY'
                    WHEN (v_style = 5) THEN 'DD-MM-YY'
                    WHEN (v_style = 105) THEN 'DD-MM-YYYY'
                    WHEN (v_style = 6) THEN 'DD $mnme$ YY'
                    WHEN (v_style IN (13, 106, 113)) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 7) THEN '$mnme$ DD, YY'
                    WHEN (v_style = 107) THEN '$mnme$ DD, YYYY'
                    WHEN (v_style = 10) THEN 'MM-DD-YY'
                    WHEN (v_style = 110) THEN 'MM-DD-YYYY'
                    WHEN (v_style = 11) THEN 'YY/MM/DD'
                    WHEN (v_style = 111) THEN 'YYYY/MM/DD'
                    WHEN (v_style = 12) THEN 'YYMMDD'
                    WHEN (v_style = 112) THEN 'YYYYMMDD'
                    WHEN (v_style IN (20, 21, 23, 25, 120, 121, 126, 127)) THEN 'YYYY-MM-DD'
                    WHEN (v_style = 130) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 131) THEN pg_catalog.format('%s/MM/YYYY', lpad(v_day, 2, ' '))
                    WHEN (v_style IN (0, 9, 100, 109)) THEN pg_catalog.format('$mnme$ %s YYYY', lpad(v_day, 2, ' '))
                 END;

    v_resstring := to_char(v_dateval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from DATE to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type DATE to %s.', pg_catalog.btrim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr,
                                     pg_catalog.lower(v_res_datatype),
                                     v_maxlength),
                   DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_hour VARCHAR COLLATE "C";
    v_month SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_fractsep VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^(?:DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    v_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE;
BEGIN
    v_datatype := pg_catalog.upper(pg_catalog.btrim(p_datatype));
    v_src_datatype := pg_catalog.upper(pg_catalog.btrim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;

        v_src_datatype := PG_CATALOG.rtrim(split_part(v_src_datatype, '(', 1));

        IF (v_src_datatype <> 'DATETIME2' AND v_scale IS NOT NULL) THEN
            RAISE invalid_indicator_parameter_value;
        ELSIF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;

        v_scale := coalesce(v_scale, 7);
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4)
        THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_datetimeval := CASE
                        WHEN (v_style NOT IN (130, 131)) THEN p_datetimeval
                        ELSE sys.babelfish_conv_greg_to_hijri(p_datetimeval) + INTERVAL '1 day'
                     END;

    v_day := PG_CATALOG.ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := PG_CATALOG.ltrim(to_char(v_datetimeval, 'HH12'), '0');
    v_month := to_char(v_datetimeval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    IF (v_src_datatype IN ('DATETIME', 'SMALLDATETIME')) THEN
        v_fseconds := sys.babelfish_round_fractseconds(to_char(v_datetimeval, 'MS'));

        IF (v_fseconds::INTEGER = 1000) THEN
            v_fseconds := '000';
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        ELSE
            v_fseconds := lpad(v_fseconds, 3, '0');
        END IF;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(to_char(v_datetimeval, 'US'), v_scale);

        -- Following condition will handle overflow of fractsecs
        IF (v_fseconds::INTEGER < 0) THEN
            v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        END IF;

        IF (v_scale = 7) THEN
            v_fseconds := pg_catalog.concat(v_fseconds, '0');
        END IF;
    END IF;

    v_fractsep := CASE v_src_datatype
                     WHEN 'DATETIME2' THEN '.'
                     ELSE ':'
                  END;

    IF ((v_style = -1 AND v_src_datatype <> 'DATETIME2') OR
        v_style IN (0, 9, 100, 109))
    THEN
        v_resmask := pg_catalog.format('$mnme$ %s YYYY %s:MI%s',
                            lpad(v_day, 2, ' '),
                            lpad(v_hour, 2, ' '),
                            CASE
                               WHEN (v_style IN (-1, 0, 100)) THEN 'AM'
                               ELSE pg_catalog.format(':SS:%sAM', v_fseconds)
                            END);
    ELSIF (v_style = 1) THEN
        v_resmask := 'MM/DD/YY';
    ELSIF (v_style = 101) THEN
        v_resmask := 'MM/DD/YYYY';
    ELSIF (v_style = 2) THEN
        v_resmask := 'YY.MM.DD';
    ELSIF (v_style = 102) THEN
        v_resmask := 'YYYY.MM.DD';
    ELSIF (v_style = 3) THEN
        v_resmask := 'DD/MM/YY';
    ELSIF (v_style = 103) THEN
        v_resmask := 'DD/MM/YYYY';
    ELSIF (v_style = 4) THEN
        v_resmask := 'DD.MM.YY';
    ELSIF (v_style = 104) THEN
        v_resmask := 'DD.MM.YYYY';
    ELSIF (v_style = 5) THEN
        v_resmask := 'DD-MM-YY';
    ELSIF (v_style = 105) THEN
        v_resmask := 'DD-MM-YYYY';
    ELSIF (v_style = 6) THEN
        v_resmask := 'DD $mnme$ YY';
    ELSIF (v_style = 106) THEN
        v_resmask := 'DD $mnme$ YYYY';
    ELSIF (v_style = 7) THEN
        v_resmask := '$mnme$ DD, YY';
    ELSIF (v_style = 107) THEN
        v_resmask := '$mnme$ DD, YYYY';
    ELSIF (v_style IN (8, 24, 108)) THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style = 10) THEN
        v_resmask := 'MM-DD-YY';
    ELSIF (v_style = 110) THEN
        v_resmask := 'MM-DD-YYYY';
    ELSIF (v_style = 11) THEN
        v_resmask := 'YY/MM/DD';
    ELSIF (v_style = 111) THEN
        v_resmask := 'YYYY/MM/DD';
    ELSIF (v_style = 12) THEN
        v_resmask := 'YYMMDD';
    ELSIF (v_style = 112) THEN
        v_resmask := 'YYYYMMDD';
    ELSIF (v_style IN (13, 113)) THEN
        v_resmask := pg_catalog.format('DD $mnme$ YYYY HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (14, 114)) THEN
        v_resmask := pg_catalog.format('HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (20, 120)) THEN
        v_resmask := 'YYYY-MM-DD HH24:MI:SS';
    ELSIF ((v_style = -1 AND v_src_datatype = 'DATETIME2') OR
           v_style IN (21, 25, 121))
    THEN
        v_resmask := pg_catalog.format('YYYY-MM-DD HH24:MI:SS.%s', v_fseconds);
    ELSIF (v_style = 22) THEN
        v_resmask := pg_catalog.format('MM/DD/YY %s:MI:SS AM', lpad(v_hour, 2, ' '));
    ELSIF (v_style = 23) THEN
        v_resmask := 'YYYY-MM-DD';
    ELSIF (v_style IN (126, 127)) THEN
        v_resmask := CASE v_src_datatype
                        WHEN 'SMALLDATETIME' THEN 'YYYY-MM-DDT$rem$HH24:MI:SS'
                        ELSE pg_catalog.format('YYYY-MM-DDT$rem$HH24:MI:SS.%s', v_fseconds)
                     END;
    ELSIF (v_style IN (130, 131)) THEN
        v_resmask := pg_catalog.concat(CASE p_style
                               WHEN 131 THEN pg_catalog.format('%s/MM/YYYY ', lpad(v_day, 2, ' '))
                               ELSE pg_catalog.format('%s $mnme$ YYYY ', lpad(v_day, 2, ' '))
                            END,
                            pg_catalog.format('%s:MI:SS%s%sAM', lpad(v_hour, 2, ' '), v_fractsep, v_fseconds));
    END IF;

    v_resstring := to_char(v_datetimeval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := pg_catalog.replace(v_resstring, '$rem$', '');

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2'' or ''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "srcdatatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_src_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from %s to a character string.',
                                      v_style, v_src_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                      v_lengthexpr, pg_catalog.lower(v_res_datatype), v_maxlength),
                    DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                    HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT,
                                                                 IN p_src_datatype TEXT,
                                                                 IN p_timeval TIME(6) WITHOUT TIME ZONE,
                                                                 IN p_style NUMERIC DEFAULT 25)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_hours VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_res_length SMALLINT;
    v_res_datatype VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_maxlength SMALLINT;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    -- We use the regex below to make sure input p_datatype is one of them
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    -- We use the regex below to get the length of the datatype, if specified
    -- For example, to get the '10' out of 'varchar(10)'
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^\s*(?:TIME)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?\s*$';
BEGIN
    v_datatype := pg_catalog.upper(pg_catalog.btrim(p_datatype));
    v_src_datatype := pg_catalog.upper(pg_catalog.btrim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := coalesce(substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT, 7);

        IF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP)
    THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_res_maxlength := CASE
                              WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                              ELSE NVARCHAR_MAX
                           END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_res_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF ((v_style BETWEEN 1 AND 7) OR
           (v_style BETWEEN 10 AND 12) OR
           (v_style BETWEEN 101 AND 107) OR
           (v_style BETWEEN 110 AND 112) OR
           v_style = 23)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_hours := PG_CATALOG.ltrim(to_char(p_timeval, 'HH12'), '0');
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(to_char(p_timeval, 'US'), v_scale);

    -- Following condition will handle overflow of fractsecs
    IF (v_fseconds::INTEGER < 0) THEN
        v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
        p_timeval := p_timeval + INTERVAL '1 second';
    END IF;

    IF (v_scale = 7) THEN
        v_fseconds := pg_catalog.concat(v_fseconds, '0');
    END IF;

    IF (v_style IN (0, 100))
    THEN
        v_resmask := pg_catalog.concat(v_hours, ':MIAM');
    ELSIF (v_style IN (8, 20, 24, 108, 120))
    THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style IN (9, 109))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN pg_catalog.concat(v_hours, ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE pg_catalog.concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
        v_resmask := pg_catalog.format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN pg_catalog.concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
                     END;
    END IF;

    v_resstring := to_char(p_timeval, v_resmask);

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "src_datatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr, pg_catalog.lower(v_res_datatype), v_res_maxlength),
                   DETAIL := 'Use of incorrect size value of target data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from TIME to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type TIME to %s.',
                                      PG_CATALOG.rtrim(split_part(pg_catalog.btrim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg TEXT, IN try BOOL, IN p_style NUMERIC)
    RENAME TO babelfish_conv_helper_to_varchar_with_text_argument_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT -1,
                                                        IN p_style_specified BOOLEAN DEFAULT FALSE)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	IF try THEN
	    RETURN sys.babelfish_try_conv_to_varchar(typename, arg, p_style, p_style_specified);
    ELSE
	    RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style, p_style_specified);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varchar_with_text_argument_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg ANYELEMENT, IN try BOOL, IN p_style NUMERIC)
    RENAME TO babelfish_conv_helper_to_varchar_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg ANYELEMENT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT -1,
                                                        IN p_style_specified BOOLEAN DEFAULT FALSE)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	IF try THEN
	    RETURN sys.babelfish_try_conv_to_varchar(typename, arg, p_style, p_style_specified);
    ELSE
	    RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style,  p_style_specified);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC)
    RENAME TO babelfish_try_conv_to_varchar_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1,
                                                        IN p_style_specified BOOLEAN DEFAULT FALSE)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style, p_style_specified);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_to_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC)
    RENAME TO babelfish_conv_to_varchar_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

-- conversion to varchar
CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1,
                                                        IN p_style_specified BOOLEAN DEFAULT FALSE)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
	v_style SMALLINT;
BEGIN
	v_style := floor(p_style)::SMALLINT;

    CASE pg_typeof(arg)
	WHEN 'date'::regtype THEN
		IF NOT p_style_specified AND v_style = -1 THEN
			RETURN sys.babelfish_conv_date_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_conv_date_to_string(typename, arg, p_style);
		END IF;
	WHEN 'time'::regtype THEN
		IF NOT p_style_specified AND v_style = -1 THEN
			RETURN sys.babelfish_conv_time_to_string(typename, 'TIME', arg);
		ELSE
			RETURN sys.babelfish_conv_time_to_string(typename, 'TIME', arg, p_style);
		END IF;
	WHEN 'sys.datetime'::regtype THEN
		IF NOT p_style_specified AND v_style = -1 THEN
			RETURN sys.babelfish_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp);
		ELSE
			RETURN sys.babelfish_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp, p_style);
		END IF;
	WHEN 'float'::regtype THEN
		IF NOT p_style_specified AND v_style = -1 THEN
			RETURN sys.babelfish_conv_float_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_conv_float_to_string(typename, arg, p_style);
		END IF;
	WHEN 'sys.money'::regtype THEN
        IF NOT p_style_specified AND v_style = -1 THEN
            RETURN sys.babelfish_conv_money_to_string(typename, arg::numeric(19,4));
        ELSE
            RETURN sys.babelfish_conv_money_to_string(typename, arg::numeric(19,4), p_style);
        END IF;
	WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.varbinarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
	WHEN 'sys.binary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.binarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
    WHEN 'sys.smallmoney'::regtype THEN 
        IF NOT p_style_specified AND v_style = -1 THEN
            RETURN sys.babelfish_conv_money_to_string(typename, arg::numeric(10,4));
        ELSE
            RETURN sys.babelfish_conv_money_to_string(typename, arg::numeric(10,4), p_style);
        END IF;
	ELSE
		RETURN CAST(arg AS sys.VARCHAR);
	END CASE;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_to_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT, IN p_moneyval NUMERIC, IN p_style NUMERIC)
    RENAME TO babelfish_try_conv_money_to_string_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_money_to_string(IN p_datatype TEXT,
														IN p_moneyval NUMERIC,
														IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_style SMALLINT;
	v_format VARCHAR COLLATE "C";
	v_moneyval NUMERIC(19,4) := p_moneyval::NUMERIC(19,4);
	v_moneysign NUMERIC(19,4) := sign(v_moneyval);
	v_moneyabs NUMERIC(19,4) := abs(v_moneyval);
	v_digits SMALLINT;
	v_integral_digits SMALLINT;
	v_decimal_digits SMALLINT;
	v_result TEXT;
    v_varchar_length TEXT;
    v_default_format VARCHAR COLLATE "C" = '999,999,999,999,990.99';
BEGIN
    v_style := floor(p_style)::SMALLINT;
    v_digits := length(v_moneyabs::TEXT);
    v_decimal_digits := scale(v_moneyabs);

    IF (scale(p_style) > 0) THEN
        RAISE USING MESSAGE := pg_catalog.format('Argument data type numeric is invalid for argument 3 of convert function.'),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';
    END IF;

    IF (v_decimal_digits > 0) THEN
        v_integral_digits := v_digits - v_decimal_digits - 1;
    ELSE
        v_integral_digits := v_digits;
    END IF;

    IF (v_style = 0) THEN
        v_format := (pow(10, v_integral_digits) - 10)::TEXT || 'D99';
        v_result := pg_catalog.btrim(to_char(v_moneyval, v_format));
    ELSIF (v_style = 2 OR v_style = 126) THEN
        v_format := (pow(10, v_integral_digits) - 10)::TEXT || 'D9999';
        v_result := pg_catalog.btrim(to_char(v_moneyval, v_format));
    ELSE
        v_result := pg_catalog.btrim(to_char(v_moneyval, v_default_format));
    END IF;

    IF (v_moneysign = -1 AND pg_catalog.left(ltrim(v_result), 1) COLLATE "C" != '-' COLLATE "C") THEN
        v_result := '-' || pg_catalog.ltrim(v_result);
    ELSIF (v_moneysign != -1 AND pg_catalog.left(ltrim(v_result), 1) COLLATE "C" = '-' COLLATE "C") THEN
        v_result := pg_catalog.ltrim(v_result, '-');
    END IF;

    IF (pg_catalog.lower(p_datatype) LIKE '%varchar%(%' OR pg_catalog.lower(p_datatype) LIKE '%char%(%') THEN
        v_varchar_length := substring(p_datatype COLLATE "C" FROM '\(([0-9]+|MAX)\)');
        IF (v_varchar_length IS NOT NULL AND v_varchar_length <> 'MAX' AND char_length(v_result) > v_varchar_length::SMALLINT) THEN
            RAISE USING MESSAGE := pg_catalog.format('There is insufficient result space to convert a money value to varchar.'),
                        DETAIL := 'The converted money value exceeds the specified varchar length.',
                        HINT := 'Use a larger varchar size or a different conversion style.';
        END IF;
    END IF;

    RETURN v_result;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_money_to_string_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT, IN p_moneyval NUMERIC, IN p_style NUMERIC)
    RENAME TO babelfish_try_conv_float_to_string_deprecated_in_5_5_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_float_to_string(IN p_datatype TEXT,
														  IN p_floatval FLOAT,
														  IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
	v_style SMALLINT;
	v_format VARCHAR COLLATE "C";
	v_floatval NUMERIC := abs(p_floatval);
	v_digits SMALLINT;
	v_integral_digits SMALLINT;
	v_decimal_digits SMALLINT;
	v_sign SMALLINT := sign(p_floatval);
	v_result TEXT;
	v_res_length SMALLINT;
	MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
	v_style := floor(p_style)::SMALLINT;
	IF (v_style = 0) THEN
		v_digits := length(v_floatval::NUMERIC::TEXT);
		v_decimal_digits := scale(v_floatval);
		IF (v_decimal_digits > 0) THEN
			v_integral_digits := v_digits - v_decimal_digits - 1;
		ELSE
			v_integral_digits := v_digits;
		END IF;
		IF (v_floatval >= 999999.5) THEN
			v_format := '9D99999EEEE';
			v_result := to_char(v_sign::NUMERIC * ceiling(v_floatval), v_format);
			v_result := to_char(substring(v_result, 1, 8)::NUMERIC, 'FM9D99999')::NUMERIC::TEXT || substring(v_result, 9);
		ELSIF (v_floatval < 0.0001 AND v_floatval != 0) THEN	
			v_format := '9D99999EEEE';
			v_result := to_char(v_sign::NUMERIC * v_floatval, v_format);
			v_result := to_char(substring(v_result, 1, 8)::NUMERIC, 'FM9D99999')::NUMERIC::TEXT || substring(v_result, 9);
		ELSE
			IF (6 - v_integral_digits < v_decimal_digits) AND (trunc(abs(v_floatval)) != 0) THEN
				v_decimal_digits := 6 - v_integral_digits;
			ELSIF (6 - v_integral_digits < v_decimal_digits) THEN
				v_decimal_digits := 6;
			END IF;
			v_format := (pow(10, v_integral_digits)-10)::TEXT || 'D';
			IF (v_decimal_digits > 0) THEN
				v_format := v_format || (pow(10, v_decimal_digits)-1)::TEXT;
			END IF;
			v_result := to_char(p_floatval, v_format);
		END IF;
	ELSIF (v_style = 1) THEN
		v_format := '9D9999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSIF (v_style = 2) THEN
		v_format := '9D999999999999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSIF (v_style = 3) THEN
		v_format := '9D9999999999999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSE
		RAISE invalid_parameter_value;
	END IF;

	v_res_length := substring(p_datatype COLLATE "C", MASK_REGEXP)::SMALLINT;
	IF v_res_length IS NULL THEN
		RETURN ltrim(v_result);
	ELSE
		RETURN rpad(ltrim(v_result),  v_res_length, ' ');
	END IF;
EXCEPTION
	WHEN invalid_parameter_value THEN
		RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from FLOAT to a character string.', v_style),
					DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
					HINT := 'Change "style" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_float_to_string_deprecated_in_5_5_0');

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
DECLARE
    arg_datatype TEXT;
    basetype OID;
BEGIN
    arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(startdate)::oid);
    -- for User Defined Datatype, use immediate base type to check for argument datatype validation
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(startdate)::oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    -- Since the datatype of the argument is still NULL it means the datatype of the argument is not defined in TSQL and is a PG supported datatype. 
    -- So we check the pg type for the argument datatype validation.
    -- We only support TIMESTAMP PG datatype over TDS endpoint, so we added a check for it.
    
    IF arg_datatype IS NULL THEN
        IF pg_typeof(startdate) = 'timestamp'::regtype THEN
            return sys.dateadd_internal_datetime(datepart, num, startdate, 3);
        END IF;
    END IF;

    IF arg_datatype = 'time' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 0);
    END IF;
    IF arg_datatype = 'date' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 1);
    END IF;
    IF arg_datatype = 'smalldatetime' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 2);
    END IF;
    IF arg_datatype = 'datetime' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 3);
    END IF;
    IF arg_datatype = 'datetime2' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 4);
    END IF;
    IF arg_datatype = 'datetimeoffset' THEN
        return sys.dateadd_internal_df(datepart, num, startdate);
    END IF;
    RAISE EXCEPTION 'Conversion failed when converting date and/or time from %.', arg_datatype;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.fn_varbintohexstr(expression sys.varbinary)
RETURNS sys.nvarchar AS 
$$ 
BEGIN 
    IF sys.len(expression) = 0 THEN
        RETURN NULL;
    END IF;
    RETURN pg_catalog.lower(expression::PG_CATALOG.TEXT);
END;
$$ 
LANGUAGE plpgsql IMMUTABLE STRICT;
-- Add rpc_out column to babelfish_server_options for remote procedure execution feature
SET allow_system_table_mods = on;
ALTER TABLE sys.babelfish_server_options ADD COLUMN IF NOT EXISTS rpc_out BOOLEAN DEFAULT FALSE;
RESET allow_system_table_mods;

-- Recreate sys.servers view to include rpc_out column
CREATE OR REPLACE VIEW sys.servers
AS
SELECT
  CAST(f.oid as int) AS server_id,
  CAST(f.srvname as sys.sysname) AS name,
  CAST('' as sys.sysname) AS product,
  CAST('tds_fdw' as sys.sysname) AS provider,
  CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'servername=%%' then substring(option, 12)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
  CAST(NULL as sys.nvarchar(4000)) AS location,
  CAST(NULL as sys.nvarchar(4000)) AS provider_string,
  CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'database=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
  CAST(s.connect_timeout as int) AS connect_timeout,
  CAST(s.query_timeout as int) AS query_timeout,
  CAST(1 as sys.bit) AS is_linked,
  CAST(0 as sys.bit) AS is_remote_login_enabled,
  CAST(COALESCE(s.rpc_out, false) as sys.bit) AS is_rpc_out_enabled,
  CAST(1 as sys.bit) AS is_data_access_enabled,
  CAST(0 as sys.bit) AS is_collation_compatible,
  CAST(1 as sys.bit) AS uses_remote_collation,
  CAST(NULL as sys.sysname) AS collation_name,
  CAST(0 as sys.bit) AS lazy_schema_validation,
  CAST(0 as sys.bit) AS is_system,
  CAST(0 as sys.bit) AS is_publisher,
  CAST(0 as sys.bit) AS is_subscriber,
  CAST(0 as sys.bit) AS is_distributor,
  CAST(0 as sys.bit) AS is_nonsql_subscriber,
  CAST(1 as sys.bit) AS is_remote_proc_transaction_promotion_enabled,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_rda_server
FROM pg_foreign_server AS f
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
LEFT JOIN sys.babelfish_server_options AS s on f.srvname = s.servername
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

CREATE OR REPLACE VIEW sys.sp_datatype_info_view_version_2 AS 
SELECT TYPE_NAME, DATA_TYPE, "PRECISION", LITERAL_PREFIX, LITERAL_SUFFIX,
       CAST(CREATE_PARAMS AS CHAR(20)) AS CREATE_PARAMS, 
       NULLABLE, CASE_SENSITIVE, SEARCHABLE,
       UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
       MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
       NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
FROM sys.sp_datatype_info_helper(2::smallint, false) 
ORDER BY DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;

GRANT SELECT ON sys.sp_datatype_info_view_version_2 TO PUBLIC;


CREATE OR REPLACE VIEW sys.sp_datatype_info_view_version_3 AS 
SELECT TYPE_NAME, DATA_TYPE, "PRECISION", LITERAL_PREFIX, LITERAL_SUFFIX,
       CAST(CREATE_PARAMS AS CHAR(20)) AS CREATE_PARAMS, 
       NULLABLE, CASE_SENSITIVE, SEARCHABLE,
       UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
       MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
       NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
FROM sys.sp_datatype_info_helper(3::smallint, false) 
ORDER BY DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;

GRANT SELECT ON sys.sp_datatype_info_view_version_3 TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_datatype_info(
    "@data_type" int = 0, 
    "@odbcver" smallint = 2)
AS $$
BEGIN
    IF @odbcver = 3
    BEGIN
        SELECT * FROM sys.sp_datatype_info_view_version_3
        WHERE @data_type = 0 OR DATA_TYPE = @data_type;
    END
    ELSE
    BEGIN
        SELECT * FROM sys.sp_datatype_info_view_version_2
        WHERE @data_type = 0 OR DATA_TYPE = @data_type;
    END
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE VIEW sys.sp_datatype_info_100_view_version_2 AS 
SELECT TYPE_NAME, DATA_TYPE, "PRECISION", LITERAL_PREFIX, LITERAL_SUFFIX,
       CAST(CREATE_PARAMS AS CHAR(20)) AS CREATE_PARAMS, 
       NULLABLE, CASE_SENSITIVE, SEARCHABLE,
       UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
       MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
       NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
FROM sys.sp_datatype_info_helper(2::smallint, true) 
ORDER BY DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;

GRANT SELECT ON sys.sp_datatype_info_100_view_version_2 TO PUBLIC;


CREATE OR REPLACE VIEW sys.sp_datatype_info_100_view_version_3 AS 
SELECT TYPE_NAME, DATA_TYPE, "PRECISION", LITERAL_PREFIX, LITERAL_SUFFIX,
       CAST(CREATE_PARAMS AS CHAR(20)) AS CREATE_PARAMS, 
       NULLABLE, CASE_SENSITIVE, SEARCHABLE,
       UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
       MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
       NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
FROM sys.sp_datatype_info_helper(3::smallint, true) 
ORDER BY DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;

GRANT SELECT ON sys.sp_datatype_info_100_view_version_3 TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100(
    "@data_type" int = 0,
    "@odbcver" smallint = 2)
AS $$
BEGIN
    IF @odbcver = 3
    BEGIN
        SELECT * FROM sys.sp_datatype_info_100_view_version_3
        WHERE @data_type = 0 OR DATA_TYPE = @data_type;
    END
    ELSE
    BEGIN
        SELECT * FROM sys.sp_datatype_info_100_view_version_2
        WHERE @data_type = 0 OR DATA_TYPE = @data_type;
    END
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
	WITH tt_internal AS MATERIALIZED (
		SELECT * FROM sys.table_types_internal
	)
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
				c.relname)
			AS sys._ci_sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS sys.varchar(10)) COLLATE sys.database_default AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
		   LEFT JOIN tt_internal tt ON c.oid = tt.typrelid

	WHERE c.relkind IN ('r', 'v', 'p')
		AND c.relispartition = false
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid IS NULL
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
