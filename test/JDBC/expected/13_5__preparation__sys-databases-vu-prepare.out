CREATE DATABASE sys_databases_vu_prepare_db
GO

CREATE VIEW sys_databases_vu_prepare_view AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'sys_databases_vu_prepare_db'
GO

CREATE PROC sys_databases_vu_prepare_proc AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'sys_databases_vu_prepare_db'
GO

CREATE FUNCTION sys_databases_vu_prepare_func()
RETURNS TINYINT
AS
BEGIN
    RETURN (SELECT compatibility_level FROM sys.databases WHERE name = 'sys_databases_vu_prepare_db')
END
GO
