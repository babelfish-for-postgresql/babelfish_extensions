USE db1_BABEL2170;
GO

-- Instead of Insert Trigger on View 
CREATE TRIGGER babel_2170_vu_employees_view_iot_insert ON babel_2170_vu_employees_view
INSTEAD OF INSERT
AS
BEGIN
    SELECT 'Trigger db1_BABEL2170.dbo.babel_2170_vu_employees_view_iot_insert Invoked'
END
GO

INSERT INTO babel_2170_vu_employees_view VALUES(3, 'adam', '1st Street', '3000');
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees;
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees_view;
GO

-- Instead of Update Trigger on View 
CREATE TRIGGER babel_2170_vu_employees_view_iot_update ON babel_2170_vu_employees_view
INSTEAD OF UPDATE
AS
BEGIN
    SELECT 'Trigger db1_BABEL2170.dbo.babel_2170_vu_employees_view_iot_update Invoked'
END
GO

UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

SELECT EmployeeID,EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID = 2 ORDER BY EmployeeID;
GO

BEGIN TRANSACTION
    UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID IN (1, 2);
COMMIT TRANSACTION;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID IN (1, 2) ORDER BY EmployeeID;
GO

-- Instead of Delete Trigger on View
CREATE TRIGGER babel_2170_vu_employees_view_iot_delete ON babel_2170_vu_employees_view
INSTEAD OF DELETE
AS
BEGIN
    SELECT 'Trigger db1_BABEL2170.dbo.babel_2170_vu_employees_view_iot_delete Invoked'
END
GO

BEGIN TRANSACTION
    DELETE FROM babel_2170_vu_employees_view WHERE EmployeeID IN (1, 2);
COMMIT TRANSACTION;
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees_view;
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view ORDER BY EmployeeID;
GO

--- Tests multiple insert queries and check if inserted table can be accessed and trigger is working fine.
CREATE TRIGGER babel_2170_vu_employees_view_iot_bulkinsert ON babel_2170_vu_employees_view_bulkinsert
INSTEAD OF INSERT
AS
    SELECT * FROM INSERTED;
GO

BEGIN TRANSACTION
DECLARE @i int = 1
    WHILE @i <= 3
    BEGIN
        INSERT INTO babel_2170_vu_employees_view_bulkinsert VALUES(@i, 'bob', '1st Street', '1000');
        SET @i = @i + 1
    END
COMMIT TRANSACTION
GO

-- Test Instead of Update trigger in same db but cross schema 

-- Cleanup default dbo schema IO Update trigger
DROP TRIGGER IF EXISTS [dbo].[babel_2170_vu_employees_view_iot_update];
GO

CREATE TRIGGER [schema_2170].[babel_2170_vu_employees_view_iot_update] ON [schema_2170].[babel_2170_vu_employees_view]
INSTEAD OF UPDATE
AS
    SELECT 'Trigger db1_BABEL2170.schema_2170.babel_2170_vu_employees_view_iot_update Invoked'
GO

CREATE TRIGGER [babel_2170_vu_employees_view_iot_update] ON [babel_2170_vu_employees_view]
INSTEAD OF UPDATE
AS
    SELECT 'Trigger db1_BABEL2170.dbo.babel_2170_vu_employees_view_iot_update Invoked'
GO

UPDATE [schema_2170].[babel_2170_vu_employees_view] SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

UPDATE [dbo].[babel_2170_vu_employees_view] SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

DROP TRIGGER IF EXISTS [dbo].[babel_2170_vu_employees_view_iot_update];
GO

-- schema_2170 object cleanup
DROP TRIGGER IF EXISTS [schema_2170].babel_2170_vu_employees_view_iot_update;
GO

DROP VIEW IF EXISTS [schema_2170].babel_2170_vu_employees_view;
GO

DROP TABLE IF EXISTS [schema_2170].babel_2170_vu_employees;
GO

DROP SCHEMA IF EXISTS schema_2170;
GO

-- test multi-db mode
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.migration_mode', 'multi-db', false);
GO

CREATE DATABASE db2_BABEL2170;
GO

USE db2_BABEL2170;
GO

CREATE TABLE babel_2170_vu_employees
(
    EmployeeID      int NOT NULL,
    EmployeeName    VARCHAR(50),
    EmployeeAddress VARCHAR(50),
    MonthSalary     NUMERIC(10, 2)
)
GO

INSERT INTO babel_2170_vu_employees VALUES(1, 'amber', '1st Street', '1000');
INSERT INTO babel_2170_vu_employees VALUES(2, 'angel', '1st Street', '2000');
GO

CREATE VIEW babel_2170_vu_employees_view AS
SELECT EmployeeID,
       EmployeeName,
       EmployeeAddress,
       MonthSalary
FROM babel_2170_vu_employees
WHERE EmployeeName LIKE 'a%';
GO

-- create same name Instead of Insert trigger in second db to test Cross db behavior
CREATE TRIGGER babel_2170_vu_employees_view_iot_insert ON babel_2170_vu_employees_view
INSTEAD OF INSERT
AS
BEGIN
    SELECT 'Trigger db2_BABEL2170.dbo.babel_2170_vu_employees_view_iot_insert Invoked'
END
GO

-- should fire IOT trigger of second db
INSERT INTO babel_2170_vu_employees_view VALUES(3, 'adam', '1st Street db2_BABEL2170', '3000');
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view  ORDER BY EmployeeID;
GO

-- clean  all objects in second database
DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_insert;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_update;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_delete;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view;
GO

DROP TABLE IF EXISTS babel_2170_vu_employees;
GO

USE MASTER;
GO

DROP DATABASE IF EXISTS db2_BABEL2170;
GO

-- Go back to Single db mode
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.migration_mode', 'single-db', false);
GO

USE db1_BABEL2170;
GO

-- Test Transaction Commit and Rollback inside Instead of triggers
CREATE TRIGGER babel_2170_vu_employees_view_iot_txn_update ON babel_2170_vu_employees_view_txn
INSTEAD OF UPDATE
AS
    BEGIN
        BEGIN TRAN;
            INSERT INTO babel_2170_vu_employees_view_txn VALUES(3, 'adam', '1st Street', '3000');
        COMMIT tran;
    END
GO

UPDATE babel_2170_vu_employees_view_txn SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_txn_update;
GO

CREATE TRIGGER babel_2170_vu_employees_view_iot_txn_update ON babel_2170_vu_employees_view_txn
INSTEAD OF UPDATE
AS
    BEGIN
        BEGIN TRAN;
            INSERT INTO babel_2170_vu_employees_view_txn VALUES(3, 'adam', '1st Street', '3000');
        ROLLBACK tran;
    END
GO

UPDATE babel_2170_vu_employees_view_txn SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_txn_update;
GO

CREATE TRIGGER babel_2170_vu_employees_view_iot_txn_insert ON babel_2170_vu_employees_view_txn INSTEAD OF INSERT AS
BEGIN TRAN;
UPDATE babel_2170_vu_employees_view_txn SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
COMMIT;
SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
SELECT * FROM inserted;
GO

BEGIN TRAN;
GO
INSERT INTO babel_2170_vu_employees_view_txn VALUES(4, 'ana', '1st Street', '4000');
GO
COMMIT;
GO

BEGIN TRAN
GO
INSERT INTO babel_2170_vu_employees_view_txn VALUES(4, 'ana', '1st Street', '4000');
GO
IF (@@trancount > 0) ROLLBACK;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_txn_insert;
GO

CREATE TRIGGER babel_2170_vu_employees_view_iot_txn_update ON babel_2170_vu_employees_view_txn INSTEAD OF UPDATE AS
SAVE TRAN sp1;
SAVE TRAN sp2;
DELETE FROM babel_2170_vu_employees_view_txn where EmployeeID =2;
ROLLBACK TRAN sp1;
GO

BEGIN TRAN
GO
SELECT @@trancount;
UPDATE babel_2170_vu_employees_view_txn SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO
IF (@@trancount > 0) ROLLBACK;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_txn_update;
GO

CREATE TRIGGER babel_2170_vu_employees_view_iot_txn_delete ON babel_2170_vu_employees_view_txn INSTEAD OF DELETE AS
SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
INSERT INTO babel_2170_vu_employees_view_txn VALUES(5, 'ash', '1st Street', '5000');
SELECT * FROM deleted;
GO

DELETE FROM babel_2170_vu_employees_view_txn where EmployeeID =1;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view_txn ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_txn_delete;
GO