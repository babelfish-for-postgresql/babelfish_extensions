USE MASTER;
GO

-- Expect an error. Test nullable identity column creation.
CREATE TABLE dbo.t1(id INT IDENTITY NULL, col1 INT);
go

CREATE TABLE dbo.t1(id INT IDENTITY NOT NULL, col1 INT);
go

CREATE TABLE dbo.t2(col1 INT);
go

-- Expect an error.
ALTER TABLE dbo.t2 ADD id INT IDENTITY NULL;
go

ALTER TABLE dbo.t2 ADD id INT IDENTITY NOT NULL;
go

CREATE TABLE dbo.test_table1(test_id INT IDENTITY(10, -1), test_col1 INT);
go

INSERT INTO test_table1 VALUES (2), (4), (8), (16);
go

SELECT * FROM test_table1;
go

CREATE TABLE dbo.test_table2(test_id INT IDENTITY(100, -20), test_col1 INT);
go

INSERT INTO test_table2 VALUES (2), (4), (8), (16);
go

SELECT * FROM test_table2;
go

CREATE TABLE dbo.test_table3(test_id INT IDENTITY(-10, 5), test_col1 INT);
go

INSERT INTO test_table3 VALUES (2), (4), (8), (16);
go

SELECT * FROM test_table3;
go

-- Test if TRUNCATE resets identity
INSERT INTO dbo.t1 VALUES (2), (4), (8), (16);
go

SELECT * FROM dbo.t1;
go

TRUNCATE TABLE dbo.t1;
GO

INSERT INTO dbo.t1 VALUES (2), (4), (8), (16);
go

SELECT * FROM dbo.t1;
go

TRUNCATE TABLE test_table1;
go

SELECT * FROM test_table1;
go

INSERT INTO test_table1 VALUES (2), (4), (8), (16);
go

SELECT * FROM test_table1;
go

-- Test preventing multiple identity columns
-- Expect error
CREATE TABLE dbo.t3(id1 INT IDENTITY, id2 INT IDENTITY);
GO

-- Expect error
CREATE TABLE dbo.t3(id1 NUMERIC IDENTITY, id2 INT IDENTITY, id3 DECIMAL IDENTITY);
GO

CREATE TABLE dbo.t3(id1 INT IDENTITY, c1 INT);
GO

-- Expect error
ALTER TABLE dbo.t3 ADD id2 INT IDENTITY;
GO

ALTER TABLE dbo.t3 DROP COLUMN id1;
GO

ALTER TABLE dbo.t3 ADD id1 INT IDENTITY;
GO

-- Expect error
ALTER TABLE dbo.t3 ADD id2 INT IDENTITY;
GO

CREATE TABLE dbo.t4(c1 INT);
GO

ALTER TABLE dbo.t4 ADD id2 SMALLINT IDENTITY;
GO

-- Expect error
ALTER TABLE dbo.t4 ADD id3 BIGINT IDENTITY;
GO

ALTER TABLE dbo.t4 DROP COLUMN id2;
GO

ALTER TABLE dbo.t4 ADD id2 SMALLINT IDENTITY;
GO

-- Expect error
ALTER TABLE dbo.t4 ADD id3 BIGINT IDENTITY;
GO

DROP TABLE dbo.t1, dbo.t2, dbo.t3, dbo.t4, dbo.test_table1, dbo.test_table2, dbo.test_table3;
GO
