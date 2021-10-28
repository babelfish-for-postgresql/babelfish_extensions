USE master;
GO

CREATE SCHEMA test
GO

CREATE TABLE t (a int)
GO

CREATE PROCEDURE foo AS SELECT 1
GO

CREATE PROCEDURE test.bar AS SELECT 2
GO

SELECT * FROM t
GO

SELECT * FROM ..t
GO

SELECT * FROM master..t
GO

SELECT * FROM .fake_schema.t
GO

EXEC test.bar
GO

EXEC .test.bar
GO

EXEC master..bar
GO

EXEC ..bar
GO

EXEC foo
GO

EXEC ..foo
GO

EXEC master..foo
GO

EXEC .schema.foo
GO

DROP TABLE t
GO

DROP PROCEDURE foo
GO

DROP PROCEDURE test.bar
GO

DROP SCHEMA test
GO

