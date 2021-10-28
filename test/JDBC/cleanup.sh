echo "===================================== CLEANING UP ======================================"
psql -d postgres -U "$USER" << EOF
\c jdbc_testdb
CALL sys.remove_babelfish();
ALTER SYSTEM RESET babelfishpg_tsql.database_name;
ALTER SYSTEM RESET babelfishpg_tds.set_db_session_property;
SELECT pg_reload_conf();
\c postgres
DROP DATABASE jdbc_testdb WITH (FORCE);
DROP OWNED BY jdbc_user;
DROP USER jdbc_user;
EOF
