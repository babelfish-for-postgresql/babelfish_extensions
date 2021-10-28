 
#create test user and database from psql terminal
echo "============================== CREATING USER AND DATABASE =============================="
psql -U "$USER" -d postgres -a << EOF
CREATE USER jdbc_user WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT;
DROP DATABASE IF EXISTS jdbc_testdb;
CREATE DATABASE jdbc_testdb OWNER jdbc_user;
\c jdbc_testdb
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;
GRANT ALL ON SCHEMA sys to jdbc_user;
ALTER USER jdbc_user CREATEDB;
\c jdbc_testdb
ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';
ALTER SYSTEM SET babelfishpg_tds.set_db_session_property = true;
SELECT pg_reload_conf();
\c jdbc_testdb
show babelfishpg_tsql.database_name;
show babelfishpg_tds.set_db_session_property;
CALL sys.initialize_babelfish('jdbc_user');
EOF
echo "============================= BUILDING JDBC TEST FRAMEWORK ============================="
