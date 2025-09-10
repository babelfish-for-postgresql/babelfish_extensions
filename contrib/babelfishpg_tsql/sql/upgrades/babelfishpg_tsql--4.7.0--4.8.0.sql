-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.8.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, false) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.degrees(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.radians(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqrt(number PG_CATALOG.NUMERIC)
RETURNS sys.float
AS $$
BEGIN
    RETURN PG_CATALOG.SQRT(number::float8);
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);