-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.1.0'" to load this file. \quit
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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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
	ELSE
		RETURN CAST(arg AS sys.VARCHAR);
	END CASE;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_money_to_string(TEXT, PG_CATALOG.MONEY, NUMERIC) RENAME TO babelfish_try_conv_money_to_string_deprecated_in_5_1_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT,
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
		v_format := (pow(10, v_integral_digits)-10)::TEXT || 'D99';
		v_result := pg_catalog.btrim(to_char(v_moneyval, v_format));
	ELSIF (v_style = 1) THEN
		IF (v_moneysign::SMALLINT = -1) THEN
			v_result := substring(p_moneyval::PG_CATALOG.MONEY::TEXT, 1, 1) || substring(p_moneyval::PG_CATALOG.MONEY::TEXT, 3);
		ELSE
			v_result := substring(p_moneyval::PG_CATALOG.MONEY::TEXT, 2);
		END IF;
	ELSIF (v_style = 2 OR v_style = 126) THEN
		v_format := (pow(10, v_integral_digits)-10)::TEXT || 'D9999';
		v_result := pg_catalog.btrim(to_char(v_moneyval, v_format));
	ELSE
		RAISE invalid_parameter_value;
	END IF;

	RETURN v_result;
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

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_money_to_string_deprecated_in_5_1_0'); 

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
