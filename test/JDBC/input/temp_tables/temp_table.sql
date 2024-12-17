USE master
GO

-- BABEL-4912 test ALTER TABLE for temp tables
CREATE TABLE #t1 (a INT IDENTITY PRIMARY KEY NOT NULL, b INT)
GO

INSERT INTO #t1 (b) values (1)
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 DROP COLUMN b
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 ADD b varchar(20)
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 ADD c AS a + 1
GO

SELECT * FROM #t1
GO

-- should throw error due to generated column
ALTER TABLE #t1 DROP COLUMN a
GO

SELECT * FROM #t1
GO

-- BABEL-5273 ALTER COLUMN to another type
ALTER TABLE #t1 ALTER COLUMN b CHAR(5)
GO

INSERT INTO #t1 (b) VALUES ('hello')
GO

SELECT * FROM #t1
GO

-- should fail due to possible truncation
ALTER TABLE #t1 ALTER COLUMN b CHAR(4)
GO

DELETE FROM #t1 WHERE b = 'hello'
GO

-- try all other TSQL types
ALTER TABLE #t1 ALTER COLUMN b TINYINT
GO

ALTER TABLE #t1 ALTER COLUMN b SMALLINT
GO

ALTER TABLE #t1 ALTER COLUMN b INT
GO

ALTER TABLE #t1 ALTER COLUMN b BIGINT
GO

ALTER TABLE #t1 ALTER COLUMN b BIT
GO

ALTER TABLE #t1 ALTER COLUMN b DECIMAL
GO

ALTER TABLE #t1 ALTER COLUMN b NUMERIC
GO

ALTER TABLE #t1 ALTER COLUMN b MONEY
GO

ALTER TABLE #t1 ALTER COLUMN b SMALLMONEY
GO

ALTER TABLE #t1 ALTER COLUMN b FLOAT
GO

ALTER TABLE #t1 ALTER COLUMN b REAL
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b DATE
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b TIME
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b DATETIME2
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b DATETIMEOFFSET
GO

ALTER TABLE #t1 ALTER COLUMN b DATETIME
GO

ALTER TABLE #t1 ALTER COLUMN b SMALLDATETIME
GO

ALTER TABLE #t1 ALTER COLUMN b CHAR
GO

ALTER TABLE #t1 ALTER COLUMN b VARCHAR
GO

-- TODO: fix this, it should work and not raise a syntax error
ALTER TABLE #t1 ALTER COLUMN b TEXT
GO

ALTER TABLE #t1 ALTER COLUMN b NCHAR
GO

ALTER TABLE #t1 ALTER COLUMN b NVARCHAR
GO

ALTER TABLE #t1 ALTER COLUMN b NTEXT
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b BINARY
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b VARBINARY
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b IMAGE
GO

-- TODO: should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b GEOGRAPHY
GO

-- should raise error due to incompatible types
ALTER TABLE #t1 ALTER COLUMN b GEOMETRY
GO

-- TODO: fix this, it should work and not raise a syntax error
ALTER TABLE #t1 ALTER COLUMN b XML
GO

ALTER TABLE #t1 DROP COLUMN b
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 DROP COLUMN c
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO

-- BABEL-4868 disallow the usage of user-defined functions in temp table column defaults (to prevent orphaned catalog entries)
CREATE FUNCTION temp_table_func1(@a INT) RETURNS INT AS BEGIN RETURN 1 END
GO

-- normal tables should be ok
CREATE TABLE temp_table_t1(a INT DEFAULT temp_table_func1(5))
GO

INSERT INTO temp_table_t1 VALUES (DEFAULT)
GO

SELECT * FROM temp_table_t1
GO

DROP TABLE temp_table_t1
GO

-- temp tables should not work
CREATE TABLE #t1 (a INT DEFAULT temp_table_func1(5))
GO

-- two and three part names should not work either
CREATE TABLE #t1 (a INT DEFAULT dbo.temp_table_func1(6))
GO

CREATE TABLE #t1 (a INT DEFAULT master.dbo.temp_table_func1(7))
GO

-- also block adding columns via ALTER TABLE
CREATE TABLE #t1 (a INT)
GO

ALTER TABLE #t1 ADD b INT DEFAULT temp_table_func1(5)
GO

DROP TABLE #t1
GO

-- same with table variables
DECLARE @tv TABLE (a INT DEFAULT temp_table_func1(5))
INSERT INTO @tv VALUES (DEFAULT)
SELECT * FROM @tv
GO

-- system functions such as ISJSON() should work
CREATE TABLE #t1 (a INT DEFAULT ISJSON('a'))
GO

ALTER TABLE #t1 ADD b INT DEFAULT ISJSON('b')
GO

INSERT INTO #t1 VALUES (DEFAULT, DEFAULT)
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO

DECLARE @tv TABLE (a INT DEFAULT ISJSON('a'))
INSERT INTO @tv VALUES (DEFAULT)
SELECT * FROM @tv
GO

-- disallow "sys"-qualified function calls
CREATE TABLE #t1 (a INT DEFAULT SYS.ISJSON('a'))
GO

-- disallow user-defined overrides for system functions
CREATE FUNCTION ISJSON(@json TEXT) RETURNS INT AS BEGIN RETURN 10 END
GO

-- cannot use schema-qualified name
CREATE TABLE #t1 (a INT DEFAULT dbo.ISJSON('a'))
GO

-- should work, default to using the system function
CREATE TABLE #t1 (a INT DEFAULT ISJSON('a'))
GO

INSERT INTO #t1 VALUES (DEFAULT)
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO

-- Aggregate functions should not work
create table #t1(a int, b int default any_value(a))
go

create table #t1(a int, b int default any_value(1))
go

-- also validate that the restrictions work for ALTER TABLE ADD CONSTRAINT
CREATE TABLE #t1 (a INT)
GO

-- user-defined functions should not work
ALTER TABLE #t1 ADD CONSTRAINT myconstraint DEFAULT temp_table_func1(5) FOR a
GO

-- nor should system function overrides
ALTER TABLE #t1 ADD CONSTRAINT myconstraint DEFAULT dbo.ISJSON('a') FOR a
GO

-- but system functions should still work
ALTER TABLE #t1 ADD CONSTRAINT myconstraint DEFAULT ISJSON('a') FOR a
GO

INSERT INTO #t1 VALUES (DEFAULT)
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO

DROP FUNCTION dbo.ISJSON
GO

DROP FUNCTION temp_table_func1
GO
