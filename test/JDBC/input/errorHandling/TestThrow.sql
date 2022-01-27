CREATE TABLE throwTable (a INT);
go

CREATE PROC throwProc1 AS
BEGIN
	INSERT INTO throwTable VALUES (1);
	THROW 51000, 'Throw error', 1;
	INSERT INTO throwTable VALUES (2);
END
go

CREATE PROC throwProc2 AS
BEGIN
	INSERT INTO throwTable VALUES (111);
	EXEC throwProc1;
	INSERT INTO throwTable VALUES (222);
END
go

CREATE PROC reThrowProc1 AS
BEGIN
	BEGIN TRY
		INSERT INTO throwTable VALUES (1);
		THROW 51000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (2);
	END TRY
	BEGIN CATCH
		THROW;
		SELECT 'THROW SHOULD NOT CONTINUE'
	END CATCH
END
go

CREATE PROC reThrowProc2 AS
BEGIN
	INSERT INTO throwTable VALUES (111);
	EXEC reThrowProc1;
	INSERT INTO throwTable VALUES (222);
END
go

/* Error -- THORW; can only be called in CATCH block */
THROW;
go

/* Error -- THROW; can only be called in CATCH block */
BEGIN TRY
	THROW;
END TRY
BEGIN CATCH
	THROW;
END CATCH
go

/* Re-throw current caught error */
BEGIN TRY
	THROW 50000, 'Throw error', 1;
END TRY
BEGIN CATCH
	THROW;
	SELECT 'THROW SHOULD NOT CONTINUE'
END CATCH
go

/* Nested TRY...CATCH, test 1 */
BEGIN TRY
	BEGIN TRY
		PRINT 100/0;
	END TRY
	BEGIN CATCH
		THROW 50000, 'Throw error', 1;
	END CATCH
END TRY
BEGIN CATCH
	THROW;
	SELECT 'THROW SHOULD NOT CONTINUE'
END CATCH
go

/* Nested TRY...CATCH, test 2 */
BEGIN TRY
	PRINT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		THROW;
	END TRY
	BEGIN CATCH
		THROW;
		SELECT 'THROW SHOULD NOT CONTINUE'
	END CATCH
END CATCH
go


/* XACT_ABORT OFF */

/* 1. Not in TRY...CATCH block, throw exception */
/* Not in TRY...CATCH block */
DECLARE @err_no INT;
DECLARE @msg VARCHAR(50);
DECLARE @state INT;
SET @err_no = 51000;
SET @msg = N'Throw error';
SET @state = 1;
THROW @err_no, @msg, @state;
go

BEGIN TRAN
	INSERT INTO throwTable VALUES (3);
	THROW 50000, 'Throw error', 1;
	INSERT INTO throwTable VALUES (4);
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM throwTable;
IF @@trancount > 0 ROLLBACK TRAN;
go
TRUNCATE TABLE throwTable
go

/* Nested procedure call */
BEGIN TRAN
	EXEC throwProc2;
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM throwTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE throwTable
go

BEGIN TRAN
	EXEC reThrowProc2;
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM throwTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE throwTable
go

/* 2. In TRY...CATCH block, catchable, abort batch without rollback */
/* THROW in TRY...CATCH */
BEGIN TRY
	BEGIN TRAN
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	COMMIT TRAN
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM throwTable;
	IF @@trancount > 0 ROLLBACK TRAN;
END CATCH
go
TRUNCATE TABLE throwTable
go

/* Procedure call in TRY...CATCH */
BEGIN TRY
	BEGIN TRAN
		SELECT xact_state();
		EXEC throwProc1;
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM throwTable;
	IF @@trancount > 0 ROLLBACK TRAN;
END CATCH
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 1 */
BEGIN TRY
	BEGIN TRY
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (5);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO throwTable VALUES (6);
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 2 */
BEGIN TRY
	BEGIN TRY
		SELECT 100/0;
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO throwTable VALUES (6);
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 3 */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (5);
	END CATCH
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

/* XACT_ABORT ON */
SET XACT_ABORT ON;
go

/* 1. Not in TRY...CATCH block, rollback transaction */
/* Not in TRY...CATCH block */
BEGIN TRAN
	INSERT INTO throwTable VALUES (3);
	THROW 50000, 'Throw error', 1;
	INSERT INTO throwTable VALUES (4);
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM throwTable;
IF @@trancount > 0 ROLLBACK TRAN;
go
TRUNCATE TABLE throwTable
go

/* Nested procedure call */
BEGIN TRAN
	EXEC throwProc2;
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM throwTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE throwTable
go

/* 2. In TRY...CATCH block, catchable, abort batch without rollback */
/* THROW in TRY...CATCH */
BEGIN TRY
	BEGIN TRAN
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	COMMIT TRAN
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM throwTable;
	IF @@trancount > 0 ROLLBACK TRAN;
END CATCH
go
TRUNCATE TABLE throwTable
go

/* Procedure call in TRY...CATCH */
BEGIN TRY
	BEGIN TRAN
		SELECT xact_state();
		EXEC throwProc1;
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM throwTable;
	IF @@trancount > 0 ROLLBACK TRAN;
END CATCH
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 1 */
BEGIN TRY
	BEGIN TRY
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (5);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO throwTable VALUES (6);
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 2 */
BEGIN TRY
	BEGIN TRY
		SELECT 100/0;
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO throwTable VALUES (6);
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

/* Nested TRY...CATCH, test 3 */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		INSERT INTO throwTable VALUES (3);
		THROW 50000, 'Throw error', 1;
		INSERT INTO throwTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO throwTable VALUES (5);
	END CATCH
END CATCH
go
SELECT * FROM throwTable
go
TRUNCATE TABLE throwTable
go

-- BABEL-2479
THROW 50000, 'Throw error', 1;
go

/* Clean up */
SET XACT_ABORT OFF;
go
DROP PROC throwProc1;
go
DROP PROC throwProc2;
go
DROP PROC reThrowProc1;
go
DROP PROC reThrowProc2;
go
DROP TABLE throwTable;
go
