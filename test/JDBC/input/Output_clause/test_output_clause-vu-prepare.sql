/*
 * ===================================================================================================================
 *                                              1. Basic Output clause test
 * ===================================================================================================================
 */

-- Test setup for OUTPUT clause functionality
CREATE TABLE OutputTest (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO OutputTest (ID, Name, Value) VALUES 
(1, 'Test1', 100),
(2, 'Test2', 200),
(3, 'Test3', 300);
GO

-- Table for OUTPUT INTO testing
CREATE TABLE OutputLog (
    LogID INT,
    Operation NVARCHAR(10),
    ID INT,
    Name NVARCHAR(50),
    Value INT
);
GO

-- Dependent objects setup
CREATE VIEW OutputTestView AS
SELECT ID, Name, Value, Status FROM OutputTest WHERE Status = 'Active';
GO

CREATE TABLE TriggerLog (
    LogID INT,
    TriggerType NVARCHAR(20),
    TableName NVARCHAR(50),
    RecordID INT
);
GO

-- Triggers for testing OUTPUT with trigger interaction
CREATE TRIGGER tr_OutputTest_Insert
ON OutputTest
AFTER INSERT
AS
BEGIN
    INSERT INTO TriggerLog (LogID, TriggerType, TableName, RecordID)
    SELECT inserted.ID + 1000, 'AFTER_INSERT', 'OutputTest', inserted.ID FROM inserted;
END;
GO

CREATE TRIGGER tr_OutputTest_Update
ON OutputTest
AFTER UPDATE
AS
BEGIN
    INSERT INTO TriggerLog (LogID, TriggerType, TableName, RecordID)
    SELECT inserted.ID + 2000, 'AFTER_UPDATE', 'OutputTest', inserted.ID FROM inserted;
END;
GO

CREATE TRIGGER tr_OutputTest_Delete
ON OutputTest
AFTER DELETE
AS
BEGIN
    INSERT INTO TriggerLog (LogID, TriggerType, TableName, RecordID)
    SELECT deleted.ID + 3000, 'AFTER_DELETE', 'OutputTest', deleted.ID FROM deleted;
END;
GO


/*
 * ===================================================================================================================
 *                                              2. Triggers + DML with OUTPUT clause test
 * ===================================================================================================================
 */


/*
 * ----------------------------   2.1 All below tests are AFTER TRIGGERS test with output clause. --------------------------------------
 */

/*
 * ------------------------------------------------------------------------------------
 *  2.1.1 Scenerio -
 *  Update command with output clause
 *  AFTER trigger on update  
 *  Another update inside AFTER trigger updating same row
 * ------------------------------------------------------------------------------------
 */


-- Setup EPQ test table
CREATE TABLE EPQTest_Update_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO EPQTest_Update_Update (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- AFTER trigger that updates the same row
CREATE TRIGGER tr_EPQTest_After_Update
ON EPQTest_Update_Update
AFTER UPDATE
AS
BEGIN
    -- UPDATE EPQTest_Update_Update 
    -- SET Counter = Counter + 100
    -- WHERE ID IN (SELECT ID FROM inserted);
    
    UPDATE EPQTest_Update_Update 
    SET Status = 'PostTrigger'
    WHERE ID IN (SELECT ID FROM inserted);
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.1.2 Scenerio -
 *  Update command with output clause
 *  AFTER trigger on update  
 *  Delete inside AFTER trigger deleting same row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_Update_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO


-- Insert test data
INSERT INTO EPQTest_Update_Delete (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO


-- Test Case 18: AFTER trigger that deletes the row being updated
CREATE TRIGGER tr_EPQTest_Delete_OnUpdate
ON EPQTest_Update_Delete
AFTER UPDATE
AS
BEGIN
    DELETE FROM EPQTest_Update_Delete
    WHERE ID IN (SELECT ID FROM inserted) ;
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.1.3 Scenerio -
 *  Delete command with output clause
 *  AFTER trigger on Delete
 *  Delete inside AFTER trigger deleting same row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_Delete_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO


-- Insert test data
INSERT INTO EPQTest_Delete_Delete (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- Test Case 19: AFTER trigger that deletes additional rows during DELETE
CREATE TRIGGER tr_EPQTest_Delete_OnDelete
ON EPQTest_Delete_Delete
AFTER DELETE
AS
BEGIN
    DELETE FROM EPQTest_Delete_Delete 
    WHERE Value < (SELECT MIN(Value) FROM deleted) + 50;
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.1.4 Scenerio -
 *  Delete command with output clause
 *  AFTER trigger on Delete
 *  Update inside AFTER trigger trying to update deleted row
 * ------------------------------------------------------------------------------------
 */


-- Setup EPQ test table
CREATE TABLE EPQTest_Delete_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO


-- Insert test data
INSERT INTO EPQTest_Delete_Update (ID, Name, Value, Counter) VALUES
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- Test Case 20: AFTER DELETE trigger that tries to update deleted rows
CREATE TRIGGER tr_EPQTest_Update_Update_AfterDelete
ON EPQTest_Delete_Update
AFTER DELETE
AS
BEGIN
    UPDATE EPQTest_Delete_Update
    SET Status = 'Updated_After_Delete'
    WHERE ID IN (SELECT ID FROM deleted);
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.1.5 Scenerio -
 *  Insert command with output clause
 *  AFTER trigger on Insert
 *  Delete inside trigger deleting new inserted row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_Insert_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Test Case 21: AFTER INSERT trigger that deletes the inserted row
CREATE TRIGGER tr_EPQTest_Delete_AfterInsert
ON EPQTest_Insert_Delete
AFTER INSERT
AS
BEGIN
    DELETE FROM EPQTest_Insert_Delete 
    WHERE ID IN (SELECT ID FROM inserted);
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.1.6 Scenerio -
 *  Insert command with output clause
 *  AFTER trigger on Insert
 *  Update inside trigger Updating new inserted row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_Insert_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- AFTER INSERT trigger that Updates the inserted row
CREATE TRIGGER tr_EPQTest_Update_AfterInsert
ON EPQTest_Insert_Update
AFTER INSERT
AS
BEGIN
    UPDATE EPQTest_Insert_Update 
    SET Status = 'PostTrigger'
    WHERE ID IN (SELECT ID FROM inserted);
END;
GO




-- Temporary table to store OUTPUT result
CREATE TABLE EPQOutputLog (
    LogID INT,
    SourceID INT,
    OldValue INT,
    NewValue INT,
    LogStatus NVARCHAR(20)
);
GO

-- Temporary table to store OUTPUT result
CREATE TABLE EPQOutputLog_Str (
    LogID INT,
    SourceID INT,
    OldValue NVARCHAR(30),
    NewValue NVARCHAR(30),
    LogStatus NVARCHAR(20)
);
GO

/*
 *  ----------------------------   2.2 All below tests are INSTEAD OF TRIGGERS test with output clause. --------------------------------------------
 */

/*
 * ------------------------------------------------------------------------------------
 *  2.2.1 Scenerio -
 *  Update command with output clause
 *  INSTEAD OF trigger on update 
 *  Another update inside trigger updating same row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table for INSTEAD OF triggers
CREATE TABLE EPQTest_InsteadOf_Update_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO EPQTest_InsteadOf_Update_Update (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- INSTEAD OF trigger that updates the same row
CREATE TRIGGER tr_EPQTest_InsteadOf_Update_Update
ON EPQTest_InsteadOf_Update_Update
INSTEAD OF UPDATE
AS
BEGIN
    UPDATE EPQTest_InsteadOf_Update_Update 
    SET Value = i.Value + 10,
        Counter = e.Counter + 1,
        Status = 'Modified'
    FROM EPQTest_InsteadOf_Update_Update e
    INNER JOIN inserted i ON e.ID = i.ID;
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.2.2 Scenerio -
 *  Update command with output clause on view
 *  INSTEAD OF trigger on update 
 *  Delete inside trigger deleting same row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_InsteadOf_Update_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO EPQTest_InsteadOf_Update_Delete (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- INSTEAD OF trigger that deletes the row being updated
CREATE TRIGGER tr_EPQTest_InsteadOf_Delete_OnUpdate
ON EPQTest_InsteadOf_Update_Delete
INSTEAD OF UPDATE
AS
BEGIN
    DELETE FROM EPQTest_InsteadOf_Update_Delete
    WHERE ID IN (SELECT ID FROM inserted);
END;
GO

/*
 * ------------------------------------------------------------------------------------
 *  2.2.3 Scenerio -
 *  Delete command with output clause on view
 *  INSTEAD OF trigger on Delete 
 *  Delete inside trigger deleting same row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_InsteadOf_Delete_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO EPQTest_InsteadOf_Delete_Delete (ID, Name, Value, Counter) VALUES 
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- INSTEAD OF trigger that deletes additional rows during DELETE
CREATE TRIGGER tr_EPQTest_InsteadOf_Delete_OnDelete
ON EPQTest_InsteadOf_Delete_Delete
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM EPQTest_InsteadOf_Delete_Delete 
    WHERE Value < (SELECT MIN(Value) FROM deleted) + 50;
    
    DELETE FROM EPQTest_InsteadOf_Delete_Delete
    WHERE ID IN (SELECT ID FROM deleted);
END;
GO

/*
 * ------------------------------------------------------------------------------------
 *  2.2.4 Scenerio -
 *  Delete command with output clause on view
 *  INSTEAD OF trigger on Delete 
 *  Update inside trigger updating deleted row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_InsteadOf_Delete_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- Insert test data
INSERT INTO EPQTest_InsteadOf_Delete_Update (ID, Name, Value, Counter) VALUES
(1, 'Row1', 100, 1),
(2, 'Row2', 200, 2),
(3, 'Row3', 300, 3);
GO

-- INSTEAD OF DELETE trigger that updates instead of deleting
CREATE TRIGGER tr_EPQTest_InsteadOf_Update_OnDelete
ON EPQTest_InsteadOf_Delete_Update
INSTEAD OF DELETE
AS
BEGIN
    UPDATE EPQTest_InsteadOf_Delete_Update
    SET Status = 'Marked_For_Delete', Counter = Counter + 1000
    WHERE ID IN (SELECT ID FROM deleted);
END;
GO


/*
 * ------------------------------------------------------------------------------------
 *  2.2.5 Scenerio -
 *  Insert command with output clause on view
 *  INSTEAD OF trigger on Insert 
 *  Delete inside trigger deleting new inserted row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_InsteadOf_Insert_Delete (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- INSTEAD OF INSERT trigger that deletes existing rows
CREATE TRIGGER tr_EPQTest_InsteadOf_Delete_OnInsert
ON EPQTest_InsteadOf_Insert_Delete
INSTEAD OF INSERT
AS
BEGIN
    DELETE FROM EPQTest_InsteadOf_Insert_Delete 
    WHERE Value < (SELECT MIN(Value) FROM inserted);
    
    INSERT INTO EPQTest_InsteadOf_Insert_Delete (ID, Name, Value, Counter, Status)
    SELECT ID, Name, Value, Counter, Status FROM inserted;
END;
GO

/*
 * ------------------------------------------------------------------------------------
 *  2.2.6 Scenerio -
 *  Insert command with output clause on view
 *  INSTEAD OF trigger on Insert 
 *  Update inside trigger Updating new inserted row
 * ------------------------------------------------------------------------------------
 */

-- Setup EPQ test table
CREATE TABLE EPQTest_InsteadOf_Insert_Update (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Value INT,
    Counter INT DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- INSTEAD OF INSERT trigger that updates existing rows and inserts new ones
CREATE TRIGGER tr_EPQTest_InsteadOf_Update_OnInsert
ON EPQTest_InsteadOf_Insert_Update
INSTEAD OF INSERT
AS
BEGIN
    UPDATE EPQTest_InsteadOf_Insert_Update 
    SET Status = 'Updated_By_Insert', Counter = Counter + 500
    WHERE Value < (SELECT MAX(Value) FROM inserted);
    
    INSERT INTO EPQTest_InsteadOf_Insert_Update (ID, Name, Value, Counter, Status)
    SELECT ID, Name, Value, Counter, 'Inserted_Via_Trigger' FROM inserted;
END;
GO


-- /*
--  * ------------------------------------------------------------------------------------
--  *  2.3 Delete and Update Trigger Deadlock - EPQ Test Case
--  *  
--  *  Scenario:
--  *  1. UPDATE command with OUTPUT clause on row ID=1
--  *  2. UPDATE trigger fires and DELETES the same row (ID=1)
--  *  3. DELETE trigger fires and tries to UPDATE the deleted row (ID=1)
--  *  4. Creates circular dependency: UPDATE -> DELETE -> UPDATE (same row)
--  *  5. OUTPUT clause references row data that gets deleted mid-operation
--  *  
--  *  Expected Output:  Should give table values without any change
--  *
--  *. Actual Output: Crashing
--  * ------------------------------------------------------------------------------------
--  */

-- -- Setup EPQ test table for INSTEAD OF triggers
-- CREATE TABLE EPQTest_Delete_Update_deadlock (
--     ID INT PRIMARY KEY,
--     Name NVARCHAR(50),
--     Value INT,
--     Counter INT DEFAULT 0,
--     Status NVARCHAR(20) DEFAULT 'Active'
-- );
-- GO

-- -- Insert test data
-- INSERT INTO EPQTest_Delete_Update_deadlock (ID, Name, Value, Counter) VALUES 
-- (1, 'Row1', 100, 1),
-- (2, 'Row2', 200, 2),
-- (3, 'Row3', 300, 3);
-- GO

-- -- UPDATE trigger that deletes the same row
-- CREATE TRIGGER tr_Update_Delete_Deadlock
-- ON EPQTest_Delete_Update_deadlock
-- AFTER UPDATE
-- AS
-- BEGIN
--     DELETE FROM EPQTest_Delete_Update_deadlock
--     WHERE ID IN (SELECT ID FROM inserted);
-- END;
-- GO

-- -- DELETE trigger that tries to update the same row (creates deadlock)
-- CREATE TRIGGER tr_Delete_Update_Deadlock
-- ON EPQTest_Delete_Update_deadlock
-- AFTER DELETE
-- AS
-- BEGIN
--     UPDATE EPQTest_Delete_Update_deadlock
--     SET Status = 'Updated_After_Delete', Counter = Counter + 1000
--     WHERE ID IN (SELECT ID FROM deleted);
-- END;
-- GO

-- /* 
--  * ====================================================================================
--  *  2.4 Mixed Triggers Scenerio
--  * ====================================================================================
--  */

 
-- /*   2.4.1 For Update command -    
--  * ------------------------------------------------------------------------------------
--  *  Scenario:
--  *  1. UPDATE command with OUTPUT clause on row ID=1
--  *  2. After trigger and Instead of trigger both present
--  *  
--  *  Expected Output:  Should give updated value
--  *
--  *  Actual Output: giving before update value
--  * ------------------------------------------------------------------------------------
--  */

-- -- Test case with both INSTEAD OF and AFTER triggers on same UPDATE
-- CREATE TABLE MixedTriggerTest (
--     ID INT PRIMARY KEY,
--     Name NVARCHAR(50),
--     Value INT
-- );
-- GO

-- INSERT INTO MixedTriggerTest VALUES (1, 'Test', 100);
-- GO

-- -- Create table to store trigger OUTPUT results
-- CREATE TABLE TriggerOutputLogMixed (
--     TriggerName NVARCHAR(50),
--     ID INT,
--     OldValue INT,
--     NewValue INT
-- );
-- GO

-- -- INSTEAD OF trigger on view
-- CREATE TRIGGER tr_InsteadOf_Mixed
-- ON MixedTriggerTest
-- INSTEAD OF UPDATE
-- AS
-- BEGIN
--     UPDATE MixedTriggerTest 
--     SET Value = inserted.Value + 10
--     OUTPUT 'InsteadOf_Trigger', deleted.ID, deleted.Value, inserted.Value
--     INTO TriggerOutputLogMixed (TriggerName, ID, OldValue, NewValue)
--     FROM MixedTriggerTest m
--     INNER JOIN inserted i ON m.ID = i.ID;
-- END;
-- GO

-- -- AFTER trigger on base table
-- CREATE TRIGGER tr_After_Mixed
-- ON MixedTriggerTest
-- AFTER UPDATE
-- AS
-- BEGIN
--     UPDATE MixedTriggerTest 
--     SET Value = Value + 100
--     WHERE ID IN (SELECT ID FROM inserted);
-- END;
-- GO


-- /*  2.4.2 For Delete command -    
--  * ------------------------------------------------------------------------------------
--  *  Scenario:
--  *  1. DELETE command with OUTPUT clause on row ID=1
--  *  2. After trigger and Instead of trigger both present
--  *  
--  *  Expected Output:  Should give deleted value
--  *
--  *  Actual Output: giving before delete value
--  * ------------------------------------------------------------------------------------
--  */

-- -- Test case with both INSTEAD OF and AFTER triggers on same DELETE
-- CREATE TABLE MixedTriggerTestDelete (
--     ID INT PRIMARY KEY,
--     Name NVARCHAR(50),
--     Value INT
-- );
-- GO

-- INSERT INTO MixedTriggerTestDelete VALUES (1, 'Test', 100);
-- GO

-- -- Create table to store trigger OUTPUT results
-- CREATE TABLE TriggerOutputLogMixedDelete (
--     TriggerName NVARCHAR(50),
--     ID INT,
--     DeletedValue INT
-- );
-- GO

-- -- INSTEAD OF trigger on view
-- CREATE TRIGGER tr_InsteadOf_MixedDelete
-- ON MixedTriggerTestDelete
-- INSTEAD OF DELETE
-- AS
-- BEGIN
--     DELETE FROM MixedTriggerTestDelete 
--     OUTPUT 'InsteadOf_Delete', deleted.ID, deleted.Value
--     INTO TriggerOutputLogMixedDelete (TriggerName, ID, DeletedValue)
--     WHERE ID IN (SELECT ID FROM deleted);
-- END;
-- GO

-- -- AFTER trigger on base table
-- CREATE TRIGGER tr_After_MixedDelete
-- ON MixedTriggerTestDelete
-- AFTER DELETE
-- AS
-- BEGIN
--     INSERT INTO TriggerOutputLogMixedDelete (TriggerName, ID, DeletedValue)
--     SELECT 'After_Delete', deleted.ID, deleted.Value FROM deleted;
-- END;
-- GO

-- /*   2.4.3 For Insert command -    
--  * ------------------------------------------------------------------------------------
--  *  Scenario:
--  *  1. INSERT command with OUTPUT clause on row ID=1
--  *  2. After trigger and Instead of trigger both present
--  *  
--  *  Expected Output:  Should give inserted value
--  *
--  *  Actual Output: giving before insert value
--  * ------------------------------------------------------------------------------------
--  */

-- -- Test case with both INSTEAD OF and AFTER triggers on same INSERT
-- CREATE TABLE MixedTriggerTestInsert (
--     ID INT PRIMARY KEY,
--     Name NVARCHAR(50),
--     Value INT
-- );
-- GO

-- -- Create table to store trigger OUTPUT results
-- CREATE TABLE TriggerOutputLogMixedInsert (
--     TriggerName NVARCHAR(50),
--     ID INT,
--     InsertedValue INT
-- );
-- GO

-- -- INSTEAD OF trigger on view
-- CREATE TRIGGER tr_InsteadOf_MixedInsert
-- ON MixedTriggerTestInsert
-- INSTEAD OF INSERT
-- AS
-- BEGIN
--     INSERT INTO MixedTriggerTestInsert (ID, Name, Value)
--     OUTPUT 'InsteadOf_Insert', inserted.ID, inserted.Value
--     INTO TriggerOutputLogMixedInsert (TriggerName, ID, InsertedValue)
--     SELECT ID, Name, Value + 10 FROM inserted;
-- END;
-- GO

-- -- AFTER trigger on base table
-- CREATE TRIGGER tr_After_MixedInsert
-- ON MixedTriggerTestInsert
-- AFTER INSERT
-- AS
-- BEGIN
--     INSERT INTO TriggerOutputLogMixedInsert (TriggerName, ID, InsertedValue)
--     SELECT 'After_Insert', inserted.ID, inserted.Value FROM inserted;
    
--     UPDATE MixedTriggerTestInsert 
--     SET Value = Value + 100
--     WHERE ID IN (SELECT ID FROM inserted);
-- END;
-- GO