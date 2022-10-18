-- complain if script is sourced in psql, rather than via ALTER EXTENSION
-- \echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.3.0'" to load this file. \quit

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

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_view(schema_name varchar, view_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop view %s.%s', schema_name, view_name);
    query2 := format('drop view %s.%s', schema_name, view_name);
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
    ELSIF ((p_year NOT BETWEEN 1753 AND 9999) OR
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
    RETURN CAST(v_string AS sys.DATETIMEOFFSET);
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
LANGUAGE SQL VOLATILE STRICT;

-- Drops a function if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_function(schema_name varchar, func_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop function %s.%s', schema_name, func_name);
    query2 := format('drop function %s.%s', schema_name, func_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop function' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- function sys.get_babel_server_collation_oid() is depcreated by babelfishpg_common extension during v2.3.0
CALL sys.babelfish_drop_deprecated_function('sys', 'get_babel_server_collation_oid_deprecated_in_2_3_0');

ALTER TABLE sys.babelfish_configurations RENAME TO babelfish_configurations_depcreated_in_2_3_0;

CREATE TABLE sys.babelfish_configurations (
    configuration_id INT,
    name sys.nvarchar(35),
    value sys.sql_variant,
    minimum sys.sql_variant,
    maximum sys.sql_variant,
    value_in_use sys.sql_variant,
    description sys.nvarchar(255),
    is_dynamic sys.BIT,
    is_advanced sys.BIT,
    comment_syscurconfigs sys.nvarchar(255),
    comment_sysconfigures sys.nvarchar(255)
) WITH (OIDS = FALSE);

INSERT INTO sys.babelfish_configurations SELECT * FROM sys.babelfish_configurations_depcreated_in_2_3_0;
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_configurations', '');

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
    v_datatype := upper(trim(p_datatype));
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
    IF (v_datatype ~* DATATYPE_MASK_REGEXP COLLATE "C") THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(' COLLATE "C", 1));
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
    ELSIF (v_datatype ~* DATATYPE_REGEXP COLLATE "C") THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;
    v_dateval := CASE
                    WHEN (v_style NOT IN (130, 131)) THEN p_dateval
                    ELSE sys.babelfish_conv_greg_to_hijri(p_dateval) + 1
                 END;
    v_day := ltrim(to_char(v_dateval, 'DD'), '0');
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
    RAISE USING MESSAGE := pg_catalog.format('Error converting data type DATE to %s.', trim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
   RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr,
                                     lower(v_res_datatype),
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
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

		RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT -1)
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
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;
    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP COLLATE "C")
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;
        v_src_datatype := rtrim(split_part(v_src_datatype, '(' COLLATE "C", 1));
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
                v_style IN (-1, 120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;
    IF (v_datatype ~* DATATYPE_MASK_REGEXP COLLATE "C") THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(' COLLATE "C", 1));
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
    ELSIF (v_datatype ~* DATATYPE_REGEXP COLLATE "C") THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;
    v_datetimeval := CASE
                        WHEN (v_style NOT IN (130, 131)) THEN p_datetimeval
                        ELSE sys.babelfish_conv_greg_to_hijri(p_datetimeval) + INTERVAL '1 day'
                     END;
    v_day := ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := ltrim(to_char(v_datetimeval, 'HH12'), '0');
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
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(v_datetimeval, 'US'), v_scale);
        IF (v_scale = 7) THEN
            v_fseconds := concat(v_fseconds, '0');
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
        v_resmask := concat(CASE p_style
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
                                      v_lengthexpr, lower(v_res_datatype), v_maxlength),
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
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',

                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_greg_to_hijri(extract(day from p_datetimeval)::SMALLINT,
                                                         extract(month from p_datetimeval)::SMALLINT,
                                                         extract(year from p_datetimeval)::INTEGER);

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_hijri_to_greg(extract(day from p_dateval)::NUMERIC,
                                                         extract(month from p_dateval)::NUMERIC,
                                                         extract(year from p_dateval)::NUMERIC);

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_date(IN p_datestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_style SMALLINT;
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_fractsecs VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP,
                                                    ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_DOTPART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP,
                                                       ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', HHMMSSFS_PART_REGEXP, '$');
    HHMMSSFS_DOT_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', HHMMSSFS_DOTPART_REGEXP, '$');
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    v_defmask4_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s*\,\s*', COMPYEAR_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*($comp_month$)\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    DOT_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', SHORTYEAR_REGEXP, '$');
    DOT_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '$');
    SLASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', SHORTYEAR_REGEXP, '$');
    SLASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', FULLYEAR_REGEXP, '$');
    DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', SHORTYEAR_REGEXP, '$');
    DASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '$');
    DOT_SLASH_DASH_YEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    YEAR_DOTMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    YEAR_SLASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '$');
    YEAR_DASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    YEAR_DOT_SLASH_DASH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '$');
    DIGITMASK1_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{6}$';
    DIGITMASK2_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{8}$';
BEGIN
    v_style := floor(p_style)::SMALLINT;
    v_datestring := trim(p_datestring);

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datestring ~* HHMMSSFS_PART_REGEXP AND v_datestring !~* HHMMSSFS_REGEXP)
    THEN
        v_datestring := trim(regexp_pg_catalog.replace(v_datestring, HHMMSSFS_PART_REGEXP, '', 'gi'));
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    v_defmask1_regexp := pg_catalog.replace(v_defmask1_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask2_regexp := pg_catalog.replace(v_defmask2_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask3_regexp := pg_catalog.replace(v_defmask3_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask4_regexp := pg_catalog.replace(v_defmask4_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask5_regexp := pg_catalog.replace(v_defmask5_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask6_regexp := pg_catalog.replace(v_defmask6_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask7_regexp := pg_catalog.replace(v_defmask7_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask8_regexp := pg_catalog.replace(v_defmask8_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask9_regexp := pg_catalog.replace(v_defmask9_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask10_regexp := pg_catalog.replace(v_defmask10_regexp, '$comp_month$', v_compmonth_regexp);

    IF (v_datestring ~* v_defmask1_regexp OR
        v_datestring ~* v_defmask2_regexp OR
        v_datestring ~* v_defmask3_regexp OR
        v_datestring ~* v_defmask4_regexp OR
        v_datestring ~* v_defmask5_regexp OR
        v_datestring ~* v_defmask6_regexp OR
        v_datestring ~* v_defmask7_regexp OR
        v_datestring ~* v_defmask8_regexp OR
        v_datestring ~* v_defmask9_regexp OR
        v_datestring ~* v_defmask10_regexp)
    THEN
        IF (v_style IN (130, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* v_defmask1_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask1_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask2_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask2_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask3_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask3_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask4_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask4_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask5_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* v_defmask6_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask6_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* v_defmask7_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask7_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask8_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask8_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask9_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask9_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];
        ELSE
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask10_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSEIF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* DOT_FULLYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_FULLYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_FULLYEAR_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (20, 21, 23, 25, 102, 111, 120, 121, 126, 127)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_YEAR_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22) AND v_date_format <> 'MDY') OR
                ((v_style IS NULL OR v_style IN (0, 1, 10, 22)) AND v_date_format NOT IN ('YDM', 'YMD', 'DMY', 'DYM', 'MYD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   ((v_style IS NULL OR v_style IN (0, 2, 11)) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   ((v_style IS NULL OR v_style IN (0, 3, 4, 5)) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day := v_leftpart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM') THEN
                RAISE character_not_in_repertoire;
            ELSIF (v_style IN (101, 103, 104, 105, 110, 131)) THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_year := v_rightpart;

            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (101, 110) AND v_date_format IN ('YDM', 'DMY', 'DYM')) OR
                       ((v_style IS NULL OR v_style IN (0, 101, 110)) AND v_date_format NOT IN ('YDM', 'DMY', 'DYM')))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22) AND v_date_format <> 'YDM') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22)) AND v_date_format = 'YDM'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 110) AND v_date_format = 'DMY') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22, 101, 110)) AND v_date_format <> 'DMY'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datestring ~* YEAR_DOTMASK_REGEXP OR
           v_datestring ~* YEAR_SLASHMASK_REGEXP OR
           v_datestring ~* YEAR_DASHMASK_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, YEAR_DOT_SLASH_DASH_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

    ELSIF (v_datestring ~* DIGITMASK1_REGEXP OR
           v_datestring ~* DIGITMASK2_REGEXP)
    THEN
        IF (v_datestring ~* DIGITMASK1_REGEXP)
        THEN
            v_day := substring(v_datestring, 5, 2);
            v_month := substring(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substring(v_datestring, 1, 2));
        ELSE
            v_day := substring(v_datestring, 7, 2);
            v_month := substring(v_datestring, 5, 2);
            v_year := substring(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datestring ~* HHMMSSFS_REGEXP)
    THEN
        v_fractsecs := coalesce(sys.babelfish_get_timeunit_from_string(v_datestring, 'FRACTSECONDS'), '');
        IF (v_datestring !~* HHMMSSFS_DOT_REGEXP AND char_length(v_fractsecs) > 3) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datestring ~* HHMMSSFS_REGEXP OR v_datestring ~* DIGITMASK1_REGEXP OR v_datestring ~* DIGITMASK2_REGEXP) AND v_style IN (130, 131)) OR
        ((v_datestring ~* DOT_FULLYEAR_REGEXP OR v_datestring ~* SLASH_FULLYEAR_REGEXP OR v_datestring ~* DASH_FULLYEAR_REGEXP) AND v_style = 131))
    THEN
        IF ((v_day::SMALLINT NOT BETWEEN 1 AND 29) OR
            (v_month::SMALLINT NOT BETWEEN 1 AND 12))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_datestring := to_char(v_hijridate, 'DD.MM.YYYY');

        v_day := split_part(v_datestring, '.', 1);
        v_month := split_part(v_datestring, '.', 2);
        v_year := split_part(v_datestring, '.', 3);
    END IF;

    RETURN to_date(concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 2 of conv_string_to_date function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to DATE.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{6}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{8}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype COLLATE "C", DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' COLLATE sys.database_default AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))) AND
             v_res_datatype = 'DATETIME2')
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_timepart := trim(substring(v_datetimestring, HHMMSSFS_PART_REGEXP));
    v_datestring := trim(regexp_replace(v_datetimestring, HHMMSSFS_PART_REGEXP, '', 'gi'));

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, '' COLLATE "C"), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
    THEN
        IF ((v_style IN (127, 130, 131) AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
            (v_style IN (130, 131) AND v_res_datatype COLLATE "C" = 'DATETIME2'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF ((v_datestring ~* pg_catalog.replace(DEFMASK1_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK2_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK3_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK4_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK5_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK6_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK7_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp)) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$' COLLATE "C", v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11) AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11, 12) AND v_res_datatype COLLATE "C" = 'DATETIME2'))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10) AND v_date_format <> 'MDY' AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10, 22) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2') OR
                (v_style IN (1, 10, 22) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format COLLATE "C" <> 'YMD') OR
                   (v_style IN (0, 2, 11) AND v_date_format COLLATE "C" = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format COLLATE "C" <> 'DMY') OR
                   (v_style IN (0, 3, 4, 5) AND v_date_format COLLATE "C" = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF (v_style = 0 AND v_date_format COLLATE "C" = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format COLLATE "C" = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format COLLATE "C" = 'YDM')
            THEN
                IF (v_res_datatype COLLATE "C" = 'DATETIME2') THEN
                    RAISE character_not_in_repertoire;
                END IF;

                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            ELSE
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
                v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME'))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_style IN (130, 131) AND v_res_datatype COLLATE "C" = 'SMALLDATETIME') THEN
                RAISE invalid_character_value_for_cast;
            END IF;

            v_year := v_rightpart;
            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format COLLATE "C" = 'DMY' AND v_res_datatype COLLATE "C" = 'DATETIME2') OR
                    (v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;

                ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (101, 110) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2') OR
                       (v_style IN (0, 101, 110) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2'))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format COLLATE "C" = 'DMY' AND v_res_datatype COLLATE "C" = 'DATETIME2') OR
                    (v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSE
                    IF (v_res_datatype COLLATE "C" = 'DATETIME2') THEN
                        RAISE invalid_datetime_format;
                    END IF;

                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
            v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype COLLATE "C" = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (130, 131) AND v_res_datatype COLLATE "C" = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT <= 12) OR v_res_datatype COLLATE "C" = 'DATETIME2')
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype COLLATE "C" <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 23, 25, 101, 102, 110, 111, 120, 121, 126, 127) AND v_res_datatype COLLATE "C" = 'DATETIME2'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM')) OR
                    v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM'))
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
            END IF;
        ELSIF (v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT > 12)
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM')) OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format COLLATE "C" NOT IN ('DMY', 'DYM', 'YDM')) OR
                   (v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format COLLATE "C" IN ('DMY', 'DYM', 'YDM')))
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_res_datatype COLLATE "C" <> 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype COLLATE "C" = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datetimestring ~* HHMMSSFS_PART_REGEXP AND v_res_datatype COLLATE "C" = 'DATETIME2') OR
        (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP OR
          v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP OR v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR1_0_REGEXP)) AND
        v_style IN (130, 131))
    THEN
        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
    v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
    v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
    v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

    IF ((v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME') OR
         (v_res_datatype COLLATE "C" = 'DATETIME2' AND v_timepart !~* HHMMSSFS_DOT_PART_REGEXP)) AND
        char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        IF (v_res_datatype COLLATE "C" IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                                 v_hours, v_minutes, v_seconds,
                                                                 rpad(v_fseconds, 3, '0'));
            IF (v_res_datatype COLLATE "C" = 'SMALLDATETIME' AND
                to_char(v_resdatetime, 'SS') <> '00')
            THEN
                IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
                    v_resdatetime := v_resdatetime + INTERVAL '1 minute';
                END IF;

                v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSIF (v_res_datatype COLLATE "C" = 'DATETIME2')
        THEN
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);

            v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN datetime_field_overflow THEN
            RAISE invalid_datetime_format;
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_character_value_for_cast;
        END IF;
    END;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_datetime function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to %s.', v_style, v_res_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to SMALLDATETIME data type.'
                                  ELSE 'Conversion failed when converting date and time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a VARCHAR data type to a DATETIME data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date and time.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT,
                                                                 IN p_timestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hours SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_daypart VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_minutes SMALLINT;
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
BEGIN
    v_datatype := trim(regexp_replace(p_datatype, 'DATETIME', 'TIME', 'gi'));
    v_timestring := upper(trim(p_timestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_src_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_src_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_daypart := substring(v_timestring, 'AM|PM');
    v_timestring := trim(regexp_replace(v_timestring, coalesce(v_daypart, ''), ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timestring ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timestring ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timestring ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timestring ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timestring ~* HH_REGEXP) THEN HH_REGEXP
        END;

    IF (v_timeunit_mask IS NULL) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_regmatch_groups := regexp_matches(v_timestring, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1]::SMALLINT;
    v_minutes := v_regmatch_groups[2]::SMALLINT;

    IF (v_timestring ~* HHMMFS_REGEXP) THEN
        v_fseconds := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fseconds := v_regmatch_groups[4];
    END IF;

   IF (v_daypart IS NOT NULL) THEN
      IF ((v_daypart = 'AM' AND v_hours NOT BETWEEN 0 AND 12) OR
          (v_daypart = 'PM' AND v_hours NOT BETWEEN 1 AND 23))
      THEN
          RAISE numeric_value_out_of_range;
      ELSIF (v_daypart = 'PM' AND v_hours < 12) THEN
          v_hours := v_hours + 12;
      ELSIF (v_daypart = 'AM' AND v_hours = 12) THEN
          v_hours := v_hours - 12;
      END IF;
   END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    RETURN make_time(v_hours, v_minutes, v_seconds::NUMERIC);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_time function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
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
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
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
        v_res_datatype := rtrim(split_part(v_datatype, '(' COLLATE "C", 1));
        v_res_maxlength := CASE
                              WHEN (v_res_datatype COLLATE "C" IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                              ELSE NVARCHAR_MAX
                           END;
        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);
        IF (v_lengthexpr <> 'MAX' COLLATE "C" AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;
        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' COLLATE "C" THEN v_res_maxlength
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
    v_hours := ltrim(to_char(p_timeval, 'HH12'), '0');
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(p_timeval, 'US'), v_scale);
    IF (v_scale = 7) THEN
        v_fseconds := concat(v_fseconds, '0');
    END IF;
    IF (v_style IN (0, 100))
    THEN
        v_resmask := concat(v_hours, ':MIAM');
    ELSIF (v_style IN (8, 20, 24, 108, 120))
    THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style IN (9, 109))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(v_hours, ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
    	v_resmask := pg_catalog.format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
                     END;
    END IF;

    v_resstring := to_char(p_timeval, v_resmask);
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' COLLATE "C" THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype COLLATE "C" NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
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
                                     v_lengthexpr, lower(v_res_datatype), v_res_maxlength),
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
                                      rtrim(split_part(trim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_lang_metadata_json(IN p_lang_spec_culture TEXT)
RETURNS JSONB
AS
$BODY$
DECLARE
    v_locale_parts TEXT[] COLLATE "C";
    v_lang_data_jsonb JSONB;
    v_lang_spec_culture VARCHAR COLLATE "C";
    v_is_cached BOOLEAN := FALSE;
BEGIN
    v_lang_spec_culture := upper(trim(p_lang_spec_culture));

    IF (char_length(v_lang_spec_culture) > 0)
    THEN
        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s' COLLATE "C",
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            v_lang_spec_culture := upper(regexp_replace(v_lang_spec_culture, '-\s*' COLLATE "C", '_', 'gi'));
            IF (v_lang_spec_culture IN ('AR', 'FI') OR
                v_lang_spec_culture ~ '_')
            THEN
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.babelfish_syslanguages
                 WHERE spec_culture = v_lang_spec_culture;
            ELSE
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.babelfish_syslanguages
                 WHERE lang_name_mssql = v_lang_spec_culture
                    OR lang_alias_mssql = v_lang_spec_culture;
            END IF;
        ELSE
            v_is_cached := TRUE;
        END IF;
    ELSE
        v_lang_spec_culture := current_setting('LC_TIME');

        v_lang_spec_culture := CASE
                                  WHEN (v_lang_spec_culture !~ '\.' COLLATE "C") THEN v_lang_spec_culture
                                  ELSE substring(v_lang_spec_culture, '(.*)(?:\.)')
                               END;

        v_lang_spec_culture := upper(regexp_replace(v_lang_spec_culture, ',\s*' COLLATE "C", '_', 'gi'));

        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s' COLLATE "C",
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            BEGIN
                IF (char_length(v_lang_spec_culture) = 5)
                THEN
                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
                ELSE
                    v_locale_parts := string_to_array(v_lang_spec_culture, '-');

                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE lang_name_pg = v_locale_parts[1]
                       AND territory = v_locale_parts[2];
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_lang_spec_culture := 'EN_US';

                    SELECT lang_data_jsonb
                      INTO v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
            END;
        ELSE
            v_is_cached := TRUE;
        END IF;
    END IF;

    IF (NOT v_is_cached) THEN
        PERFORM set_config(format('sys.lang_metadata_json.%s' COLLATE "C",
                                  v_lang_spec_culture),
                           v_lang_data_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_lang_data_jsonb;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE USING MESSAGE := format('The language metadata JSON value extracted from chache is not a valid JSON object.',
                                      p_lang_spec_culture),
                    HINT := 'Drop the current session, fix the appropriate record in "sys.babelfish_syslanguages" table, and try again after reconnection.';

    WHEN OTHERS THEN
        RAISE USING MESSAGE := format('"%s" is not a valid special culture or language name parameter.',
                                      p_lang_spec_culture),
                    DETAIL := 'Use of incorrect "lang_spec_culture" parameter value during conversion process.',
                    HINT := 'Change "lang_spec_culture" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_remove_delimiter_pair(IN name TEXT)
RETURNS TEXT AS
$BODY$
BEGIN
    IF name collate sys.database_default IN('[', ']', '"') THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '[' collate sys.database_default AND right(name, 1) = ']' collate sys.database_default THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '[' collate sys.database_default AND right(name, 1) != ']' collate sys.database_default THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '[' collate sys.database_default AND right(name, 1) = ']' collate sys.database_default THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '"' collate sys.database_default AND right(name, 1) = '"' collate sys.database_default THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '"' collate sys.database_default AND right(name, 1) != '"' collate sys.database_default THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '"' collate sys.database_default AND right(name, 1) = '"' collate sys.database_default THEN
        RETURN NULL;

    END IF;
    RETURN name;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_name_delimiter_pos(name TEXT)
RETURNS INTEGER
AS $$
DECLARE
    pos int;
    name_tmp TEXT collate "C" := name;
BEGIN
    IF (length(name_tmp collate sys.database_default) <= 2 AND (position('"' IN name_tmp) != 0 OR position(']' IN name_tmp) != 0 OR position('[' IN name_tmp) != 0))
       -- invalid name
       THEN RETURN 0;
    ELSIF left(name_tmp, 1) collate sys.database_default = '[' THEN
        pos = position('].' IN name_tmp);
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 1;
        END IF;
    ELSIF left(name_tmp, 1) collate sys.database_default = '"' THEN
        -- search from position 1 in case name starts with ".
        pos = position('".' IN right(name_tmp, length(name_tmp) - 1));
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 2;
        END IF;
    ELSE
        RETURN position('.' IN name_tmp);
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_has_any_privilege(
    perm_target_type text,
    schema_name text,
    object_name text)
RETURNS INTEGER
AS
$BODY$
DECLARE
    relevant_permissions text[];
    namespace_id oid;
    function_signature text;
    qualified_name text;
    permission text;
BEGIN
 IF perm_target_type IS NULL OR perm_target_type COLLATE sys.database_default NOT IN('table', 'function', 'procedure')
        THEN RETURN NULL;
    END IF;

    relevant_permissions := (
        SELECT CASE
            WHEN perm_target_type = 'table' COLLATE sys.database_default
                THEN '{"select", "insert", "update", "delete", "references"}'
            WHEN perm_target_type = 'column' COLLATE sys.database_default
                THEN '{"select", "update", "references"}'
            WHEN perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
                THEN '{"execute"}'
        END
    );

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = schema_name COLLATE sys.database_default;

    IF perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
        THEN SELECT oid::regprocedure
                INTO function_signature
                FROM pg_catalog.pg_proc
                WHERE proname = object_name COLLATE sys.database_default
                    AND pronamespace = namespace_id;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', schema_name, '"."', object_name, '"');

    FOREACH permission IN ARRAY relevant_permissions
    LOOP
        IF perm_target_type = 'table' COLLATE sys.database_default AND has_table_privilege(qualified_name, permission)::integer = 1
            THEN RETURN 1;
        ELSIF perm_target_type COLLATE sys.database_default IN ('function', 'procedure') AND has_function_privilege(function_signature, permission)::integer = 1
            THEN RETURN 1;
        END IF;
    END LOOP;
    RETURN 0;
END
$BODY$
LANGUAGE plpgsql;


-- Return the object ID given the object name. Can specify optional type.
CREATE OR REPLACE FUNCTION sys.object_id(IN object_name TEXT, IN object_type char(2) DEFAULT '')
RETURNS INTEGER AS
$BODY$
DECLARE
        id oid;
        db_name text collate "C";
        bbf_schema_name text collate "C";
        schema_name text collate "C";
        schema_oid oid;
        obj_name text collate "C";
        is_temp_object boolean;
        obj_type char(2) collate "C";
        cs_as_object_name text collate "C" := object_name;
BEGIN
        obj_type = object_type;
        id = null;
        schema_oid = NULL;

        SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, obj_name
        FROM babelfish_split_object_name(cs_as_object_name) s;

        -- Invalid object_name
        IF obj_name IS NULL OR obj_name = '' collate sys.database_default THEN
            RETURN NULL;
        END IF;

        IF bbf_schema_name IS NULL OR bbf_schema_name = '' collate sys.database_default THEN
            bbf_schema_name := sys.schema_name();
        END IF;

        schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

        -- Check if looking for temp object.
        is_temp_object = left(obj_name, 1) = '#' collate sys.database_default;

        -- Can only search in current database. Allowing tempdb for temp objects.
        IF db_name IS NOT NULL AND db_name collate sys.database_default <> db_name() AND db_name collate sys.database_default <> 'tempdb' THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;

        IF schema_name IS NULL OR schema_name = '' collate sys.database_default THEN
            RETURN NULL;
        END IF;

        -- Searching within a schema. Get schema oid.
        schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
        IF schema_oid IS NULL THEN
            RETURN NULL;
        END IF;

        if object_type <> '' then
            case
                -- Schema does not apply as much to temp objects.
                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
             id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);

                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
             id := (select oid from pg_class where lower(relname) collate sys.database_default = obj_name
                            and relnamespace = schema_oid limit 1);

                when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
             id := (select oid from pg_constraint where lower(conname) collate sys.database_default = obj_name
                            and connamespace = schema_oid limit 1);

                when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
             id := (select oid from pg_proc where lower(proname) collate sys.database_default = obj_name
                            and pronamespace = schema_oid limit 1);

                when upper(object_type) in ('TR', 'TA') then
             id := (select oid from pg_trigger where lower(tgname) collate sys.database_default = obj_name limit 1);

                -- Throwing exception as a reminder to add support in the future.
                when upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                    RAISE EXCEPTION 'Object type currently unsupported.';

                -- unsupported object_type
                else id := null;
            end case;
        else
            if not is_temp_object then id := (
                                            select oid from pg_class where lower(relname) = obj_name
                                                and relnamespace = schema_oid
                union
                   select oid from pg_constraint where lower(conname) = obj_name
                and connamespace = schema_oid
                                                union
                   select oid from pg_proc where lower(proname) = obj_name
                and pronamespace = schema_oid
                                                union
                   select oid from pg_trigger where lower(tgname) = obj_name
                   limit 1);
            else
                -- temp object without "object_type" in-argument
                id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);
            end if;
        end if;

        RETURN id::integer;
END;
$BODY$
LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;

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
  if left(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"', 'i');
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if right(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%', 'i');
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

CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty (
property_name varchar(128),
level0_object_type varchar(128),
level0_object_name varchar(128),
level1_object_type varchar(128),
level1_object_name varchar(128),
level2_object_type varchar(128),
level2_object_name varchar(128)
)
returns table (
objtype sys.sysname,
objname sys.sysname,
name sys.sysname,
value sys.sql_variant
)
as $$
begin
-- currently only support COLUMN property
IF (((SELECT coalesce(property_name COLLATE sys.database_default, '')) = '') or
    ((SELECT UPPER(coalesce(property_name COLLATE sys.database_default, ''))) = 'COLUMN')) THEN
 IF (((SELECT LOWER(coalesce(level0_object_type COLLATE sys.database_default, ''))) = 'schema') and
     ((SELECT LOWER(coalesce(level1_object_type COLLATE sys.database_default, ''))) = 'table') and
     ((SELECT LOWER(coalesce(level2_object_type COLLATE sys.database_default, ''))) = 'column')) THEN
  RETURN query
  select CAST('COLUMN' AS sys.sysname) as objtype,
         CAST(t3.column_name AS sys.sysname) as objname,
         t1.name as name,
         t1.value as value
  from sys.extended_properties t1, pg_catalog.pg_class t2, information_schema.columns t3
  where t1.major_id = t2.oid and
     t2.relname = cast(t3.table_name as sys.sysname) COLLATE sys.database_default and
        t2.relname = (SELECT coalesce(level1_object_name COLLATE sys.database_default, '')) COLLATE sys.database_default and
     t3.column_name = (SELECT coalesce(level2_object_name COLLATE sys.database_default, '')) COLLATE sys.database_default;
 END IF;
END IF;
RETURN;
end;
$$
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty(
 varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id oid, property name, property_name text)
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare extra_bytes CONSTANT integer := 4;
declare return_value integer;
begin
 return_value := (
     select
      case LOWER(property_name)
       when 'charmaxlen' COLLATE sys.database_default then
        (select CASE WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes ELSE NULL END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
       when 'allowsnull' COLLATE sys.database_default then
        (select CASE WHEN a.attnotnull THEN 0 ELSE 1 END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
       else
        null
      end
     );

  RETURN return_value::integer;
EXCEPTION
 WHEN others THEN
   RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id oid, property name, property_name text) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    db_name text COLLATE sys.database_default; 
    bbf_schema_name text;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
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
    cs_as_securable = lower(rtrim(cs_as_securable));
    cs_as_securable_class = lower(rtrim(cs_as_securable_class));
    cs_as_permission = lower(rtrim(cs_as_permission));
    cs_as_sub_securable = lower(rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(rtrim(cs_as_sub_securable_class));

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
                    AND CAST(ext.dbid AS oid) = CAST(sys.db_id() AS oid)) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND CURRENT_USER IN('dbo', 'master_dbo', 'tempdb_dbo', 'msdb_dbo') THEN
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
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(name) 
                        FROM sys.all_columns 
                        WHERE name = cs_as_sub_securable COLLATE sys.database_default
                            -- Use V as the object type to specify that the securable is table-like.
                            -- We don't know that the securable is a view, but object_id behaves the 
                            -- same for differint table-like types, so V can be arbitrarily chosen.
                            AND object_id = sys.object_id(cs_as_securable, 'V')) = 1
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
    
    -- Object wasn't found
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
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(function_signature, 'execute') AS integer)
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

ALTER TABLE sys.babelfish_namespace_ext RENAME TO babelfish_namespace_ext_deprecated_in_2_3_0;

-- we need to drop primary key constraint also because babelfish_namespace_ext_pkey is being used from C code to perform some lokkup
ALTER TABLE sys.babelfish_namespace_ext_deprecated_in_2_3_0 DROP CONSTRAINT babelfish_namespace_ext_pkey;

-- BABELFISH_NAMESPACE_EXT
CREATE TABLE sys.babelfish_namespace_ext (
    nspname NAME NOT NULL,
    dbid SMALLINT NOT NULL,
    orig_name sys.NVARCHAR(128) NOT NULL,
 properties TEXT NOT NULL COLLATE "C",
    PRIMARY KEY (nspname)
);
GRANT SELECT ON sys.babelfish_namespace_ext TO PUBLIC;

INSERT INTO sys.babelfish_namespace_ext SELECT * FROM babelfish_namespace_ext_deprecated_in_2_3_0;
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_namespace_ext', '');

CALL babel_catalog_initializer();

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
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128)) TO PUBLIC;

-- SYSDATABASES
CREATE OR REPLACE VIEW sys.sysdatabases AS
SELECT
t.name,
sys.db_id(t.name) AS dbid,
CAST(CAST(r.oid AS int) AS SYS.VARBINARY(85)) AS sid,
CAST(0 AS SMALLINT) AS mode,
t.status,
t.status2,
CAST(t.crdate AS SYS.DATETIME) AS crdate,
CAST('1900-01-01 00:00:00.000' AS SYS.DATETIME) AS reserved,
CAST(0 AS INT) AS category,
CAST(120 AS SYS.TINYINT) AS cmptlevel,
CAST(NULL AS SYS.NVARCHAR(260)) AS filename,
CAST(NULL AS SMALLINT) AS version
FROM sys.babelfish_sysdatabases AS t
LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = t.owner;

-- PG_NAMESPACE_EXT
CREATE OR REPLACE VIEW sys.pg_namespace_ext AS
SELECT BASE.* , DB.name as dbname FROM
pg_catalog.pg_namespace AS base
LEFT OUTER JOIN sys.babelfish_namespace_ext AS EXT on BASE.nspname = EXT.nspname
INNER JOIN sys.babelfish_sysdatabases AS DB ON EXT.dbid = DB.dbid;

-- Logical Schema Views
create or replace view sys.schemas as
select
  CAST(ext.orig_name as sys.SYSNAME) as name
  , base.oid as schema_id
  , base.nspowner as principal_id
from pg_catalog.pg_namespace base INNER JOIN sys.babelfish_namespace_ext ext on base.nspname = ext.nspname
where base.nspname not in ('information_schema', 'pg_catalog', 'pg_toast', 'sys', 'public')
and ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT ON sys.schemas TO PUBLIC;

ALTER TABLE sys.babelfish_authid_login_ext RENAME TO babelfish_authid_login_ext_deprecated_in_2_3_0;

-- we need to drop primary key constraint also because babelfish_authid_login_ext_pkey is being used from C code to perform some lokkup
ALTER TABLE sys.babelfish_authid_login_ext_deprecated_in_2_3_0 DROP CONSTRAINT babelfish_authid_login_ext_pkey;

-- LOGIN EXT
-- Note: change here requires change in FormData_authid_login_ext too
CREATE TABLE sys.babelfish_authid_login_ext (
rolname NAME NOT NULL, -- pg_authid.rolname
is_disabled INT NOT NULL DEFAULT 0, -- to support enable/disable login
type CHAR(1) NOT NULL DEFAULT 'S',
credential_id INT NOT NULL,
owning_principal_id INT NOT NULL,
is_fixed_role INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
default_database_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128) NOT NULL,
properties JSONB,
PRIMARY KEY (rolname));
GRANT SELECT ON sys.babelfish_authid_login_ext TO PUBLIC;

INSERT INTO sys.babelfish_authid_login_ext SELECT * FROM sys.babelfish_authid_login_ext_deprecated_in_2_3_0;
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_login_ext', '');

CALL babel_catalog_initializer();

-- SERVER_PRINCIPALS
CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
ELSE NULL END AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

ALTER TABLE sys.babelfish_authid_user_ext RENAME TO babelfish_authid_user_ext_deprecated_in_2_3_0;

-- we need to drop primary key constraint also because babelfish_authid_user_ext_pkey is being used from C code to perform some lokkup
ALTER TABLE sys.babelfish_authid_user_ext_deprecated_in_2_3_0 DROP CONSTRAINT babelfish_authid_user_ext_pkey;

ALTER INDEX babelfish_authid_user_ext_login_db_idx RENAME TO babelfish_authid_user_ext_login_db_idx_deprecated_in_2_3_0;

-- USER extension
CREATE TABLE sys.babelfish_authid_user_ext (
rolname NAME NOT NULL,
login_name NAME NOT NULL,
type CHAR(1) NOT NULL DEFAULT 'S',
owning_principal_id INT,
is_fixed_role INT NOT NULL DEFAULT 0,
authentication_type INT,
default_language_lcid INT,
allow_encrypted_value_modifications INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
orig_username SYS.NVARCHAR(128) NOT NULL,
database_name SYS.NVARCHAR(128) NOT NULL,
default_schema_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128),
authentication_type_desc SYS.NVARCHAR(60),
PRIMARY KEY (rolname));

CREATE INDEX babelfish_authid_user_ext_login_db_idx ON sys.babelfish_authid_user_ext (login_name, database_name);
GRANT SELECT ON sys.babelfish_authid_user_ext TO PUBLIC;

INSERT INTO sys.babelfish_authid_user_ext SELECT * FROM sys.babelfish_authid_user_ext_deprecated_in_2_3_0;

CALL babel_catalog_initializer();

-- DATABASE_PRINCIPALS
CREATE OR REPLACE VIEW sys.database_principals AS SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.OID AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER'
WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

-- DATABASE_ROLE_MEMBERS
CREATE OR REPLACE VIEW sys.database_role_members AS
SELECT
CAST(Auth1.oid AS INT) AS role_principal_id,
CAST(Auth2.oid AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_authid AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_authid AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = DB_NAME()
AND Ext2.database_name = DB_NAME()
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';

GRANT SELECT ON sys.database_role_members TO PUBLIC;

create or replace view sys.databases as	
select	
  CAST(d.name as SYS.SYSNAME) as name	
  , CAST(sys.db_id(d.name) as INT) as database_id	
  , CAST(NULL as INT) as source_database_id	
  , cast(s.sid as SYS.VARBINARY(85)) as owner_sid	
  , CAST(d.crdate AS SYS.DATETIME) as create_date	
  , CAST(s.cmptlevel AS SYS.TINYINT) as compatibility_level	
  , CAST(c.collname as SYS.SYSNAME) as collation_name	
  , CAST(0 AS SYS.TINYINT)  as user_access	
  , CAST('MULTI_USER' AS SYS.NVARCHAR(60)) as user_access_desc	
  , CAST(0 AS SYS.BIT) as is_read_only	
  , CAST(0 AS SYS.BIT) as is_auto_close_on	
  , CAST(0 AS SYS.BIT) as is_auto_shrink_on	
  , CAST(0 AS SYS.TINYINT) as state	
  , CAST('ONLINE' AS SYS.NVARCHAR(60)) as state_desc	
  , CAST(	
	  	CASE 	
			WHEN pg_is_in_recovery() is false THEN 0 	
			WHEN pg_is_in_recovery() is true THEN 1 	
		END 	
	AS SYS.BIT) as is_in_standby	
  , CAST(0 AS SYS.BIT) as is_cleanly_shutdown	
  , CAST(0 AS SYS.BIT) as is_supplemental_logging_enabled	
  , CAST(1 AS SYS.TINYINT) as snapshot_isolation_state	
  , CAST('ON' AS SYS.NVARCHAR(60)) as snapshot_isolation_state_desc	
  , CAST(1 AS SYS.BIT) as is_read_committed_snapshot_on	
  , CAST(1 AS SYS.TINYINT) as recovery_model	
  , CAST('FULL' AS SYS.NVARCHAR(60)) as recovery_model_desc	
  , CAST(0 AS SYS.TINYINT) as page_verify_option	
  , CAST(NULL AS SYS.NVARCHAR(60)) as page_verify_option_desc	
  , CAST(1 AS SYS.BIT) as is_auto_create_stats_on	
  , CAST(0 AS SYS.BIT) as is_auto_create_stats_incremental_on	
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_on	
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_async_on	
  , CAST(0 AS SYS.BIT) as is_ansi_null_default_on	
  , CAST(0 AS SYS.BIT) as is_ansi_nulls_on	
  , CAST(0 AS SYS.BIT) as is_ansi_padding_on	
  , CAST(0 AS SYS.BIT) as is_ansi_warnings_on	
  , CAST(0 AS SYS.BIT) as is_arithabort_on	
  , CAST(0 AS SYS.BIT) as is_concat_null_yields_null_on	
  , CAST(0 AS SYS.BIT) as is_numeric_roundabort_on	
  , CAST(0 AS SYS.BIT) as is_quoted_identifier_on	
  , CAST(0 AS SYS.BIT) as is_recursive_triggers_on	
  , CAST(0 AS SYS.BIT) as is_cursor_close_on_commit_on	
  , CAST(0 AS SYS.BIT) as is_local_cursor_default	
  , CAST(0 AS SYS.BIT) as is_fulltext_enabled	
  , CAST(0 AS SYS.BIT) as is_trustworthy_on	
  , CAST(0 AS SYS.BIT) as is_db_chaining_on	
  , CAST(0 AS SYS.BIT) as is_parameterization_forced	
  , CAST(0 AS SYS.BIT) as is_master_key_encrypted_by_server	
  , CAST(0 AS SYS.BIT) as is_query_store_on	
  , CAST(0 AS SYS.BIT) as is_published	
  , CAST(0 AS SYS.BIT) as is_subscribed	
  , CAST(0 AS SYS.BIT) as is_merge_published	
  , CAST(0 AS SYS.BIT) as is_distributor	
  , CAST(0 AS SYS.BIT) as is_sync_with_backup	
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as service_broker_guid	
  , CAST(0 AS SYS.BIT) as is_broker_enabled	
  , CAST(0 AS SYS.TINYINT) as log_reuse_wait	
  , CAST('NOTHING' AS SYS.NVARCHAR(60)) as log_reuse_wait_desc	
  , CAST(0 AS SYS.BIT) as is_date_correlation_on	
  , CAST(0 AS SYS.BIT) as is_cdc_enabled	
  , CAST(0 AS SYS.BIT) as is_encrypted	
  , CAST(0 AS SYS.BIT) as is_honor_broker_priority_on	
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as replica_id	
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as group_database_id	
  , CAST(NULL AS INT) as resource_pool_id	
  , CAST(NULL AS SMALLINT) as default_language_lcid	
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_language_name	
  , CAST(NULL AS INT) as default_fulltext_language_lcid	
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_fulltext_language_name	
  , CAST(NULL AS SYS.BIT) as is_nested_triggers_on	
  , CAST(NULL AS SYS.BIT) as is_transform_noise_words_on	
  , CAST(NULL AS SMALLINT) as two_digit_year_cutoff	
  , CAST(0 AS SYS.TINYINT) as containment	
  , CAST('NONE' AS SYS.NVARCHAR(60)) as containment_desc	
  , CAST(0 AS INT) as target_recovery_time_in_seconds	
  , CAST(0 AS INT) as delayed_durability	
  , CAST(NULL AS SYS.NVARCHAR(60)) as delayed_durability_desc	
  , CAST(0 AS SYS.BIT) as is_memory_optimized_elevate_to_snapshot_on	
  , CAST(0 AS SYS.BIT) as is_federation_member	
  , CAST(0 AS SYS.BIT) as is_remote_data_archive_enabled	
  , CAST(0 AS SYS.BIT) as is_mixed_page_allocation_on	
  , CAST(0 AS SYS.BIT) as is_temporal_history_retention_enabled	
  , CAST(0 AS INT) as catalog_collation_type	
  , CAST('Not Applicable' AS SYS.NVARCHAR(60)) as catalog_collation_type_desc	
  , CAST(NULL AS SYS.NVARCHAR(128)) as physical_database_name	
  , CAST(0 AS SYS.BIT) as is_result_set_caching_on	
  , CAST(0 AS SYS.BIT) as is_accelerated_database_recovery_on	
  , CAST(0 AS SYS.BIT) as is_tempdb_spill_to_remote_store	
  , CAST(0 AS SYS.BIT) as is_stale_page_detection_on	
  , CAST(0 AS SYS.BIT) as is_memory_optimized_enabled	
  , CAST(0 AS SYS.BIT) as is_ledger_on	
 from sys.babelfish_sysdatabases d 	
 INNER JOIN sys.sysdatabases s on d.dbid = s.dbid	
 LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname;	
GRANT SELECT ON sys.databases TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
 scale INT;
BEGIN
 IF type IS NULL THEN
  RETURN -1;
 END IF;

 IF typemod = -1 THEN
  CASE type
  WHEN 'date' THEN scale = 0;
  WHEN 'datetime' THEN scale = 3;
  WHEN 'smalldatetime' THEN scale = 0;
  WHEN 'datetime2' THEN scale = 6;
  WHEN 'datetimeoffset' THEN scale = 6;
  WHEN 'decimal' THEN scale = 38;
  WHEN 'numeric' THEN scale = 38;
  WHEN 'money' THEN scale = 4;
  WHEN 'smallmoney' THEN scale = 4;
  WHEN 'time' THEN scale = 6;
  WHEN 'tinyint' THEN scale = 0;
  ELSE
   IF return_null_for_rest
    THEN scale = NULL;
   ELSE scale = 0;
   END IF;
  END CASE;
  RETURN scale;
 END IF;

 CASE type
 WHEN 'decimal' THEN scale = (typemod - 4) & 65535;
 WHEN 'numeric' THEN scale = (typemod - 4) & 65535;
 WHEN 'smalldatetime' THEN scale = 0;
 WHEN 'datetime2' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for datetime2 in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 WHEN 'datetimeoffset' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for datetimeoffset in Babelfish
  -- but adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 WHEN 'time' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for time in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 ELSE
  IF return_null_for_rest
   THEN scale = NULL;
  ELSE scale = 0;
  END IF;
 END CASE;
 RETURN scale;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_precision_helper(IN type TEXT, IN typemod INT) RETURNS sys.TINYINT
AS $$
DECLARE
 precision INT;
BEGIN
 IF type IS NULL THEN
  RETURN -1;
 END IF;

 IF typemod = -1 THEN
  CASE type
  WHEN 'bigint' THEN precision = 19;
  WHEN 'bit' THEN precision = 1;
  WHEN 'date' THEN precision = 10;
  WHEN 'datetime' THEN precision = 23;
  WHEN 'datetime2' THEN precision = 26;
  WHEN 'datetimeoffset' THEN precision = 33;
  WHEN 'decimal' THEN precision = 38;
  WHEN 'numeric' THEN precision = 38;
  WHEN 'float' THEN precision = 53;
  WHEN 'int' THEN precision = 10;
  WHEN 'money' THEN precision = 19;
  WHEN 'real' THEN precision = 24;
  WHEN 'smalldatetime' THEN precision = 16;
  WHEN 'smallint' THEN precision = 5;
  WHEN 'smallmoney' THEN precision = 10;
  WHEN 'time' THEN precision = 15;
  WHEN 'tinyint' THEN precision = 3;
  ELSE precision = 0;
  END CASE;
  RETURN precision;
 END IF;

 CASE type
 WHEN 'numeric' THEN precision = ((typemod - 4) >> 16) & 65535;
 WHEN 'decimal' THEN precision = ((typemod - 4) >> 16) & 65535;
 WHEN 'smalldatetime' THEN precision = 16;
 WHEN 'datetime2' THEN
  CASE typemod
  WHEN 0 THEN precision = 19;
  WHEN 1 THEN precision = 21;
  WHEN 2 THEN precision = 22;
  WHEN 3 THEN precision = 23;
  WHEN 4 THEN precision = 24;
  WHEN 5 THEN precision = 25;
  WHEN 6 THEN precision = 26;
  -- typemod = 7 is not possible for datetime2 in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN precision = 27;
  END CASE;
 WHEN 'datetimeoffset' THEN
  CASE typemod
  WHEN 0 THEN precision = 26;
  WHEN 1 THEN precision = 28;
  WHEN 2 THEN precision = 29;
  WHEN 3 THEN precision = 30;
  WHEN 4 THEN precision = 31;
  WHEN 5 THEN precision = 32;
  WHEN 6 THEN precision = 33;
  -- typemod = 7 is not possible for datetimeoffset in Babelfish
  -- but adding the case just in case we support it in future
  WHEN 7 THEN precision = 34;
  END CASE;
 WHEN 'time' THEN
  CASE typemod
  WHEN 0 THEN precision = 8;
  WHEN 1 THEN precision = 10;
  WHEN 2 THEN precision = 11;
  WHEN 3 THEN precision = 12;
  WHEN 4 THEN precision = 13;
  WHEN 5 THEN precision = 14;
  WHEN 6 THEN precision = 15;
  -- typemod = 7 is not possible for time in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN precision = 16;
  END CASE;
 ELSE precision = 0;
 END CASE;
 RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Need to add parameter for tsql_type_max_length_helper 
ALTER FUNCTION sys.tsql_type_max_length_helper RENAME TO tsql_type_max_length_helper_deprecated_in_2_3_0;

CREATE OR REPLACE FUNCTION sys.tsql_type_max_length_helper(IN type TEXT, IN typelen INT, IN typemod INT, IN for_sys_types boolean DEFAULT false, IN used_typmod_array boolean DEFAULT false)
RETURNS SMALLINT
AS $$
DECLARE
	max_length SMALLINT;
	precision INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	-- unknown tsql type
	IF v_type IS NULL THEN
		RETURN CAST(typelen as SMALLINT);
	END IF;

	-- if using typmod_array from pg_proc.probin
	IF used_typmod_array THEN
		IF v_type = 'sysname' THEN
			RETURN 256;
		ELSIF (v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary', 'nchar', 'nvarchar'))
		THEN
			IF typemod < 0 THEN -- max value. 
				RETURN -1;
			ELSIF v_type in ('nchar', 'nvarchar') THEN
				RETURN (2 * typemod);
			ELSE
				RETURN typemod;
			END IF;
		END IF;
	END IF;

	IF typelen != -1 THEN
		CASE v_type 
		WHEN 'tinyint' THEN max_length = 1;
		WHEN 'date' THEN max_length = 3;
		WHEN 'smalldatetime' THEN max_length = 4;
		WHEN 'smallmoney' THEN max_length = 4;
		WHEN 'datetime2' THEN
			IF typemod = -1 THEN max_length = 8;
			ELSIF typemod <= 2 THEN max_length = 6;
			ELSIF typemod <= 4 THEN max_length = 7;
			ELSEIF typemod <= 7 THEN max_length = 8;
			-- typemod = 7 is not possible for datetime2 in Babel
			END IF;
		WHEN 'datetimeoffset' THEN
			IF typemod = -1 THEN max_length = 10;
			ELSIF typemod <= 2 THEN max_length = 8;
			ELSIF typemod <= 4 THEN max_length = 9;
			ELSIF typemod <= 7 THEN max_length = 10;
			-- typemod = 7 is not possible for datetimeoffset in Babel
			END IF;
		WHEN 'time' THEN
			IF typemod = -1 THEN max_length = 5;
			ELSIF typemod <= 2 THEN max_length = 3;
			ELSIF typemod <= 4 THEN max_length = 4;
			ELSIF typemod <= 7 THEN max_length = 5;
			END IF;
		WHEN 'timestamp' THEN max_length = 8;
		ELSE max_length = typelen;
		END CASE;
		RETURN max_length;
	END IF;

	IF typemod = -1 THEN
		CASE 
		WHEN v_type COLLATE sys.database_default in ('image', 'text', 'ntext') THEN max_length = 16;
		WHEN v_type COLLATE sys.database_default = 'sql_variant' THEN max_length = 8016;
		WHEN v_type COLLATE sys.database_default in ('varbinary', 'varchar', 'nvarchar') THEN 
			IF for_sys_types THEN max_length = 8000;
			ELSE max_length = -1;
			END IF;
		WHEN v_type COLLATE sys.database_default in ('binary', 'char', 'bpchar', 'nchar') THEN max_length = 8000;
		WHEN v_type COLLATE sys.database_default in ('decimal', 'numeric') THEN max_length = 17;
		ELSE max_length = typemod;
		END CASE;
		RETURN max_length;
	END IF;

	CASE
	WHEN v_type COLLATE sys.database_default in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN max_length = typemod - 4;
	WHEN v_type COLLATE sys.database_default in ('nchar', 'nvarchar') THEN max_length = (typemod - 4) * 2;
	WHEN v_type COLLATE sys.database_default = 'sysname' THEN max_length = (typemod - 4) * 2;
	WHEN v_type COLLATE sys.database_default in ('numeric', 'decimal') THEN
		precision = ((typemod - 4) >> 16) & 65535;
		IF precision >= 1 and precision <= 9 THEN max_length = 5;
		ELSIF precision <= 19 THEN max_length = 9;
		ELSIF precision <= 28 THEN max_length = 13;
		ELSIF precision <= 38 THEN max_length = 17;
	ELSE max_length = typelen;
	END IF;
	ELSE
		max_length = typemod;
	END CASE;
	RETURN max_length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(0 as sys.bit) as is_identity
  , CAST(0 as sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_parameters
AS
SELECT
    CAST(ss.p_oid AS INT) AS object_id
  , CAST(COALESCE(ss.proargnames[(ss.x).n], '') AS sys.SYSNAME) AS name
  , CAST(
      CASE 
        WHEN is_out_scalar = 1 THEN 0 -- param_id = 0 for output of scalar function
        ELSE (ss.x).n
      END 
    AS INT) AS parameter_id
  -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
  -- This is because the IDs of system type values generated by
  -- Babelfish installation will exceed the size of TINYINT
  , CAST(st.system_type_id AS INT) AS system_type_id
  , CAST(st.user_type_id AS INT) AS user_type_id
  , CAST( 
      CASE
        WHEN st.is_table_type = 1 THEN -1 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.max_length -- UDT case
        ELSE sys.tsql_type_max_length_helper(st.name, t.typlen, typmod, true, true)
      END
    AS smallint) AS max_length
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.precision -- UDT case
        ELSE sys.tsql_type_precision_helper(st.name, typmod)
      END
    AS sys.tinyint) AS precision
  , CAST(
      CASE 
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.scale
        ELSE sys.tsql_type_scale_helper(st.name, typmod,false)
      END
    AS sys.tinyint) AS scale
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 1 -- Output of a scalar function
        WHEN ss.proargmodes[(ss.x).n] in ('o', 'b', 't') THEN 1
        ELSE 0
      END 
    AS sys.bit) AS is_output
  , CAST(0 AS sys.bit) AS is_cursor_ref
  , CAST(0 AS sys.bit) AS has_default_value
  , CAST(0 AS sys.bit) AS is_xml_document
  , CAST(NULL AS sys.sql_variant) AS default_value
  , CAST(0 AS int) AS xml_collection_id
  , CAST(0 AS sys.bit) AS is_readonly
  , CAST(1 AS sys.bit) AS is_nullable
  , CAST(NULL AS int) AS encryption_type
  , CAST(NULL AS sys.nvarchar(64)) AS encryption_type_desc
  , CAST(NULL AS sys.sysname) AS encryption_algorithm_name
  , CAST(NULL AS int) AS column_encryption_key_id
  , CAST(NULL AS sys.sysname) AS column_encryption_key_database_name
FROM pg_type t
  INNER JOIN sys.types st ON st.user_type_id = t.oid
  INNER JOIN 
  (
    SELECT
      p.oid AS p_oid,
      p.proargnames,
      p.proargmodes,
      p.prokind,
      json_extract_path(CAST(p.probin as json), 'typmod_array') AS typmod_array,
      information_schema._pg_expandarray(
      COALESCE(p.proallargtypes,
        CASE 
          WHEN p.prokind = 'f' THEN (CAST( p.proargtypes AS oid[]) || p.prorettype) -- Adds return type if not present on proallargtypes
          ELSE CAST(p.proargtypes AS oid[])
        END
      )) AS x
    FROM pg_proc p
    WHERE (
      p.pronamespace in (select schema_id from sys.schemas union all select oid from pg_namespace where nspname = 'sys')
      AND (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND p.probin like '{%typmod_array%}') -- Needs to have a typmod array in JSON format
  ) ss ON t.oid = (ss.x).x,
  COALESCE(pg_get_function_result(ss.p_oid), '') AS return_type,
  CAST(ss.typmod_array->>(ss.x).n-1 AS INT) AS typmod, 
  CAST(
    CASE
      WHEN ss.prokind = 'f' AND ss.proargnames[(ss.x).n] IS NULL THEN 1 -- checks if param is output of scalar function
      ELSE 0
    END 
  AS INT) AS is_out_scalar
WHERE ( -- If it's a Table function, we only want the inputs
      return_type NOT LIKE 'TABLE(%' OR 
      (return_type LIKE 'TABLE(%' AND ss.proargmodes[(ss.x).n] = 'i'));
GRANT SELECT ON sys.all_parameters TO PUBLIC;


create or replace view sys.columns AS
select out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
from sys.columns_internal();
GRANT SELECT ON sys.columns TO PUBLIC;

CREATE OR replace view sys.foreign_keys AS
SELECT
  CAST(c.conname AS sys.SYSNAME) AS name
, CAST(c.oid AS INT) AS object_id
, CAST(NULL AS INT) AS principal_id
, CAST(sch.schema_id AS INT) AS schema_id
, CAST(c.conrelid AS INT) AS parent_object_id
, CAST('F' AS CHAR(2)) AS type
, CAST('FOREIGN_KEY_CONSTRAINT' AS NVARCHAR(60)) AS type_desc
, CAST(NULL AS sys.DATETIME) AS create_date
, CAST(NULL AS sys.DATETIME) AS modify_date
, CAST(0 AS sys.BIT) AS is_ms_shipped
, CAST(0 AS sys.BIT) AS is_published
, CAST(0 AS sys.BIT) as is_schema_published
, CAST(c.confrelid AS INT) AS referenced_object_id
, CAST(c.conindid AS INT) AS key_index_id
, CAST(0 AS sys.BIT) AS is_disabled
, CAST(0 AS sys.BIT) AS is_not_for_replication
, CAST(0 AS sys.BIT) AS is_not_trusted
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS delete_referential_action
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) AS delete_referential_action_desc
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS update_referential_action
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) update_referential_action_desc
, CAST(1 AS sys.BIT) AS is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

CREATE OR replace view sys.identity_columns AS
SELECT 
  CAST(out_object_id AS INT) AS object_id
  , CAST(out_name AS SYSNAME) AS name
  , CAST(out_column_id AS INT) AS column_id
  , CAST(out_system_type_id AS TINYINT) AS system_type_id
  , CAST(out_user_type_id AS INT) AS user_type_id
  , CAST(out_max_length AS SMALLINT) AS max_length
  , CAST(out_precision AS TINYINT) AS precision
  , CAST(out_scale AS TINYINT) AS scale
  , CAST(out_collation_name AS SYSNAME) AS collation_name
  , CAST(out_is_nullable AS sys.BIT) AS is_nullable
  , CAST(out_is_ansi_padded AS sys.BIT) AS is_ansi_padded
  , CAST(out_is_rowguidcol AS sys.BIT) AS is_rowguidcol
  , CAST(out_is_identity AS sys.BIT) AS is_identity
  , CAST(out_is_computed AS sys.BIT) AS is_computed
  , CAST(out_is_filestream AS sys.BIT) AS is_filestream
  , CAST(out_is_replicated AS sys.BIT) AS is_replicated
  , CAST(out_is_non_sql_subscribed AS sys.BIT) AS is_non_sql_subscribed
  , CAST(out_is_merge_published AS sys.BIT) AS is_merge_published
  , CAST(out_is_dts_replicated AS sys.BIT) AS is_dts_replicated
  , CAST(out_is_xml_document AS sys.BIT) AS is_xml_document
  , CAST(out_xml_collection_id AS INT) AS xml_collection_id
  , CAST(out_default_object_id AS INT) AS default_object_id
  , CAST(out_rule_object_id AS INT) AS rule_object_id
  , CAST(out_is_sparse AS sys.BIT) AS is_sparse
  , CAST(out_is_column_set AS sys.BIT) AS is_column_set
  , CAST(out_generated_always_type AS TINYINT) AS generated_always_type
  , CAST(out_generated_always_type_desc AS NVARCHAR(60)) AS generated_always_type_desc
  , CAST(out_encryption_type AS INT) AS encryption_type
  , CAST(out_encryption_type_desc AS NVARCHAR(60)) AS encryption_type_desc
  , CAST(out_encryption_algorithm_name AS SYSNAME) AS encryption_algorithm_name
  , CAST(out_column_encryption_key_id AS INT) column_encryption_key_id
  , CAST(out_column_encryption_key_database_name AS SYSNAME) AS column_encryption_key_database_name
  , CAST(out_is_hidden AS sys.BIT) AS is_hidden
  , CAST(out_is_masked AS sys.BIT) AS is_masked
  , CAST(sys.ident_seed(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS seed_value
  , CAST(sys.ident_incr(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS increment_value
  , CAST(sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) AS SQL_VARIANT) AS last_value
  , CAST(0 as sys.BIT) as is_not_for_replication
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = cast(a.attname as sys.sysname) COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

create or replace view sys.indexes as
select
  CAST(object_id as int)
  , CAST(name as sys.sysname)
  , CAST(type as sys.tinyint)
  , CAST(type_desc as sys.nvarchar(60))
  , CAST(is_unique as sys.bit)
  , CAST(data_space_id as int)
  , CAST(ignore_dup_key as sys.bit)
  , CAST(is_primary_key as sys.bit)
  , CAST(is_unique_constraint as sys.bit)
  , CAST(fill_factor as sys.tinyint)
  , CAST(is_padded as sys.bit)
  , CAST(is_disabled as sys.bit)
  , CAST(is_hypothetical as sys.bit)
  , CAST(allow_row_locks as sys.bit)
  , CAST(allow_page_locks as sys.bit)
  , CAST(has_filter as sys.bit)
  , CAST(filter_definition as sys.nvarchar)
  , CAST(auto_created as sys.bit)
  , CAST(index_id as int)
from
(
  -- Get all indexes from all system and user tables
  select
    i.indrelid as object_id
    , c.relname as name
    , case when i.indisclustered then 1 else 2 end as type
    , case when i.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as type_desc
    , case when i.indisunique then 1 else 0 end as is_unique
    , c.reltablespace as data_space_id
    , 0 as ignore_dup_key
    , case when i.indisprimary then 1 else 0 end as is_primary_key
    , case when (SELECT count(constr.oid) FROM pg_constraint constr WHERE constr.conindid = c.oid and constr.contype = 'u') > 0 then 1 else 0 end as is_unique_constraint
    , 0 as fill_factor
    , case when i.indpred is null then 0 else 1 end as is_padded
    , case when i.indisready then 0 else 1 end as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , case when i.indisclustered then 1 else c.oid end as index_id
  from pg_class c
  inner join pg_index i on i.indexrelid = c.oid
  where c.relkind = 'i' and i.indislive
  and (c.relnamespace in (select schema_id from sys.schemas) or c.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(c.relnamespace, 'USAGE')

  union all

  -- Create HEAP entries for each system and user table
  select distinct on (t.oid)
    t.oid as object_id
    , null as name
    , 0 as type
    , 'HEAP' as type_desc
    , 0 as is_unique
    , 1 as data_space_id
    , 0 as ignore_dup_key
    , 0 as is_primary_key
    , 0 as is_unique_constraint
    , 0 as fill_factor
    , 0 as is_padded
    , 0 as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , 0 as index_id
  from pg_class t
  where t.relkind = 'r'
  and (t.relnamespace in (select schema_id from sys.schemas) or t.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(t.relnamespace, 'USAGE')
  and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

) as indexes_select order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

-- BABELFISH_FUNCTION_EXT
CREATE TABLE sys.babelfish_function_ext (
	nspname NAME NOT NULL,
	funcname NAME NOT NULL,
	orig_name sys.NVARCHAR(128), -- users' original input name
	funcsignature TEXT NOT NULL COLLATE "C",
	default_positions TEXT COLLATE "C",
	create_date SYS.DATETIME NOT NULL,
	modify_date SYS.DATETIME NOT NULL,
	PRIMARY KEY(nspname, funcsignature)
);
GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');


create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(0 as sys.bit) as is_identity
  , CAST(0 as sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;


CREATE OR replace view sys.key_constraints AS
SELECT
    CAST(c.conname AS SYSNAME) AS name
  , CAST(c.oid AS INT) AS object_id
  , CAST(0 AS INT) AS principal_id
  , CAST(sch.schema_id AS INT) AS schema_id
  , CAST(c.conrelid AS INT) AS parent_object_id
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PK'
      WHEN 'u' THEN 'UQ'
    END)
    AS CHAR(2)) AS type
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PRIMARY_KEY_CONSTRAINT'
      WHEN 'u' THEN 'UNIQUE_CONSTRAINT'
    END)
    AS NVARCHAR(60)) AS type_desc
  , CAST(NULL AS DATETIME) AS create_date
  , CAST(NULL AS DATETIME) AS modify_date
  , CAST(c.conindid AS INT) AS unique_index_id
  , CAST(0 AS sys.BIT) AS is_ms_shipped
  , CAST(0 AS sys.BIT) AS is_published
  , CAST(0 AS sys.BIT) AS is_schema_published
  , CAST(1 as sys.BIT) as is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype IN ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;


create or replace view sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.type::smallint as indid
  , null::binary(6) as root
  , 0::smallint as minlen
  , 1::smallint as keycnt
  , null::smallint as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0::bigint as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0::smallint as xmaxlen
  , null::smallint as maxirow
  , 90::sys.tinyint as "OrigFillFactor"
  , 0::sys.tinyint as "StatVersion"
  , 0 as reserved2
  , null::binary(6) as "FirstIAM"
  , 0::smallint as impid
  , 0::smallint as lockflags
  , 0 as pgmodctr
  , null::sys.varbinary(816) as keys
  , i.name::sys.sysname as name
  , null::sys.image as statblob
  , 0 as maxlen
  , 0 as rows
from sys.indexes i;

create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , a.state as status
  , null::bytea as sid
  , CAST(t.host_name AS sys.nchar(128)) as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , null::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database();
GRANT SELECT ON sys.sysprocesses TO PUBLIC;



-- re-creating objects to point to new tsql_type_max_length_helper

create or replace view sys.types As
-- For System types
select tsql_type_name COLLATE sys.database_default as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , cast(sys.tsql_type_precision_helper(tsql_type_name, t.typtypmod) as int) as precision
  , cast(sys.tsql_type_scale_helper(tsql_type_name, t.typtypmod, false) as int) as scale
  , CASE c.collname
    WHEN 'default' THEN cast(current_setting('babelfishpg_tsql.server_collation_name') as name)
    ELSE  c.collname COLLATE "C"
    END as collation_name
  , case when typnotnull then 0 else 1 end as is_nullable
  , 0 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , 0 as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
left join pg_collation c on c.oid = t.typcollation
, sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name
where tsql_type_name IS NOT NULL
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as text) COLLATE sys.database_default as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , null::integer as principal_id
  , case when is_tbl_type then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when is_tbl_type then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when is_tbl_type then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN cast(current_setting('babelfishpg_tsql.server_collation_name') as name)
    ELSE  c.collname 
    END as collation_name
  , case when is_tbl_type then 0
         else case when typnotnull then 0 else 1 end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , 1 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , case when is_tbl_type then 1 else 0 end as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
join sys.schemas sch on t.typnamespace = sch.schema_id
left join pg_collation c on c.oid = t.typcollation
, sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
, sys.is_table_type(t.typrelid) as is_tbl_type
-- we want to show details of user defined datatypes created under babelfish database
where tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    sys.is_table_type(t.typrelid)
  );
GRANT SELECT ON sys.types TO PUBLIC;

create or replace view sys.table_types as
select st.*
  , pt.typrelid::int as type_table_object_id
  , 0::sys.bit as is_memory_optimized -- return 0 until we support in-memory tables
from sys.types st
inner join pg_catalog.pg_type pt on st.user_type_id = pt.oid
where is_table_type = 1;

ALTER VIEW sys.default_constraints RENAME TO default_constraints_deprecated_in_2_3_0;
ALTER VIEW sys.check_constraints RENAME TO check_constraints_deprecated_in_2_3_0;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name collate "C" || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as char(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_expr returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(pg_get_expr(d.adbin, d.adrelid), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as char(2)) as type
  , CAST('CHECK_CONSTRAINT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.bit) as is_disabled
  , CAST(0 as sys.bit) as is_not_for_replication
  , CAST(0 as sys.bit) as is_not_trusted
  , CAST(c.conkey[1] as integer) AS parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_constraintdef returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(substring(pg_get_constraintdef(c.oid) from 7), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on cast(t.schema_name as sys.sysname) = cast(ns.nspname as sys.sysname)

union all

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name=b.orig_name COLLATE sys.database_default
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname COLLATE sys.database_default;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

create or replace view sys.all_objects as
select
    cast (name as sys.sysname)
  , cast (object_id as integer)
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , cast (type as char(2))
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , cast (case when (schema_id::regnamespace::text = 'sys' collate sys.database_default) then 1
          when name in (select name from sys.shipped_objects_not_in_sys nis
                        where nis.name = name collate sys.database_default and nis.schemaid = schema_id and nis.type = type collate sys.database_default) then 1
          else 0 end as sys.bit) as is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- details of user defined and system tables
select
    t.relname collate sys.database_default as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U' as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    t.relname collate sys.database_default as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    c.conname collate sys.database_default as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F' as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'f'
union all
-- details of user defined and system primary key constraints
select
    c.conname collate sys.database_default as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK' as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'p'
union all
-- details of user defined and system defined procedures
select
    p.proname collate sys.database_default as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null
           then tr.tgrelid
           else 0 end as int)
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'::varchar(2)
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'::varchar(60)
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
union all
-- details of all default constraints
select
    ('DF_' || o.relname collate sys.database_default || '_' || d.oid)::name collate sys.database_default as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
where a.atthasdef = 't' and a.attgenerated = ''
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::name collate sys.database_default
  , c.oid::integer as object_id
  , NULL::integer as principal_id
  , c.connamespace::integer as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'c' and c.conrelid != 0
union all
-- details of user defined and system defined sequence objects
select
  p.relname collate sys.database_default as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where p.relkind = 'S'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
union all
-- details of user defined table types
select
    ('TT_' || tt.name collate sys.database_default || '_' || tt.type_table_object_id)::name collate sys.database_default as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::varchar(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace view sys.system_objects as
select * from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname = 'sys';
GRANT SELECT ON sys.system_objects TO PUBLIC;

create or replace view sys.all_views as
select
    CAST(t.name as sys.SYSNAME) AS name
  , CAST(t.object_id as int) AS object_id
  , CAST(t.principal_id as int) AS principal_id
  , CAST(t.schema_id as int) AS schema_id
  , CAST(t.parent_object_id as int) AS parent_object_id
  , CAST(t.type as sys.bpchar(2)) AS type
  , CAST(t.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(t.create_date as sys.datetime) AS create_date
  , CAST(t.modify_date as sys.datetime) AS modify_date
  , CAST(t.is_ms_shipped as sys.BIT) AS is_ms_shipped
  , CAST(t.is_published as sys.BIT) AS is_published
  , CAST(t.is_schema_published as sys.BIT) AS is_schema_published
  , CAST(0 as sys.BIT) AS is_replicated
  , CAST(0 as sys.BIT) AS has_replication_filter
  , CAST(0 as sys.BIT) AS has_opaque_metadata
  , CAST(0 as sys.BIT) AS has_unchecked_assembly_data
  , CAST(
      CASE
        WHEN (v.check_option = 'NONE' COLLATE sys.database_default)
          THEN 0
        ELSE 1
      END
    AS sys.BIT) AS with_check_option
  , CAST(0 as sys.BIT) AS is_date_correlation_view
from sys.all_objects t
INNER JOIN pg_namespace ns ON t.schema_id = ns.oid
INNER JOIN information_schema.views v ON t.name = cast(v.table_name as sys.sysname) AND ns.nspname = v.table_schema
where t.type = 'V';
GRANT SELECT ON sys.all_views TO PUBLIC;

create or replace view sys.objects as
select
      CAST(t.name as sys.sysname) as name 
    , CAST(t.object_id as int) as object_id
    , CAST(t.principal_id as int) as principal_id
    , CAST(t.schema_id as int) as schema_id
    , CAST(t.parent_object_id as int) as parent_object_id
    , CAST('U' as char(2)) as type
    , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
    , CAST(t.create_date as sys.datetime) as create_date
    , CAST(t.modify_date as sys.datetime) as modify_date
    , CAST(t.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(t.is_published as sys.bit) as is_published
    , CAST(t.is_schema_published as sys.bit) as is_schema_published
from  sys.tables t
union all
select
      CAST(v.name as sys.sysname) as name
    , CAST(v.object_id as int) as object_id
    , CAST(v.principal_id as int) as principal_id
    , CAST(v.schema_id as int) as schema_id
    , CAST(v.parent_object_id as int) as parent_object_id
    , CAST('V' as char(2)) as type
    , CAST('VIEW' as sys.nvarchar(60)) as type_desc
    , CAST(v.create_date as sys.datetime) as create_date
    , CAST(v.modify_date as sys.datetime) as modify_date
    , CAST(v.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(v.is_published as sys.bit) as is_published
    , CAST(v.is_schema_published as sys.bit) as is_schema_published
from  sys.views v
union all
select
      CAST(f.name as sys.sysname) as name
    , CAST(f.object_id as int) as object_id
    , CAST(f.principal_id as int) as principal_id
    , CAST(f.schema_id as int) as schema_id
    , CAST(f.parent_object_id as int) as parent_object_id
    , CAST('F' as char(2)) as type
    , CAST('FOREIGN_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(f.create_date as sys.datetime) as create_date
    , CAST(f.modify_date as sys.datetime) as modify_date
    , CAST(f.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(f.is_published as sys.bit) as is_published
    , CAST(f.is_schema_published as sys.bit) as is_schema_published
 from sys.foreign_keys f
union all
select
      CAST(p.name as sys.sysname) as name
    , CAST(p.object_id as int) as object_id
    , CAST(p.principal_id as int) as principal_id
    , CAST(p.schema_id as int) as schema_id
    , CAST(p.parent_object_id as int) as parent_object_id
    , CAST('PK' as char(2)) as type
    , CAST('PRIMARY_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
where p.type = 'PK'
union all
select
      CAST(pr.name as sys.sysname) as name
    , CAST(pr.object_id as int) as object_id
    , CAST(pr.principal_id as int) as principal_id
    , CAST(pr.schema_id as int) as schema_id
    , CAST(pr.parent_object_id as int) as parent_object_id
    , CAST(pr.type as char(2)) as type
    , CAST(pr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(pr.create_date as sys.datetime) as create_date
    , CAST(pr.modify_date as sys.datetime) as modify_date
    , CAST(pr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(pr.is_published as sys.bit) as is_published
    , CAST(pr.is_schema_published as sys.bit) as is_schema_published
 from sys.procedures pr
union all
select
      CAST(tr.name as sys.sysname) as name
    , CAST(tr.object_id as int) as object_id
    , CAST(NULL as int) as principal_id
    , CAST(p.pronamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_proc p on p.oid = tr.object_id
union all 
select
    CAST(def.name as sys.sysname) as name
  , CAST(def.object_id as int) as object_id
  , CAST(def.principal_id as int) as principal_id
  , CAST(def.schema_id as int) as schema_id
  , CAST(def.parent_object_id as int) as parent_object_id
  , CAST(def.type as char(2)) as type
  , CAST(def.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(def.create_date as sys.datetime) as create_date
  , CAST(def.modified_date as sys.datetime) as modify_date
  , CAST(def.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(def.is_published as sys.bit) as is_published
  , CAST(def.is_schema_published as sys.bit) as is_schema_published
  from sys.default_constraints def
union all
select
    CAST(chk.name as sys.sysname) as name
  , CAST(chk.object_id as int) as object_id
  , CAST(chk.principal_id as int) as principal_id
  , CAST(chk.schema_id as int) as schema_id
  , CAST(chk.parent_object_id as int) as parent_object_id
  , CAST(chk.type as char(2)) as type
  , CAST(chk.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(chk.create_date as sys.datetime) as create_date
  , CAST(chk.modify_date as sys.datetime) as modify_date
  , CAST(chk.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(chk.is_published as sys.bit) as is_published
  , CAST(chk.is_schema_published as sys.bit) as is_schema_published
  from sys.check_constraints chk
union all
select
    CAST(p.relname as sys.sysname) as name
  , CAST(p.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(s.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('SO' as char(2)) as type
  , CAST('SEQUENCE_OBJECT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
and has_schema_privilege(s.schema_id, 'USAGE')
union all
select
    CAST(('TT_' || tt.name COLLATE "C" || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt
inner join pg_class c on tt.type_table_object_id = c.oid;
GRANT SELECT ON sys.objects TO PUBLIC;

create or replace view sys.sysobjects as
select
  CAST(s.name as sys._ci_sysname)
  , CAST(s.object_id as int) as id
  , CAST(s.type as sys.bpchar(2)) as xtype

  -- 'uid' is specified as type INT here, and not SMALLINT per SQL Server documentation.
  -- This is because if you routinely drop and recreate databases, it is possible for the
  -- dbo schema which relies on pg_catalog oid values to exceed the size of a smallint.
  , CAST(s.schema_id as int) as uid
  , CAST(0 as smallint) as info
  , CAST(0 as int) as status
  , CAST(0 as int) as base_schema_ver
  , CAST(0 as int) as replinfo
  , CAST(s.parent_object_id as int) as parent_obj
  , CAST(s.create_date as sys.datetime) as crdate
  , CAST(0 as smallint) as ftcatid
  , CAST(0 as int) as schema_ver
  , CAST(0 as int) as stats_schema_ver
  , CAST(s.type as sys.bpchar(2)) as type
  , CAST(0 as smallint) as userstat
  , CAST(0 as smallint) as sysstat
  , CAST(0 as smallint) as indexdel
  , CAST(s.modify_date as sys.datetime) as refdate
  , CAST(0 as int) as version
  , CAST(0 as int) as deltrig
  , CAST(0 as int) as instrig
  , CAST(0 as int) as updtrig
  , CAST(0 as int) as seltrig
  , CAST(0 as int) as category
  , CAST(0 as smallint) as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF') THEN tsql_get_functiondef(ao.object_id)
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      WHEN ao.type = 'TR' THEN NULL
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition  -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF') THEN
        CASE WHEN p.proisstrict THEN 1
        ELSE 0 
        END
      ELSE 0
      END
    AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nmext.nspname = ext.nspname
LEFT OUTER JOIN sys.babelfish_view_def bvd 
 on (
      ext.orig_name = bvd.schema_name AND 
      ext.dbid = bvd.dbid AND
      ao.name = bvd.object_name 
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1;
GRANT SELECT ON sys.all_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.system_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 1;

CREATE OR REPLACE VIEW sys.sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 0;
GRANT SELECT ON sys.sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscharsets
AS
SELECT 1001 as type,
  1 as id,
  0 as csid,
  0 as status,
  NULL::nvarchar(128) as name,
  NULL::nvarchar(255) as description ,
  NULL::varbinary(6000) binarydefinition ,
  NULL::image definition;
GRANT SELECT ON sys.syscharsets TO PUBLIC;

CREATE OR REPLACE VIEW sys.computed_columns
AS
SELECT out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
  , substring(pg_get_expr(d.adbin, d.adrelid), 1, 4000)::sys.nvarchar(4000) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;


CREATE OR REPLACE VIEW sys.endpoints
AS
SELECT CAST('TSQL Default TCP' AS sys.sysname) AS name
 , CAST(4 AS int) AS endpoint_id
 , CAST(1 AS int) AS principal_id
 , CAST(2 AS sys.tinyint) AS protocol
 , CAST('TCP' AS sys.nvarchar(60)) AS protocol_desc
 , CAST(2 AS sys.tinyint) AS type
  , CAST('TSQL' AS sys.nvarchar(60)) AS type_desc
  , CAST(0 AS tinyint) AS state
  , CAST('STARTED' AS sys.nvarchar(60)) AS state_desc
  , CAST(0 AS sys.bit) AS is_admin_endpoint;
GRANT SELECT ON sys.endpoints TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscolumns AS
SELECT out_name as name
  , out_object_id as id
  , out_system_type_id as xtype
  , 0::sys.tinyint as typestat
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as xusertype
  , out_max_length as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , out_column_id::smallint as colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , out_default_object_id::int as cdefault
  , out_rule_object_id::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , out_offset as offset
  , out_collation_id as collationid
  , (case out_is_nullable::int when 1 then 8 else 0 end +
     case out_is_identity::int when 1 then 128 else 0 end)::sys.tinyint as status
  , out_system_type_id as type
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal()
union all
SELECT p.name
  , p.id
  , p.xtype
  , 0::sys.tinyint as typestat
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as xusertype
  , null as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , p.colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , null::int as cdefault
  , null::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , 0::smallint as offset
  , collationid
  , (case p.isoutparam when 1 then 64 else 0 end)::sys.tinyint as status
  , p.xtype as type
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , p.prec
  , p.scale
  , 0::int as iscomputed
  , p.isoutparam
  , 1::int as isnullable
  , p.collation
FROM sys.proc_param_helper() as p;
GRANT SELECT ON sys.syscolumns TO PUBLIC;

create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , d.host_name::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , null::sys.nvarchar(128) as context_info
    , null::integer as cpu_time
    , null::integer as memory_usage
    , null::integer as total_scheduled_time
    , null::integer as total_elapsed_time
    , a.client_port as endpoint_id
    , a.query_start::sys.datetime as last_request_start_time
    , a.state_change::sys.datetime as last_request_end_time
    , null::bigint as "reads"
    , null::bigint as "writes"
    , null::bigint as logical_reads
    , case when a.client_port > 0 then 1::sys.bit else 0::sys.bit end as is_user_process
    , d.textsize as text_size
    , d.language::sys.nvarchar(128) as language
    , 'ymd'::sys.nvarchar(3) as date_format-- Bld 173 lacks support for SET DATEFORMAT and always expects ymd
    , d.datefirst::smallint as date_first -- Bld 173 lacks support for SET DATEFIRST and always returns 7
    , CAST(CAST(d.quoted_identifier as integer) as sys.bit) as quoted_identifier
    , CAST(CAST(d.arithabort as integer) as sys.bit) as arithabort
    , CAST(CAST(d.ansi_null_dflt_on as integer) as sys.bit) as ansi_null_dflt_on
    , CAST(CAST(d.ansi_defaults as integer) as sys.bit) as ansi_defaults
    , CAST(CAST(d.ansi_warnings as integer) as sys.bit) as ansi_warnings
    , CAST(CAST(d.ansi_padding as integer) as sys.bit) as ansi_padding
    , CAST(CAST(d.ansi_nulls as integer) as sys.bit) as ansi_nulls
    , CAST(CAST(d.concat_null_yields_null as integer) as sys.bit) as concat_null_yields_null
    , d.transaction_isolation::smallint as transaction_isolation_level
    , d.lock_timeout as lock_timeout
    , 0 as deadlock_priority
    , d.row_count as row_count
    , d.error as prev_error
    , null::sys.varbinary(85) as original_security_id
    , a.usename::sys.nvarchar(128) as original_login_name
    , null::sys.datetime as last_successful_logon
    , null::sys.datetime as last_unsuccessful_logon
    , null::bigint as unsuccessful_logons
    , null::int as group_id
    , d.database_id::smallint as database_id
    , 0 as authenticating_database_id
    , d.trancount as open_transaction_count
  from pg_catalog.pg_stat_activity AS a
  RIGHT JOIN sys.tsql_stat_get_activity('sessions') AS d ON (a.pid = d.procid);
  GRANT SELECT ON sys.dm_exec_sessions TO PUBLIC;

create or replace view sys.dm_exec_connections
 as
 select a.pid as session_id
   , a.pid as most_recent_session_id
   , a.backend_start::sys.datetime as connect_time
   , 'TCP'::sys.nvarchar(40) as net_transport
   , 'TSQL'::sys.nvarchar(40) as protocol_type
   , d.protocol_version as protocol_version
   , 4 as endpoint_id
   , d.encrypyt_option::sys.nvarchar(40) as encrypt_option
   , null::sys.nvarchar(40) as auth_scheme
   , null::smallint as node_affinity
   , null::int as num_reads
   , null::int as num_writes
   , null::sys.datetime as last_read
   , null::sys.datetime as last_write
   , d.packet_size as net_packet_size
   , a.client_addr::varchar(48) as client_net_address
   , a.client_port as client_tcp_port
   , null::varchar(48) as local_net_address
   , null::int as local_tcp_port
   , null::sys.uniqueidentifier as connection_id
   , null::sys.uniqueidentifier as parent_connection_id
   , a.pid::sys.varbinary(64) as most_recent_sql_handle
 from pg_catalog.pg_stat_activity AS a
 RIGHT JOIN sys.tsql_stat_get_activity('connections') AS d ON (a.pid = d.procid);
GRANT SELECT ON sys.dm_exec_connections TO PUBLIC;

CREATE OR REPLACE VIEW sys.configurations
AS
SELECT configuration_id,
        name,
        value,
        minimum,
        maximum,
        value_in_use,
        description,
        is_dynamic,
        is_advanced
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.configurations TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscurconfigs
AS
SELECT value,
        configuration_id AS config,
        comment_syscurconfigs AS comment,
        CASE
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 0 THEN CAST(0 as smallint)
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 1 THEN CAST(1 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 0 THEN CAST(2 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 1 THEN CAST(3 as smallint)
        END AS status
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.syscurconfigs TO PUBLIC;

CREATE OR REPLACE VIEW sys.data_spaces
AS
SELECT
  CAST('PRIMARY' as SYSNAME) AS name,
  CAST(1 as INT) AS data_space_id,
  CAST('FG' as CHAR(2)) AS type,
  CAST('ROWS_FILEGROUP' as NVARCHAR(60)) AS type_desc,
  CAST(1 as sys.BIT) AS is_default,
  CAST(0 as sys.BIT) AS is_system;
GRANT SELECT ON sys.data_spaces TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_mirroring
AS
SELECT
      CAST(database_id AS int) AS database_id,
      CAST(NULL AS sys.uniqueidentifier) AS mirroring_guid,
      CAST(NULL AS sys.tinyint) AS mirroring_state,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_state_desc,
      CAST(NULL AS sys.tinyint) AS mirroring_role,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_role_desc,
      CAST(NULL AS int) AS mirroring_role_sequence,
      CAST(NULL AS sys.tinyint) as mirroring_safety_level,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_safety_level_desc,
      CAST(NULL AS int) as mirroring_safety_sequence,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_name,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_instance,
      CAST(NULL AS sys.nvarchar(128)) AS mirroring_witness_name,
      CAST(NULL AS sys.tinyint) AS mirroring_witness_state,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_witness_state_desc,
      CAST(NULL AS numeric(25,0)) AS mirroring_failover_lsn,
      CAST(NULL AS int) AS mirroring_connection_timeout,
      CAST(NULL AS int) AS mirroring_redo_queue,
      CAST(NULL AS sys.nvarchar(60)) AS mirroring_redo_queue_type,
      CAST(NULL AS numeric(25,0)) AS mirroring_end_of_log_lsn,
      CAST(NULL AS numeric(25,0)) AS mirroring_replication_lsn
FROM sys.databases;
GRANT SELECT ON sys.database_mirroring TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_schema_collections
AS
SELECT
  CAST(NULL AS INT) as xml_collection_id,
  CAST(NULL AS INT) as schema_id,
  CAST(NULL AS INT) as principal_id,
  CAST('sys' AS sys.sysname) as name,
  CAST(NULL as sys.datetime) as create_date,
  CAST(NULL as sys.datetime) as modify_date
WHERE FALSE;
GRANT SELECT ON sys.xml_schema_collections TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_database_replica_states
AS
SELECT
   CAST(0 as INT) database_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as replica_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_database_id
  ,CAST(0 as sys.BIT) as is_local
  ,CAST(0 as sys.BIT) as is_primary_replica
  ,CAST(0 as sys.TINYINT) as synchronization_state
  ,CAST('' as sys.nvarchar(60)) as synchronization_state_desc
  ,CAST(0 as sys.BIT) as is_commit_participant
  ,CAST(0 as sys.TINYINT) as synchronization_health
  ,CAST('' as sys.nvarchar(60)) as synchronization_health_desc
  ,CAST(0 as sys.TINYINT) as database_state
  ,CAST('' as sys.nvarchar(60)) as database_state_desc
  ,CAST(0 as sys.BIT) as is_suspended
  ,CAST(0 as sys.TINYINT) as suspend_reason
  ,CAST('' as sys.nvarchar(60)) as suspend_reason_desc
  ,CAST(0.0 as numeric(25,0)) as truncation_lsn
  ,CAST(0.0 as numeric(25,0)) as recovery_lsn
  ,CAST(0.0 as numeric(25,0)) as last_sent_lsn
  ,CAST(NULL as sys.DATETIME) as last_sent_time
  ,CAST(0.0 as numeric(25,0)) as last_received_lsn
  ,CAST(NULL as sys.DATETIME) as last_received_time
  ,CAST(0.0 as numeric(25,0)) as last_hardened_lsn
  ,CAST(NULL as sys.DATETIME) as last_hardened_time
  ,CAST(0.0 as numeric(25,0)) as last_redone_lsn
  ,CAST(NULL as sys.DATETIME) as last_redone_time
  ,CAST(0 as sys.BIGINT) as log_send_queue_size
  ,CAST(0 as sys.BIGINT) as log_send_rate
  ,CAST(0 as sys.BIGINT) as redo_queue_size
  ,CAST(0 as sys.BIGINT) as redo_rate
  ,CAST(0 as sys.BIGINT) as filestream_send_rate
  ,CAST(0.0 as numeric(25,0)) as end_of_log_lsn
  ,CAST(0.0 as numeric(25,0)) as last_commit_lsn
  ,CAST(NULL as sys.DATETIME) as last_commit_time
  ,CAST(0 as sys.BIGINT) as low_water_mark_for_ghosts
  ,CAST(0 as sys.BIGINT) as secondary_lag_seconds
WHERE FALSE;
GRANT SELECT ON sys.dm_hadr_database_replica_states TO PUBLIC;

CREATE OR REPLACE VIEW sys.syslanguages
AS
SELECT
    lang_id AS langid,
    CAST(lower(lang_data_jsonb ->> 'date_format') AS SYS.NCHAR(3)) AS dateformat,
    CAST(lang_data_jsonb -> 'date_first' AS SYS.TINYINT) AS datefirst,
    CAST(NULL AS INT) AS upgrade,
    CAST(coalesce(lang_name_mssql, lang_name_pg) AS SYS.SYSNAME) AS name,
    CAST(coalesce(lang_alias_mssql, lang_alias_pg) AS SYS.SYSNAME) AS alias,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_names')), ',') AS SYS.NVARCHAR(372)) AS months,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_shortnames')),',') AS SYS.NVARCHAR(132)) AS shortmonths,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'days_shortnames')),',') AS SYS.NVARCHAR(217)) AS days,
    CAST(NULL AS INT) AS lcid,
    CAST(NULL AS SMALLINT) AS msglangid
FROM sys.babelfish_syslanguages;
GRANT SELECT ON sys.syslanguages TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_files
AS
SELECT
    CAST(1 as INT) AS file_id,
    CAST(NULL as sys.uniqueidentifier) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as sys.NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as sys.SYSNAME) AS name,
    CAST('' as sys.NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as sys.NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as sys.uniqueidentifier) AS differential_base_guid,
    CAST(NULL as sys.datetime) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn
WHERE false;
GRANT SELECT ON sys.database_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.hash_indexes
AS
SELECT
  si.object_id,
  si.name,
  si.index_id,
  si.type,
  si.type_desc,
  si.is_unique,
  si.data_space_id,
  si.ignore_dup_key,
  si.is_primary_key,
  si.is_unique_constraint,
  si.fill_factor,
  si.is_padded,
  si.is_disabled,
  si.is_hypothetical,
  si.allow_row_locks,
  si.allow_page_locks,
  si.has_filter,
  si.filter_definition,
  CAST(0 as INT) AS bucket_count,
  si.auto_created
FROM sys.indexes si
WHERE FALSE;
GRANT SELECT ON sys.hash_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetable_system_defined_objects
AS
SELECT
  CAST(0 as INT) AS object_id,
  CAST(0 as INT) AS parent_object_id
  WHERE FALSE;
GRANT SELECT ON sys.filetable_system_defined_objects TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_filestream_options
AS
SELECT
  CAST(0 as INT) AS database_id,
  CAST('' as NVARCHAR(255)) AS directory_name,
  CAST(0 as TINYINT) AS non_transacted_access,
  CAST('' as NVARCHAR(60)) AS non_transacted_access_desc
WHERE FALSE;
GRANT SELECT ON sys.database_filestream_options TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetables
AS
SELECT
   CAST(0 AS INT) AS object_id,
   CAST(0 AS sys.BIT) AS is_enabled,
   CAST('' AS sys.VARCHAR(255)) AS directory_name,
   CAST(0 AS INT) AS filename_collation_id,
   CAST('' AS sys.VARCHAR) AS filename_collation_name
   WHERE FALSE;
GRANT SELECT ON sys.filetables TO PUBLIC;

CREATE OR REPLACE VIEW sys.registered_search_property_lists
AS
SELECT
   CAST(0 AS INT) AS property_list_id,
   CAST('' AS SYSNAME) AS name,
   CAST(NULL AS DATETIME) AS create_date,
   CAST(NULL AS DATETIME) AS modify_date,
   CAST(0 AS INT) AS principal_id
WHERE FALSE;
GRANT SELECT ON sys.registered_search_property_lists TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_languages
AS
SELECT
   CAST(0 as INT) AS lcid,
   CAST('' as SYSNAME) AS name
WHERE FALSE;
GRANT SELECT ON sys.fulltext_languages TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_index_columns
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS column_id,
   CAST(0 as INT) AS type_column_id,
   CAST(0 as INT) AS language_id,
   CAST(0 as INT) AS statistical_semantics
WHERE FALSE;
GRANT SELECT ON sys.fulltext_index_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.selective_xml_index_paths
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS index_id,
   CAST(0 as INT) AS path_id,
   CAST('' as NVARCHAR(4000)) AS path,
   CAST('' as SYSNAME) AS name,
   CAST(0 as TINYINT) AS path_type,
   CAST(0 as SYSNAME) AS path_type_desc,
   CAST(0 as INT) AS xml_component_id,
   CAST('' as NVARCHAR(4000)) AS xquery_type_description,
   CAST(0 as sys.BIT) AS is_xquery_type_inferred,
   CAST(0 as SMALLINT) AS xquery_max_length,
   CAST(0 as sys.BIT) AS is_xquery_max_length_inferred,
   CAST(0 as sys.BIT) AS is_node,
   CAST(0 as TINYINT) AS system_type_id,
   CAST(0 as TINYINT) AS user_type_id,
   CAST(0 as SMALLINT) AS max_length,
   CAST(0 as TINYINT) AS precision,
   CAST(0 as TINYINT) AS scale,
   CAST('' as SYSNAME) AS collation_name,
   CAST(0 as sys.BIT) AS is_singleton
WHERE FALSE;
GRANT SELECT ON sys.selective_xml_index_paths TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_indexes
AS
SELECT
   object_id,
   name,
   index_id,
   type,
   type_desc,
   is_unique,
   data_space_id,
   ignore_dup_key,
   is_primary_key,
   is_unique_constraint,
   fill_factor,
   is_padded,
   is_disabled,
   is_hypothetical,
   allow_row_locks,
   allow_page_locks,
   CAST(1 as TINYINT) AS spatial_index_type,
   CAST('' as NVARCHAR(60)) AS spatial_index_type_desc,
   CAST('' as SYSNAME) AS tessellation_scheme,
   has_filter,
   filter_definition,
   auto_created
FROM sys.indexes WHERE FALSE;
GRANT SELECT ON sys.spatial_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_catalogs
AS
SELECT
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST('' as SYSNAME) AS name,
   CAST('' as NVARCHAR(260)) AS path,
   CAST(0 as sys.BIT) AS is_default,
   CAST(0 as sys.BIT) AS is_accent_sensitivity_on,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS file_id,
   CAST(0 as INT) AS principal_id,
   CAST(2 as sys.BIT) AS is_importing
WHERE FALSE;
GRANT SELECT ON sys.fulltext_catalogs TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_stoplists
AS
SELECT
   CAST(0 as INT) AS stoplist_id,
   CAST('' as SYSNAME) AS name,
   CAST(NULL as DATETIME) AS create_date,
   CAST(NULL as DATETIME) AS modify_date,
   CAST(0 as INT) AS Principal_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_stoplists TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_indexes
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS unique_index_id,
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST(0 as sys.BIT) AS is_enabled,
   CAST('O' as sys.BPCHAR(1)) AS change_tracking_state,
   CAST('' as sys.NVARCHAR(60)) AS change_tracking_state_desc,
   CAST(0 as sys.BIT) AS has_crawl_completed,
   CAST('' as sys.BPCHAR(1)) AS crawl_type,
   CAST('' as sys.NVARCHAR(60)) AS crawl_type_desc,
   CAST(NULL as sys.DATETIME) AS crawl_start_date,
   CAST(NULL as sys.DATETIME) AS crawl_end_date,
   CAST(NULL as BINARY(8)) AS incremental_timestamp,
   CAST(0 as INT) AS stoplist_id,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS property_list_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.assembly_modules
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS assembly_id,
   CAST('' AS SYSNAME) AS assembly_class,
   CAST('' AS SYSNAME) AS assembly_method,
   CAST(0 AS sys.BIT) AS null_on_null_input,
   CAST(0 as INT) AS execute_as_principal_id
   WHERE FALSE;
GRANT SELECT ON sys.assembly_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.change_tracking_databases
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(0 as sys.BIT) AS is_auto_cleanup_on,
   CAST(0 as INT) AS retention_period,
   CAST('' as NVARCHAR(60)) AS retention_period_units_desc,
   CAST(0 as TINYINT) AS retention_period_units
WHERE FALSE;
GRANT SELECT ON sys.change_tracking_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.filegroups
AS
SELECT
   CAST(ds.name AS sys.SYSNAME),
   CAST(ds.data_space_id AS INT),
   CAST(ds.type AS sys.BPCHAR(2)),
   CAST(ds.type_desc AS sys.NVARCHAR(60)),
   CAST(ds.is_default AS sys.BIT),
   CAST(ds.is_system AS sys.BIT),
   CAST(NULL as sys.UNIQUEIDENTIFIER) AS filegroup_guid,
   CAST(0 as INT) AS log_filegroup_id,
   CAST(0 as sys.BIT) AS is_read_only,
   CAST(0 as sys.BIT) AS is_autogrow_all_files
FROM sys.data_spaces ds WHERE type = 'FG';
GRANT SELECT ON sys.filegroups TO PUBLIC;

CREATE OR REPLACE VIEW sys.master_files
AS
SELECT
    CAST(0 as INT) AS database_id,
    CAST(0 as INT) AS file_id,
    CAST(NULL as UNIQUEIDENTIFIER) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as SYSNAME) AS name,
    CAST('' as NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS differential_base_guid,
    CAST(NULL as DATETIME) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn,
    CAST(0 as INT) AS credential_id
WHERE FALSE;
GRANT SELECT ON sys.master_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.stats
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST('' as SYSNAME) AS name,
   CAST(0 as INT) AS stats_id,
   CAST(0 as sys.BIT) AS auto_created,
   CAST(0 as sys.BIT) AS user_created,
   CAST(0 as sys.BIT) AS no_recompute,
   CAST(0 as sys.BIT) AS has_filter,
   CAST('' as sys.NVARCHAR(4000)) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT) AS index_id
  , CAST(idx.type AS sys.tinyint) AS type
  , CAST(idx.type_desc AS sys.nvarchar(60)) AS type_desc
  , CAST(idx.is_unique AS sys.bit) AS is_unique
  , CAST(idx.data_space_id AS int) AS data_space_id
  , CAST(idx.ignore_dup_key AS sys.bit) AS ignore_dup_key
  , CAST(idx.is_primary_key AS sys.bit) AS is_primary_key
  , CAST(idx.is_unique_constraint AS sys.bit) AS is_unique_constraint
  , CAST(idx.fill_factor AS sys.tinyint) AS fill_factor
  , CAST(idx.is_padded AS sys.bit) AS is_padded
  , CAST(idx.is_disabled AS sys.bit) AS is_disabled
  , CAST(idx.is_hypothetical AS sys.bit) AS is_hypothetical
  , CAST(idx.allow_row_locks AS sys.bit) AS allow_row_locks
  , CAST(idx.allow_page_locks AS sys.bit) AS allow_page_locks
  , CAST(idx.has_filter AS sys.bit) AS has_filter
  , CAST(idx.filter_definition AS sys.nvarchar(4000)) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS char(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_cluster
AS
SELECT
   CAST('' as sys.nvarchar(128)) as cluster_name
  ,CAST(0 as sys.tinyint) as quorum_type
  ,CAST('NODE_MAJORITY' as sys.nvarchar(50)) as quorum_type_desc
  ,CAST(0 as sys.tinyint) as quorum_state
  ,CAST('NORMAL_QUORUM' as sys.nvarchar(50)) as quorum_state_desc;
GRANT SELECT ON sys.dm_hadr_cluster TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_index_tessellations
AS
SELECT
    CAST(0 as int) AS object_id
  , CAST(0 as int) AS index_id
  , CAST('' as sys.sysname) AS tessellation_scheme
  , CAST(0 as float(53)) AS bounding_box_xmin
  , CAST(0 as float(53)) AS bounding_box_ymin
  , CAST(0 as float(53)) AS bounding_box_xmax
  , CAST(0 as float(53)) AS bounding_box_ymax
  , CAST(0 as smallint) as level_1_grid
  , CAST('' as sys.nvarchar(60)) AS level_1_grid_desc
  , CAST(0 as smallint) as level_2_grid
  , CAST('' as sys.nvarchar(60)) AS level_2_grid_desc
  , CAST(0 as smallint) as level_3_grid
  , CAST('' as sys.nvarchar(60)) AS level_3_grid_desc
  , CAST(0 as smallint) as level_4_grid
  , CAST('' as sys.nvarchar(60)) AS level_4_grid_desc
  , CAST(0 as int) as cells_per_object
WHERE FALSE;
GRANT SELECT ON sys.spatial_index_tessellations TO PUBLIC;

CREATE OR REPLACE VIEW sys.synonyms
AS
SELECT
    CAST(obj.name as sys.sysname) AS name
  , CAST(obj.object_id as int) AS object_id
  , CAST(obj.principal_id as int) AS principal_id
  , CAST(obj.schema_id as int) AS schema_id
  , CAST(obj.parent_object_id as int) AS parent_object_id
  , CAST(obj.type as sys.bpchar(2)) AS type
  , CAST(obj.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(obj.create_date as sys.datetime) as create_date
  , CAST(obj.modify_date as sys.datetime) as modify_date
  , CAST(obj.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(obj.is_published as sys.bit) as is_published
  , CAST(obj.is_schema_published as sys.bit) as is_schema_published
  , CAST('' as sys.nvarchar(1035)) AS base_object_name
FROM sys.objects obj
WHERE type='SN';
GRANT SELECT ON sys.synonyms TO PUBLIC;

CREATE OR REPLACE VIEW sys.plan_guides
AS
SELECT
    CAST(0 as int) AS plan_guide_id
  , CAST('' as sys.sysname) AS name
  , CAST(NULL as sys.datetime) as create_date
  , CAST(NULL as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_disabled
  , CAST('' as sys.nvarchar(4000)) AS query_text
  , CAST(0 as sys.tinyint) AS scope_type
  , CAST('' as sys.nvarchar(60)) AS scope_type_desc
  , CAST(0 as int) AS scope_type_id
  , CAST('' as sys.nvarchar(4000)) AS scope_batch
  , CAST('' as sys.nvarchar(4000)) AS parameters
  , CAST('' as sys.nvarchar(4000)) AS hints
WHERE FALSE;
GRANT SELECT ON sys.plan_guides TO PUBLIC;

CREATE OR REPLACE VIEW sys.numbered_procedures
AS
SELECT
    CAST(0 as int) AS object_id
  , CAST(0 as smallint) AS procedure_number
  , CAST('' as sys.nvarchar(4000)) AS definition
WHERE FALSE; -- This condition will ensure that the view is empty

CREATE OR REPLACE VIEW sys.events
AS
SELECT
  CAST(pt.tgfoid as int) AS object_id
  , CAST(
      CASE
        WHEN tr.event_manipulation='INSERT' COLLATE sys.database_default THEN 1
        WHEN tr.event_manipulation='UPDATE' COLLATE sys.database_default THEN 2
        WHEN tr.event_manipulation='DELETE' COLLATE sys.database_default THEN 3
        ELSE 1
      END as int
  ) AS type
  , CAST(tr.event_manipulation as sys.nvarchar(60)) AS type_desc
  , CAST(1 as sys.bit) AS is_trigger_event
  , CAST(null as int) AS event_group_type
  , CAST(null as sys.nvarchar(60)) AS event_group_type_desc
FROM information_schema.triggers tr
JOIN pg_catalog.pg_namespace np ON tr.event_object_schema = np.nspname COLLATE sys.database_default
JOIN pg_class pc ON pc.relname = tr.event_object_table COLLATE sys.database_default AND pc.relnamespace = np.oid
JOIN pg_trigger pt ON pt.tgrelid = pc.oid AND tr.trigger_name = pt.tgname COLLATE sys.database_default
AND has_schema_privilege(pc.relnamespace, 'USAGE')
AND has_table_privilege(pc.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.events TO PUBLIC;

CREATE OR REPLACE VIEW sys.trigger_events
AS
SELECT
  CAST(e.object_id as int) AS object_id,
  CAST(e.type as int) AS type,
  CAST(e.type_desc as sys.nvarchar(60)) AS type_desc,
  CAST(0 as sys.bit) AS is_first,
  CAST(0 as sys.bit) AS is_last,
  CAST(null as int) AS event_group_type,
  CAST(null as sys.nvarchar(60)) AS event_group_type_desc,
  CAST(e.is_trigger_event as sys.bit) AS is_trigger_event
FROM sys.events e
WHERE e.is_trigger_event = 1;
GRANT SELECT ON sys.trigger_events TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.columns AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
   CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
   CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
   CAST(a.attnum AS int) AS "ORDINAL_POSITION",
   CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin collate "C", ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
   CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
    AS varchar(3))
    AS "IS_NULLABLE",

   CAST(
    CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
    ELSE tsql_type_name END
    AS sys.nvarchar(128))
    AS "DATA_TYPE",

   CAST(
    information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
    AS int)
    AS "CHARACTER_MAXIMUM_LENGTH",

   CAST(
    information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
    AS int)
    AS "CHARACTER_OCTET_LENGTH",

   CAST(

    information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
    AS sys.tinyint)
    AS "NUMERIC_PRECISION",

   CAST(
    information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
    AS smallint)
    AS "NUMERIC_PRECISION_RADIX",

   CAST(
    information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
    AS int)
    AS "NUMERIC_SCALE",

   CAST(
    information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
    AS smallint)
    AS "DATETIME_PRECISION",

   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",




   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

   CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
   CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",


   CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN nc.dbname collate "C" ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN ext.orig_name ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN t.typname ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_NAME"

 FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
  JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
  JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
  LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
   ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
  LEFT JOIN pg_collation co on co.oid = a.attcollation
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
  information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
  information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
  sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

 WHERE (NOT pg_is_other_temp_schema(nc.oid))
  AND a.attnum > 0 AND NOT a.attisdropped
  AND c.relkind IN ('r', 'v', 'p')
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_column_privilege(c.oid, a.attnum,
         'SELECT, INSERT, UPDATE, REFERENCES'))
  AND ext.dbid = cast(sys.db_id() as oid);

CREATE OR REPLACE VIEW information_schema_tsql.domains AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
  CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
  CAST(t.typname AS sys.sysname) AS "DOMAIN_NAME",
  CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",

  CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
   AS int)
  AS "CHARACTER_MAXIMUM_LENGTH",

  CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
   AS int)
  AS "CHARACTER_OCTET_LENGTH",

  CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
  CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",


  CAST(
   CASE co.collname
    WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
    ELSE co.collname collate "C"
   END
  AS sys.nvarchar(128)) AS "COLLATION_NAME",

  CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
  CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",




  CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

  CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.typbasetype, t.typtypmod)
   AS sys.tinyint)
  AS "NUMERIC_PRECISION",

  CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, t.typbasetype, t.typtypmod)
   AS smallint)
  AS "NUMERIC_PRECISION_RADIX",

  CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.typbasetype, t.typtypmod)
   AS int)
  AS "NUMERIC_SCALE",

  CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, t.typtypmod)
   AS smallint)
  AS "DATETIME_PRECISION",

  CAST(case when is_tbl_type THEN NULL ELSE t.typdefault collate "C" END AS sys.nvarchar(4000)) AS "DOMAIN_DEFAULT"

  FROM (pg_type t JOIN sys.pg_namespace_ext nc ON t.typnamespace = nc.oid)
  LEFT JOIN pg_collation co ON t.typcollation = co.oid
  LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
  sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_type_name,
  sys.is_table_type(t.typrelid) as is_tbl_type

  WHERE (pg_has_role(t.typowner, 'USAGE')
   OR has_type_privilege(t.oid, 'USAGE'))
  AND (t.typtype = 'd' OR is_tbl_type)
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;





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
    AS varchar(10)) AS "TABLE_TYPE"

 FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

 WHERE c.relkind IN ('r', 'v', 'p')
  AND (NOT pg_is_other_temp_schema(nc.oid))
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
   OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.table_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(nr.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(extr.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype NOT IN ('t', 'x')
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nr.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
    AND extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.CONSTRAINT_COLUMN_USAGE AS
SELECT CAST(tblcat AS sys.nvarchar(128)) AS "TABLE_CATALOG",
          CAST(tblschema AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
          CAST(tblname AS sys.nvarchar(128)) AS "TABLE_NAME" ,
          CAST(colname AS sys.nvarchar(128)) AS "COLUMN_NAME",
          CAST(cstrcat AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
          CAST(cstrschema AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
          CAST(cstrname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME"

FROM (

   SELECT DISTINCT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r, pg_depend d

     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND d.refclassid = 'pg_catalog.pg_class'::regclass
          AND d.refobjid = r.oid
          AND d.refobjsubid = a.attnum
          AND d.classid = 'pg_catalog.pg_constraint'::regclass
          AND d.objid = c.oid
          AND c.connamespace = nc.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND NOT a.attisdropped
    AND (pg_has_role(r.relowner, 'USAGE')
      OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
    OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

       UNION ALL


   SELECT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r
     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND nc.oid = c.connamespace
          AND r.oid = c.conrelid
          AND a.attnum = ANY (c.conkey)
          AND NOT a.attisdropped
          AND c.contype IN ('p', 'u', 'f')
          AND r.relkind IN ('r', 'p')
    AND (pg_has_role(r.relowner, 'USAGE')
      OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
    OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

      ) AS x (tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat);

GRANT SELECT ON information_schema_tsql.CONSTRAINT_COLUMN_USAGE TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.COLUMN_DOMAIN_USAGE AS
    SELECT isc_col."DOMAIN_CATALOG",
           isc_col."DOMAIN_SCHEMA" ,
           CAST(isc_col."DOMAIN_NAME" AS sys.sysname),
           isc_col."TABLE_CATALOG",
           isc_col."TABLE_SCHEMA",
           CAST(isc_col."TABLE_NAME" AS sys.sysname),
           CAST(isc_col."COLUMN_NAME" AS sys.sysname)

    FROM information_schema_tsql.columns AS isc_col
    WHERE isc_col."DOMAIN_NAME" IS NOT NULL;

GRANT SELECT ON information_schema_tsql.COLUMN_DOMAIN_USAGE TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
     CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
     CAST(sys.tsql_get_constraintdef(c.oid) AS sys.nvarchar(4000)) AS "CHECK_CLAUSE"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nc.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
    AND extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;


CREATE OR REPLACE VIEW information_schema_tsql.routines AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SPECIFIC_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "SPECIFIC_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "SPECIFIC_NAME",
           CAST(nc.dbname AS sys.nvarchar(128)) AS "ROUTINE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "ROUTINE_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "ROUTINE_NAME",
           CAST(CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END
           	 AS sys.nvarchar(20)) AS "ROUTINE_TYPE",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_NAME",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_NAME",
	   CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
           CAST(information_schema_tsql._pgtsql_char_max_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_MAXIMUM_LENGTH",
           CAST(information_schema_tsql._pgtsql_char_octet_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_OCTET_LENGTH",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_SCHEMA",
           CAST(
                 CASE co.collname
                       WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
                       ELSE co.collname
                 END
            AS sys.nvarchar(128)) AS "COLLATION_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
	    /*
                 * TODO: We need to first create mapping of collation name to char-set name;
                 * Until then return null.
            */
	    CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
	    CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION",
	    CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_SCALE",
            CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
                        AS smallint)
            AS "DATETIME_PRECISION",
	    CAST(NULL AS sys.nvarchar(30)) AS "INTERVAL_TYPE",
            CAST(NULL AS smallint) AS "INTERVAL_PRECISION",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_NAME",
            CAST(NULL AS bigint) AS "MAXIMUM_CARDINALITY",
            CAST(NULL AS sys.nvarchar(128)) AS "DTD_IDENTIFIER",
            CAST(CASE WHEN l.lanname = 'sql' THEN 'SQL' WHEN l.lanname = 'pltsql' THEN 'SQL' ELSE 'EXTERNAL' END AS sys.nvarchar(30)) AS "ROUTINE_BODY",
            CAST(sys.tsql_get_functiondef(p.oid) AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
	    CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
	    inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT),
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
	    sys.is_table_type(t.typrelid) as is_tbl_type

       WHERE
            (case p.prokind 
	       when 'p' then true 
	       when 'a' then false
               else 
    	           (case format_type(p.prorettype, null) 
	   	      when 'trigger' then false 
	   	      else true 
   		    end) 
            end)  
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND has_function_privilege(p.oid, 'EXECUTE')
            AND (pg_has_role(t.typowner, 'USAGE')
            OR has_type_privilege(t.oid, 'USAGE'))
            AND ext.dbid = cast(sys.db_id() as oid)
	    AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid
	    AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
  SELECT
  CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,

  CASE WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp'
    THEN 8
    ELSE
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
  END AS PRECISION,

  CASE WHEN a.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
  END AS LENGTH,


  CASE WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
  END AS SCALE,


  CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
  case
    when t4."IS_NULLABLE" = 'YES' then CAST(1 AS smallint)
    else CAST(0 AS smallint)
  end AS NULLABLE,

  CAST(NULL AS varchar(254)) AS remarks,
  CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,

  CASE WHEN t4."DATA_TYPE" = 'xml' COLLATE sys.database_default THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' COLLATE sys.database_default THEN 8000::INT
    WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,

  CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
  CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME

  FROM pg_catalog.pg_class t1
     JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
     JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname COLLATE sys.database_default
     JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND ext.orig_name = t4."TABLE_SCHEMA" COLLATE sys.database_default)
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname = t4."COLUMN_NAME" COLLATE sys.database_default
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = t5.TYPE_NAME COLLATE sys.database_default)
    AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597 for BABEL-1784
drop function if exists sys.sp_columns_100_internal(
 in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384),
    in_table_qualifier sys.nvarchar(384),
    in_column_name sys.nvarchar(384),
 in_NameScope int,
    in_ODBCVer int,
    in_fusepattern smallint);
create function sys.sp_columns_100_internal(
 in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384) = '',
    in_table_qualifier sys.nvarchar(384) = '',
    in_column_name sys.nvarchar(384) = '',
 in_NameScope int = 0,
    in_ODBCVer int = 2,
    in_fusepattern smallint = 1)
returns table (
 out_table_qualifier sys.sysname,
 out_table_owner sys.sysname,
 out_table_name sys.sysname,
 out_column_name sys.sysname,
 out_data_type smallint,
 out_type_name sys.sysname,
 out_precision int,
 out_length int,
 out_scale smallint,
 out_radix smallint,
 out_nullable smallint,
 out_remarks varchar(254),
 out_column_def sys.nvarchar(4000),
 out_sql_data_type smallint,
 out_sql_datetime_sub smallint,
 out_char_octet_length int,
 out_ordinal_position int,
 out_is_nullable varchar(254),
 out_ss_is_sparse smallint,
 out_ss_is_column_set smallint,
 out_ss_is_computed smallint,
 out_ss_is_identity smallint,
 out_ss_udt_catalog_name varchar(254),
 out_ss_udt_schema_name varchar(254),
 out_ss_udt_assembly_type_name varchar(254),
 out_ss_xml_schemacollection_catalog_name varchar(254),
 out_ss_xml_schemacollection_schema_name varchar(254),
 out_ss_xml_schemacollection_name varchar(254),
 out_ss_data_type sys.tinyint
)
as $$
begin
 IF in_fusepattern = 1 THEN
  return query
     select table_qualifier,
    table_owner,
    table_name,
    column_name,
    data_type,
    type_name,
    precision,
    length,
    scale,
    radix,
    nullable,
    remarks,
    column_def,
    sql_data_type,
    sql_datetime_sub,
    char_octet_length,
    ordinal_position,
    is_nullable,
    ss_is_sparse,
    ss_is_column_set,
    ss_is_computed,
    ss_is_identity,
    ss_udt_catalog_name,
    ss_udt_schema_name,
    ss_udt_assembly_type_name,
    ss_xml_schemacollection_catalog_name,
    ss_xml_schemacollection_schema_name,
    ss_xml_schemacollection_name,
    ss_data_type
  from sys.sp_columns_100_view
     where lower(table_name) similar to lower(in_table_name) COLLATE "C" -- TBD - this should be changed to ci_as
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name collate sys.bbf_unicode_general_ci_as)
  order by table_qualifier,
           table_owner,
    table_name,
    ordinal_position;
 ELSE
  return query
     select table_qualifier, precision from sys.sp_columns_100_view
       where in_table_name = table_name collate sys.bbf_unicode_general_ci_as
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name collate sys.bbf_unicode_general_ci_as)
  order by table_qualifier,
           table_owner,
    table_name,
    ordinal_position;
 END IF;
end;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id AS object_id,
        o.schema_id AS schema_id,
        c.column_id AS colid,
        CASE WHEN p.attoptions[1] collate "C" LIKE 'bbf_original_name=%' THEN split_part(p.attoptions[1] collate "C", '=', 2)
            ELSE c.name END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname COLLATE sys.database_default AND c.object_id = p.attrelid)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

ALTER TABLE sys.assemblies RENAME TO assemblies_deprecated_in_2_3_0;

CREATE TABLE sys.assemblies(
 name sys.sysname,
 principal_id int,
 assembly_id int,
 clr_name nvarchar(4000),
 permission_set tinyint,
 permission_set_desc nvarchar(60),
 is_visible bit,
 create_date datetime,
 modify_date datetime,
 is_user_defined bit
);
GRANT SELECT ON sys.assemblies TO PUBLIC;

INSERT INTO sys.assemblies SELECT * FROM sys.assemblies_deprecated_in_2_3_0;

CREATE OR REPLACE VIEW sys.assembly_types
AS
SELECT
   CAST(t.name as sys.sysname) AS name,
   -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
   -- This is because the IDs of generated SQL Server system type values generated by B
   -- Babelfish installation will exceed the size of TINYINT.
   CAST(t.system_type_id as int) AS system_type_id,
   CAST(t.user_type_id as int) AS user_type_id,
   CAST(t.schema_id as int) AS schema_id,
   CAST(t.principal_id as int) AS principal_id,
   CAST(t.max_length as smallint) AS max_length,
   CAST(t.precision as sys.tinyint) AS precision,
   CAST(t.scale as sys.tinyint) AS scale,
   CAST(t.collation_name as sys.sysname) AS collation_name,
   CAST(t.is_nullable as sys.bit) AS is_nullable,
   CAST(t.is_user_defined as sys.bit) AS is_user_defined,
   CAST(t.is_assembly_type as sys.bit) AS is_assembly_type,
   CAST(t.default_object_id as int) AS default_object_id,
   CAST(t.rule_object_id as int) AS rule_object_id,
   CAST(NULL as int) AS assembly_id,
   CAST(NULL as sys.sysname) AS assembly_class,
   CAST(NULL as sys.bit) AS is_binary_ordered,
   CAST(NULL as sys.bit) AS is_fixed_length,
   CAST(NULL as sys.nvarchar(40)) AS prog_id,
   CAST(NULL as sys.nvarchar(4000)) AS assembly_qualified_name,
   CAST(t.is_table_type as sys.bit) AS is_table_type
FROM sys.types t
WHERE t.is_assembly_type = 1;
GRANT SELECT ON sys.assembly_types TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_databases_view AS
 SELECT CAST(database_name AS sys.SYSNAME),
 -- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
 CASE WHEN (sum(table_size)/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
  ELSE CAST((sum(table_size)/1024.0) AS int) END as database_size,
 CAST(NULL AS sys.VARCHAR(254)) as remarks
 FROM (
  SELECT pg_catalog.pg_namespace.oid as schema_oid,
  pg_catalog.pg_namespace.nspname as schema_name,
  INT.name AS database_name,
  coalesce(pg_relation_size(pg_catalog.pg_class.oid), 0) as table_size
  FROM
  sys.babelfish_namespace_ext EXT
  JOIN sys.babelfish_sysdatabases INT ON EXT.dbid = INT.dbid
  JOIN pg_catalog.pg_namespace ON pg_catalog.pg_namespace.nspname = EXT.nspname
  LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid
 ) t
 GROUP BY database_name
 ORDER BY database_name;

 CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
 JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND ext.orig_name = t4."TABLE_SCHEMA" COLLATE sys.database_default)
 JOIN pg_constraint t5 ON t1.oid = t5.conrelid
 , generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = cast(sys.db_id() as oid);

CREATE OR REPLACE VIEW sys.sp_statistics_view AS
SELECT
CAST(t3."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t3."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(NULL AS smallint) AS NON_UNIQUE,
CAST(NULL AS sys.sysname) AS INDEX_QUALIFIER,
CAST(NULL AS sys.sysname) AS INDEX_NAME,
CAST(0 AS smallint) AS TYPE,
CAST(NULL AS smallint) AS SEQ_IN_INDEX,
CAST(NULL AS sys.sysname) AS COLUMN_NAME,
CAST(NULL AS sys.varchar(1)) AS COLLATION,
CAST(t1.reltuples AS int) AS CARDINALITY,
CAST(t1.relpages AS int) AS PAGES,
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN information_schema_tsql.columns t3 ON (t1.relname = t3."TABLE_NAME" COLLATE sys.database_default AND s1.name = t3."TABLE_SCHEMA")
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
UNION
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(t1.relname AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
CASE
WHEN t8.oid > 0 THEN CAST(t6.relname AS sys.sysname)
ELSE CAST(SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname)
END AS INDEX_NAME,
CASE
WHEN t7.starelid > 0 THEN CAST(0 AS smallint)
ELSE
 CASE
 WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
 ELSE CAST(3 AS smallint)
 END
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND s1.name = t4."TABLE_SCHEMA")
 JOIN (pg_catalog.pg_index t5 JOIN
  pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
 LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
 LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];

create or replace function sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname = '',
    in_table_qualifier sys.sysname = '',
    in_index_name sys.sysname = '',
 in_is_unique char = 'N',
 in_accuracy char = 'Q'
)
returns table(
    out_table_qualifier sys.sysname,
    out_table_owner sys.sysname,
    out_table_name sys.sysname,
 out_non_unique smallint,
 out_index_qualifier sys.sysname,
 out_index_name sys.sysname,
 out_type smallint,
 out_seq_in_index smallint,
 out_column_name sys.sysname,
 out_collation sys.varchar(1),
 out_cardinality int,
 out_pages int,
 out_filter_condition sys.varchar(128)
)
as $$
begin
    return query
    select * from sys.sp_statistics_view
    where in_table_name = table_name COLLATE sys.database_default
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner COLLATE sys.database_default)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier COLLATE sys.database_default)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name COLLATE sys.database_default)
        and ((UPPER(in_is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(in_is_unique) = 'N'))
    order by non_unique, type, index_name, seq_in_index;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW sys.dm_os_host_info AS
SELECT
  -- get_host_os() depends on a Postgres function created separately.
  cast( sys.get_host_os() as sys.nvarchar(256) ) as host_platform
  -- Hardcoded at the moment. Should likely be GUC with default '' (empty string). Then set by control plane to e.g. Amazon Linux.
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_distribution') as sys.nvarchar(256) ) as host_distribution
  -- documentation on one hand states this is empty string on 1, but otoh shows an example with "ubuntu 16.04"
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_release') as sys.nvarchar(256) ) as host_release
  -- empty string on 1 . we can populate this in control plane if it's helpful.
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_service_pack_level') as sys.nvarchar(256) )
    as host_service_pack_level
  -- windows stock keeping unit. null on 1 .
  , cast( null as int ) as host_sku
  -- lcid
  , cast( sys.collationproperty( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.server_collation_name') , 'lcid') as int )
    as "os_language_version";

CREATE OR REPLACE VIEW sys.sp_column_privileges_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(COALESCE(SPLIT_PART(t6.attoptions[1] collate "C", '=', 2), t5.column_name collate "C") AS sys.sysname) AS COLUMN_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantor::name) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantee::name) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
	JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
GRANT SELECT ON sys.sp_column_privileges_view TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
-- Will use sp_column_priivleges_view to get information from SELECT, INSERT and REFERENCES (only need permission from 1 column in table)
SELECT DISTINCT
CAST(TABLE_QUALIFIER AS sys.sysname) COLLATE sys.database_default AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) COLLATE sys.database_default AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) AS IS_GRANTABLE
FROM sys.sp_column_privileges_view

UNION
-- We need these set of joins only for the DELETE privilege
SELECT
CAST(t2.dbname AS sys.sysname) COLLATE sys.database_default AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) COLLATE sys.database_default AS TABLE_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
 JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type = 'DELETE' collate sys.database_default;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
 "@table_name" sys.nvarchar(384),
 "@table_owner" sys.nvarchar(384) = '',
 "@table_qualifier" sys.sysname = '',
 "@fusepattern" sys.bit = 1
)
AS $$
BEGIN

 IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 IF @fusepattern = 1
 BEGIN
  SELECT
  TABLE_QUALIFIER,
  TABLE_OWNER,
  TABLE_NAME,
  GRANTOR,
  GRANTEE,
  PRIVILEGE,
  IS_GRANTABLE FROM sys.sp_table_privileges_view
  WHERE LOWER(TABLE_NAME) LIKE LOWER(@table_name)
   AND ((SELECT COALESCE(@table_owner,'')) = '' collate database_default OR LOWER(TABLE_OWNER) LIKE LOWER(@table_owner))
  ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
 END
 ELSE
 BEGIN
  SELECT
  TABLE_QUALIFIER,
  TABLE_OWNER,
  TABLE_NAME,
  GRANTOR,
  GRANTEE,
  PRIVILEGE,
  IS_GRANTABLE FROM sys.sp_table_privileges_view
  WHERE LOWER(TABLE_NAME) = LOWER(@table_name)
   AND ((SELECT COALESCE(@table_owner,'')) = '' collate database_default OR LOWER(TABLE_OWNER) = LOWER(@table_owner))
  ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
 END

END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.sp_special_columns_precision_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('real','float') THEN sp_columns_max_length * 2 - 1
  WHEN type COLLATE sys.database_default in ('char','varchar','binary','varbinary') THEN sp_columns_max_length
  WHEN type COLLATE sys.database_default in ('nchar','nvarchar') THEN sp_columns_max_length / 2
  WHEN type COLLATE sys.database_default in ('sysname','uniqueidentifier') THEN sp_datatype_info_precision
  ELSE sp_columns_precision
 END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_length_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('decimal','numeric','money','smallmoney') THEN sp_columns_precision + 2
  WHEN type COLLATE sys.database_default in ('time','date','datetime2','datetimeoffset') THEN sp_columns_precision * 2
  WHEN type COLLATE sys.database_default in ('smalldatetime') THEN sp_columns_precision
  WHEN type COLLATE sys.database_default in ('datetime') THEN sp_columns_max_length * 2
  WHEN type COLLATE sys.database_default in ('sql_variant') THEN sp_datatype_info_precision
  ELSE sp_columns_max_length
 END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_scale_helper(IN type TEXT, IN sp_columns_scale INT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('bit','real','float','char','varchar','nchar','nvarchar','time','date','datetime2','datetimeoffset','varbinary','binary','sql_variant','sysname','uniqueidentifier') THEN NULL
  ELSE sp_columns_scale
 END;
$$ LANGUAGE SQL IMMUTABLE;

-- TODO: BABEL-2838
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT DISTINCT
CAST(1 as smallint) AS SCOPE,
CAST(coalesce (split_part(pa.attoptions[1] collate "C", '=', 2) ,c1.name) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS smallint) AS DATA_TYPE,

CASE -- cases for when they are of type identity.
 WHEN c1.is_identity = 1 AND (t8.name COLLATE sys.database_default = 'decimal' or t8.name COLLATE sys.database_default = 'numeric')
 THEN CAST(CONCAT(t8.name, '() identity') AS sys.sysname)
 WHEN c1.is_identity = 1 AND (t8.name COLLATE sys.database_default != 'decimal' AND t8.name COLLATE sys.database_default != 'numeric')
 THEN CAST(CONCAT(t8.name, ' identity') AS sys.sysname)
 ELSE CAST(t8.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS smallint) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CAST(c1.is_nullable AS int) AS IS_NULLABLE,
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,

CASE
 WHEN idx.is_primary_key != 1
 THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
 ELSE CAST('p' AS sys.sysname)
END AS CONSTRAINT_TYPE,
CAST(idx.name AS sys.sysname) AS CONSTRAINT_NAME,
CAST(idx.index_id AS int) AS INDEX_ID

FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
 LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
 INNER JOIN pg_catalog.pg_attribute i2 ON idx.index_id = i2.attrelid
 INNER JOIN sys.columns c1 ON c1.object_id = idx.object_id AND cast(i2.attname as sys.sysname) = c1.name collate sys.database_default

 JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
 JOIN sys.types AS t8 ON c1.user_type_id = t8.user_type_id
 LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name collate sys.database_default OR t7.typname = t6.type_name collate sys.database_default --need in order to get accurate DATA_TYPE value
 LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname collate sys.database_default
 , sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
 , sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
 WHERE has_schema_privilege(s1.schema_id, 'USAGE');

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
-- primary key info
CAST(t2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname COLLATE sys.database_default = ref.table_schema) AS sys.sysname) AS PKTABLE_OWNER,
CAST(ref.table_name AS sys.sysname) AS PKTABLE_NAME,
CAST(coalesce(split_part(pkname_table.attoptions[1] COLLATE "C", '=', 2), ref.column_name) AS sys.sysname) AS PKCOLUMN_NAME,

-- foreign key info
CAST(t2.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname COLLATE sys.database_default = fk.table_schema) AS sys.sysname) AS FKTABLE_OWNER,
CAST(fk.table_name AS sys.sysname) AS FKTABLE_NAME,
CAST(coalesce(split_part(fkname_table.attoptions[1] COLLATE "C", '=', 2), fk.column_name) AS sys.sysname) AS FKCOLUMN_NAME,

CAST(seq AS smallint) AS KEY_SEQ,
CASE
    WHEN map.update_rule collate sys.database_default = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.update_rule collate sys.database_default = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.update_rule collate sys.database_default = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS UPDATE_RULE,

CASE
    WHEN map.delete_rule collate sys.database_default = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.delete_rule collate sys.database_default = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.delete_rule collate sys.database_default = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(fk.constraint_name AS sys.sysname) AS FK_NAME,
CAST(ref.constraint_name AS sys.sysname) AS PK_NAME

FROM information_schema.referential_constraints AS map

-- join unique constraints (e.g. PKs constraints) to ref columns info
INNER JOIN information_schema.key_column_usage AS ref
 JOIN pg_catalog.pg_class p1 -- Need to join this in order to get oid for pkey's original bbf name
    JOIN sys.pg_namespace_ext p2 ON p1.relnamespace = p2.oid
    JOIN information_schema.columns p4 ON p1.relname = p4.table_name AND p1.relnamespace::regnamespace::text = p4.table_schema
    JOIN pg_constraint p5 ON p1.oid = p5.conrelid
    ON (p1.relname=ref.table_name AND p4.column_name=ref.column_name AND ref.table_schema = p2.nspname AND ref.table_schema = p4.table_schema)

    ON ref.constraint_catalog = map.unique_constraint_catalog
    AND ref.constraint_schema = map.unique_constraint_schema
    AND ref.constraint_name = map.unique_constraint_name

-- join fk columns to the correct ref columns using ordinal positions
INNER JOIN information_schema.key_column_usage AS fk
    ON fk.constraint_catalog = map.constraint_catalog
    AND fk.constraint_schema = map.constraint_schema
    AND fk.constraint_name = map.constraint_name
    AND fk.position_in_unique_constraint = ref.ordinal_position

INNER JOIN pg_catalog.pg_class t1
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name AND t1.relnamespace::regnamespace::text = t4.table_schema
    JOIN pg_constraint t5 ON t1.oid = t5.conrelid
    ON (t1.relname=fk.table_name AND t4.column_name=fk.column_name AND fk.table_schema = t2.nspname AND fk.table_schema = t4.table_schema)

-- get foreign key's original bbf name
JOIN pg_catalog.pg_attribute fkname_table
 ON (t1.oid = fkname_table.attrelid) AND (fk.column_name = fkname_table.attname)

-- get primary key's original bbf name
JOIN pg_catalog.pg_attribute pkname_table
 ON (p1.oid = pkname_table.attrelid) AND (ref.column_name = pkname_table.attname)

 , generate_series(1,16) seq -- BBF has max 16 columns per primary key
WHERE t5.contype = 'f'
AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT 
CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()
WHERE has_schema_privilege(s1.schema_id, 'USAGE')

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM    pg_catalog.pg_namespace n 
JOIN    pg_catalog.pg_proc p 
ON      pronamespace = n.oid   
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

CREATE OR REPLACE PROCEDURE sys.sp_stored_procedures(
    "@sp_name" sys.nvarchar(390) = '',
    "@sp_owner" sys.nvarchar(384) = '',
    "@sp_qualifier" sys.sysname = '',
    "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
 IF (@sp_qualifier != '') AND LOWER(sys.db_name()) != LOWER(@sp_qualifier)
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 -- If @sp_name or @sp_owner = '%', it gets converted to NULL or '' regardless of @fusepattern
 IF @sp_name = '%'
 BEGIN
  SELECT @sp_name = ''
 END

 IF @sp_owner = '%'
 BEGIN
  SELECT @sp_owner = ''
 END

 -- Changes fusepattern to 0 if no wildcards are used. NOTE: Need to add [] wildcard pattern when it is implemented. Wait for BABEL-2452
 IF @fusepattern = 1
 BEGIN
  IF (CHARINDEX('%', @sp_name) != 0 AND CHARINDEX('_', @sp_name) != 0 AND CHARINDEX('%', @sp_owner) != 0 AND CHARINDEX('_', @sp_owner) != 0 )
  BEGIN
   SELECT @fusepattern = 0;
  END
 END

 -- Condition for when sp_name argument is not given or is null, or is just a wildcard (same order)
 IF COALESCE(@sp_name, '') = ''
 BEGIN
  IF @fusepattern=1
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
  ELSE
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
 END
 -- When @sp_name is not null
 ELSE
 BEGIN
  -- When sp_owner is null and fusepattern = 0
  IF (@fusepattern = 0 AND COALESCE(@sp_owner,'') = '')
  BEGIN
   IF EXISTS ( -- Search in the sys schema
     SELECT * FROM sys.sp_stored_procedures_view
     WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
      AND (LOWER(procedure_owner) = 'sys'))
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = 'sys')
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END
   ELSE IF EXISTS (
    SELECT * FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
     )
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END
   ELSE -- Search in the dbo schema (if nothing exists it should just return nothing).
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = 'dbo')
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END

  END
  ELSE IF (@fusepattern = 0 AND COALESCE(@sp_owner,'') != '')
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
    AND (LOWER(procedure_owner) = LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
  ELSE -- fusepattern = 1
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, -2)) LIKE LOWER(@sp_name))
    AND ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
 END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

ALTER VIEW sys.sp_sproc_columns_view RENAME TO sp_sproc_columns_view_deprecated_in_2_3_0;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view AS
-- Get parameters (if any) for a user-defined stored procedure/function
(SELECT
 CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
 CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134))
  ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134))
 END AS PROCEDURE_NAME,

 CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
 CAST(1 AS smallint) AS COLUMN_TYPE,
 CAST(t5.data_type AS smallint) AS DATA_TYPE,
 CAST(coalesce(t6.name, '') AS sys.sysname) COLLATE sys.database_default AS TYPE_NAME,
 CAST(t6.precision AS int) AS PRECISION,
 CAST(t6.max_length AS int) AS LENGTH,
 CAST(t6.scale AS smallint) AS SCALE,
 CAST(t5.num_prec_radix AS smallint) AS RADIX,
 CAST(t6.is_nullable AS smallint) AS NULLABLE,
 CAST(NULL AS varchar(254)) AS REMARKS,
 CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
 CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
 CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
 CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
 CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
 CAST('YES' AS varchar(254)) AS IS_NULLABLE,
 CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
 CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

 FROM information_schema.routines proc
 JOIN information_schema.parameters args
  ON proc.specific_schema = args.specific_schema COLLATE sys.database_default AND proc.specific_name = args.specific_name COLLATE sys.database_default
 INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = cast(ext.nspname as sys.sysname) COLLATE sys.database_default
 INNER JOIN sys.databases d ON d.database_id =ext.dbid
 INNER JOIN sys.spt_datatype_info_table AS t5
  JOIN sys.types t6
  JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
   ON t7.name = t5.type_name COLLATE sys.database_default
  ON (args.data_type != 'USER-DEFINED' COLLATE sys.database_default AND args.udt_name = t5.pg_type_name COLLATE sys.database_default AND t6.name = t7.name COLLATE sys.database_default)
  OR (args.data_type='USER-DEFINED' COLLATE sys.database_default AND args.udt_name = t6.name COLLATE sys.database_default)
 WHERE coalesce(args.parameter_name, '') LIKE '@%'
  AND ext.dbid = sys.db_id()
  AND has_schema_privilege(proc.specific_schema, 'USAGE')

UNION ALL

-- Create row describing return type for a user-defined stored procedure/function
SELECT
 CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
 CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134))
  ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134))
 END AS PROCEDURE_NAME,

 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
  ELSE cast('@RETURN_VALUE' AS sys.sysname)
  END AS COLUMN_NAME,

 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
  ELSE CAST(5 as smallint)
 END AS COLUMN_TYPE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN cast((SELECT data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
  ELSE CAST(t5.data_type AS smallint)
 END AS DATA_TYPE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST('int' AS sys.sysname) COLLATE sys.database_default
  WHEN pg_function_result_type like '%TABLE%' then CAST('table' AS sys.sysname) COLLATE sys.database_default
  ELSE CAST(coalesce(t6.name, '') AS sys.sysname) COLLATE sys.database_default
 END AS TYPE_NAME,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(10 AS int)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int)
  ELSE CAST(t6.precision AS int)
 END AS PRECISION,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(4 AS int)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int)
  ELSE CAST(t6.max_length AS int)
 END AS LENGTH,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(0 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t6.scale AS smallint)
 END AS SCALE,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(10 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t5.num_prec_radix AS smallint)
 END AS RADIX,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(0 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t6.is_nullable AS smallint)
 END AS NULLABLE,
 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254))
  ELSE CAST(NULL AS varchar(254))
 END AS REMARKS,

 CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint)
  ELSE CAST(t5.sql_data_type AS smallint)
 END AS SQL_DATA_TYPE,

 CAST(null AS smallint) AS SQL_DATETIME_SUB,
 CAST(null AS int) AS CHAR_OCTET_LENGTH,
 CAST(0 AS int) AS ORDINAL_POSITION,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST('NO' AS varchar(254))
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
  ELSE CAST('YES' AS varchar(254))
 END AS IS_NULLABLE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(56 AS sys.tinyint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint)
  ELSE CAST(t5.ss_data_type AS sys.tinyint)
 END AS SS_DATA_TYPE,
 CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

 FROM information_schema.routines proc
    INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname COLLATE sys.database_default
    INNER JOIN sys.databases d ON d.database_id = ext.dbid and ext.dbid = sys.db_id()
    INNER JOIN pg_catalog.pg_proc p ON cast(proc.specific_name as sys.sysname) = (p.proname || '_' || p.oid) COLLATE sys.database_default
    LEFT JOIN sys.spt_datatype_info_table AS t5
        JOIN sys.types t6
        JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
        ON t7.name = t5.type_name COLLATE sys.database_default
    ON (proc.data_type != 'USER-DEFINED' COLLATE sys.database_default
            AND proc.type_udt_name = t5.pg_type_name COLLATE sys.database_default
            AND t6.name = t7.name COLLATE sys.database_default)
        OR (proc.data_type = 'USER-DEFINED' COLLATE sys.database_default
            AND proc.type_udt_name = t6.name COLLATE sys.database_default),
    pg_get_function_result(p.oid) AS pg_function_result_type
 WHERE has_schema_privilege(proc.specific_schema, 'USAGE'))

UNION ALL

-- Get parameters (if any) for a system stored procedure/function
(SELECT
 CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
 CAST(args.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134))
  ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134))
 END AS PROCEDURE_NAME,

 CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
 CAST(1 as smallint) AS COLUMN_TYPE,
 CAST(t5.data_type AS smallint) AS DATA_TYPE,
 CAST(coalesce(t6.name, '') as sys.sysname) COLLATE sys.database_default as TYPE_NAME,
 CAST(t6.precision as int) as PRECISION,
 CAST(t6.max_length as int) as LENGTH,
 CAST(t6.scale AS smallint) AS SCALE,
 CAST(t5.num_prec_radix AS smallint) AS RADIX,
 CAST(t6.is_nullable as smallint) AS NULLABLE,
 CAST(NULL AS varchar(254)) AS REMARKS,
 CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
 CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
 CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
 CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
 CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
 CAST('YES' AS varchar(254)) AS IS_NULLABLE,
 CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
 CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

 FROM information_schema.routines proc
 JOIN information_schema.parameters args
  on proc.specific_schema = args.specific_schema COLLATE sys.database_default
  and proc.specific_name = args.specific_name COLLATE sys.database_default
 LEFT JOIN sys.spt_datatype_info_table AS t5
  LEFT JOIN sys.types t6 ON t6.name = t5.type_name COLLATE sys.database_default
  ON args.udt_name = t5.pg_type_name COLLATE sys.database_default OR args.udt_name = t5.type_name COLLATE sys.database_default
 WHERE args.specific_schema ='sys' COLLATE sys.database_default
  AND coalesce(args.parameter_name, '') LIKE '@%'
  AND (args.specific_name LIKE 'sp\_%'
   OR args.specific_name LIKE 'xp\_%'
   OR args.specific_name LIKE 'dm\_%'
   OR args.specific_name LIKE 'fn\_%')
  AND has_schema_privilege(proc.specific_schema, 'USAGE')

UNION ALL

-- Create row describing return type for a system stored procedure/function
SELECT
 CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
 CAST(proc.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134))
  ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134))
 END AS PROCEDURE_NAME,

 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
  ELSE cast('@RETURN_VALUE' AS sys.sysname)
  END AS COLUMN_NAME,

 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
  ELSE CAST(5 AS smallint)
 END AS COLUMN_TYPE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN cast((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
  ELSE CAST(t5.data_type AS smallint)
 END AS DATA_TYPE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST('int' AS sys.sysname) COLLATE sys.database_default
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('table' AS sys.sysname) COLLATE sys.database_default
  ELSE CAST(coalesce(t6.name, '') AS sys.sysname) COLLATE sys.database_default
 END AS TYPE_NAME,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(10 AS int)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int)
  ELSE CAST(t6.precision AS int)
 END AS PRECISION,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(4 AS int)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int)
  ELSE CAST(t6.max_length AS int)
 END AS LENGTH,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(0 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t6.scale AS smallint)
 END AS SCALE,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(10 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t5.num_prec_radix AS smallint)
 END AS RADIX,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(0 AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
  ELSE CAST(t6.is_nullable AS smallint)
 END AS NULLABLE,

 CASE
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254))
  ELSE CAST(NULL AS varchar(254))
 END AS REMARKS,

 CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint)
  ELSE CAST(t5.sql_data_type AS smallint)
 END AS SQL_DATA_TYPE,

 CAST(null AS smallint) AS SQL_DATETIME_SUB,
 CAST(null AS int) AS CHAR_OCTET_LENGTH,
 CAST(0 AS int) AS ORDINAL_POSITION,
 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST('NO' AS varchar(254))
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
  ELSE CAST('YES' AS varchar(254))
 END AS IS_NULLABLE,

 CASE
  WHEN proc.routine_type='PROCEDURE' COLLATE sys.database_default THEN CAST(56 AS sys.tinyint)
  WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint)
  ELSE CAST(t5.ss_data_type AS sys.tinyint)
 END AS SS_DATA_TYPE,
 CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

 FROM information_schema.routines proc
 INNER JOIN pg_catalog.pg_proc p ON cast(proc.specific_name as sys.sysname) = (p.proname || '_' || p.oid) collate sys.database_default
 LEFT JOIN sys.spt_datatype_info_table AS t5
  LEFT JOIN sys.types t6 ON t6.name = t5.type_name collate sys.database_default
 ON proc.type_udt_name = t5.pg_type_name COLLATE sys.database_default
  OR proc.type_udt_name = t5.type_name COLLATE sys.database_default,
 pg_get_function_result(p.oid) AS pg_function_result_type
 WHERE cast(proc.specific_schema as sys.sysname) = 'sys' 
  AND (cast(proc.specific_name as sys.sysname) LIKE 'sp\_%' 
   OR cast(proc.specific_name as sys.sysname) LIKE 'xp\_%' 
   OR cast(proc.specific_name as sys.sysname) LIKE 'dm\_%' 
   OR cast(proc.specific_name as sys.sysname) LIKE 'fn\_%' )
  AND has_schema_privilege(proc.specific_schema, 'USAGE')
 );

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)	
AS $$
	SELECT @procedure_name = LOWER(COALESCE(@procedure_name, ''))
	SELECT @procedure_owner = LOWER(COALESCE(@procedure_owner, ''))
	SELECT @procedure_qualifier = LOWER(COALESCE(@procedure_qualifier, ''))
	SELECT @column_name = LOWER(COALESCE(@column_Name, ''))
BEGIN 
	IF (@procedure_qualifier != '' AND (SELECT LOWER(sys.db_name())) != @procedure_qualifier)
		BEGIN
			THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 	   	END
	IF @fusepattern = '1'
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name LIKE @procedure_name COLLATE database_default )
				AND (@procedure_owner = '' OR procedure_owner LIKE @procedure_owner COLLATE database_default )
				AND (@column_name = '' OR column_name LIKE @column_name COLLATE database_default )
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier COLLATE database_default )
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
	ELSE
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name = @procedure_name)
				AND (@procedure_owner = '' OR procedure_owner = @procedure_owner)
				AND (@column_name = '' OR column_name = @column_name)
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns TO PUBLIC;

ALTER TABLE sys.babelfish_view_def ADD COLUMN create_date SYS.DATETIME, add COLUMN modify_date SYS.DATETIME;

ALTER TABLE sys.babelfish_view_def RENAME TO babelfish_view_def_deprecated_in_2_3_0;

-- we need to drop primary key constraint also because babelfish_view_def_pkey is being used from C code to perform some lokkup
ALTER TABLE sys.babelfish_view_def_deprecated_in_2_3_0 DROP CONSTRAINT babelfish_view_def_pkey;

CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name sys.SYSNAME NOT NULL,
	object_name sys.SYSNAME NOT NULL,
	definition sys.NTEXT,
	flag_validity BIGINT,
	flag_values BIGINT,
	create_date SYS.DATETIME,
	modify_date SYS.DATETIME,
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;

INSERT INTO sys.babelfish_view_def SELECT * FROM sys.babelfish_view_def_deprecated_in_2_3_0;
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');

CALL babel_catalog_initializer();

CREATE OR REPLACE FUNCTION sys.babelfish_get_pltsql_function_signature(IN funcoid OID)
RETURNS text
AS 'babelfishpg_tsql', 'get_pltsql_function_signature' LANGUAGE C;

create or replace view sys.tables as
select
  CAST(t.relname as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(sch.schema_id as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as CHAR(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , CAST(NULL as int) as filestream_data_space_id
  , CAST(relnatts as int) as max_column_id_used
  , CAST(0 as sys.bit) as lock_on_bulk_load
  , CAST(1 as sys.bit) as uses_ansi_nulls
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as has_replication_filter
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_sync_tran_subscribed
  , CAST(0 as sys.bit) as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , CAST(0 as sys.bit) as large_value_types_out_of_row
  , CAST(0 as sys.bit) as is_tracked_by_cdc
  , CAST(0 as sys.tinyint) as lock_escalation
  , CAST('TABLE' as sys.nvarchar(60)) as lock_escalation_desc
  , CAST(0 as sys.bit) as is_filetable
  , CAST(0 as sys.tinyint) as durability
  , CAST('SCHEMA_AND_DATA' as sys.nvarchar(60)) as durability_desc
  , CAST(0 as sys.bit) is_memory_optimized
  , case relpersistence when 't' then CAST(2 as sys.tinyint) else CAST(0 as sys.tinyint) end as temporal_type
  , case relpersistence when 't' then CAST('SYSTEM_VERSIONED_TEMPORAL_TABLE' as sys.nvarchar(60)) else CAST('NON_TEMPORAL_TABLE' as sys.nvarchar(60)) end as temporal_type_desc
  , CAST(null as integer) as history_table_id
  , CAST(0 as sys.bit) as is_remote_data_archive_enabled
  , CAST(0 as sys.bit) as is_external
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and not sys.is_table_type(t.oid)
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;

create or replace view sys.views as 
select 
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type 
  , 'VIEW'::varchar(60) as type_desc
  , vd.create_date::timestamp as create_date
  , vd.create_date::timestamp as modify_date
  , 0 as is_ms_shipped 
  , 0 as is_published 
  , 0 as is_schema_published 
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id 
left outer join sys.babelfish_view_def vd on t.relname COLLATE sys.database_default = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id() 
where t.relkind = 'v'
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

create or replace view sys.procedures as
select
  cast(p.proname as sys.sysname) as name
  , cast(p.oid as int) as object_id
  , cast(null as int) as principal_id
  , cast(sch.schema_id as int) as schema_id
  , cast (0 as int) as parent_object_id
  , cast(case p.prokind
      when 'p' then 'P'
      when 'a' then 'AF'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'
          else 'FN'
        end
    end as sys.bpchar(2)) as type
  , cast(case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'
      when 'a' then 'AGGREGATE_FUNCTION'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'
          else 'SQL_SCALAR_FUNCTION'
        end
    end as sys.nvarchar(60)) as type_desc
  , cast(f.create_date as sys.datetime) as create_date
  , cast(f.create_date as sys.datetime) as modify_date
  , cast(0 as sys.bit) as is_ms_shipped
  , cast(0 as sys.bit) as is_published
  , cast(0 as sys.bit) as is_schema_published
  , cast(0 as sys.bit) as is_auto_executed
  , cast(0 as sys.bit) as is_execution_replicated
  , cast(0 as sys.bit) as is_repl_serializable_only
  , cast(0 as sys.bit) as skips_repl_constraints
from pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and format_type(p.prorettype, null) <> 'trigger'
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(p.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(f.create_date as sys.datetime) AS create_date,
  CAST(f.create_date as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(
      CASE WHEN tr.tgenabled = 'D'
      THEN 1
      ELSE 0
      END
      AS sys.bit
  )	AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;


CREATE OR REPLACE VIEW information_schema_tsql.views AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
   CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
   CAST(vd.definition AS sys.nvarchar(4000)) AS "VIEW_DEFINITION",

   CAST(
    CASE WHEN 'check_option=cascaded' = ANY (c.reloptions)
     THEN 'CASCADE'
     ELSE 'NONE' END
    AS sys.varchar(7)) AS "CHECK_OPTION",

   CAST('NO' AS sys.varchar(2)) AS "IS_UPDATABLE"

 FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext
   ON (nc.nspname = ext.nspname COLLATE sys.database_default)
  LEFT OUTER JOIN sys.babelfish_view_def vd
   ON ext.dbid = vd.dbid
    AND (ext.orig_name = vd.schema_name COLLATE sys.database_default)
    AND (CAST(c.relname AS sys.nvarchar(128)) = vd.object_name COLLATE sys.database_default)
 WHERE c.relkind = 'v'
  AND (NOT pg_is_other_temp_schema(nc.oid))
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
   OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.views TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If server role is not specified, return info for all server roles
	IF @srvrolename IS NULL
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	-- If the role is a SQL server predefined role (i.e. serveradmin), 
	-- do not raise an error even if it does not exist
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_login_ext
					WHERE (rolname = RTRIM(@srvrolename)
					OR lower(rolname) = lower(RTRIM(@srvrolename)))
					AND type = 'R')
					OR lower(RTRIM(@srvrolename)) IN (
					'serveradmin', 'setupadmin', 'securityadmin', 'processadmin',
					'dbcreator', 'diskadmin', 'bulkadmin')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		AND (Ext1.rolname = RTRIM(@srvrolename) OR lower(Ext1.rolname) = lower(RTRIM(@srvrolename)))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT
AS
$body$
BEGIN
    RETURN sys.dateadd_internal(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'date'::regtype AND
		datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond', 'nanosecond') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type date.', datepart;
	END IF;
    IF pg_typeof(startdate) = 'time'::regtype AND
		datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'weekday') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type time.', datepart;
	END IF;

	CASE datepart
	WHEN 'year' THEN
		RETURN startdate + make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate + make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate + make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate + make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate + make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate + make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate + make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate + make_interval(secs => (num::numeric) * 0.001);
	WHEN 'microsecond' THEN
        IF pg_typeof(startdate) = 'sys.datetimeoffset'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
	WHEN 'nanosecond' THEN
        IF pg_typeof(startdate) = 'sys.datetimeoffset'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
	ELSE
		RAISE EXCEPTION '''%'' is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.format_datetime(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '') RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_datetime' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_datetime(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.format_numeric(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '', IN e_position INT DEFAULT -1) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_numeric' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_numeric(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR, IN INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.FORMAT(IN arg anyelement, IN p_format_pattern NVARCHAR, IN p_culture VARCHAR default 'en-us')
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    arg_type regtype;
    v_temp_integer INTEGER;
BEGIN
    arg_type := pg_typeof(arg);

    CASE
        WHEN arg_type IN ('time'::regtype ) THEN
            RETURN sys.format_datetime(arg, p_format_pattern, p_culture, 'time');

        WHEN arg_type IN ('date'::regtype, 'sys.datetime'::regtype, 'sys.smalldatetime'::regtype, 'sys.datetime2'::regtype ) THEN
            RETURN sys.format_datetime(arg::timestamp, p_format_pattern, p_culture);

        WHEN arg_type IN ('sys.tinyint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'tinyint');

        WHEN arg_type IN ('smallint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'smallint');

        WHEN arg_type IN ('integer'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'integer');

         WHEN arg_type IN ('bigint'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'bigint');

        WHEN arg_type IN ('numeric'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('sys.decimal'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('real'::regtype) THEN
            IF(p_format_pattern LIKE 'R%') THEN
                v_temp_integer := length(nullif((regexp_matches(arg::real::text, '(?<=\d*\.).*(?=[eE].*)')::text[])[1], ''));
            ELSE v_temp_integer:= -1;
            END IF;

            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'real', v_temp_integer);

        WHEN arg_type IN ('float'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'float');

        WHEN pg_typeof(arg) IN ('sys.smallmoney'::regtype, 'sys.money'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');
        ELSE
            RAISE datatype_mismatch;
        END CASE;
EXCEPTION
	WHEN datatype_mismatch THEN
		RAISE USING MESSAGE := format('Argument data type % is invalid for argument 1 of format function.', pg_typeof(arg)),
					DETAIL := 'Invalid datatype.',
					HINT := 'Convert it to valid datatype and try again.';
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.FORMAT(IN anyelement, IN NVARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg TEXT, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE pg_catalog.format('SELECT CAST(%L AS %s)', arg, format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_sp_aws_add_jobschedule (
  par_job_id integer = NULL::integer,
  par_schedule_id integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  proc_name_mask VARCHAR(100);
  var_owner_login_name VARCHAR(128);
  var_xml TEXT DEFAULT '';
  var_cron_expression VARCHAR(50);
  var_job_cmd VARCHAR(255);
  lambda_arn VARCHAR(255);
  return_message text;
  var_schedule_name VARCHAR(255);
  var_job_name VARCHAR(128);
  var_start_step_id INTEGER;
  var_notify_level_email INTEGER;
  var_notify_email_operator_id INTEGER;
  var_notify_email_operator_name VARCHAR(128);
  notify_email_sender VARCHAR(128);
  var_delete_level INTEGER;
BEGIN
  IF (EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    SELECT cron_expression
      FROM sys.babelfish_sp_schedule_to_cron (par_job_id, par_schedule_id)
      INTO var_cron_expression;
    SELECT name
      FROM sys.sysschedules
     WHERE schedule_id = par_schedule_id
      INTO var_schedule_name;
    SELECT name
         , start_step_id
         , COALESCE(notify_level_email,0)
         , COALESCE(notify_email_operator_id,0)
         , COALESCE(notify_email_operator_name,'')
         , COALESCE(delete_level,0)
      FROM sys.sysjobs
     WHERE job_id = par_job_id
      INTO var_job_name
         , var_start_step_id
         , var_notify_level_email
         , var_notify_email_operator_id
         , var_notify_email_operator_name
         , var_delete_level;

    proc_name_mask := 'sys_data.sql_agent$job_%s_step_%s';
    var_job_cmd := pg_catalog.format(proc_name_mask, par_job_id, '1');
    notify_email_sender := 'aws_test_email_sender@dbbest.com';


    var_xml := CONCAT(var_xml, '{');
    var_xml := CONCAT(var_xml, '"mode": "add_job",');
    var_xml := CONCAT(var_xml, '"parameters": {');
    var_xml := CONCAT(var_xml, '"vendor": "postgresql",');
    var_xml := CONCAT(var_xml, '"job_name": "',var_schedule_name,'",');
    var_xml := CONCAT(var_xml, '"job_frequency": "',var_cron_expression,'",');
    var_xml := CONCAT(var_xml, '"job_cmd": "',var_job_cmd,'",');
    var_xml := CONCAT(var_xml, '"notify_level_email": ',var_notify_level_email,',');
    var_xml := CONCAT(var_xml, '"delete_level": ',var_delete_level,',');
    var_xml := CONCAT(var_xml, '"uid": "',par_job_id,'",');
    var_xml := CONCAT(var_xml, '"callback": "sys.babelfish_sp_job_log",');
    var_xml := CONCAT(var_xml, '"notification": {');
    var_xml := CONCAT(var_xml, '"notify_email_sender": "',notify_email_sender,'",');
    var_xml := CONCAT(var_xml, '"notify_email_recipient": "',var_notify_email_operator_name,'"');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    -- RAISE NOTICE '%', var_xml;
    SELECT sys.babelfish_get_service_setting ('JOB', 'LAMBDA_ARN')
      INTO lambda_arn;
    SELECT sys.awslambda_fn (lambda_arn, var_xml) INTO return_message;
    returncode := 0;
  ELSE
    returncode := 1;
    RAISE 'Job not fount' USING ERRCODE := '50000';
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_schedule_to_cron (
  par_job_id integer,
  par_schedule_id integer,
  out cron_expression varchar
)
RETURNS VARCHAR AS
$body$
DECLARE
  var_enabled INTEGER;
  var_freq_type INTEGER;
  var_freq_interval INTEGER;
  var_freq_subday_type INTEGER;
  var_freq_subday_interval INTEGER;
  var_freq_relative_interval INTEGER;
  var_freq_recurrence_factor INTEGER;
  var_active_start_date INTEGER;
  var_active_end_date INTEGER;
  var_active_start_time INTEGER;
  var_active_end_time INTEGER;
  var_next_run_date date;
  var_next_run_time time;
  var_next_run_dt timestamp;
  var_tmp_interval varchar(50);
  var_current_dt timestamp;
  var_next_dt timestamp;
BEGIN
  SELECT enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
    FROM sys.sysschedules
    INTO var_enabled
       , var_freq_type
       , var_freq_interval
       , var_freq_subday_type
       , var_freq_subday_interval
       , var_freq_relative_interval
       , var_freq_recurrence_factor
       , var_active_start_date
       , var_active_end_date
       , var_active_start_time
       , var_active_end_time
   WHERE schedule_id = par_schedule_id;
  /* if enabled = 0 return */
  CASE var_freq_type
    WHEN 1 THEN
      NULL;
    WHEN 4 THEN
    BEGIN
        cron_expression :=
        CASE
          /* WHEN var_freq_subday_type = 1 THEN var_freq_subday_interval::character varying || ' At the specified time'  -- start time */
          /* WHEN var_freq_subday_type = 2 THEN var_freq_subday_interval::character varying || ' second'  -- ADD var_freq_subday_interval SECOND */
          WHEN var_freq_subday_type = 4 THEN pg_catalog.format('cron(*/%s * * * ? *)', var_freq_subday_interval::character varying) /* ADD var_freq_subday_interval MINUTE */
          WHEN var_freq_subday_type = 8 THEN pg_catalog.format('cron(0 */%s * * ? *)', var_freq_subday_interval::character varying) /* ADD var_freq_subday_interval HOUR */
          ELSE ''
        END;
    END;
    WHEN 8 THEN
      NULL;
    WHEN 16 THEN
      NULL;
    WHEN 32 THEN
      NULL;
    WHEN 64 THEN
      NULL;
    WHEN 128 THEN
     NULL;
  END CASE;
 -- return cron_expression;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_day NUMERIC,
                                                                IN p_hour NUMERIC,
                                                                IN p_minute NUMERIC,
                                                                IN p_seconds NUMERIC,
                                                                IN p_fractions NUMERIC,
                                                                IN p_precision NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
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
   ELSIF ((p_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
       (p_month::SMALLINT NOT BETWEEN 1 AND 12) OR
       (p_day::SMALLINT NOT BETWEEN 1 AND 31) OR
       (p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
       (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
       (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := pg_catalog.format('%s.%s',
                            floor(p_seconds)::SMALLINT,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

   RETURN make_timestamp(floor(p_year)::SMALLINT,
                         floor(p_month)::SMALLINT,
                         floor(p_day)::SMALLINT,
                         floor(p_hour)::SMALLINT,
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
           (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;

    v_calc_seconds := pg_catalog.format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

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

CREATE OR REPLACE FUNCTION sys.space(IN number INTEGER, OUT result SYS.VARCHAR) AS $$
-- sys.varchar has default length of 1, so we have to pass in 'number' to be the
-- type modifier.
BEGIN
	EXECUTE pg_catalog.format(E'SELECT repeat(\' \', %s)::SYS.VARCHAR(%s)', number, number) INTO result;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_full_year(IN p_short_year TEXT,
                                                           IN p_base_century TEXT DEFAULT '',
                                                           IN p_year_cutoff NUMERIC DEFAULT 49)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_full_year SMALLINT;
    v_short_year SMALLINT;
    v_base_century SMALLINT;
    v_result_param_set JSONB;
    v_full_year_res_jsonb JSONB;
BEGIN
    v_short_year := p_short_year::SMALLINT;

    BEGIN
        v_full_year_res_jsonb := nullif(current_setting('sys.full_year_res_json'), '')::JSONB;
    EXCEPTION
        WHEN undefined_object THEN
        v_full_year_res_jsonb := NULL;
    END;

    SELECT result
      INTO v_full_year
      FROM jsonb_to_recordset(v_full_year_res_jsonb) AS result_set (param1 SMALLINT,
                                                                    param2 TEXT,
                                                                    param3 NUMERIC,
                                                                    result VARCHAR)
     WHERE param1 = v_short_year
       AND param2 = p_base_century
       AND param3 = p_year_cutoff;

    IF (v_full_year IS NULL)
    THEN
        IF (v_short_year <= 99)
        THEN
            v_base_century := CASE
                                 WHEN (p_base_century ~ '^\s*([1-9]{1,2})\s*$') THEN concat(trim(p_base_century), '00')::SMALLINT
                                 ELSE trunc(extract(year from current_date)::NUMERIC, -2)
                              END;

            v_full_year = v_base_century + v_short_year;
            v_full_year = CASE
                             WHEN (v_short_year::NUMERIC > p_year_cutoff) THEN v_full_year - 100
                             ELSE v_full_year
                          END;
        ELSE v_full_year := v_short_year;
        END IF;

        v_result_param_set := jsonb_build_object('param1', v_short_year,
                                                 'param2', p_base_century,
                                                 'param3', p_year_cutoff,
                                                 'result', v_full_year);
        v_full_year_res_jsonb := CASE
                                    WHEN (v_full_year_res_jsonb IS NULL) THEN jsonb_build_array(v_result_param_set)
                                    ELSE v_full_year_res_jsonb || v_result_param_set
                                 END;

        PERFORM set_config('sys.full_year_res_json',
                           v_full_year_res_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_full_year;
EXCEPTION
	WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE PROCEDURE sys.sp_helpdbfixedrole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- Returns a list of the fixed database roles. 
	-- Only fixed role present in babelfish is db_owner.
	IF LOWER(RTRIM(@rolename)) IS NULL OR LOWER(RTRIM(@rolename)) = 'db_owner'
	BEGIN
		SELECT CAST('db_owner' AS sys.SYSNAME) AS DbFixedRole, CAST('DB Owners' AS sys.nvarchar(70)) AS Description;
	END
	ELSE IF LOWER(RTRIM(@rolename)) IN (
			'db_accessadmin','db_securityadmin','db_ddladmin', 'db_backupoperator', 
			'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
	BEGIN
		-- Return an empty result set instead of raising an error
		SELECT CAST(NULL AS sys.SYSNAME) AS DbFixedRole, CAST(NULL AS sys.nvarchar(70)) AS Description
		WHERE 1=0;	
	END
	ELSE
		RAISERROR('''%s'' is not a known fixed role.', 16, 1, @rolename);
END
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpdbfixedrole TO PUBLIC;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT
AS $$
BEGIN

    IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
    THEN
        RETURN NULL;
    END IF;

    property := RTRIM(LOWER(COALESCE(property, '')));

    IF property = 'ownerid' -- OwnerId
    THEN
        RETURN (
                SELECT CAST(COALESCE(t1.principal_id, pn.nspowner) AS INT)
                FROM sys.all_objects t1
                INNER JOIN pg_catalog.pg_namespace pn ON pn.oid = t1.schema_id
                WHERE t1.object_id = id);

    ELSEIF property = 'isdefaultcnst' -- IsDefaultCnst
    THEN
        RETURN (SELECT count(distinct dc.object_id) FROM sys.default_constraints dc WHERE dc.object_id = id);

    ELSEIF property = 'execisquotedidenton' -- ExecIsQuotedIdentOn
    THEN
        RETURN (SELECT CAST(sm.uses_quoted_identifier as int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'tablefulltextpopulatestatus' -- TableFullTextPopulateStatus
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'tablehasvardecimalstorageformat' -- TableHasVarDecimalStorageFormat
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'ismsshipped' -- IsMSShipped
    THEN
        RETURN (SELECT CAST(ao.is_ms_shipped AS int) FROM sys.all_objects ao WHERE ao.object_id = id);

    ELSEIF property = 'isschemabound' -- IsSchemaBound
    THEN
        RETURN (SELECT CAST(sm.is_schema_bound AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'execisansinullson' -- ExecIsAnsiNullsOn
    THEN
        RETURN (SELECT CAST(sm.uses_ansi_nulls AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'isdeterministic' -- IsDeterministic
    THEN
        RETURN 0;

    ELSEIF property = 'isprocedure' -- IsProcedure
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'P');

    ELSEIF property = 'istable' -- IsTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IT', 'TT', 'U', 'S'));

    ELSEIF property = 'isview' -- IsView
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'V');

    ELSEIF property = 'isusertable' -- IsUserTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'U' and is_ms_shipped = 0);

    ELSEIF property = 'istablefunction' -- IsTableFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF', 'TF', 'FT'));

    ELSEIF property = 'isinlinefunction' -- IsInlineFunction
    THEN
        RETURN 0;

    ELSEIF property = 'isscalarfunction' -- IsScalarFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('FN', 'FS'));

    ELSEIF property = 'isprimarykey' -- IsPrimaryKey
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'PK');

    ELSEIF property = 'isindexed' -- IsIndexed
    THEN
        RETURN (SELECT count(distinct object_id) from sys.indexes WHERE object_id = id and index_id > 0);

    ELSEIF property = 'isdefault' -- IsDefault
    THEN
        RETURN 0;

    ELSEIF property = 'isrule' -- IsRule
    THEN
        RETURN 0;

    ELSEIF property = 'istrigger' -- IsTrigger
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('TA', 'TR'));
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'check_constraints_deprecated_in_2_3_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'default_constraints_deprecated_in_2_3_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys','sp_sproc_columns_view_deprecated_in_2_3_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

CREATE OR REPLACE PROCEDURE sys.sp_helpdb(IN "@dbname" VARCHAR(32))
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT
  CAST(name AS sys.nvarchar(128)),
  CAST(db_size AS sys.nvarchar(13)),
  CAST(owner AS sys.nvarchar(128)),
  CAST(dbid AS sys.int),
  CAST(created AS sys.nvarchar(11)),
  CAST(status AS sys.nvarchar(600)),
  CAST(compatibility_level AS sys.tinyint)
  FROM sys.babelfish_helpdb(@dbname);

  SELECT
  CAST(NULL AS sys.nchar(128)) AS name,
  CAST(NULL AS smallint) AS fileid,
  CAST(NULL AS sys.nchar(260)) AS filename,
  CAST(NULL AS sys.nvarchar(128)) AS filegroup,
  CAST(NULL AS sys.nvarchar(18)) AS size,
  CAST(NULL AS sys.nvarchar(18)) AS maxsize,
  CAST(NULL AS sys.nvarchar(18)) AS growth,
  CAST(NULL AS sys.varchar(9)) AS usage;

  RETURN 0;
END;
$$;

