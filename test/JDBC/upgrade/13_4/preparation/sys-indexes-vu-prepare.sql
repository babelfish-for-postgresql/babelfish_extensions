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

CREATE DATABASE db1_sys_indexes
GO

USE db1_sys_indexes
GO

USE master
GO

CREATE TABLE t_pkey_table(c1 int PRIMARY KEY)
GO
CREATE TABLE t_fkey_table(c2 int)
GO
ALTER TABLE t_fkey_table ADD FOREIGN KEY(c2) REFERENCES t_pkey_table (c1);
GO

CREATE TABLE t_unique_index(c1 int UNIQUE NOT NULL)
GO
