
-- list all the babel catalogs that has not been analyzed manually during extension create
-- will return NULL in this case
SELECT relname FROM pg_stat_all_tables WHERE schemaname = 'sys' and last_analyze IS NULL order by relname
Go

-- list all the babel catalogs that has been analyzed manually during extension create
SELECT relname FROM pg_stat_all_tables WHERE schemaname = 'sys' and last_analyze IS NOT NULL order by relname
Go