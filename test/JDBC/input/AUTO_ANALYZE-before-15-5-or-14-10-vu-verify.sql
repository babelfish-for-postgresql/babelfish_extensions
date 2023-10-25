
-- list all the babel catalogs that has not been analyzed manually during extension upgrade
-- will return NULL in this case
SELECT relname FROM pg_stat_all_tables WHERE schemaname = 'sys' and last_analyze IS NULL order by relname
GO
