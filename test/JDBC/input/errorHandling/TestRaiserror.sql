CREATE TABLE raiserrorTable (a INT);
go

CREATE PROC raiserrorProc1 AS
BEGIN
	INSERT INTO raiserrorTable VALUES (1);
	RAISERROR ('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES (2);
END
go

CREATE PROC raiserrorProc2 AS
BEGIN
	INSERT INTO raiserrorTable VALUES (111);
	EXEC raiserrorProc1;
	INSERT INTO raiserrorTable VALUES (222);
END
go

CREATE PROC raiserrorProc3 AS
BEGIN
	BEGIN TRY
		RAISERROR ('raiserror 16', 16, 1);
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (11);
		RAISERROR ('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (12);
	END CATCH
END
go

/* XACT_ABORT OFF */

/* 1. Not in TRY...CATCH block, terminates nothing */
/* Not in TRY...CATCH block */
RAISERROR('raiserror 0', 0, 1);

DECLARE @m1 NVARCHAR(10);
DECLARE @m2 VARCHAR(10);
DECLARE @m3 NCHAR(10);
DECLARE @m4 CHAR(10);

SET @m1 = 'raiserror 0';
SET @m2 = 'raiserror 0';
SET @m3 = 'raiserror 0';
SET @m4 = 'raiserror 0';

RAISERROR(@m1, 0, 1);
RAISERROR(@m2, 0, 2);
RAISERROR(@m3, 0, 3);
RAISERROR(@m4, 0, 4);
go

DECLARE @msg_id INT;
DECLARE @severity INT;
DECLARE @state INT;
SET @msg_id = 51000;
SET @severity = 0;
SET @state = 1;
RAISERROR(@msg_id, @severity, @state) WITH LOG, NOWAIT, SETERROR;
go

BEGIN TRANSACTION
	INSERT INTO raiserrorTable VALUES (3);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES (4);
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM raiserrorTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE raiserrorTable
go

/* Nested procedure call */
BEGIN TRANSACTION
	EXEC raiserrorProc2;
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM raiserrorTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE raiserrorTable
go

/* 2. In TRY...CATCH block, catchable */
/* RAISERROR in TRY...CATCH */
BEGIN TRY
	BEGIN TRANSACTION
		RAISERROR('raiserror 10', 10, 1);
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM raiserrorTable;
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Procedure call in TRY...CATCH */
BEGIN TRY
	BEGIN TRANSACTION
		SELECT xact_state();
		EXEC raiserrorProc1;
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM raiserrorTable;
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Error in both TRY...CATCH */
BEGIN TRY
	BEGIN TRANSACTION
	INSERT INTO raiserrorTable VALUES(1);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES(3);
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (5);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES (7);
	SELECT * FROM raiserrorTable
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Error in nested CATCH */
BEGIN TRY
	BEGIN TRANSACTION
	INSERT INTO raiserrorTable VALUES(1);
	EXEC raiserrorProc3;
	INSERT INTO raiserrorTable VALUES(3);
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (5);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES (7);
	SELECT * FROM raiserrorTable
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Error in CATCH chain */
BEGIN TRY
	BEGIN TRANSACTION
	INSERT INTO raiserrorTable VALUES(1);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES(3);
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (5);
	EXEC raiserrorProc3;
	INSERT INTO raiserrorTable VALUES (7);
	SELECT * FROM raiserrorTable
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go


/* Nested TRY..CATCH, test 1 */
BEGIN TRY
	BEGIN TRY
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (5);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (6);
END CATCH
go
SELECT * FROM raiserrorTable
go
TRUNCATE TABLE raiserrorTable
go

/* Nested TRY...CATCH, test 2 */
BEGIN TRY
	BEGIN TRY
		SELECT 100/0;
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (5);
END CATCH
go
SELECT * FROM raiserrorTable
go
TRUNCATE TABLE raiserrorTable
go

/* Nested TRY...CATCH, test 3 */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (5);
	END CATCH
END CATCH
go
SELECT * FROM raiserrorTable
go
TRUNCATE TABLE raiserrorTable
go

/* XACT_ABORT ON, RAISERROR does not honor XACT_ABORT */
SET XACT_ABORT ON;
go

/* 1. Not in TRY...CATCH block, terminates nothing */
/* Not in TRY...CATCH block */
BEGIN TRANSACTION
	INSERT INTO raiserrorTable VALUES (3);
	RAISERROR('raiserror 16', 16, 1);
	INSERT INTO raiserrorTable VALUES (4);
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM raiserrorTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE raiserrorTable
go

/* Nested procedure call */
BEGIN TRANSACTION
	EXEC raiserrorProc2;
go
SELECT xact_state();
SELECT @@trancount;
SELECT * FROM raiserrorTable;
IF @@trancount > 0 ROLLBACK TRANSACTION;
go
TRUNCATE TABLE raiserrorTable
go

/* 2. In TRY...CATCH block, catchable */
/* RAISERROR in TRY...CATCH */
BEGIN TRY
	BEGIN TRANSACTION
		RAISERROR('raiserror 10', 10, 1);
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM raiserrorTable;
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Procedure call in TRY...CATCH */
BEGIN TRY
	BEGIN TRANSACTION
		SELECT xact_state();
		EXEC raiserrorProc1;
END TRY
BEGIN CATCH
	SELECT xact_state();
	SELECT @@trancount;
	SELECT * FROM raiserrorTable;
	IF @@trancount > 0 ROLLBACK TRANSACTION;
END CATCH
go
TRUNCATE TABLE raiserrorTable
go

/* Nested TRY..CATCH, test 1 */
BEGIN TRY
	BEGIN TRY
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (5);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (6);
END CATCH
go
SELECT * FROM raiserrorTable
go
TRUNCATE TABLE raiserrorTable
go

/* Nested TRY...CATCH, test 2 */
BEGIN TRY
	BEGIN TRY
		SELECT 100/0;
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END CATCH
END TRY
BEGIN CATCH
	INSERT INTO raiserrorTable VALUES (5);
END CATCH
go
SELECT * FROM raiserrorTable
TRUNCATE TABLE raiserrorTable
go

/* Nested TRY...CATCH, test 3 */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		INSERT INTO raiserrorTable VALUES (3);
		RAISERROR('raiserror 16', 16, 1);
		INSERT INTO raiserrorTable VALUES (4);
	END TRY
	BEGIN CATCH
		INSERT INTO raiserrorTable VALUES (5);
	END CATCH
END CATCH
go
SELECT * FROM raiserrorTable
go
TRUNCATE TABLE raiserrorTable
go

/* 
 * SETERROR option
 * 1. Outside TRY...CATCH, SETERROR would set @@ERROR to specified msg_id
 *	  or 50000, regardless of the severity level
 * 2. Inside TRY...CATCH, @@ERROR is always set to the captured error number
 *    with or without SETERROR
 * TODO: After full support, @@ERROR should return user defined error number
 */
DECLARE @err INT;
RAISERROR(51000, 10, 1);
SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
RAISERROR(51000, 10, 2) WITH SETERROR;
SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
RAISERROR('raiserror 16', 16, 1);
SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
RAISERROR('raiserror 16', 16, 2) WITH SETERROR;
SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
go

DECLARE @err INT;
BEGIN TRY
	BEGIN TRY
		RAISERROR(51000, 16, 1);
	END TRY
	BEGIN CATCH
		SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
		RAISERROR(51000, 16, 2) WITH SETERROR;
	END CATCH
END TRY
BEGIN CATCH
	SET @err = @@ERROR; IF @err = 0 SELECT 0 ELSE SELECT 1;
END CATCH
go

/* Clean up */
SET XACT_ABORT OFF;
go
DROP PROC raiserrorProc1;
go
DROP PROC raiserrorProc2;
go
DROP PROC raiserrorProc3;
go
DROP TABLE raiserrorTable;
go
