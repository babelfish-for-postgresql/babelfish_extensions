SELECT * FROM babelfish_sysdatabases_vu_prepare_view
GO

EXEC babelfish_sysdatabases_vu_prepare_proc
GO

SELECT babelfish_sysdatabases_vu_prepare_func()
GO

SELECT name FROM sys.babelfish_sysdatabases WHERE name LIKE 'babelfish_sysdatabases_vu_prepare_db%'
ORDER BY name
GO
