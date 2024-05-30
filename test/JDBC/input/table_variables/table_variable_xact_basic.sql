-------------------------------------------------------------------------------
-- High-Level Description:
-- Test basic commit and rollback scenarios with BBF Table Variable.
-- Test BABEL-579, BABEL-3968 scenarios
-- Test Table Variable with Primary Key, Constraint, toast table
-- The results were compared against MS SQL server
-------------------------------------------------------------------------------

SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID
GO

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------
CREATE VIEW enr_view AS
    SELECT
        CASE
            WHEN relname LIKE '@pg_toast%' AND relname LIKE '%index%' THEN '@pg_toast_#oid_masked#_index'
            WHEN relname LIKE '@pg_toast%' THEN '@pg_toast_#oid_masked#'
            ELSE relname
        END AS relname
    FROM sys.babelfish_get_enr_list()
GO

-------------------------------------------------------------------------------
-- Test BABEL-579 Use Case 1: Explicit ROLLBACK
-- Repeat with COMMIT
-------------------------------------------------------------------------------
CREATE TYPE tableType AS TABLE(i INT, j INT);
GO

DECLARE @tv1 tableType;
BEGIN TRANSACTION
    INSERT @tv1 VALUES (1,2), (2,1);
ROLLBACK
    SELECT * FROM @tv1
SELECT * FROM enr_view
GO

CREATE PROCEDURE rcv_tv3 AS
BEGIN
    DECLARE @tv tableType;
    BEGIN TRAN;
        INSERT INTO @tv values (1,2);
    ROLLBACK;
    SELECT * FROM @tv;
END
GO

EXEC rcv_tv3
GO

DROP PROCEDURE rcv_tv3
GO

DECLARE @tv1 tableType;
BEGIN TRANSACTION
    INSERT @tv1 VALUES (1,2), (2,1);
COMMIT TRANSACTION
    SELECT * FROM @tv1
SELECT * FROM enr_view
GO

CREATE PROCEDURE rcv_tv3 AS
BEGIN
    DECLARE @tv tableType;
    BEGIN TRAN;
        INSERT INTO @tv values (1,2);
    COMMIT;
    SELECT * FROM @tv;
END
GO

DROP PROCEDURE rcv_tv3
GO

DROP TYPE tableType
GO

-------------------------------------------------------------------------------
-- Test BABEL-579 Use Case 3: Error scenario leads to Implicit ROLLBACK
-------------------------------------------------------------------------------
CREATE TYPE empDates AS TABLE (start_date DATE, end_date DATE);
GO

DECLARE @empJobHist empDates;
INSERT INTO @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988', '1988-06-30');
GO

DECLARE @empJobHist empDates;
insert into @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988-06-30');
GO

DROP TYPE empDates
GO

-------------------------------------------------------------------------------
-- Test BABEL-3968
-------------------------------------------------------------------------------
CREATE TYPE tabvar_type_function_error AS TABLE(a int)
GO

CREATE PROCEDURE tabvar_select(@tvp tabvar_type_function_error READONLY) AS
BEGIN
    SELECT * from @tvp
END
GO

CREATE FUNCTION f_batch_tran_abort(@tvp tabvar_type_function_error READONLY)
RETURNS smallmoney AS
BEGIN
    DECLARE @i smallmoney = 1;
    SELECT @i = CAST('ABC' AS SMALLMONEY);
    RETURN @i
END
GO

DECLARE @tvp2 tabvar_type_function_error;
INSERT INTO @tvp2 values (1);
SELECT dbo.f_batch_tran_abort(@tvp2);
GO

DECLARE @tvp2 tabvar_type_function_error
INSERT INTO @tvp2 values (2)
EXEC tabvar_select @tvp2
SELECT * FROM enr_view
GO

DROP FUNCTION f_batch_tran_abort
GO

DROP PROCEDURE tabvar_select
GO

DROP TYPE tabvar_type_function_error
GO
-------------------------------------------------------------------------------
-- Test 1: Simple INSERT INTO Table Variable with ROLLBACK
--          Repeat with COMMIT
-------------------------------------------------------------------------------
DECLARE @tv2 TABLE(c1 INT, c2 INT);
INSERT INTO @tv2 VALUES(1, 2);
BEGIN TRANSACTION
    INSERT INTO @tv2 VALUES(2, 3);
    SELECT * FROM @tv2                          -- should see 2 rows
    SELECT * FROM @tv2                          -- repeat when hint bits are set
ROLLBACK
SELECT * FROM @tv2                              -- should still see 2 rows
GO

DECLARE @tv2 TABLE(c1 INT, c2 INT);
INSERT INTO @tv2 VALUES(1, 2);
BEGIN TRANSACTION
    INSERT INTO @tv2 VALUES(2, 3);
    SELECT * FROM @tv2                          -- should see 2 rows
    SELECT * FROM @tv2                          -- repeat when hint bits are set
COMMIT
SELECT * FROM @tv2                              -- should still see 2 rows
GO

-------------------------------------------------------------------------------
-- Test 2: DECLARE Table Variable inside a transaction then ROLLBACK
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv4 TABLE(c1 INT, c2 INT)
    INSERT INTO @tv4 VALUES(1, 2)
ROLLBACK
SELECT * FROM @tv4                              -- tv4 accessible and should see 1 row
GO

BEGIN TRANSACTION
    DECLARE @tv4 TABLE(c1 INT, c2 INT)
    INSERT INTO @tv4 VALUES(1, 2)
COMMIT
SELECT * FROM @tv4                              -- tv4 accessible and should see 1 row
GO

-------------------------------------------------------------------------------
-- Test 3: INSERT with COMMIT
-------------------------------------------------------------------------------
DECLARE @tv3 TABLE(c1 INT, c2 INT);
INSERT INTO @tv3 VALUES(1, 2)
BEGIN TRANSACTION
    INSERT INTO @tv3 VALUES(2, 3)
COMMIT
SELECT * FROM @tv3                              -- should see 2 rows
GO

-------------------------------------------------------------------------------
-- Test 4: INSERT and UPDATE with ROLLBACK. Repeat with COMMIT
-------------------------------------------------------------------------------
DECLARE @tv5 TABLE(c1 INT, c2 INT)
INSERT INTO @tv5 VALUES(1, 2)
BEGIN TRANSACTION
    UPDATE @tv5 SET c1 = 10 WHERE c1 = 1
    UPDATE @tv5 SET c1 = 100 WHERE c1 = 10
ROLLBACK
SELECT * FROM @tv5                              -- should see (100, 2)
GO

DECLARE @tv5 TABLE(c1 INT, c2 INT)
INSERT INTO @tv5 VALUES(1, 2)
BEGIN TRANSACTION
    UPDATE @tv5 SET c1 = 10 WHERE c1 = 1
    UPDATE @tv5 SET c1 = 100 WHERE c1 = 10
COMMIT
SELECT * FROM @tv5                              -- should see (100, 2)
GO

-- Also test with Identity columns
DECLARE @tv5 TABLE(c1 INT IDENTITY, c2 INT)
INSERT INTO @tv5 VALUES(1)
BEGIN TRANSACTION
    UPDATE @tv5 SET c2 = 10 WHERE c1 = 1
    UPDATE @tv5 SET c2 = 100 WHERE c1 = 1
ROLLBACK
SELECT * FROM @tv5                              -- should see (1, 100)
INSERT INTO @tv5 VALUES(2)
SELECT * FROM @tv5                              -- should see (2, 2)
GO
-------------------------------------------------------------------------------
-- Test 5: Data with multiple versions
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv1 TABLE(c1 INT, c2 INT);
    INSERT INTO @tv1 VALUES (1, 2);
    UPDATE @tv1 SET c1 = 10 WHERE c1 = 1;
    UPDATE @tv1 SET c1 = 100 WHERE c1 = 10;
ROLLBACK

BEGIN TRANSACTION
    SELECT c1 FROM @tv1                         -- UPDATE operation still valid
    DELETE FROM @tv1 WHERE c1 = 1;              -- no rows affected
    DELETE FROM @tv1 WHERE c1=100               -- 1 row affected
ROLLBACK;
    SELECT c1 FROM @tv1                         -- DELETE operation still valid
GO

-- Repeat with commit then rollback
BEGIN TRANSACTION
    DECLARE @tv1 TABLE(c1 INT, c2 INT);
    INSERT INTO @tv1 VALUES (1, 2);
    UPDATE @tv1 SET c1 = 10 WHERE c1 = 1;
    UPDATE @tv1 SET c1 = 100 WHERE c1 = 10;
COMMIT

BEGIN TRANSACTION
    SELECT c1 FROM @tv1                         -- UPDATE operation still valid
    DELETE FROM @tv1 WHERE c1 = 1;              -- no rows affected
    DELETE FROM @tv1 WHERE c1=100               -- 1 row affected
ROLLBACK;
    SELECT c1 FROM @tv1                         -- DELETE operation still valid
GO

-------------------------------------------------------------------------------
-- Test 6: Table Variable with Primary Key
-- should not show rows inserted by failed transaction
-------------------------------------------------------------------------------
CREATE TYPE tv_table_primary_key AS
TABLE(c1 INT PRIMARY KEY, b INT, c CHAR(15) DEFAULT 'Whoops!')
GO

DECLARE @tv1 tv_table_primary_key;
INSERT INTO @tv1 VALUES(1, 1, 'First')
INSERT INTO @tv1 VALUES(1, 1, 'Second')         -- Heap insert succeeds, index insert fails.
SELECT * FROM @tv1                              -- Should only show one record
GO

-------------------------------------------------------------------------------
-- Test 7: Primary Key metadata should be accessible after rollback
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv1 tv_table_primary_key;
    INSERT INTO @tv1 VALUES(1, 1, 'First')
    INSERT INTO @tv1 VALUES(1, 1, 'Second')     -- Heap insert succeeds, index insert fails.
ROLLBACK
INSERT INTO @tv1 VALUES(1, 1, 'Second')         -- index still valid. should fail with duplicate key
SELECT * FROM @tv1                              -- Should only show one record
GO

DROP TYPE tv_table_primary_key
GO
-------------------------------------------------------------------------------
-- Test 8: Similar as above but with Unique Key constraint instead of Primary Key
-------------------------------------------------------------------------------
CREATE TYPE tv_table_constraint AS
TABLE(a VARCHAR(15) UNIQUE NOT NULL, b INT, c CHAR(15) DEFAULT 'Whoops!')
GO

DECLARE @tv1 tv_table_constraint;
INSERT INTO @tv1 VALUES(1, 1, 'First')
INSERT INTO @tv1 VALUES(2, 2, 'Second')
UPDATE @tv1 SET a = 1 WHERE a = 2               -- Duplicate Key
SELECT * FROM @tv1                              -- Should show the two original records
SELECT * FROM enr_view
GO

-------------------------------------------------------------------------------
-- Test 9: Unique Key constraint metadata should be accessible after rollback
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv1 tv_table_constraint;
    INSERT INTO @tv1 VALUES(1, 1, 'First')
    INSERT INTO @tv1 VALUES(2, 2, 'Second')
    UPDATE @tv1 SET a = 1 WHERE a = 2           -- Duplicate Key
ROLLBACK
UPDATE @tv1 SET a = 1 WHERE a = 2               -- Duplicate Key
SELECT * FROM @tv1                              -- Should show the two original records
GO

DROP TYPE tv_table_constraint
GO

-------------------------------------------------------------------------------
-- Test 10: Table Variable with toast table
-- Toast metadata and data should be accessible and valid after ROLLBACK
-- Repeat for COMMITT
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv_toast TABLE(i INT, v VARCHAR(MAX));
    INSERT INTO @tv_toast VALUES (1, REPLICATE('this is the first record. ', 10000));
ROLLBACK
    INSERT INTO @tv_toast VALUES (2, REPLICATE('this is the second record. ', 10000)); -- toast relation should be accessible
    UPDATE @tv_toast SET v = REPLICATE('this is the updated second record. ', 10000) WHERE i = 2
    SELECT i, SUBSTRING(v, 1, 64) FROM @tv_toast ORDER BY i
GO

BEGIN TRANSACTION
    DECLARE @tv_toast TABLE(i INT, v VARCHAR(MAX));
    INSERT INTO @tv_toast VALUES (1, REPLICATE('this is the first record. ', 10000));
COMMIT
    INSERT INTO @tv_toast VALUES (2, REPLICATE('this is the second record. ', 10000)); -- toast relation should be accessible
    UPDATE @tv_toast SET v = REPLICATE('this is the updated second record. ', 10000) WHERE i = 2
    SELECT i, SUBSTRING(v, 1, 64) FROM @tv_toast ORDER BY i
GO

-------------------------------------------------------------------------------
-- Test 11: Table Variable should be safe from Halloween Problem
-------------------------------------------------------------------------------
BEGIN TRANSACTION
    DECLARE @tv_toast TABLE(a INT, b CHAR(256), c VARCHAR(MAX));
    INSERT INTO @tv_toast SELECT GENERATE_SERIES(1, 32, 1), 'Hello', REPLICATE('this is the first record. ', 10000);
ROLLBACK
    -- should update 10 records only
    UPDATE @tv_toast SET c = 'updated: this is the first record' WHERE a <= 10

    -- explicitly not include ORDER BY to confirm sequence scan order
    SELECT a, SUBSTRING(c, 1, 32) FROM @tv_toast
GO

-------------------------------------------------------------------------------
-- Test 12: Table Variable used with OUTPUT clause
-------------------------------------------------------------------------------

CREATE TABLE TestTable (ID INT, TEXTVal VARCHAR(100))
INSERT TestTable (ID, TEXTVal) VALUES (1,'FirstVal'), (2, 'SecondVal')

BEGIN TRANSACTION
DECLARE @TmpTable TABLE (ID_New INT, TEXTVal_New VARCHAR(100),ID_Old INT, TEXTVal_Old VARCHAR(100))

UPDATE TestTable SET TEXTVal = 'NewValue'
OUTPUT Inserted.ID, Inserted.TEXTVal, Deleted.ID, Deleted.TEXTVal INTO @TmpTable
WHERE ID IN (1,2)

SELECT * FROM @TmpTable
SELECT * FROM TestTable
ROLLBACK

-- Table Variable should keep values after rollback
SELECT * FROM @TmpTable
SELECT * FROM TestTable
GO

DROP TABLE TestTable
GO

-------------------------------------------------------------------------------
-- Test 13: Table Variable used with CURSOR
-------------------------------------------------------------------------------

DECLARE @source TABLE(c1 INT, c2 INT)
INSERT INTO @source VALUES(1, 2), (2,3), (4,5), (6,7), (8,9)

DECLARE @target INT

DECLARE cur CURSOR
FOR SELECT c1 FROM @source
FOR UPDATE OF c1

OPEN cur
FETCH NEXT FROM cur INTO @target
WHILE @@FETCH_STATUS = 0 BEGIN

    UPDATE @source set c1 = c1 * 10 WHERE c1 = @target
    FETCH NEXT FROM cur INTO @target -- next item
End

-- housekeeping
CLOSE cur
DEALLOCATE cur

SELECT * FROM @source

GO

-------------------------------------------------------------------------------
-- Test 14: BABEL-4267 Table Variables with Identity Columns
-------------------------------------------------------------------------------
CREATE TABLE numbers (number INT NOT NULL)
GO

DECLARE @FirstString nVarchar(255)
DECLARE @PseudoMatrix TABLE(location int identity primary key, c2 int)
SELECT number, SUBSTRING(@FirstString,number,1) AS ch
    FROM numbers WHERE number <= LEN(@FirstString) union all Select 0, Char(0)
GO

DROP TABLE numbers
GO

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------
DROP VIEW enr_view
GO
