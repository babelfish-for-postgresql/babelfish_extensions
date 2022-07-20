CREATE DATABASE db_sys_databases_vu_prepare
GO

CREATE VIEW sys_databases_view_vu_prepare AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'db_sys_databases_vu_prepare'
GO

CREATE PROC sys_databases_proc_vu_prepare AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'db_sys_databases_vu_prepare'
GO

CREATE FUNCTION sys_databases_func_vu_prepare()
RETURNS TINYINT
AS
BEGIN
    RETURN (SELECT compatibility_level FROM sys.databases WHERE name = 'db_sys_databases_vu_prepare')
END
GO
