-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.9.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
