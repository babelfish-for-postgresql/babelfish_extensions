CREATE PROC errorFuncProc1 AS
BEGIN TRY
	RAISERROR ('raiserror 16', 16, 1);
END TRY
BEGIN CATCH
	SELECT 'CATCH in Procedure 1';
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;

	THROW;
END CATCH
go

CREATE PROC errorFuncProc2 AS
BEGIN TRY
	EXEC errorFuncProc1;
END TRY
BEGIN CATCH
	DECLARE @msg NVARCHAR(4000);
	DECLARE @sev INT;
	DECLARE @state INT;

	SELECT 'CATCH in Procedure 2';
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
	
	SELECT
		@msg = ERROR_MESSAGE(),
		@sev = ERROR_SEVERITY(),
		@state = ERROR_STATE();

	SET @state = @state+1;

	RAISERROR (@msg, @sev, @state);
END CATCH
go

/* Outside of CATCH -- test 1 */
SELECT 
	ERROR_LINE() AS line, 
	ERROR_MESSAGE() AS msg,
	ERROR_NUMBER() AS num, 
	ERROR_PROCEDURE() AS proc_,
	ERROR_SEVERITY() AS sev,
	ERROR_STATE() AS state;
go

/* Outside of CATCH -- test 2 */
BEGIN TRY
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END TRY
BEGIN CATCH
	SELECT 'Not arriving here';
END CATCH
go

/* Multiple errors in single batch -- test 1 */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	SELECT 'First CATCH';
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END CATCH
BEGIN TRY
	THROW 51000, 'throw error', 1;
END TRY
BEGIN CATCH
	SELECT 'Second CATCH';
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END CATCH
go

/* Multiple errors in single batch -- test 2 */
/* Nested TRY...CATCH */
BEGIN TRY
	SELECT 100/0;
END TRY
BEGIN CATCH
	BEGIN TRY
		THROW 51000, 'throw error', 1;
	END TRY
	BEGIN CATCH
		SELECT 'Inner CATCH';
		SELECT 
			ERROR_LINE() AS line, 
			ERROR_MESSAGE() AS msg,
			ERROR_NUMBER() AS num, 
			ERROR_PROCEDURE() AS proc_,
			ERROR_SEVERITY() AS sev,
			ERROR_STATE() AS state;
	END CATCH
	SELECT 'Outer CATCH';
	SELECT 
		ERROR_LINE() AS line, 
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num, 
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END CATCH

/* Multiple errors in nested batch */
EXEC errorFuncProc2;
go

/* 
 * BABEL-1602 
 * Output of ERROR functions should be the same as error message
 */
CREATE TABLE errorFuncTable
(
	a INT,
	b INT,
	c VARCHAR(10) NOT NULL,
	CONSTRAINT CK_a_gt_b CHECK (b > a)
)
go

INSERT INTO errorFuncTable VALUES (5, 2, 'one')
go

BEGIN TRY
	INSERT INTO errorFuncTable VALUES (5, 2, 'one')
END TRY
BEGIN CATCH
	SELECT 
		ERROR_LINE() AS line,
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num,
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END CATCH
go

INSERT INTO errorFuncTable VALUES (1, 2, NULL)
go

BEGIN TRY
	INSERT INTO errorFuncTable VALUES (1, 2, NULL)
END TRY
BEGIN CATCH
	SELECT 
		ERROR_LINE() AS line,
		ERROR_MESSAGE() AS msg,
		ERROR_NUMBER() AS num,
		ERROR_PROCEDURE() AS proc_,
		ERROR_SEVERITY() AS sev,
		ERROR_STATE() AS state;
END CATCH
go

-- Nested procedures (nested estates)
CREATE PROC errorFuncProcInner AS
SELECT
	ERROR_LINE() AS line,
	ERROR_MESSAGE() AS msg,
	ERROR_NUMBER() AS num,
	ERROR_PROCEDURE() AS proc_,
	ERROR_SEVERITY() AS sev,
	ERROR_STATE() AS state;
go

CREATE PROC errorFuncProcOuter1 AS
BEGIN TRY
	DECLARE @a INT
	SET @a = 1/0
END TRY
BEGIN CATCH
	EXEC errorFuncProcInner
END CATCH
go

EXEC errorFuncProcOuter1
go

CREATE PROC errorFuncProcMiddle AS
BEGIN TRY
	EXEC errorFuncProcInner
END TRY
BEGIN CATCH
	SELECT 'error'
END CATCH
go

CREATE PROC errorFuncProcOuter2 AS
BEGIN TRY
	DECLARE @a INT
	SET @a = 1/0
END TRY
BEGIN CATCH
	EXEC errorFuncProcMiddle
END CATCH
go

EXEC errorFuncProcOuter2
go

-- Multiple-level nested procedures with nested errors
-- Should report division by zero error in errorFuncProcOuter1
CREATE PROC errorFuncProcOuter3 AS
BEGIN TRY
	THROW 51000, 'throw error', 1;
END TRY
BEGIN CATCH
	EXEC errorFuncProcOuter1
END CATCH
go

EXEC errorFuncProcOuter3
go

-- Should report THROW error in errorFuncProcOuter4
CREATE PROC errorFuncProcOuter4 AS
BEGIN TRY
	DECLARE @a INT
	SET @a = 1/0
END TRY
BEGIN CATCH
	BEGIN TRY
		THROW 51000, 'throw error', 1;
	END TRY
	BEGIN CATCH
		EXEC errorFuncProcMiddle
	END CATCH
END CATCH
go

EXEC errorFuncProcOuter4
go

/* Clean up */
DROP PROC errorFuncProc1
go

DROP PROC errorFuncProc2
go

DROP PROC errorFuncProcOuter1
go

DROP PROC errorFuncProcOuter2
go

DROP PROC errorFuncProcOuter3
go

DROP PROC errorFuncProcOuter4
go

DROP PROC errorFuncProcMiddle
go

DROP PROC errorFuncProcInner
go

DROP TABLE errorFuncTable
go
