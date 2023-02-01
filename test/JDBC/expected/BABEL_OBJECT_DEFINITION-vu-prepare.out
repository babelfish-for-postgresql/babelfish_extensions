CREATE DATABASE object_definition_db;
GO

USE object_definition_db;
GO

CREATE SCHEMA object_definition_sch;
GO

-- Default constraint
CREATE TABLE object_definition_t1(a int default 100);
GO

-- Check constraint
CREATE TABLE object_definition_t2(b char, check(b <> 'b'));
GO

-- Procedure
CREATE PROC object_definition_proc
AS
SELECT 1;
GO

-- Scalar function
CREATE FUNCTION object_definition_fc1(@fc1_a nvarchar) RETURNS nvarchar AS BEGIN return @fc1_a END;
GO

-- DML trigger
CREATE TRIGGER object_definition_tr1 ON object_definition_t1 INSTEAD OF INSERT
AS
BEGIN
SELECT * FROM object_definition_t1;
END
GO

-- Inline table-valued function
CREATE FUNCTION object_definition_itvf()
RETURNS table
AS
RETURN (SELECT 42 AS VALUE)
go

-- Table-valued function
CREATE FUNCTION object_definition_tvf()
RETURNS @testFuncTvf table (tvf int PRIMARY KEY)
AS
BEGIN
INSERT INTO @testFuncTvf VALUES (1)
RETURN
END;
GO

-- View
CREATE VIEW object_definition_sch.object_definition_v1
AS
SELECT * FROM object_definition_t2
GO

-- Dependency test
CREATE VIEW object_definition_v2
AS
SELECT COUNT(*) FROM OBJECT_DEFINITION(NULL);
GO
