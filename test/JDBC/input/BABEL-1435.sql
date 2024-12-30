-- Test inital databases
SELECT name FROM sys.sysdatabases ORDER BY name;
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'sysadmin';
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'master_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'master_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'master_dbo';
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'tempdb_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'tempdb_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'tempdb_dbo';
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'msdb_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'msdb_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'msdb_dbo';
GO

-- Test Create User Database
CREATE DATABASE db1;
GO

SELECT name FROM sys.sysdatabases ORDER BY name;
GO

-- test error
CREATE DATABASE db1;
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'dbo';
GO

CREATE DATABASE db2;
GO

USE db1;
GO

SELECT (case when db_id() = db_id('db1') then 'true' else 'false' end) result;
GO

USE master;
GO

SELECT (case when db_id() = db_id('master') then 'true' else 'false' end) result;
GO

-- test error
USE db2;
GO

DROP DATABASE db1;
GO
