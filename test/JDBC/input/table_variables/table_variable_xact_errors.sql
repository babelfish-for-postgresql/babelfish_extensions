-- Test how Table Variables behave during implicit rollback due to error

SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID
GO

-------------------------------------------------------------------------------
-- Test 1: Table Variables inside TRY-CATCH block with error
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @tv TABLE(c1 INT PRIMARY KEY, c2 INT)
    INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
    SELECT 1 / 0    -- error
END TRY
BEGIN CATCH
    BEGIN TRANSACTION
        SELECT * FROM @tv                  -- 3 records
        DELETE FROM @tv
    ROLLBACK
END CATCH;

-- Table and index should still be accessible here
INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
UPDATE @tv SET c1 = 1 WHERE c1 = 3 -- duplicate key
SELECT * FROM @tv                  -- 3 records
GO

-------------------------------------------------------------------------------
-- Test 2: Procedure with Table Variables and THROW
-------------------------------------------------------------------------------
CREATE PROC table_variable_throw_proc1 AS
BEGIN
    DECLARE @tv TABLE (a INT PRIMARY KEY, b CHAR(8))
    INSERT INTO @tv VALUES (1, 'First');
    SELECT * FROM @tv;
    THROW 51000, 'Throw error', 1;
    INSERT INTO @tv VALUES (2, 'Second');
END
GO

EXEC table_variable_throw_proc1
GO

SELECT * FROM @tv
GO

DROP PROCEDURE table_variable_throw_proc1
GO

-------------------------------------------------------------------------------
-- Test 3: ROLLBACK due to RAISE
-------------------------------------------------------------------------------
CREATE PROCEDURE table_variable_throw_proc1
AS
BEGIN TRY
    DECLARE @tv TABLE (a INT PRIMARY KEY, b CHAR(8))
    INSERT INTO @tv VALUES (1, 'First');
    RAISERROR ('raiserror 16', 16, 1);
END TRY
BEGIN CATCH
    SELECT 'CATCH in Procedure 1';
    INSERT INTO @tv VALUES (2, 'Second');
    SELECT * FROM @tv; -- return 2 rows
    THROW;
END CATCH
GO

EXEC table_variable_throw_proc1
GO

DROP PROCEDURE table_variable_throw_proc1
GO

-------------------------------------------------------------------------------
-- Test 4: Batch termination
-------------------------------------------------------------------------------
CREATE TYPE empDates AS TABLE (start_date DATE, end_date DATE);
GO

DECLARE @empJobHist empDates;
INSERT INTO @empJobHist VALUES ('1973-01-01', '1973-11-01');
INSERT INTO @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988', '1988-06-30');
INSERT INTO @empJobHist VALUES ('1993-01-01', '1993-11-01'); -- should not get here
SELECT * FROM @empJobHist
GO

DECLARE @empJobHist empDates;
insert into @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988-06-30');
SELECT * FROM @empJobHist
GO

DROP TYPE empDates
GO

