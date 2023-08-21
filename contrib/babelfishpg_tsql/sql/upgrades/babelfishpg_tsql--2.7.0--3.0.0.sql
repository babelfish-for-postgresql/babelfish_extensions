-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.0.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

CALL sys.babelfish_update_collation_to_default('sys', 'babelfish_authid_user_ext_login_db_idx', 'database_name');
-- we have to reindex babelfish_authid_user_ext_login_db_idx because given index includes database_name and we have to change its collation
REINDEX INDEX sys.babelfish_authid_user_ext_login_db_idx;

DROP PROCEDURE sys.babelfish_update_collation_to_default(varchar, varchar, varchar);
DROP FUNCTION  sys.babelfishpg_tsql_get_babel_server_collation_oid();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
