CREATE USER :user WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT;
DROP DATABASE IF EXISTS :db;
CREATE DATABASE :db OWNER :user;
\c :db
SET allow_system_table_mods = ON;
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;
GRANT ALL ON SCHEMA sys to :user;
ALTER USER :user CREATEDB;
ALTER SYSTEM SET babelfishpg_tsql.database_name = :db;
ALTER SYSTEM SET babelfishpg_tds.set_db_session_property = true;
SELECT pg_reload_conf();
CALL SYS.INITIALIZE_BABELFISH(:'user');
