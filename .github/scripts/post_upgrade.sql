CREATE CAST (pg_catalog.BOOL as sys.BPCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

CREATE CAST (pg_catalog.BOOL as sys.VARCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

ALTER EXTENSION babelfishpg_common ADD CAST (boolean as sys.bpchar);
ALTER EXTENSION babelfishpg_common ADD CAST (boolean as sys.varchar);

ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';
ALTER SYSTEM SET babelfishpg_tsql.migration_mode = 'multi-db';
SELECT pg_reload_conf();
