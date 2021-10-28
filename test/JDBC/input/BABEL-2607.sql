USE master
go

CREATE DATABASE babel_2607_db
go

-- This is to test if sp_helpdb can be executed successfully
-- Output are not fixed values, and sp_helpdb is a procedure which we cannot
-- control the output, so we run the underlying function instead
SELECT
	CASE WHEN name IS NOT NULL 
		AND owner IS NOT NULL
		AND dbid > 0
		AND created IS NOT NULL
	THEN 'correct' ELSE 'error' END
FROM babelfish_helpdb();
go

SELECT name, dbid
FROM babelfish_helpdb('master')
WHERE name = 'master'
go

SELECT name, dbid
FROM babelfish_helpdb('tempdb')
WHERE name = 'tempdb'
go

SELECT name
FROM babelfish_helpdb('babel_2607_db') 
WHERE name = 'babel_2607_db';
go

DROP DATABASE babel_2607_db
go
