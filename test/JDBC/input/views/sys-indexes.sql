SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.indexes');
GO

DROP TABLE IF EXISTS t_sys_index_test1
GO

DROP TABLE IF EXISTS t_sys_no_index
GO

CREATE TABLE t_sys_index_test1 (
	c1 INT, 
	c2 VARCHAR(128)
);
GO

CREATE TABLE t_sys_no_index (
	c1 INT, 
	c2 VARCHAR(128)
);
GO

INSERT INTO t_sys_index_test1 (c1, c2) VALUES
(100, 'abc'),
(200, 'bcd'),
(300, 'cde'),
(1400, 'def')
GO

-- two NONCLUSTERED indexes created
CREATE INDEX i_sys_index_test1 ON t_sys_index_test1 (c1);
CREATE INDEX i_sys_index_test1a ON t_sys_index_test1 (c2);
GO

-- should return 3, two rows for NONCLUSTERED indexes and one for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1');
GO

-- should return 1, one row for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_no_index')
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_no_index');
GO

CREATE DATABASE db1
GO

USE db1
GO

-- index "t_sys_index_test1" should not be visible here
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

USE master
GO

DROP INDEX i_sys_index_test1 ON t_sys_index_test1;
DROP INDEX i_sys_index_test1a ON t_sys_index_test1;
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test%';
GO

DROP TABLE IF EXISTS t_pkey_table
GO
DROP TABLE IF EXISTS t_fkey_table
GO
CREATE TABLE t_pkey_table(c1 int PRIMARY KEY)
GO
CREATE TABLE t_fkey_table(c2 int)
GO
ALTER TABLE t_fkey_table ADD FOREIGN KEY(c2) REFERENCES t_pkey_table (c1);
GO
-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 0 for both cases
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('t_pkey_table')
GO

DROP TABLE IF EXISTS t_unique_index
GO
CREATE TABLE t_unique_index(c1 int UNIQUE NOT NULL)
GO
-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 1 for NONCLUSTERED case
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('t_unique_index')
GO

DROP TABLE IF EXISTS t_sys_index_test1
GO

DROP TABLE IF EXISTS t_sys_no_index
GO

DROP TABLE IF EXISTS t_fkey_table
GO

DROP TABLE IF EXISTS t_pkey_table
GO

DROP TABLE IF EXISTS t_unique_index
GO

DROP DATABASE db1
GO