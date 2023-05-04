SELECT * FROM OPENQUERY(bbf_server, 'SELECT 123')
GO

-- should throw error as it takes more than 5 seconds to run
SELECT * FROM OPENQUERY(bbf_server_1, 'select CAST(pg_sleep(5) AS text)')
GO

-- SELECT * FROM openquery_vu_prepare__openquery_view
GO