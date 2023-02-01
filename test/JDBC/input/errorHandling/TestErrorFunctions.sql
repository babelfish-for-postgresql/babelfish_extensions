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

-- stmt terminating
create function f_with_error()returns int as begin	declare @i int = 0 set @i = 1 / 0 return 1 end
go

-- -1 should be returned
select 1;
select dbo.f_with_error();
select -1;
go

begin transaction
go

-- second @@trancount should be executed
select @@trancount
select dbo.f_with_error();
select @@trancount
go

-- @@trancount should be 1
select @@trancount
go

commit
go

-- batch and transaction aborting
create function f_batch_tran_abort() returns smallmoney as begin declare @i smallmoney = 1; SELECT @i = CAST('ABC' AS SMALLMONEY); return @i end
go

-- -1 should not be returned
select 1;
select dbo.f_batch_tran_abort();
select -1;
go

begin transaction
go

-- second @@trancount should not be executed and transaction should rollback
select @@trancount
select dbo.f_batch_tran_abort();
select @@trancount
go

-- @@trancount should be 0
select @@trancount
go

-- tests for xact_abort
set xact_abort on
go

begin transaction
go

-- transaction rollback for simple stmt termination error.
-- we cant have any function execution throwing an error that ignores xact abort
-- since most of the errors are at DDL phase.
select dbo.f_with_error();
select @@trancount
go

select @@trancount
go

set xact_abort off
go

-- try catch testing
BEGIN TRY
	SELECT 'TRY';
	select dbo.f_with_error();
	SELECT 'TRY AFTER ERROR'
END TRY
BEGIN CATCH
    SELECT 'CATCH';
END CATCH
go

BEGIN TRY
	SELECT 'TRY';
	select dbo.f_batch_tran_abort();
	SELECT 'TRY AFTER ERROR'
END TRY
BEGIN CATCH
    SELECT 'CATCH';
END CATCH
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

drop function dbo.f_with_error
drop function dbo.f_batch_tran_abort
go