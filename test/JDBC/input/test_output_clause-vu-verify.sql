/*
 * |  #  |                    Test Case                     |        Type         |                    Remark                     |
 * |-----|--------------------------------------------------|---------------------|-----------------------------------------------|
 * |  1  | INSERT with OUTPUT                               | Basic DML           | Tests basic INSERT OUTPUT clause             |
 * |  2  | UPDATE with OUTPUT                               | Basic DML           | Tests basic UPDATE OUTPUT clause             |
 * |  3  | DELETE with OUTPUT                               | Basic DML           | Tests basic DELETE OUTPUT clause             |
 * |  4  | INSERT with OUTPUT INTO                          | OUTPUT INTO         | Tests INSERT OUTPUT INTO target table        |
 * |  5  | UPDATE with OUTPUT INTO                          | OUTPUT INTO         | Tests UPDATE OUTPUT INTO target table        |
 * |  6  | DELETE with OUTPUT INTO                          | OUTPUT INTO         | Tests DELETE OUTPUT INTO target table        |
 * |  7  | Multiple row UPDATE with OUTPUT                  | Multi-row           | Tests OUTPUT with multiple affected rows     |
 * |  8  | OUTPUT with computed columns                     | Computed Values     | Tests OUTPUT with calculated expressions     |
 * |  9  | OUTPUT with dependent objects (view)             | View Integration    | Tests OUTPUT with view dependencies          |
 * | 10  | UPDATE base table with OUTPUT (view test)        | View Operations     | Tests OUTPUT on base table through view      |
 * | 11  | INSERT with OUTPUT and trigger interaction       | Trigger Basic       | Tests OUTPUT with trigger execution          |
 * | 12  | UPDATE with OUTPUT and trigger interaction       | Trigger Basic       | Tests OUTPUT with trigger modifications      |
 * | 13  | DELETE with OUTPUT and trigger interaction       | Trigger Basic       | Tests OUTPUT with trigger deletions          |
 * | 14  | Multiple operations with triggers and OUTPUT INTO| Trigger Batch       | Tests batch operations with triggers         |
 * | 15  | OUTPUT with trigger execution order validation   | Trigger Order       | Tests OUTPUT timing with trigger execution   |
 * | 16  | Same Row UPDATE with OUTPUT (EPQ scenario)       | EPQ Complex         | Tests EPQ when trigger updates same row      |
 * | 17  | UPDATE with AFTER UPDATE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with UPDATE inside UPDATE trigger  |
 * | 18  | UPDATE with AFTER DELETE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with DELETE inside UPDATE trigger  |
 * | 19  | DELETE with AFTER DELETE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with DELETE inside DELETE trigger  |
 * | 20  | DELETE with AFTER UPDATE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with UPDATE inside DELETE trigger  |
 * | 21  | INSERT with AFTER DELETE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with DELETE inside INSERT trigger  |
 * | 22  | INSERT with AFTER UPDATE trigger (EPQ)           | AFTER Trigger EPQ   | Tests EPQ with UPDATE inside INSERT trigger  |
 * | 23  | INSTEAD OF UPDATE with UPDATE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF UPDATE OUTPUT with EPQ      |
 * | 24  | INSTEAD OF UPDATE with DELETE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF UPDATE OUTPUT with DELETE   |
 * | 25  | INSTEAD OF DELETE with DELETE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF DELETE OUTPUT cascading    |
 * | 26  | INSTEAD OF DELETE with UPDATE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF DELETE OUTPUT with UPDATE   |
 * | 27  | INSTEAD OF INSERT with DELETE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF INSERT OUTPUT with DELETE   |
 * | 28  | INSTEAD OF INSERT with UPDATE trigger            | INSTEAD OF EPQ      | Tests INSTEAD OF INSERT OUTPUT with UPDATE   |
 */

/*
 * ===================================================================================================================
 *                                              1. Basic Output clause test
 * ===================================================================================================================
 */

-- Test Case 1: INSERT with OUTPUT
INSERT INTO OutputTest (ID, Name, Value) 
OUTPUT inserted.ID, inserted.Name, inserted.Value
VALUES (4, 'NewTest', 400);
GO

-- Test Case 2: UPDATE with OUTPUT
UPDATE OutputTest 
SET Value = OutputTest.Value + 50
OUTPUT deleted.Name, deleted.Value as OldValue, inserted.Value as NewValue
WHERE ID = 1;
GO

-- Test Case 3: DELETE with OUTPUT
DELETE FROM OutputTest
OUTPUT deleted.ID, deleted.Name, deleted.Value
WHERE ID = 2;
GO

-- Test Case 4: INSERT with OUTPUT INTO
INSERT INTO OutputTest (ID, Name, Value)
OUTPUT 1, 'INSERT', inserted.ID, inserted.Name, inserted.Value INTO OutputLog (LogID, Operation, ID, Name, Value)
VALUES (5, 'LoggedTest', 500);
GO

-- Test Case 5: UPDATE with OUTPUT INTO
UPDATE OutputTest
SET Status = 'Updated'
OUTPUT 2, 'UPDATE', inserted.ID, inserted.Name, inserted.Value INTO OutputLog (LogID, Operation, ID, Name, Value)
WHERE ID = 3;
GO

-- Test Case 6: DELETE with OUTPUT INTO
DELETE FROM OutputTest
OUTPUT 3, 'DELETE', deleted.ID, deleted.Name, deleted.Value INTO OutputLog (LogID, Operation, ID, Name, Value)
WHERE Name = 'LoggedTest';
GO

-- Test Case 7: Multiple row UPDATE with OUTPUT
UPDATE OutputTest
SET Value = OutputTest.Value * 2
OUTPUT deleted.ID, deleted.Value as Before, inserted.Value as After
WHERE OutputTest.Value > 100;
GO

-- Test Case 8: OUTPUT with computed columns
INSERT INTO OutputTest (ID, Name, Value)
OUTPUT inserted.ID, inserted.Name, inserted.Value, inserted.Value * 2 as DoubleValue
VALUES (6, 'Computed', 250);
GO

-- Test Case 9: OUTPUT with dependent object (view)
INSERT INTO OutputTest (ID, Name, Value, Status)
OUTPUT inserted.ID, inserted.Name, inserted.Status
VALUES (7, 'ViewTest', 600, 'Active');
GO

-- Test Case 10: UPDATE base table with OUTPUT (view test)
UPDATE OutputTest
SET Value = 999
OUTPUT deleted.Name, deleted.Value as OldValue, inserted.Value as NewValue
WHERE Name = 'ViewTest' AND Status = 'Active';
GO

-- Test Case 11: INSERT with OUTPUT and trigger interaction
INSERT INTO OutputTest (ID, Name, Value)
OUTPUT inserted.ID, inserted.Name, 'TRIGGER_TEST' as TestType
VALUES (8, 'TriggerTest1', 700);
GO

-- Test Case 12: UPDATE with OUTPUT and trigger interaction
UPDATE OutputTest
SET Value = OutputTest.Value + 100, Status = 'Modified'
OUTPUT deleted.Status as OldStatus, inserted.Status as NewStatus, inserted.ID
WHERE Name = 'TriggerTest1';
GO

-- Test Case 13: DELETE with OUTPUT and trigger interaction
DELETE FROM OutputTest
OUTPUT deleted.ID, deleted.Name, 'DELETED_BY_TRIGGER_TEST' as Note
WHERE Name = 'TriggerTest1';
GO

-- Test Case 14: Multiple operations with triggers and OUTPUT INTO
INSERT INTO OutputTest (ID, Name, Value)
OUTPUT 4, 'MULTI_OP', inserted.ID, inserted.Name, inserted.Value INTO OutputLog (LogID, Operation, ID, Name, Value)
VALUES (9, 'MultiOp1', 800), (10, 'MultiOp2', 900);
GO

UPDATE OutputTest
SET Status = 'Batch_Updated'
OUTPUT 5, 'BATCH_UPD', inserted.ID, inserted.Name, inserted.Value INTO OutputLog (LogID, Operation, ID, Name, Value)
WHERE Name LIKE 'MultiOp%';
GO

-- Test Case 15: OUTPUT with trigger execution order validation
INSERT INTO OutputTest (ID, Name, Value)
OUTPUT inserted.ID, inserted.Name, 'OrderTest_Time' as OutputTime
VALUES (11, 'OrderTest', 1000);
GO

-- Test Case 16: Same Row UPDATE - Trigger updates the SAME ROW with OUTPUT clause
-- This tests the most complex EPQ scenario: both original and trigger UPDATE the same row
INSERT INTO OutputTest (ID, Name, Value, Status) VALUES (12, 'SameRowTest', 1100, 'Active');
GO

-- This UPDATE will trigger the UPDATE trigger which updates THE SAME ROW with OUTPUT
-- Original UPDATE: Changes Value from 1100 to 1200
-- Trigger UPDATE: Changes Value from 1200 to 2200 (1200 + 1000) and Status to 'Trigger_Modified'
UPDATE OutputTest
SET Value = 1200
OUTPUT deleted.Value as OriginalOldValue, inserted.Value as OriginalNewValue, 
       deleted.Status as OriginalOldStatus, inserted.Status as OriginalNewStatus
WHERE Name = 'SameRowTest';
GO

-- Verify the final state shows both updates occurred
SELECT ID, Name, Value, Status FROM OutputTest WHERE Name = 'SameRowTest';
GO

-- Verify OUTPUT INTO results
SELECT * FROM OutputLog ORDER BY LogID;
GO

-- Verify trigger execution
SELECT * FROM TriggerLog ORDER BY LogID;
GO

-- Verify view functionality
SELECT * FROM OutputTestView ORDER BY ID;
GO

-- Verify final table state
SELECT * FROM OutputTest ORDER BY ID;
GO


/*
 * ===================================================================================================================
 *                                              2. Triggers with DML test.
 * ===================================================================================================================
 */


/*
 * 2.1 All below tests are AFTER TRIGGERS test with output clause
 */


------------------------------------------------------- UPDATE -----------------------------------------

-- 2.1.1 update inside update trigger
UPDATE EPQTest_Update_Update
SET Value = 500
OUTPUT 
    deleted.ID,
    deleted.Name,
    deleted.Value as OldValue,
    deleted.Counter as OldCounter,
    inserted.Value as NewValue,
    inserted.Counter as NewCounter
WHERE ID = 1;
GO

UPDATE EPQTest_Update_Update
SET Value = 999
OUTPUT 
    1,
    inserted.ID,
    deleted.Value,
    inserted.Value,
    'Logged'
INTO EPQOutputLog (LogID, SourceID, OldValue, NewValue, LogStatus)
WHERE ID = 1;
GO

-- Final state check
SELECT * FROM EPQTest_Update_Update ORDER BY ID;
SELECT * FROM EPQOutputLog ORDER BY LogID;
GO
delete from EPQOutputLog;
GO


--2.1.2 delete inside update trigger
UPDATE EPQTest_Update_Delete 
SET Value = 999
OUTPUT 
    1,
    inserted.ID,
    deleted.Value,
    inserted.Value,
    'Logged'
INTO EPQOutputLog (LogID, SourceID, OldValue, NewValue, LogStatus)
WHERE ID = 1;
GO

-- Final state check
SELECT * FROM EPQTest_Update_Delete ORDER BY ID;
SELECT * FROM EPQOutputLog ORDER BY LogID;
GO
delete from EPQOutputLog;
GO


------------------------------------------------------- DELETE ------------------------------------------------
-- 2.1.3 delete inside delete trigger
DELETE FROM EPQTest_Delete_Delete
OUTPUT deleted.ID, deleted.Name, deleted.Value
WHERE ID = 2;
GO

-- Final state check
SELECT * FROM EPQTest_Delete_Delete ORDER BY ID;
SELECT * FROM EPQOutputLog ORDER BY LogID;
GO
delete from EPQOutputLog;
GO

-- 2.1.4 Update inside delete trigger
DELETE FROM EPQTest_Delete_Update
OUTPUT deleted.ID, deleted.Name, deleted.Value
WHERE ID = 2;
GO

-- Final state check
SELECT * FROM EPQTest_Delete_Update ORDER BY ID;
SELECT * FROM EPQOutputLog ORDER BY LogID;
GO
delete from EPQOutputLog;
GO

------------------------------------------------------- INSERT -------------------------------------------------

-- 2.1.5 delete inside insert trigger
INSERT INTO EPQTest_Insert_Delete (ID, Name, Value, Counter)
OUTPUT 
    1,
    1,
    deleted.ID,
    inserted.ID,
    'Logged'
INTO EPQOutputLog (LogID, SourceID, OldValue, NewValue, LogStatus)
VALUES (1, 'Row1', 100, 1);
GO

-- Final state check
SELECT * FROM EPQTest_Insert_Delete ORDER BY ID;
SELECT * FROM EPQOutputLog ORDER BY LogID;
GO
delete from EPQOutputLog;
GO


-- 2.1.6 Update inside insert trigger
INSERT INTO EPQTest_Insert_Update (ID, Name, Value, Counter)
OUTPUT 
    1,
    1,
    'NA',
    inserted.Status,
    'Logged'
INTO EPQOutputLog_Str (LogID, SourceID, OldValue, NewValue, LogStatus)
VALUES (1, 'Row1', 100, 1);
GO

-- Final state check
SELECT * FROM EPQTest_Insert_Update ORDER BY ID;
SELECT * FROM EPQOutputLog_Str ORDER BY LogID;
GO
delete from EPQOutputLog_Str;
GO




------------------------------------------------------ INSTEAD OF TRIGGERS TEST ---------------------------------------------

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Update  + update inside update trigger
* ------------------------------------------------------------------------------------
*/

-- Create table to capture OUTPUT results
CREATE TABLE OutputCapture (
    TestCase NVARCHAR(50),
    ID INT,
    Name NVARCHAR(50),
    OldValue INT
);
GO

-- 2.2.1 INSTEAD OF UPDATE trigger with OUTPUT - EPQ condition
UPDATE EPQTest_InsteadOf_Update_Update
SET Value = 1500
OUTPUT 'InsteadOf_Update_Update', deleted.ID, deleted.Name, deleted.Value
INTO OutputCapture (TestCase, ID, Name, OldValue)
WHERE ID = 1;
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Update+Update OUTPUT' as TestPhase, * FROM OutputCapture;
GO

-- Verify INSTEAD OF trigger updated the row
SELECT 'INSTEAD OF Update+Update' as TestPhase, * FROM EPQTest_InsteadOf_Update_Update WHERE ID = 1;
GO

-- Clear OUTPUT capture
delete from OutputCapture;

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Update  + delete inside update trigger
* ------------------------------------------------------------------------------------
*/

-- 2.2.2 INSTEAD OF UPDATE trigger that deletes with OUTPUT
UPDATE EPQTest_InsteadOf_Update_Delete
SET Value = 2000
OUTPUT 'InsteadOf_Update_Delete', deleted.ID, deleted.Name, deleted.Value
INTO OutputCapture (TestCase, ID, Name, OldValue)
WHERE ID = 1;
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Update+Delete OUTPUT' as TestPhase, * FROM OutputCapture;
GO

-- Clear OUTPUT capture
DELETE FROM OutputCapture;
GO

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Delete  + delete inside delete trigger
* ------------------------------------------------------------------------------------
*/

-- 2.2.3 INSTEAD OF DELETE trigger with cascading deletes
DELETE FROM EPQTest_InsteadOf_Delete_Delete
OUTPUT 'InsteadOf_Delete_Delete', deleted.ID, deleted.Name, deleted.Value
INTO OutputCapture (TestCase, ID, Name, OldValue)
WHERE ID = 2;
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Delete+Delete OUTPUT' as TestPhase, * FROM OutputCapture;
GO

-- Verify cascading deletes occurred
SELECT 'INSTEAD OF Delete+Delete' as TestPhase, COUNT(*) as RemainingRows FROM EPQTest_InsteadOf_Delete_Delete;
GO

-- Clear OUTPUT capture
DELETE FROM OutputCapture;
GO

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Delete  + update inside delete trigger
* ------------------------------------------------------------------------------------
*/

-- 2.2.4 INSTEAD OF DELETE trigger that updates instead of deleting
DELETE FROM EPQTest_InsteadOf_Delete_Update
OUTPUT 'InsteadOf_Delete_Update', deleted.ID, deleted.Name, deleted.Counter
INTO OutputCapture (TestCase, ID, Name, OldValue)
WHERE ID = 1;
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Delete+Update OUTPUT' as TestPhase, * FROM OutputCapture;
GO

-- Verify row was updated instead of deleted
SELECT 'INSTEAD OF Delete+Update' as TestPhase, * FROM EPQTest_InsteadOf_Delete_Update WHERE ID = 1;
GO

-- Clear OUTPUT capture
DELETE FROM OutputCapture;
GO

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Insert  + delete inside insert trigger
* ------------------------------------------------------------------------------------
*/

-- 2.2.5 Create table to capture OUTPUT results
CREATE TABLE OutputCapture_insert (
    TestCase NVARCHAR(50),
    ID INT,
    Name NVARCHAR(50),
    OldValue INT,
    NewValue INT,
    Status NVARCHAR(50)
);
GO

-- Insert some data first for delete scenario
INSERT INTO EPQTest_InsteadOf_Insert_Delete (ID, Name, Value, Counter) VALUES (1, 'Existing1', 50, 1);
GO

-- Test Case 34: INSTEAD OF INSERT trigger that deletes existing rows
INSERT INTO EPQTest_InsteadOf_Insert_Delete (ID, Name, Value, Counter, Status)
OUTPUT 'InsteadOf_Insert_Delete', inserted.ID, inserted.Name, 0, inserted.Value, inserted.Status
INTO OutputCapture_insert (TestCase, ID, Name, OldValue, NewValue, Status)
VALUES (2, 'NewRow', 100, 2, 'Active');
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Insert+Delete OUTPUT' as TestPhase, * FROM OutputCapture_insert;
GO

-- Verify existing row was deleted and new row inserted
SELECT 'INSTEAD OF Insert+Delete' as TestPhase, COUNT(*) as TotalRows FROM EPQTest_InsteadOf_Insert_Delete;
GO

SELECT * FROM EPQTest_InsteadOf_Insert_Delete ORDER BY ID;
GO

delete from OutputCapture_insert;
GO

/*
* ------------------------------------------------------------------------------------
*  INSTEAD OF Insert  + update inside insert trigger
* ------------------------------------------------------------------------------------
*/

-- Insert some data first for update scenario
INSERT INTO EPQTest_InsteadOf_Insert_Update (ID, Name, Value, Counter) VALUES (1, 'Existing1', 50, 1);
GO

-- 2.2.6 INSTEAD OF INSERT trigger that updates existing rows
INSERT INTO EPQTest_InsteadOf_Insert_Update (ID, Name, Value, Counter, Status)
OUTPUT 'InsteadOf_Insert_Update', inserted.ID, inserted.Name, 0, inserted.Value, inserted.Status
INTO OutputCapture_insert (TestCase, ID, Name, OldValue, NewValue, Status)
VALUES (2, 'NewRow', 200, 2, 'Active');
GO

-- Print OUTPUT results
SELECT 'INSTEAD OF Insert+Update OUTPUT' as TestPhase, * FROM OutputCapture_insert;
GO

-- Verify existing row was updated and new row inserted
SELECT 'INSTEAD OF Insert+Update' as TestPhase, COUNT(*) as TotalRows FROM EPQTest_InsteadOf_Insert_Update;
GO

SELECT * FROM EPQTest_InsteadOf_Insert_Update ORDER BY ID;
GO

-- Final cleanup of OUTPUT capture table
DROP TABLE OutputCapture_insert;
DROP TABLE OutputCapture;
GO