CREATE USER :user WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT;
DROP DATABASE IF EXISTS :db;
CREATE DATABASE :db OWNER :user;
\c :db
SET allow_system_table_mods = ON;
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;
GRANT ALL ON SCHEMA sys to :user;
ALTER USER :user CREATEDB;
ALTER SYSTEM SET babelfishpg_tsql.database_name = :db;
ALTER SYSTEM SET babelfishpg_tsql.migration_mode = :'migration_mode';
ALTER SYSTEM SET babelfishpg_tds.port = :tsql_port;
ALTER SYSTEM SET track_functions = 'pl';

\if :parallel_query_mode
    ALTER SYSTEM SET parallel_setup_cost = 0;
    ALTER SYSTEM SET parallel_tuple_cost = 0;
    ALTER SYSTEM SET min_parallel_index_scan_size = 0;
    ALTER SYSTEM SET min_parallel_table_scan_size = 0;
    ALTER SYSTEM SET debug_parallel_query = 1;
    ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
\endif

SELECT pg_reload_conf();
CALL SYS.INITIALIZE_BABELFISH(:'user');
