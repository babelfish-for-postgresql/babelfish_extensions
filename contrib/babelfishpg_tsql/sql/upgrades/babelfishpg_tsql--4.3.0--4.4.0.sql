-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.4.0'" to load this file. \quit

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
DO $$
DECLARE
    exception_message text;
BEGIN
    -- Rename bbf_pivot for dependencies
    ALTER FUNCTION sys.bbf_pivot() RENAME TO bbf_pivot_deprecated_in_4_4_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.bbf_pivot(IN src_sql TEXT, IN cat_sql TEXT, IN agg_func TEXT)
RETURNS setof record
AS 'babelfishpg_tsql', 'bbf_pivot'
LANGUAGE C STABLE;

DO $$
DECLARE
    exception_message text;
BEGIN
    -- DROP bbf_pivot_deprecated_in_4_4_0
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_pivot_deprecated_in_4_4_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- Assigning dbo role to the db_owner login
DO $$
DECLARE
    owner_name NAME;
    db_name TEXT;
    role_name NAME;
    owner_cursor CURSOR FOR SELECT DISTINCT owner, name FROM sys.babelfish_sysdatabases;
BEGIN
    OPEN owner_cursor;
    FETCH NEXT FROM owner_cursor INTO owner_name, db_name;

    WHILE FOUND
    LOOP
        SELECT rolname FROM sys.babelfish_authid_user_ext WHERE database_name = db_name INTO role_name;

        IF db_name = 'master' OR db_name = 'tempdb' OR db_name = 'msdb'
        THEN
            FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
            CONTINUE;
        END IF;

        EXECUTE FORMAT('GRANT %I TO %I', role_name, owner_name);

        FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
    END LOOP;

    CLOSE owner_cursor;
END;
$$ LANGUAGE plpgsql;

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
    v_datatype := trim(regexp_replace(p_datatype COLLATE "C", 'DATETIME', 'TIME', 'gi'));
    v_timestring := pg_catalog.upper(trim(p_timestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_src_datatype := pg_catalog.upper(v_datatype_groups[1]);
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
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
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

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT,
														IN p_moneyval PG_CATALOG.MONEY,
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
	v_res_length SMALLINT;
	MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
	v_result TEXT;
BEGIN
	v_style := floor(p_style)::SMALLINT;
	v_digits := length(v_moneyabs::TEXT);
	v_decimal_digits := scale(v_moneyabs);
	IF (v_decimal_digits > 0) THEN
		v_integral_digits := v_digits - v_decimal_digits - 1;
	ELSE
		v_integral_digits := v_digits;
	END IF;
	IF (v_style = 0) THEN
		v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D99';
		v_result := to_char(v_moneyval, v_format);
	ELSIF (v_style = 1) THEN
		IF (v_moneysign::SMALLINT = 1) THEN
			v_result := substring(p_moneyval::TEXT, 2);
		ELSE
			v_result := substring(p_moneyval::TEXT, 1, 1) || substring(p_moneyval::TEXT, 3);
		END IF;
	ELSIF (v_style = 2) THEN
		v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D9999';
		v_result := to_char(v_moneyval, v_format);
	ELSE
		RAISE invalid_parameter_value;
	END IF;
	v_res_length := substring(p_datatype COLLATE "C", MASK_REGEXP)::SMALLINT;
	IF v_res_length IS NULL THEN
		RETURN v_result;
	ELSE
		RETURN rpad(v_result, v_res_length, ' ');
	END IF;
EXCEPTION
	WHEN invalid_parameter_value THEN
		RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from MONEY to a character string.', v_style),
					DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
					HINT := 'Change "style" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT,
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
			v_result := to_char(v_sign * ceiling(v_floatval), v_format);
			v_result := to_char(substring(v_result, 1, 8)::NUMERIC, 'FM9D99999')::NUMERIC::TEXT || substring(v_result, 9);
		ELSE
			if (6 - v_integral_digits < v_decimal_digits) THEN
				v_decimal_digits := 6 - v_integral_digits;
			END IF;
			v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D';
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
		RETURN v_result;
	ELSE
		RETURN rpad(v_result,  v_res_length, ' ');
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

CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = '' COLLATE sys.database_default
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE 
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

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
    bbf_schema_name text COLLATE sys.database_default;
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
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name COLLATE sys.database_default) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
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
                    WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
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
    json_path_convert = regexp_replace(json_path COLLATE "C", '\$\.|]|\$\[' , '' , 'ig'); -- To remove "$." and "]" sign from the string 
    json_path_convert = regexp_replace(json_path_convert COLLATE "C", '\.|\[' , ',' , 'ig'); -- To replace "." and "[" with "," to change into required format
    new_jsonb_path = CONCAT('{',json_path_convert,'}'); -- Final required format of path by jsonb_set

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

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
DECLARE
    is_windows_grp boolean := (CHARINDEX('\', role) != 0);
BEGIN
    -- Always return 1 for 'public'
    IF (role = 'public' COLLATE sys.database_default )
    THEN RETURN 1;
    END IF;

    IF EXISTS (SELECT orig_loginname FROM sys.babelfish_authid_login_ext WHERE orig_loginname = role COLLATE sys.database_default AND type != 'S') -- do not consider sql logins
    THEN
        IF ((EXISTS (SELECT name FROM sys.login_token WHERE name = role COLLATE sys.database_default AND type IN ('SERVER ROLE', 'SQL LOGIN'))) OR is_windows_grp) -- do not consider sql logins, server roles
        THEN RETURN NULL; -- Also return NULL if session is not a windows auth session but argument is a windows group
        ELSIF EXISTS (SELECT name FROM sys.login_token WHERE name = role COLLATE sys.database_default AND type NOT IN ('SERVER ROLE', 'SQL LOGIN'))
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSIF EXISTS (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE orig_username = role COLLATE sys.database_default)
    THEN
        IF EXISTS (SELECT name FROM sys.user_token WHERE name = role COLLATE sys.database_default)
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

	IF property = 'basetype' COLLATE "C"-- BaseType
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

CREATE OR REPLACE FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128))
RETURNS INT AS
$BODY$
DECLARE
ret_val INT;
BEGIN
	index_or_statistics_name = LOWER(TRIM(index_or_statistics_name)) COLLATE sys.database_default;
	property = LOWER(TRIM(property)) COLLATE sys.database_default;
    SELECT INTO ret_val
    CASE
       
        WHEN (SELECT CAST(type AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default) = 3 -- is XML index
        THEN CAST(NULL AS int)
	    
        WHEN property = 'indexdepth' COLLATE sys.database_default
        THEN CAST(0 AS int)

        WHEN property = 'indexfillfactor' COLLATE sys.database_default
        THEN (SELECT CAST(fill_factor AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'indexid' COLLATE sys.database_default
        THEN (SELECT CAST(index_id AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isautostatistics' COLLATE sys.database_default
        THEN CAST(0 AS int)

        WHEN property = 'isclustered' COLLATE sys.database_default
        THEN (SELECT CAST(CASE WHEN type = 1 THEN 1 ELSE 0 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isdisabled' COLLATE sys.database_default
        THEN (SELECT CAST(is_disabled AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isfulltextkey' COLLATE sys.database_default
        THEN CAST(0 AS int)
        
        WHEN property = 'ishypothetical' COLLATE sys.database_default
        THEN (SELECT CAST(is_hypothetical AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'ispadindex' COLLATE sys.database_default
        THEN (SELECT CAST(is_padded AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'ispagelockdisallowed' COLLATE sys.database_default
        THEN (SELECT CAST(CASE WHEN allow_page_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isrowlockdisallowed' COLLATE sys.database_default
        THEN (SELECT CAST(CASE WHEN allow_row_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id=$1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'isstatistics' COLLATE sys.database_default
        THEN CAST(0 AS int)
        
        WHEN property = 'isunique' COLLATE sys.database_default
        THEN (SELECT CAST(is_unique AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)
        
        WHEN property = 'iscolumnstore' COLLATE sys.database_default
        THEN CAST(0 AS int)
        
        WHEN property = 'isoptimizedforsequentialkey' COLLATE sys.database_default
        THEN CAST(0 AS int)
    ELSE
        CAST(NULL AS int)
    END;
RETURN ret_val;
END;
$BODY$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
	scale INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
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

	CASE v_type 
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
  v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
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

	CASE v_type
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

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  value_type text;
  enum_value text[];
  cnt int;
  cur refcursor;
  guc_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' collate "C" THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF PG_CATALOG.lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  IF cnt = 0 THEN 
    IF LOWER(normalized_name) = 'babelfishpg_tsql.escape_hatch_unique_constraint' COLLATE C THEN
      CALl sys.printarg('Config option babelfishpg_tsql.escape_hatch_unique_constraint has been deprecated, babelfish now supports unique constraints on nullable columns');
    ELSE
      RAISE EXCEPTION 'unknown configuration: %', normalized_name;
    END IF;
  ELSIF cnt > 1 AND (pg_catalog.lower("@option_value") != 'ignore' AND pg_catalog.lower("@option_value") != 'strict' 
                AND pg_catalog.lower("@option_value") != 'default') THEN
    RAISE EXCEPTION 'unvalid option: %', pg_catalog.lower("@option_value");
  END IF;

  OPEN cur FOR SELECT name FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  LOOP
    FETCH NEXT FROM cur into guc_name;
    exit when not found;

    SELECT boot_val, vartype, enumvals INTO default_value, value_type, enum_value FROM pg_catalog.pg_settings WHERE name = guc_name;
    IF pg_catalog.lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(guc_name, default_value, 'false');
    ELSIF pg_catalog.lower("@option_value") = 'ignore' or pg_catalog.lower("@option_value") = 'strict' THEN
      IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
      ELSE
        CONTINUE;
      END IF;
    ELSE
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF pg_catalog.lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, default_value);
      ELSIF pg_catalog.lower("@option_value") = 'ignore' or pg_catalog.lower("@option_value") = 'strict' THEN
        IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
          EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
        ELSE
          CONTINUE;
        END IF;
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
      END IF;
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_columns (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
	"@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		where pg_catalog.lower(table_name) like pg_catalog.lower(sys.babelfish_truncate_identifier(@table_name)) COLLATE database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner),'')) = '' or table_owner like sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier like sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name like sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier, precision from sys.sp_columns_100_view
			where sys.babelfish_truncate_identifier(@table_name) = table_name collate database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner), '')) = '' or table_owner = sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier = sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name = sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_columns_100 (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
	"@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
        -- TODO: Temporary fix to use '\' as escape character for now, need to remove ESCAPE clause from LIKE once we have fixed the dependencies on this procedure
		where pg_catalog.lower(table_name) like pg_catalog.lower(sys.babelfish_truncate_identifier(@table_name)) COLLATE database_default ESCAPE '\'
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner),'')) = '' or table_owner like sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier like sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name like sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier, precision from sys.sp_columns_100_view
			where sys.babelfish_truncate_identifier(@table_name) = table_name collate database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner), '')) = '' or table_owner = sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier = sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name = sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
END;
$$
LANGUAGE 'pltsql';

create or replace function sys.get_tds_id(
	datatype sys.varchar(50)
)
returns INT
AS $$
DECLARE
	tds_id INT;
BEGIN
	IF datatype IS NULL THEN
		RETURN 0;
	END IF;
	CASE datatype
		WHEN 'text' COLLATE sys.database_default THEN tds_id = 35;
		WHEN 'uniqueidentifier' COLLATE sys.database_default THEN tds_id = 36;
		WHEN 'tinyint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'smallint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'int' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'bigint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'ntext' COLLATE sys.database_default THEN tds_id = 99;
		WHEN 'bit' COLLATE sys.database_default THEN tds_id = 104;
		WHEN 'float' COLLATE sys.database_default THEN tds_id = 109;
		WHEN 'real' COLLATE sys.database_default THEN tds_id = 109;
		WHEN 'varchar' COLLATE sys.database_default THEN tds_id = 167;
		WHEN 'nvarchar' COLLATE sys.database_default THEN tds_id = 231;
		WHEN 'nchar' COLLATE sys.database_default THEN tds_id = 239;
		WHEN 'money' COLLATE sys.database_default THEN tds_id = 110;
		WHEN 'smallmoney' COLLATE sys.database_default THEN tds_id = 110;
		WHEN 'char' COLLATE sys.database_default THEN tds_id = 175;
		WHEN 'date' COLLATE sys.database_default THEN tds_id = 40;
		WHEN 'datetime' COLLATE sys.database_default THEN tds_id = 111;
		WHEN 'smalldatetime' COLLATE sys.database_default THEN tds_id = 111;
		WHEN 'numeric' COLLATE sys.database_default THEN tds_id = 108;
		WHEN 'xml' COLLATE sys.database_default THEN tds_id = 241;
		WHEN 'decimal' COLLATE sys.database_default THEN tds_id = 106;
		WHEN 'varbinary' COLLATE sys.database_default THEN tds_id = 165;
		WHEN 'binary' COLLATE sys.database_default THEN tds_id = 173;
		WHEN 'image' COLLATE sys.database_default THEN tds_id = 34;
		WHEN 'time' COLLATE sys.database_default THEN tds_id = 41;
		WHEN 'datetime2' COLLATE sys.database_default THEN tds_id = 42;
		WHEN 'sql_variant' COLLATE sys.database_default THEN tds_id = 98;
		WHEN 'datetimeoffset' COLLATE sys.database_default THEN tds_id = 43;
		WHEN 'timestamp' COLLATE sys.database_default THEN tds_id = 173;
		WHEN 'vector' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'sparsevec' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'halfvec' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'geometry' COLLATE sys.database_default THEN tds_id = 240;
		WHEN 'geography' COLLATE sys.database_default THEN tds_id = 240;
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = 'dbo',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select * from sys.sp_pkeys_view
	where table_name = @table_name
		and table_owner = coalesce(@table_owner, 'dbo') 
		and ((SELECT
		         coalesce(@table_qualifier, '')) = '' or
		         table_qualifier = @table_qualifier )
	order by table_qualifier,
	         table_owner,
		 table_name,
		 key_seq;
END; 
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_statistics(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where @table_name = table_name
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_statistics_100(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where @table_name = table_name
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF sys.user_name() != 'dbo' THEN
    RAISE EXCEPTION 'user does not have permission';
  END IF;

  IF pg_catalog.lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF pg_catalog.lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
-- Will use sp_column_priivleges_view to get information from SELECT, INSERT and REFERENCES (only need permission from 1 column in table)
SELECT DISTINCT
CAST(TABLE_QUALIFIER AS sys.sysname) COLLATE sys.database_default AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) COLLATE sys.database_default AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) COLLATE sys.database_default AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) COLLATE sys.database_default AS IS_GRANTABLE
FROM sys.sp_column_privileges_view

UNION 
-- We need these set of joins only for the DELETE privilege
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type = 'DELETE'; 

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
	role  := TRIM(trailing from LOWER(role));
	login := TRIM(trailing from LOWER(login));
	
	login_valid = (login = suser_name() COLLATE sys.database_default) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				LOWER(name) = login COLLATE sys.database_default
				AND type = 'S'));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' COLLATE sys.database_default THEN
    	RETURN 1;
	
 	ELSIF role = 'sysadmin' COLLATE sys.database_default THEN
	  	has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
	    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role COLLATE sys.database_default IN (
            'serveradmin',
            'securityadmin',
            'setupadmin',
            'securityadmin',
            'processadmin',
            'dbcreator',
            'diskadmin',
            'bulkadmin') THEN 
    	RETURN 0;
 	
    ELSE
 		  RETURN NULL;
 	END IF;
	
 	EXCEPTION WHEN OTHERS THEN
	 	  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE sys.sp_helpuser("@name_in_db" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If security account is not specified, return info about all users
	IF @name_in_db IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public'
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
					ELSE LogExt.orig_loginname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username != 'db_owner'
		ORDER BY UserName, RoleName;
	END
	-- If the security account is the db fixed role - db_owner
    ELSE IF @name_in_db = 'db_owner'
	BEGIN
		-- TODO: Need to change after we can add/drop members to/from db_owner
		SELECT CAST('db_owner' AS SYS.SYSNAME) AS 'Role_name',
			   ROLE_ID('db_owner') AS 'Role_id',
			   CAST('dbo' AS SYS.SYSNAME) AS 'Users_in_role',
			   USER_ID('dbo') AS 'Userid';
	END
	-- If the security account is a db role
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'Role_name',
			   CAST(Base1.oid AS INT) AS 'Role_id',
			   CAST(Ext2.orig_username AS SYS.SYSNAME) AS 'Users_in_role',
			   CAST(Base2.oid AS INT) AS 'Userid'
		FROM sys.babelfish_authid_user_ext AS Ext2
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.rolname = Ext2.rolname
		INNER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base2.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
		ORDER BY Role_name, Users_in_role;
	END
	-- If the security account is a user
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type != 'R')
	BEGIN
		SELECT DISTINCT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public' 
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
					ELSE LogExt.orig_loginname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
		ORDER BY UserName, RoleName;
	END
	-- If the security account is not valid
	ELSE 
		RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';

create or replace view sys.types As
with RECURSIVE type_code_list as
(
    select distinct  pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
),
tt_internal as MATERIALIZED
(
  select * from sys.table_types_internal
)
-- For System types
select
  CAST(ti.tsql_type_name as sys.sysname) as name
  , cast(t.oid as int) as system_type_id
  , cast(t.oid as int) as user_type_id
  , cast(s.oid as int) as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(ti.tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , sys.tsql_type_precision_helper(ti.tsql_type_name, t.typtypmod) as precision
  , sys.tsql_type_scale_helper(ti.tsql_type_name, t.typtypmod, false) as scale
  , CASE
        WHEN t.typcollation = 0 THEN CAST(NULL as sys.sysname)
        ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE name = db_name() COLLATE "C") as sys.sysname)
    END as collation_name
  , case when typnotnull then cast(0 as sys.bit) else cast(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_user_defined
  , CASE ti.tsql_type_name
    -- CLR UDT have is_assembly_type = 1
    WHEN 'geometry' THEN CAST(1 as sys.bit)
    WHEN 'geography' THEN CAST(1 as sys.bit)
    ELSE  CAST(0 as sys.bit)
    END as is_assembly_type
  , CAST(0 as int) as default_object_id
  , CAST(0 as int) as rule_object_id
  , CAST(0 as sys.bit) as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
inner join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
where
ti.tsql_type_name IS NOT NULL
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as sys.sysname) as name
  , cast(t.typbasetype as int) as system_type_id
  , cast(t.oid as int) as user_type_id
  , cast(t.typnamespace as int) as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) end as precision
  , case when tt.typrelid is not null then 0::sys.tinyint else sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) end as scale
  , CASE
        WHEN t.typcollation = 0 THEN CAST(NULL as sys.sysname)
        ELSE CAST((SELECT default_collation FROM babelfish_sysdatabases WHERE name = db_name() COLLATE "C") as sys.sysname)
    END as collation_name
  , case when tt.typrelid is not null then cast(0 as sys.bit)
         else case when typnotnull then cast(0 as sys.bit) else cast(1 as sys.bit) end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , CAST(1 as sys.bit) as is_user_defined
  , CASE tsql_base_type_name
    -- CLR UDT have is_assembly_type = 1
    WHEN 'geometry' THEN CAST(1 as sys.bit)
    WHEN 'geography' THEN CAST(1 as sys.bit)
    ELSE  CAST(0 as sys.bit)
    END as is_assembly_type
  , CAST(0 as int) as default_object_id
  , CAST(0 as int) as rule_object_id
  , case when tt.typrelid is not null then CAST(1 as sys.bit) else CAST(0 as sys.bit) end as is_table_type
from pg_type t
join sys.schemas sch on t.typnamespace = sch.schema_id
left join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
left join tt_internal tt on t.typrelid = tt.typrelid
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
-- we want to show details of user defined datatypes created under babelfish database
where 
 ti.tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    tt.typrelid is not null  
  );
GRANT SELECT ON sys.types TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_os_sys_info 
AS SELECT 
  CAST(0 AS BIGINT) AS cpu_ticks,
  CAST(ROUND(EXTRACT(EPOCH FROM NOW()) * 1000.0, 0) AS BIGINT) AS ms_ticks, 
  CAST(0 AS INT) AS cpu_count,
  CAST(0 AS INT) AS hyperthread_ratio,
  CAST(0 AS BIGINT) AS physical_memory_kb,
  CAST(0 AS BIGINT) AS virtual_memory_kb,
  CAST(0 AS BIGINT) AS committed_kb,
  CAST(0 AS BIGINT) AS committed_target_kb,
  CAST(0 AS BIGINT) AS visible_target_kb,
  CAST(0 AS INT) AS stack_size_in_bytes,
  CAST(0 AS BIGINT) AS os_quantum,
  CAST(0 AS INT) AS os_error_mode,
  CAST(0 AS INT) AS os_priority_class,
  CAST(0 AS INT) AS max_workers_count,
  CAST(0 AS INT) AS scheduler_count,
  CAST(0 AS INT) AS scheduler_total_count,
  CAST(0 AS INT) AS deadlock_monitor_serial_number,
  CAST(ROUND(EXTRACT(EPOCH FROM pg_postmaster_start_time()) * 1000.0, 0) AS BIGINT) AS sqlserver_start_time_ms_ticks, 
  CAST(pg_postmaster_start_time() AS sys.DATETIME) AS sqlserver_start_time,
  CAST(0 AS INT) AS affinity_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS affinity_type_desc,
  CAST(0 AS BIGINT) AS process_kernel_time_ms,
  CAST(0 AS BIGINT) AS process_user_time_ms,
  CAST(0 AS INT) AS time_source,
  CAST(NULL AS sys.NVARCHAR(60)) AS time_source_desc,
  CAST(0 AS INT) AS virtual_machine_type,
  CAST('NONE' AS sys.NVARCHAR(60)) AS virtual_machine_type_desc,
  CAST(0 AS INT) AS softnuma_configuration,
  CAST('OFF' AS sys.NVARCHAR(60)) AS softnuma_configuration_desc,
  CAST(NULL AS sys.NVARCHAR(3072)) AS process_physical_affinity,
  CAST(0 AS INT) AS sql_memory_model,
  CAST(NULL AS sys.NVARCHAR(60)) AS sql_memory_model_desc,
  CAST(0 AS INT) AS socket_count,
  CAST(0 AS INT) AS cores_per_socket,
  CAST(0 AS INT) AS numa_node_count,
  CAST(0 AS INT) AS container_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS container_type_desc;
GRANT SELECT ON sys.dm_os_sys_info TO PUBLIC;

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
INNER JOIN pg_attribute a ON a.attrelid = sc.out_object_id AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = NULL,
    "@table_owner" sys.nvarchar(384) = NULL, 
    "@table_qualifier" sys.sysname = NULL,
    "@table_type" sys.nvarchar(100) = NULL,
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN

	-- Handle special case: Enumerate all databases when name and owner are blank but qualifier is '%'
	IF (@table_qualifier = '%' AND @table_owner = '' AND @table_name = '')
	BEGIN
		SELECT
			d.name AS TABLE_QUALIFIER,
			CAST(NULL AS sys.sysname) AS TABLE_OWNER,
			CAST(NULL AS sys.sysname) AS TABLE_NAME,
			CAST(NULL AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(NULL AS sys.varchar(254)) AS REMARKS
		FROM sys.databases d ORDER BY TABLE_QUALIFIER;
		
		RETURN;
	END;

	IF (@table_qualifier != '' AND LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF (@fusepattern = 1)
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view 
		WHERE (@table_name IS NULL OR table_name LIKE @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner LIKE @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier LIKE @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
	ELSE
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view
		WHERE (@table_name IS NULL OR table_name = @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner = @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier = @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

ALTER FUNCTION sys.sp_tables_internal RENAME TO sp_tables_internal_deprecated_in_4_4_0;

ALTER FUNCTION sys.sp_columns_100_internal RENAME TO sp_columns_100_internal_deprecated_in_4_4_0;

ALTER FUNCTION sys.sp_statistics_internal RENAME TO sp_statistics_internal_deprecated_in_4_4_0;

ALTER FUNCTION sys.sp_pkeys_internal RENAME TO sp_pkeys_internal_deprecated_in_4_4_0;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sp_tables_internal_deprecated_in_4_4_0');

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sp_columns_100_internal_deprecated_in_4_4_0');

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sp_statistics_internal_deprecated_in_4_4_0');

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sp_pkeys_internal_deprecated_in_4_4_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

CREATE OR REPLACE PROCEDURE sys.sp_reset_connection()
AS 'babelfishpg_tsql', 'sp_reset_connection_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_reset_connection() TO PUBLIC;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
