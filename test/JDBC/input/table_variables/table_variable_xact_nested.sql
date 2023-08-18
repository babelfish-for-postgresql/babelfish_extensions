
-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------

SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID
GO

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
-- Test 1.A: Multiple Savepoints
-------------------------------------------------------------------------------

CREATE FUNCTION table_var_func1(@i INT)
RETURNS INT
AS
BEGIN DECLARE @a AS TABLE(a INT, b INT);
INSERT INTO @a VALUES(1, 2);
RETURN 1;
END;
GO

BEGIN TRANSACTION T1

	SAVE TRANSACTION T2

		DECLARE @table2 TABLE (c1 INT PRIMARY KEY, c2 INT, c3 INT, savepoint_name CHAR(16))
		INSERT INTO @table2 VALUES(1, 2, 3, 'savepoint_t2')
		INSERT INTO @table2 VALUES(1, 2, 3, 'savepoint_t2')      -- error duplicate key

		SAVE TRANSACTION T3
			DECLARE @tv3 TABLE(savepoint_name CHAR(16))
			INSERT INTO @tv3 VALUES('savepoint_t3')
			UPDATE @table2 SET c1 = 10                          -- This should only update 1 row

			SELECT dbo.table_var_func1(1);

			UPDATE @table2 SET c2 = 20 WHERE c1 = 10
		ROLLBACK TRANSACTION T3
	ROLLBACK TRANSACTION T2

	DECLARE @tv1 TABLE(c1 INT, c2 INT, savepoint_name CHAR(16))
	INSERT INTO @tv1 VALUES(1, 2, 'savepoint_t1')
	SELECT * FROM @table2;                                    -- should only show one row with c1=10, c2=20
	SELECT * FROM @tv1;

ROLLBACK TRANSACTION T1

SELECT * FROM @tv1;                                           -- one row inserted even after rollback
SELECT * FROM @table2;                                        -- should only show one row with c2=20
SELECT * FROM @tv3;                                           -- one row inserted after rollback

SELECT * FROM enr_view
GO

DROP FUNCTION table_var_func1
GO

-------------------------------------------------------------------------------
-- Test 1.B: Multiple Savepoints with Identity Columns
-------------------------------------------------------------------------------

CREATE FUNCTION table_var_func1(@i INT)
RETURNS INT
AS
BEGIN DECLARE @a AS TABLE(a INT, b INT);
INSERT INTO @a VALUES(1, 2);
RETURN 1;
END;
GO

BEGIN TRANSACTION T1

	SAVE TRANSACTION T2

		DECLARE @table2 TABLE (c1 INT IDENTITY PRIMARY KEY, c2 INT, c3 INT, savepoint_name CHAR(16))
		INSERT INTO @table2 VALUES(2, 3, 'savepoint_t2')
		INSERT INTO @table2 VALUES(2, 3, 'savepoint_t2')

		SAVE TRANSACTION T3
			DECLARE @tv3 TABLE(savepoint_name CHAR(16))
			INSERT INTO @tv3 VALUES('savepoint_t3')

			SELECT dbo.table_var_func1(1);

			UPDATE @table2 SET c2 = 20 WHERE c1 = 10
		ROLLBACK TRANSACTION T3
	ROLLBACK TRANSACTION T2

	DECLARE @tv1 TABLE(c1 INT, c2 INT, savepoint_name CHAR(16))
	INSERT INTO @tv1 VALUES(1, 2, 'savepoint_t1')
	SELECT * FROM @table2;                                    -- show two rows, only c1 is different
	INSERT INTO @table2 VALUES(2, 3, 'savepoint_t2')          -- sequence should still be valid
	SELECT * FROM @tv1;

ROLLBACK TRANSACTION T1

SELECT * FROM @tv1;                                           -- one row inserted even after rollback
SELECT * FROM @table2;                                        -- should show 3 rows
SELECT * FROM @tv3;                                           -- one row inserted after rollback

SELECT * FROM enr_view
GO

DROP FUNCTION table_var_func1
GO

-------------------------------------------------------------------------------
-- Test 2: Table Variables inside TRY-CATCH block
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @tv TABLE(c1 INT PRIMARY KEY, c2 INT, c3 INT IDENTITY)
    INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
    UPDATE @tv SET c1 = 1 WHERE c1 = 3 -- duplicate key
    SELECT * FROM @tv
END TRY
BEGIN CATCH
    BEGIN TRANSACTION
        DELETE FROM @tv
    ROLLBACK
END CATCH;

-- Table, index and sequence should still be accessible here
INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
UPDATE @tv SET c1 = 1 WHERE c1 = 3 -- duplicate key
SELECT * FROM @tv                  -- 3 records
SELECT * FROM enr_view
GO

-------------------------------------------------------------------------------
-- Test 3.A: Function P1 has TV and calls Function P2 with TV
--         A Transaction modifies the TV returned by P1
-------------------------------------------------------------------------------

CREATE FUNCTION table_variable_inner_func (@number INTEGER)
RETURNS @result TABLE (c1 int PRIMARY KEY, c2 CHAR(128)) AS
BEGIN
    WITH nums_cte(num1, num2) AS (select 1, 'table_variable_inner_func')
    INSERT @result SELECT num1, num2 FROM nums_cte
    RETURN
END;
GO

CREATE FUNCTION table_variable_outer_func()
RETURNS @result TABLE (c1 int PRIMARY KEY, c2 CHAR(128)) AS
BEGIN
    INSERT INTO @result SELECT * FROM table_variable_inner_func(1)
    RETURN;
END
GO

BEGIN TRANSACTION
    SAVE TRANSACTION Savepoint1
        DECLARE @tvf TABLE(c1 INT PRIMARY KEY, c2 CHAR(128));
        INSERT INTO @tvf SELECT * FROM table_variable_outer_func();
    ROLLBACK TRANSACTION Savepoint1

    INSERT INTO @tvf VALUES(2, 'Inserted by Txn')
ROLLBACK TRANSACTION

INSERT INTO @tvf VALUES(1, 'Duplicate Key')  -- Table Variable and its Primary Key should still be valid
SELECT * FROM @tvf

SELECT * FROM enr_view
GO

SELECT * FROM @tvf                           -- Table Variable not valid anymore
GO

DROP FUNCTION table_variable_outer_func
GO

DROP FUNCTION table_variable_inner_func
GO

-------------------------------------------------------------------------------
-- Test 3.B: Function P1 has TV and calls Function P2 with TV
--         A Transaction modifies the TV returned by P1
-------------------------------------------------------------------------------

CREATE FUNCTION table_variable_inner_func (@number INTEGER)
RETURNS @result TABLE (c1 INT PRIMARY KEY, c2 CHAR(128), c3 INT IDENTITY) AS
BEGIN
    WITH nums_cte(num1, num2) AS (select 1, 'table_variable_inner_func')
    INSERT @result SELECT num1, num2 FROM nums_cte
    RETURN
END;
GO

CREATE FUNCTION table_variable_outer_func()
RETURNS @result TABLE (c1 int PRIMARY KEY, c2 CHAR(128), c3 INT) AS
BEGIN
    INSERT INTO @result SELECT * FROM table_variable_inner_func(1)
    RETURN;
END
GO

BEGIN TRANSACTION
    SAVE TRANSACTION Savepoint1
        DECLARE @tvf TABLE(c1 INT PRIMARY KEY, c2 CHAR(128), c3 INT, c4 INT IDENTITY);
        INSERT INTO @tvf SELECT * FROM table_variable_outer_func();
    ROLLBACK TRANSACTION Savepoint1

    INSERT INTO @tvf VALUES(2, 'Inserted by Txn', 1)
ROLLBACK TRANSACTION

INSERT INTO @tvf VALUES(1, 'Duplicate Key', 2)  -- Table Variable and its Primary Key should still be valid
SELECT * FROM @tvf

SELECT * FROM enr_view
GO

SELECT * FROM @tvf                           -- Table Variable not valid anymore
GO

DROP FUNCTION table_variable_outer_func
GO

DROP FUNCTION table_variable_inner_func
GO

-------------------------------------------------------------------------------
-- Test 4: Table Variables in triggers and procedure
-------------------------------------------------------------------------------

CREATE TABLE MainTable (
 firstname VARCHAR(255),
 lastname VARCHAR(255),
);
GO

CREATE TABLE TableUpdatedByTrigger (
 FULLNAME VARCHAR(255),
 XACT_STATUS varchar(255),
 SQLIDENTITYCOL [int] IDENTITY(1,1) NOT NULL
)
GO

-- Keeps track of table variables for each nest level
CREATE TABLE TableVariableTracker(
 nestlevel INT,
 table_variable_name TEXT
)
GO

CREATE TRIGGER UpdateMainTableByTrigger ON MainTable
FOR INSERT AS
BEGIN TRANSACTION
    SAVE TRANSACTION S1;
        DECLARE @table_variable_in_trigger TABLE(fullname VARCHAR(255), valtype VARCHAR(255))
        INSERT INTO @table_variable_in_trigger SELECT CONCAT(firstname, '_', lastname) ,'commit' FROM INSERTED -- insert first row

        INSERT INTO TableUpdatedByTrigger(fullname, xact_status) SELECT fullname, valtype FROM @table_variable_in_trigger;
    ROLLBACK TRANSACTION S1;
INSERT INTO @table_variable_in_trigger VALUES('', 'rollback') -- insert second row
INSERT INTO TableUpdatedByTrigger(fullname, xact_status) SELECT fullname, valtype FROM @table_variable_in_trigger;
INSERT INTO TableVariableTracker SELECT @@NESTLEVEL, relname FROM enr_view
COMMIT TRANSACTION
GO

CREATE TRIGGER UpdateTableUpdatedByTrigger ON TableUpdatedByTrigger
FOR INSERT
AS
BEGIN TRANSACTION
    SAVE TRANSACTION S1;
        DECLARE @table_variable_in_trigger TABLE(fullname VARCHAR(255), valtype VARCHAR(255))
        INSERT INTO @table_variable_in_trigger SELECT fullname,'commit' FROM INSERTED -- insert first row
    ROLLBACK TRANSACTION S1;
    INSERT INTO @table_variable_in_trigger VALUES('<No Name>','rollback') -- insert second row
INSERT INTO TableVariableTracker SELECT @@NESTLEVEL, relname FROM enr_view
COMMIT TRANSACTION
GO

CREATE PROCEDURE InsertIntoMainTable(@firstname VARCHAR(255), @lastname VARCHAR(255))
AS
    DECLARE @tv TABLE(first VARCHAR(255), last VARCHAR(255))
    INSERT INTO @tv VALUES(@firstname, @lastname)
    INSERT INTO MainTable(firstname, lastname) SELECT first, last FROM @tv
    INSERT INTO TableVariableTracker SELECT @@NESTLEVEL, relname FROM enr_view
GO

EXEC InsertIntoMainTable @firstname=N'John', @lastname=N'Doe'
GO

SELECT * FROM MainTable
GO

SELECT * FROM TableUpdatedByTrigger; -- should show two rows
GO

SELECT * FROM TableVariableTracker
GO

DROP TRIGGER UpdateTableUpdatedByTrigger
GO

DROP TRIGGER UpdateMainTableByTrigger
GO

DROP TABLE TableVariableTracker
GO

DROP TABLE TableUpdatedByTrigger
GO

DROP TABLE MainTable
GO

DROP PROCEDURE InsertIntoMainTable
GO

-------------------------------------------------------------------------------
-- Test 5: Multiple Savepoints with INSERT INTO SELECT
-------------------------------------------------------------------------------

BEGIN TRANSACTION T1

	SAVE TRANSACTION T2

		DECLARE @accumulator TABLE (c1 INT, c2 INT, c3 INT, savepoint_name CHAR(16))
		INSERT INTO @accumulator VALUES(1, 1, 1, 'savepoint_t2')

		DECLARE @table2 TABLE (c1 INT PRIMARY KEY, c2 INT, c3 INT, savepoint_name CHAR(16))
		INSERT INTO @table2 VALUES(1, 2, 3, 'savepoint_t2')
		INSERT INTO @table2 VALUES(1, 2, 3, 'savepoint_t2')      -- error duplicate key

		INSERT INTO @accumulator SELECT * FROM @accumulator      -- add second row

		SAVE TRANSACTION T3
			INSERT INTO @accumulator SELECT * FROM @accumulator  -- add 3rd to 4th rows

			DECLARE @tv3 TABLE(savepoint_name CHAR(16))
			INSERT INTO @tv3 VALUES('savepoint_t3')
			UPDATE @table2 SET c1 = 10                          -- This should only update 1 row

			UPDATE @table2 SET c2 = 20 WHERE c1 = 10

			INSERT INTO @accumulator SELECT * FROM @accumulator  -- add 5th to 8th rows
			UPDATE @accumulator SET c1 = c1 + 10
		ROLLBACK TRANSACTION T3
	ROLLBACK TRANSACTION T2

	INSERT INTO @accumulator SELECT * FROM @accumulator  -- add 9th to 16th rows
	SELECT * FROM @accumulator                           -- there should be 16 rows

	DECLARE @tv1 TABLE(c1 INT, c2 INT, savepoint_name CHAR(16))
	INSERT INTO @tv1 VALUES(1, 2, 'savepoint_t1')
	SELECT * FROM @table2;                                    -- should only show one row with c1=10, c2=20
	SELECT * FROM @tv1;

ROLLBACK TRANSACTION T1

SELECT * FROM @tv1;                                           -- one row inserted even after rollback
SELECT * FROM @table2;                                        -- should only show one row with c2=20
SELECT * FROM @tv3;                                           -- one row inserted after rollback

SELECT * FROM enr_view
GO

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

DROP VIEW enr_view
GO


