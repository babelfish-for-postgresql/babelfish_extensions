SELECT * FROM OPENQUERY(bbf_server, 'SELECT 123')
GO

-- check whether query timeout value is getting persisted after the upgrade
SELECT name, query_timeout FROM sys.servers WHERE name = 'bbf_server_1'
GO

-- should throw error as it takes more than 5 seconds to run
SELECT * FROM OPENQUERY(bbf_server_1, 'select CAST(pg_sleep(5) AS text)')
GO

-- check whether connect_timeout value is getting persisted after the upgrade
SELECT name, connect_timeout FROM sys.servers WHERE name = 'bbf_server_2'
GO

-- should throw connection timeout error in one second as the server does not exist
SELECT * FROM OPENQUERY(bbf_server_2, 'select 1')
GO

-- SELECT * FROM openquery_vu_prepare__openquery_view
GO

EXEC openquery_upgrd_vu_prepare__openquery_proc
GO

SELECT openquery_upgrd_vu_prepare__openquery_func()
GO
