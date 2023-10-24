-- function to list all the babelfish catalogs that has not been analyzed manually
CREATE FUNCTION auto_analyze_vu_prepare_catalogs_have_not_been_analyzed()
RETURNS TABLE 
AS RETURN
(SELECT relname FROM pg_stat_all_tables WHERE schemaname = 'sys' and last_analyze IS NULL)
GO

-- function to list all the babelfish catalogs that has been analyzed manually
CREATE FUNCTION auto_analyze_vu_prepare_catalogs_have_been_analyzed()
RETURNS TABLE 
AS RETURN
(SELECT relname FROM pg_stat_all_tables WHERE schemaname = 'sys' and last_analyze IS NOT NULL)
GO


-- will return null as all of the catalog has been analyzed during extension create
SELECT * FROM auto_analyze_vu_prepare_catalogs_have_not_been_analyzed()
GO