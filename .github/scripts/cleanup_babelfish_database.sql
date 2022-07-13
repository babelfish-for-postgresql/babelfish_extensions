\c :db
CALL SYS.REMOVE_BABELFISH();
ALTER SYSTEM RESET babelfishpg_tsql.database_name;
SELECT pg_reload_conf();
\c postgres
DROP DATABASE :db WITH (FORCE);
DROP OWNED BY :user;
DROP USER :user;
