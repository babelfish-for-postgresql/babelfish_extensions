CREATE DATABASE db_sys_databases
GO

USE db_sys_databases
GO

CREATE VIEW sys_databases_view AS
SELECT database_id FROM sys.databases WHERE name = 'master'
GO

CREATE PROC sys_databases_proc AS
SELECT database_id FROM sys.databases WHERE name = 'master'
GO

CREATE FUNCTION sys_databases_func()
RETURNS TABLE
AS
RETURN (SELECT database_id FROM sys.databases WHERE name = 'master')
GO
