-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.10.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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
    ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) RENAME TO bbf_numeric_round_deprecated_3_10_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_round_deprecated_3_10_0');


DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) RENAME TO bbf_numeric_trunc_deprecated_3_10_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_trunc_deprecated_3_10_0');

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER) TO PUBLIC;



CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER) TO PUBLIC;



CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg sys.VARCHAR,
															IN try BOOL,
															IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
	RETURN sys.babelfish_conv_helper_to_datetime(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg sys.NVARCHAR,
															IN try BOOL,
															IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
	RETURN sys.babelfish_conv_helper_to_datetime(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg sys.bpchar,
															IN try BOOL,
															IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
	RETURN sys.babelfish_conv_helper_to_datetime(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg sys.NCHAR,
															IN try BOOL,
															IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
	RETURN sys.babelfish_conv_helper_to_datetime(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg anyelement,
															IN try BOOL,
															IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
DECLARE
	resdatetime sys.DATETIME;
BEGIN
	IF try THEN
		BEGIN
			resdatetime := CAST(arg AS sys.DATETIME);
		EXCEPTION
			WHEN cannot_coerce THEN
				RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
			WHEN OTHERS THEN
				RETURN NULL;
		END;
	ELSE
		BEGIN
			resdatetime := CAST(arg AS sys.DATETIME);
		EXCEPTION
			WHEN cannot_coerce THEN
				RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
			WHEN datetime_field_overflow THEN
				RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetime.';
		END;
	END IF;

	RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);