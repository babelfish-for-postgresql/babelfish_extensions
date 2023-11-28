-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.0.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

SELECT sys.babelfish_update_server_collation_name();

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

-- Created to to fetch default collation Oid which is being used to set collation of system objects
CREATE OR REPLACE FUNCTION sys.babelfishpg_tsql_get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_tsql', 'get_server_collation_oid';

-- Set the collation of given schema_name.table_name.column_name column to default collation
CREATE OR REPLACE PROCEDURE sys.babelfish_update_collation_to_default(schema_name varchar, table_name varchar, column_name varchar) AS
$$
DECLARE
    sys_schema oid;
    table_oid oid;
    att_coll oid;
    default_coll_oid oid;
    c_coll_oid oid;
BEGIN
    select oid into default_coll_oid from pg_collation where collname = 'default';
    select oid into c_coll_oid from pg_collation where collname = 'C';
    select oid into sys_schema from pg_namespace where nspname = schema_name collate sys.database_default;
    select oid into table_oid from pg_class where relname = table_name collate sys.database_default and relnamespace = sys_schema;
    select attcollation into att_coll from pg_attribute where attname = column_name collate sys.database_default and attrelid = table_oid;
    if att_coll = default_coll_oid or att_coll = c_coll_oid then
        update pg_attribute set attcollation = sys.babelfishpg_tsql_get_babel_server_collation_oid() where attname = column_name collate sys.database_default and attrelid = table_oid;
    end if;
END
$$
LANGUAGE plpgsql;

-- please add your SQL here

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

CALL sys.babelfish_update_collation_to_default('sys', 'babelfish_authid_user_ext_login_db_idx', 'database_name');
-- we have to reindex babelfish_authid_user_ext_login_db_idx because given index includes database_name and we have to change its collation
REINDEX INDEX sys.babelfish_authid_user_ext_login_db_idx;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
DROP PROCEDURE sys.babelfish_update_collation_to_default(varchar, varchar, varchar);
DROP FUNCTION  sys.babelfishpg_tsql_get_babel_server_collation_oid();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);