-- Setup
CREATE TABLE implicit_tran_table (a int)
GO

INSERT INTO implicit_tran_table VALUES (10)
GO

SET IMPLICIT_TRANSACTIONS ON
GO

-- Select from table should start implicit transaction
SELECT @@TRANCOUNT
SELECT * FROM implicit_tran_table
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
DECLARE @implicit_tran_table_var int
SELECT @implicit_tran_table_var = a FROM implicit_tran_table
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Select from table variable should start implicit transaction
SELECT @@TRANCOUNT
DECLARE @implicit_tran_table_var TABLE (col1 VARCHAR(10));
SELECT * FROM @implicit_tran_table_var
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Select not from a table should not start implicit transaction
SELECT @@TRANCOUNT
SELECT 123
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
DECLARE @implicit_tran_table_var int
SELECT @implicit_tran_table_var = 1234
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- BABEL-1869
-- 2-Column select should not start implicit transaction
SELECT @@TRANCOUNT
SELECT 1, 2
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
SELECT 1, 2, 3
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Select from table in subquery should start implicit transaction
SELECT @@TRANCOUNT
SELECT (select count(*) from implicit_tran_table)
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
SELECT 1, 2 FROM (SELECT * FROM implicit_tran_table) as dummy_table
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Select to call a function should not start implicit transaction
SELECT @@TRANCOUNT
SELECT @@ERROR
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

/* 
 * DMLs should start implicit transaction 
 * Note: Did not add test for MERGE since 
 * we do not support it (BABEL-877) 
 */
SELECT @@TRANCOUNT
INSERT INTO implicit_tran_table VALUES (11)
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
UPDATE implicit_tran_table SET a = 100 WHERE a = 10
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

SELECT @@TRANCOUNT
DELETE FROM implicit_tran_table WHERE a = 100
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Create table should start implicit transaction
SELECT @@TRANCOUNT
CREATE TABLE implicit_tran_table2 (c smallint)
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- BABEL-1870
-- SELECT ... INTO should start implicit transaction
-- Note: We internally convert this to CREATE TABLE AS
SELECT @@TRANCOUNT
SELECT * INTO dummy_table FROM implicit_tran_table2
SELECT @@TRANCOUNT
DROP TABLE dummy_table
IF @@TRANCOUNT > 0 COMMIT
GO

-- Alter table should start implicit transaction
SELECT @@TRANCOUNT;
ALTER TABLE implicit_tran_table2 ADD CONSTRAINT default_c DEFAULT 99 FOR c
SELECT @@TRANCOUNT;
IF @@TRANCOUNT > 0 COMMIT
GO

-- truncate table should start implicit transaction
SELECT @@TRANCOUNT
TRUNCATE TABLE implicit_tran_table2
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Drop table should start implicit transaction
SELECT @@TRANCOUNT
DROP TABLE implicit_tran_table2
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Create procedure should start implicit transaction
SELECT @@TRANCOUNT
GO
CREATE PROCEDURE implicit_tran_proc
    AS
    BEGIN
        SELECT 'Select inside a procedure'
    END
GO
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

/* 
 * Alter procedure should start implicit transaction
 * Note: Did not add test for ALTER PROCEDURE since 
 * we do not support it (BABEL-442)
 */


-- Drop procedure should start implicit transaction
SELECT @@TRANCOUNT
DROP PROCEDURE implicit_tran_proc
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Begin transaction should start implicit transaction
SELECT @@TRANCOUNT
BEGIN TRANSACTION
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Create database should not start implicit transaction
SELECT @@TRANCOUNT
CREATE DATABASE implicit_tran_db
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

-- Drop database should not start implicit transaction
SELECT @@TRANCOUNT
DROP DATABASE implicit_tran_db
SELECT @@TRANCOUNT
IF @@TRANCOUNT > 0 COMMIT
GO

/*
 * Declare cursor should start an implicit transaction
 */
SELECT @@TRANCOUNT;
DECLARE implicit_tran_cursor CURSOR FOR SELECT * FROM implicit_tran_table;
SELECT @@TRANCOUNT;
DEALLOCATE implicit_tran_cursor;
IF @@TRANCOUNT > 0 COMMIT;
GO

SELECT @@TRANCOUNT;
DECLARE implicit_tran_cursor CURSOR FOR SELECT 9876;
SELECT @@TRANCOUNT;
DEALLOCATE implicit_tran_cursor;
GO

-- Open and fetch should start implicit transaction
-- Close and deallocate should not start implicit transaction
DECLARE implicit_tran_cursor CURSOR FOR SELECT * FROM implicit_tran_table;
DECLARE @val INT;
IF @@TRANCOUNT > 0 COMMIT;
SELECT @@TRANCOUNT;
OPEN implicit_tran_cursor;
SELECT @@TRANCOUNT;
IF @@TRANCOUNT > 0 COMMIT;
SELECT @@TRANCOUNT;
FETCH FROM implicit_tran_cursor INTO @val;
SELECT @@TRANCOUNT;
IF @@TRANCOUNT > 0 COMMIT;
SELECT @@TRANCOUNT;
CLOSE implicit_tran_cursor;
SELECT @@TRANCOUNT;
DEALLOCATE implicit_tran_cursor;
SELECT @@TRANCOUNT;
GO

-- Cleanup
SET IMPLICIT_TRANSACTIONS OFF
GO

DROP TABLE implicit_tran_table
GO
