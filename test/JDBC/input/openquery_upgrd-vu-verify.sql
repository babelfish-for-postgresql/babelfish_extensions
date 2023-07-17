SELECT * FROM OPENQUERY(bbf_server, 'SELECT 123')
GO

-- check whether query timeout value is getting persisted after the upgrade
SELECT name, query_timeout FROM sys.servers WHERE name = 'bbf_server_1'
GO

-- should throw error as it takes more than 5 seconds to run
SELECT * FROM OPENQUERY(bbf_server_1, 'select CAST(pg_sleep(5) AS text)')
GO

-- SELECT * FROM openquery_vu_prepare__openquery_view
GO

EXEC openquery_upgrd_vu_prepare__openquery_proc
GO

SELECT openquery_upgrd_vu_prepare__openquery_func()
GO

-- Call OPENQUERY from a database other than master
USE tempdb
SELECT * FROM OPENQUERY(bbf_server, 'SELECT ''Called from tempdb''')
GO

CREATE DATABASE openquery_db
USE openquery_db
GO

SELECT * FROM OPENQUERY(bbf_server, 'SELECT ''Called from openquery_db''')
GO

USE master
DROP DATABASE openquery_db
GO
