CREATE TABLE ErrorWithTryCatchTable (a varchar(15) UNIQUE NOT NULL, b nvarchar(25), c int PRIMARY KEY, d char(15) DEFAULT 'Whoops!', e nchar(25), f datetime, g numeric(4,1) CHECK (g >= 103.5))
GO

-- setup for "invalid characters found: cannot cast value "%s" to money" error
CREATE TABLE t293_1(a money, b int);
GO

INSERT INTO t293_1(a, b) values ($100, 1), ($101, 2);
GO

-- setup for error "column \"%s\" of relation \"%s\" is a generated column" error
CREATE TABLE t1752_2(c1 INT, c2 INT, c3 as c1*c2)
GO

-- setup for "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations" error
CREATE TABLE t141_2(c1 int, c2 int); 
GO

-- Error: duplicate key value violates unique constraint
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END TRY 
BEGIN CATCH 
    SELECT xact_state(); 
END CATCH 
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: duplicate key value violates unique constraint
-- Simple batch with transaction inside try-catch
BEGIN TRY 
    BEGIN TRAN 
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END TRY 
BEGIN CATCH 
    SELECT xact_state(); 
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: duplicate key value violates unique constraint
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
GO
BEGIN TRY 
    SELECT xact_state(); 
    EXEC errorWithTryCatchProc1; 
END TRY 
BEGIN CATCH
    SELECT xact_state(); 
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: duplicate key value violates unique constraint
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state(); 
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: duplicate key value violates unique constraint
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS 
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: duplicate key value violates unique constraint
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO




-- Error: check constraint violation
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: check constraint violation
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: check constraint violation
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: check constraint violation
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: check constraint violation
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: check constraint violation
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET g = 101.4 WHERE c = 1;
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO







-- Error: not null constraint violation
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: not null constraint violation
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: not null constraint violation
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: not null constraint violation
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: not null constraint violation
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: not null constraint violation
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE ErrorWithTryCatchTable SET c = NULL WHERE c = 1;
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO







-- Error: creating an existing table
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE ErrorWithTryCatchTable (a int);
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: creating an existing table
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE ErrorWithTryCatchTable (a int);
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: creating an existing table
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE ErrorWithTryCatchTable (a int);
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: creating an existing table
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE ErrorWithTryCatchTable (a int);
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: creating an existing table
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE ErrorWithTryCatchTable (a int);
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: creating an existing table
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE ErrorWithTryCatchTable (a int);
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO







-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_2 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO


-- Error: "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations"
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_2;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations"
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DECLARE @a int; SELECT @a = c1, c2 FROM t141_2;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: "value for domain tinyint violates check constraint "tinyint_check""
-- Simple error inside try-catch
BEGIN TRY
    SELECT xact_state();
    DECLARE @a tinyint = 1000;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Simple batch with try catch
BEGIN TRY
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Simple batch with transaction inside try-catch
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Simple procedure inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';;
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Transaction inside try-catch but not inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Transaction inside procedure but not inside try-catch
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';
    COMMIT TRAN
END
GO
BEGIN TRY
    SELECT xact_state();
    EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- Transaction inside try-catch and inside procedure
CREATE PROCEDURE errorWithTryCatchProc1
AS
BEGIN
    BEGIN TRAN
        INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE t293_1 SET a = convert(money, ''string'') WHERE b > 1;';
    COMMIT TRAN
END
GO
BEGIN TRY
    BEGIN TRAN
        SELECT xact_state();
        EXEC errorWithTryCatchProc1;
END TRY
BEGIN CATCH
    SELECT xact_state();
END CATCH;
GO
IF @@trancount > 0 ROLLBACK TRAN;
GO
DROP PROCEDURE errorWithTryCatchProc1
GO
select * from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- valid INSERT inside catch after an error
-- Simple batch with try catch
BEGIN TRY
    BEGIN TRAN
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END TRY
BEGIN CATCH
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Orange', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END CATCH;
GO
select a from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO

-- invalid INSERT inside catch after an error
-- Simple batch with try catch
BEGIN TRY
    BEGIN TRAN
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END TRY
BEGIN CATCH
    SELECT xact_state();
    INSERT INTO ErrorWithTryCatchTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
END CATCH;
GO
select a from ErrorWithTryCatchTable ORDER BY c
GO
truncate table ErrorWithTryCatchTable
GO


DROP TABLE ErrorWithTryCatchTable
GO

-- cleanup for "invalid characters found: cannot cast value "%s" to money" error
DROP TABLE t293_1;
GO

-- cleanup for error "column \"%s\" of relation \"%s\" is a generated column" error
DROP TABLE t1752_2
GO

-- cleanup for "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations" error
DROP TABLE t141_2;
GO

while (@@trancount > 0) commit tran;
GO

