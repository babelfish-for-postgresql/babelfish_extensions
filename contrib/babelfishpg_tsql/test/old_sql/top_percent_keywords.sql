-- Prove that TOP and PERCENT are keywords when babelfishpg_tsql.sql_dialect = tsql

SELECT set_config('babelfishpg_tsql.sql_dialect', 'tsql', false);
SELECT TOP 5 PERCENT relpages FROM pg_class;
CREATE TABLE percent(top int);

-- Prove that TOP and PERCENT are not keywords when babelfishpg_tsql.sql_dialect = postgres

SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
SELECT TOP 5 PERCENT relpages FROM pg_class;
CREATE TABLE percent(top int);

