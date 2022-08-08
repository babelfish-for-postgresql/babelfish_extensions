CREATE DATABASE sys_sysdatabases_vu_prepare_db
GO

CREATE VIEW sys_sysdatabases_vu_prepare_view
AS
SELECT name, cmptlevel 
FROM sys.sysdatabases 
WHERE name LIKE 'sys_sysdatabases_vu_prepare_db%'
ORDER BY name
GO

CREATE PROC sys_sysdatabases_vu_prepare_proc
AS
SELECT name, cmptlevel 
FROM sys.sysdatabases 
WHERE name LIKE 'sys_sysdatabases_vu_prepare_db%'
ORDER BY name
GO

CREATE FUNCTION sys_sysdatabases_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.sysdatabases WHERE name LIKE 'sys_sysdatabases_vu_prepare_db%')
END
GO
