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

INSERT INTO babel_2170_vu_employees_view VALUES(5, 'alex', '1st Street', '5000');
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

UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 3;
GO

SELECT EmployeeID,EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID = 3 ORDER BY EmployeeID;
GO

BEGIN TRANSACTION
    UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID IN (3, 4);
COMMIT TRANSACTION;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID IN (3, 4) ORDER BY EmployeeID;
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
    SELECT * from INSERTED;
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

-- cleanup default dbo schema IO upadte trigger
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

UPDATE [schema_2170].[babel_2170_vu_employees_view] SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 3;
GO

UPDATE [dbo].[babel_2170_vu_employees_view] SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 3;
GO

DROP TRIGGER IF EXISTS [schema_2170].[babel_2170_vu_employees_view_iot_update];
GO

DROP TRIGGER IF EXISTS[dbo].[babel_2170_vu_employees_view_iot_update];
GO

-- create same name Instead of Insert trigger in second db to test Cross db behavior
USE db2_BABEL2170;
GO

CREATE TRIGGER babel_2170_vu_employees_view_iot_insert ON babel_2170_vu_employees_view
INSTEAD OF INSERT
AS
BEGIN
    SELECT 'Trigger db2_BABEL2170.dbo.babel_2170_vu_employees_view_iot_insert Invoked'
END
GO

-- should fire IOT trigger of second db
INSERT INTO babel_2170_vu_employees_view VALUES(5, 'alex', '1st Street db2_BABEL2170', '5000');
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID =3;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees_view WHERE EmployeeID =5;
GO