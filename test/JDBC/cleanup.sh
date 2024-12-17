echo "===================================== CLEANING UP ======================================"
psql -d postgres -U "$USER" << EOF
\c babelfish_db
CALL sys.remove_babelfish();
ALTER SYSTEM RESET babelfishpg_tsql.database_name;
ALTER SYSTEM RESET babelfishpg_tsql.migration_mode;
SELECT pg_reload_conf();
\c postgres
DROP DATABASE babelfish_db WITH (FORCE);
DROP OWNED BY jdbc_user;
DROP USER jdbc_user;
EOF
