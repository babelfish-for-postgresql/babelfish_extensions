CREATE DATABASE db_sys_databases
GO

CREATE VIEW sys_databases_view AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'db_sys_databases'
GO

CREATE PROC sys_databases_proc AS
SELECT name, compatibility_level, collation_name FROM sys.databases WHERE name = 'db_sys_databases'
GO

CREATE FUNCTION sys_databases_func()
RETURNS TINYINT
AS
BEGIN
    RETURN (SELECT compatibility_level FROM sys.databases WHERE name = 'db_sys_databases')
END
GO
