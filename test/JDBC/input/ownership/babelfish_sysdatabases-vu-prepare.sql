CREATE DATABASE test_babelfish_sysdatabases_db
GO

CREATE VIEW test_babelfish_sysdatabases_view
AS
SELECT name, owner, default_collation 
FROM sys.babelfish_sysdatabases 
WHERE name LIKE 'test_babelfish_sysdatabases_db%'
ORDER BY name
GO

CREATE PROC test_babelfish_sysdatabases_proc
AS
SELECT name, owner, default_collation 
FROM sys.babelfish_sysdatabases 
WHERE name LIKE 'test_babelfish_sysdatabases_db%'
ORDER BY name
GO

CREATE FUNCTION test_babelfish_sysdatabases_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_sysdatabases WHERE name LIKE 'test_babelfish_sysdatabases_db%')
END
GO
