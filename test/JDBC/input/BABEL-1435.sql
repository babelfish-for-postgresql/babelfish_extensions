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

-- Set current_user for testing db mode
IF (SELECT 1 FROM pg_roles WHERE rolname='jdbc_user') = 1
BEGIN
	WITH SET_CTE
	AS
	(SELECT set_config('role', 'jdbc_user', false))
	SELECT NULL
	FROM SET_CTE
END
ELSE
BEGIN
	WITH SET_CTE
	AS
	(SELECT set_config('role', 'babeltestuser', false))
	SELECT NULL
	FROM SET_CTE
END
GO

-- test multi-db mode 
SELECT set_config('babelfishpg_tsql.migration_mode', 'multi-db', false);
GO

SELECT name FROM sys.sysdatabases ORDER BY name;
GO

CREATE DATABASE db1;
GO

-- test error
CREATE DATABASE db1;
GO

CREATE DATABASE db2;
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'db1_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db1_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'db1_dbo';
GO

SELECT COUNT(*) FROM pg_roles where rolname = 'db2_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db2_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'db2_dbo';
GO

DROP DATABASE db1;
GO

DROP DATABASE db2;
GO

SELECT name FROM sys.sysdatabases ORDER BY name;
GO

SELECT set_config('babelfishpg_tsql.migration_mode', 'single-db', false);
GO
