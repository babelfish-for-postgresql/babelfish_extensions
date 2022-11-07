CREATE SCHEMA ident_bifs;
GO

-- Test standard INSERTs
SELECT IDENT_SEED('ident_bifs.t1');
go
SELECT IDENT_INCR('ident_bifs.t1');
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
CREATE TABLE ident_bifs.t1(id INT IDENTITY, c1 INT);
go
SELECT @@IDENTITY;
go
SELECT IDENT_SEED('ident_bifs.t1');
go
SELECT IDENT_INCR('ident_bifs.t1');
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go

-- Test IDENTITY_INSERT
SET IDENTITY_INSERT ident_bifs.t1 ON;
go
INSERT INTO ident_bifs.t1 (id, c1) VALUES (10, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
INSERT INTO ident_bifs.t1 (id, c1) VALUES (-5, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
SET IDENTITY_INSERT ident_bifs.t1 OFF;
go

-- Test follow-up INSERTs
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go

-- Test new table with IDENTITY_INSERT
CREATE TABLE ident_bifs.t2(id INT IDENTITY, c1 INT);
go
SET IDENTITY_INSERT ident_bifs.t2 ON;
go
INSERT INTO ident_bifs.t2 (id, c1) VALUES (10, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go
SET IDENTITY_INSERT ident_bifs.t2 OFF;
go

-- Test follow-up INSERTs
INSERT INTO ident_bifs.t2 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go
INSERT INTO ident_bifs.t2 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go

-- Test follow-up INSERTs to the previous table
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
INSERT INTO ident_bifs.t1 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go

-- Test standard INSERTs with decrementing values
CREATE TABLE ident_bifs.t3(id INT IDENTITY(5, -25), c1 INT);
go
SELECT @@IDENTITY;
go
SELECT IDENT_SEED('ident_bifs.t3');
go
SELECT IDENT_INCR('ident_bifs.t3');
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go

-- Test IDENTITY_INSERT
SET IDENTITY_INSERT ident_bifs.t3 ON;
go
INSERT INTO ident_bifs.t3 (id, c1) VALUES (-500, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
INSERT INTO ident_bifs.t3 (id, c1) VALUES (10, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
SET IDENTITY_INSERT ident_bifs.t3 OFF;
go

-- Test follow-up INSERTs
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go

-- Test new table with IDENTITY_INSERT
CREATE TABLE ident_bifs.t4(id INT IDENTITY(-10, -1), c1 INT);
go
SELECT IDENT_SEED('ident_bifs.t4');
go
SELECT IDENT_INCR('ident_bifs.t4');
go
SELECT IDENT_CURRENT('ident_bifs.t4');
go
SET IDENTITY_INSERT ident_bifs.t4 ON;
go
INSERT INTO ident_bifs.t4 (id, c1) VALUES (-50, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t4');
go
SET IDENTITY_INSERT ident_bifs.t4 OFF;
go

-- Test follow-up INSERTs
INSERT INTO ident_bifs.t4 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t4');
go
INSERT INTO ident_bifs.t4 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t4');
go

-- Test follow-up INSERTs to the previous table
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
INSERT INTO ident_bifs.t3 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go

-- Test multi-inserts
SET IDENTITY_INSERT ident_bifs.t1 ON;
go
INSERT INTO ident_bifs.t1 (id, c1) VALUES (10, 42), (9999,42), (0, 42), (-100, 42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go
SET IDENTITY_INSERT ident_bifs.t1 OFF;
go

CREATE PROCEDURE ident_bifs.insertLoopT1
AS BEGIN
DECLARE @N INT
SET @N = 1
SET IDENTITY_INSERT ident_bifs.t1 ON
WHILE (@N < 10)
BEGIN
	INSERT INTO ident_bifs.t1 (id, c1) VALUES (@N*42, 42)
	SET @N = @N + 1
END
SET IDENTITY_INSERT ident_bifs.t1 OFF
END;
go

EXEC ident_bifs.insertLoopT1;
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t1');
go

-- Update the last identity value as a reference
INSERT INTO ident_bifs.t2 (c1) VALUES (42);
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go

-- Insert select and check that the last value changed to what is expected
SET IDENTITY_INSERT ident_bifs.t2 ON;
go
INSERT INTO ident_bifs.t2 (id, c1) SELECT * FROM ident_bifs.t1;
go
SELECT @@IDENTITY;
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go
SET IDENTITY_INSERT ident_bifs.t2 OFF;
go

-- Check value of each table in the session so far
SELECT IDENT_CURRENT('ident_bifs.t1');
go
SELECT IDENT_CURRENT('ident_bifs.t2');
go
SELECT IDENT_CURRENT('ident_bifs.t3');
go
SELECT IDENT_CURRENT('ident_bifs.t4');
go

-- Test with table in default schema
CREATE TABLE id_bifs_t1(id INT IDENTITY(64, 32), c1 INT);
go
SELECT IDENT_SEED('id_bifs_t1');
go
SELECT IDENT_INCR('id_bifs_t1');
go
SELECT IDENT_CURRENT('id_bifs_t1');
go
INSERT INTO id_bifs_t1 (c1) VALUES (8);
go
SELECT IDENT_CURRENT('id_bifs_t1');
go
SELECT @@IDENTITY;
go

-- Test camel case
CREATE TABLE [ident_bifs].[ID_BIFs_T2](id INT IDENTITY(0, -128), c1 INT);
go
SELECT IDENT_SEED('[ident_bifs].[ID_BIFs_T2]');
go
SELECT IDENT_INCR('[ident_bifs].[ID_BIFs_T2]');
go
SELECT IDENT_CURRENT('[ident_bifs].[ID_BIFs_T2]');
go
INSERT INTO [ident_bifs].[ID_BIFs_T2] (c1) VALUES (8);
go
SELECT IDENT_CURRENT('[ident_bifs].[ID_BIFs_T2]');
go
INSERT INTO [ident_bifs].[ID_BIFs_T2] (c1) VALUES (8);
go
SELECT IDENT_CURRENT('[ident_bifs].[ID_BIFs_T2]');
go
SELECT @@IDENTITY;
go

-- Test faulty input
SELECT IDENT_SEED('[ident_bifs].ID_BIFs_T2');
go
SELECT IDENT_INCR('[ident_bifs].[ID_BIFs_T2');
go
SELECT IDENT_CURRENT('[ident_bifs].ID_BIFs_T2]');
go
SELECT IDENT_SEED('[ident_bifs].[[ID_BIFs_T2]]');
go
SELECT IDENT_INCR('[ident_bifs].[[ID_BIFs_T2]');
go
SELECT IDENT_CURRENT('[ident_bifs].ID_[BIFs]_T2');
go
SELECT IDENT_SEED('');
go
SELECT IDENT_INCR('');
go
SELECT IDENT_CURRENT('');
go
SELECT IDENT_SEED(NULL);
go
SELECT IDENT_INCR(NULL);
go
SELECT IDENT_CURRENT(NULL);
go

-- For DMS, we've suggested the following PG functions related to identity
-- feature that can be called from TDS endpoint and they should get the exact
-- same behaviour as PG endpoint.  So, let's add some tests.
-- basic sequence operations for setval, nextval, currentval (tests are taken
-- src/test/regress/sql/sequence.sql PG regression test suite)
CREATE SEQUENCE sequence_test;
go

SELECT nextval('sequence_test');
go
SELECT currval('sequence_test');
go
SELECT setval('sequence_test', 32);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 99, false);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 32);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 99, false);
go
SELECT nextval('sequence_test');
go

DROP SEQUENCE sequence_test
go

DROP PROC ident_bifs.insertLoopT1;
go
DROP TABLE ident_bifs.t1, ident_bifs.t2, ident_bifs.t3, ident_bifs.t4, id_bifs_t1, ident_bifs.ID_BIFs_T2;
go
DROP SCHEMA ident_bifs;
GO
