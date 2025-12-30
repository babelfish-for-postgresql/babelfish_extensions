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
    IF (arg_datatype = 'datetime' OR arg_datatype = 'timestamp') THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 3);
    END IF;
    IF arg_datatype = 'datetime2' THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 4);
    END IF;
    IF arg_datatype = 'datetimeoffset' THEN
        return sys.dateadd_internal_df(datepart, num, startdate);
    END IF;
    RAISE EXCEPTION 'Conversion failed when converting date and/or time from %.', pg_typeof(startdate);
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE parallel safe;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
