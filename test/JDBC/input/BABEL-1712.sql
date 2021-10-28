--Under Single-DB mode
USE master;
GO
CREATE DATABASE db1;
GO
USE db1;
GO
CREATE schema test;
GO
SELECT nspname FROM pg_namespace WHERE nspname = 'test';
GO
CREATE table t1 ( a int, b int); -- should be created into dbo.t1
GO
INSERT INTO t1 VALUES ( 1, 1);
GO
SELECT * FROM t1;
GO
-- cross DB reference
USE master;
GO
SELECT * FROM t1; -- doesn't exist expected, querying master.dbo.t1
GO
SELECT * FROM db1.dbo.t1;
GO
SELECT * FROM dbo.t1; -- error expected, querying master.dbo.t1
GO
-- search path
USE db1;
GO
CREATE TABLE test.t1 ( a int, b int, c int);
GO
INSERT INTO test.t1 VALUES (1,2,3);
GO
SELECT * FROM t1; -- selecting 2 column db1.dbo.t1
GO
SELECT * FROM test.t1; -- selecting 3 column db1.test.t1
GO
USE MASTER;
GO
DROP DATABASE db1;
GO
