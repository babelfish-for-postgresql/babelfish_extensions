
-- list all the babelfish catalogs that has not been analyzed manually after upgrade
-- will return null 
SELECT * FROM auto_analyze_vu_prepare_catalogs_have_not_been_analyzed()
GO

DROP FUNCTION auto_analyze_vu_prepare_catalogs_have_not_been_analyzed
GO

DROP FUNCTION auto_analyze_vu_prepare_catalogs_have_been_analyzed
GO