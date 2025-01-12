-- single_db_mode_expected
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

-- single-db
SELECT COUNT(*) FROM pg_roles where rolname = 'dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'dbo';
GO

-- multi-db
SELECT COUNT(*) FROM pg_roles where rolname = 'db1_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db1_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'db1_dbo';
GO

-- should raise error in single-db
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

-- should raise error in single-db
USE db2;
GO

DROP DATABASE db1;
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

USE master;
GO

DROP DATABASE db2;
GO

-- Tests for db level collation
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
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

SELECT name FROM sys.sysdatabases ORDER BY name;
GO

-- test error
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

-- single-db
SELECT COUNT(*) FROM pg_roles where rolname = 'dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'dbo';
GO

-- multi-db
SELECT COUNT(*) FROM pg_roles where rolname = 'db1_dbo';
SELECT COUNT(*) FROM pg_roles where rolname = 'db1_db_owner';
SELECT COUNT(*) FROM pg_namespace where nspname = 'db1_dbo';
GO

-- should raise error in single-db
CREATE DATABASE db2 COLLATE BBF_Unicode_CP1_CI_AI;
GO

USE db1;
GO

SELECT (case when db_id() = db_id('db1') then 'true' else 'false' end) result;
GO

USE master;
GO

SELECT (case when db_id() = db_id('master') then 'true' else 'false' end) result;
GO

-- should raise error in single-db
USE db2;
GO

DROP DATABASE db1;
GO


SELECT name FROM sys.sysdatabases ORDER BY name;
GO

CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

-- test error
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

CREATE DATABASE db2 COLLATE BBF_Unicode_CP1_CI_AI;
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

USE master;
GO

DROP DATABASE db2;
GO
