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
DROP DATABASE IF EXISTS babelfish_db;
CREATE DATABASE babelfish_db OWNER jdbc_user;
\c babelfish_db
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;
GRANT ALL ON SCHEMA sys to jdbc_user;
ALTER USER jdbc_user CREATEDB;
\c babelfish_db
ALTER SYSTEM SET babelfishpg_tsql.database_name = 'babelfish_db';
ALTER SYSTEM SET babelfishpg_tsql.migration_mode = 'multi-db';
SELECT pg_reload_conf();
\c babelfish_db
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
DROP DATABASE IF EXISTS babelfish_db;
CREATE DATABASE babelfish_db OWNER jdbc_user;
\c babelfish_db
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;
GRANT ALL ON SCHEMA sys to jdbc_user;
ALTER USER jdbc_user CREATEDB;
\c babelfish_db
ALTER SYSTEM SET babelfishpg_tsql.database_name = 'babelfish_db';
ALTER SYSTEM SET babelfishpg_tsql.migration_mode = 'multi-db';
ALTER SYSTEM SET parallel_setup_cost = 0;
ALTER SYSTEM SET parallel_tuple_cost = 0;
ALTER SYSTEM SET min_parallel_index_scan_size = 0;
ALTER SYSTEM SET min_parallel_table_scan_size = 0;
ALTER SYSTEM SET debug_parallel_query = 1;
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
SELECT pg_reload_conf();
\c babelfish_db
show babelfishpg_tsql.database_name;
CALL sys.initialize_babelfish('jdbc_user');
EOF
echo "============================= BUILDING JDBC TEST FRAMEWORK ============================="
fi
