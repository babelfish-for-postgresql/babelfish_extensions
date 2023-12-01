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

ALTER FUNCTION sys.datepart_internal RENAME TO datepart_internal_deprecated_3_5;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datepart_internal_deprecated_3_5');


CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.BIT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.SMALLMONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_money'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.TINYINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date SMALLINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
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
AS 'babelfishpg_tsql', 'datepart_internal_smalldatetime'
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

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date REAL ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_real'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date NUMERIC ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_numeric'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date FLOAT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_float'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date INT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date BIGINT ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_int'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(field text, datapart_date sys.MONEY ,df_tz INTEGER DEFAULT 0)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'datepart_internal_money'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
