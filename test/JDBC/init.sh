# Default values
parallel_query_mode=false

# Parse command-line flags/arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -enable_parallel_query)
        parallel_query_mode=true
        shift
        ;;
      *)
        # Unknown option
        exit 1
        ;;
    esac
    shift
done

# create test user and database from psql terminal
if [[ $parallel_query_mode = false ]]; then
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
SELECT pg_reload_conf();
\c jdbc_testdb
show babelfishpg_tsql.database_name;
CALL sys.initialize_babelfish('jdbc_user');
EOF
echo "============================= BUILDING JDBC TEST FRAMEWORK ============================="
fi

# create test user and database from psql terminal when parallel query mode is on
if [[ $parallel_query_mode = true ]]; then
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
ALTER SYSTEM SET parallel_setup_cost = 0;
ALTER SYSTEM SET parallel_tuple_cost = 0;
ALTER SYSTEM SET min_parallel_index_scan_size = 0;
ALTER SYSTEM SET min_parallel_table_scan_size = 0;
ALTER SYSTEM SET force_parallel_mode = 1;
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
SELECT pg_reload_conf();
\c jdbc_testdb
show babelfishpg_tsql.database_name;
CALL sys.initialize_babelfish('jdbc_user');
EOF
echo "============================= BUILDING JDBC TEST FRAMEWORK ============================="
fi
