SELECT * FROM test_babelfish_sysdatabases_view
GO

EXEC test_babelfish_sysdatabases_proc
GO

SELECT test_babelfish_sysdatabases_func()
GO

SELECT name FROM sys.babelfish_sysdatabases WHERE name LIKE 'test_babelfish_sysdatabases_db%'
GO
