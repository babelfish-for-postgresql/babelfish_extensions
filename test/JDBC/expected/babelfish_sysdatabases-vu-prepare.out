CREATE DATABASE babelfish_sysdatabases_vu_prepare_db
GO

CREATE VIEW babelfish_sysdatabases_vu_prepare_view
AS
SELECT name, owner, default_collation 
FROM sys.babelfish_sysdatabases 
WHERE name LIKE 'babelfish_sysdatabases_vu_prepare_db%'
ORDER BY name
GO

CREATE PROC babelfish_sysdatabases_vu_prepare_proc
AS
SELECT name, owner, default_collation 
FROM sys.babelfish_sysdatabases 
WHERE name LIKE 'babelfish_sysdatabases_vu_prepare_db%'
ORDER BY name
GO

CREATE FUNCTION babelfish_sysdatabases_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_sysdatabases WHERE name LIKE 'babelfish_sysdatabases_vu_prepare_db%')
END
GO
