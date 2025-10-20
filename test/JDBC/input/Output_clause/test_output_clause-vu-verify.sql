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
* --------------------------------------------------------------------------------------------------
* Trigger on Update DML + OUTPUT clause
* Trigger 
* --------------------------------------------------------------------------------------------------
*/


------------------------------------------------------- UPDATE -----------------------

-- update inside update trigger
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


-- delete inside update trigger
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
-- delete inside delete trigger
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

-- Update inside delete trigger
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

--  delete inside insert trigger
INSERT INTO EPQTest_Insert_Delete (ID, Name, Value, Counter)
OUTPUT inserted.ID, inserted.Name, 'STRESS_TEST' as TestType
VALUES (1, 'Row1', 100, 1);
GO



