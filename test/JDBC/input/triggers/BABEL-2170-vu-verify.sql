-- Instead of Insert Trigger on View 
CREATE TRIGGER babel_2170_vu_employees_view_iot_insert ON babel_2170_vu_employees_view
INSTEAD OF INSERT
AS
BEGIN
    UPDATE babel_2170_vu_employees SET EmployeeAddress = 'New Street' WHERE EmployeeID = 3;
END
GO

INSERT INTO babel_2170_vu_employees_view VALUES(5, 'alex', '1st Street', '5000');
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees;
GO

SELECT COUNT(EmployeeID) FROM babel_2170_vu_employees_view;
GO

UPDATE babel_2170_vu_employees SET EmployeeAddress = '1st Street' WHERE EmployeeID = 3;
GO

-- Instead of Update Trigger on View 
CREATE TRIGGER babel_2170_vu_employees_view_iot_update ON babel_2170_vu_employees_view
INSTEAD OF UPDATE
AS
BEGIN
    UPDATE babel_2170_vu_employees SET MonthSalary = MonthSalary + 100 WHERE EmployeeID = 3;
END
GO

UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 3;
GO

SELECT EmployeeID,EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID = 3 ORDER BY EmployeeID;
GO

UPDATE babel_2170_vu_employees SET MonthSalary = 3000 WHERE EmployeeID = 3;
GO

BEGIN TRANSACTION
    UPDATE babel_2170_vu_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID IN (3, 4);
COMMIT TRANSACTION;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_vu_employees WHERE EmployeeID IN (3, 4) ORDER BY EmployeeID;
GO

UPDATE babel_2170_vu_employees SET MonthSalary = 3000 WHERE EmployeeID = 3;
GO

-- Instead of Delete Trigger on View
CREATE TRIGGER babel_2170_vu_employees_view_iot_delete ON babel_2170_vu_employees_view
INSTEAD OF DELETE
AS
BEGIN
    UPDATE babel_2170_vu_employees SET MonthSalary = MonthSalary + 100 WHERE EmployeeID = 3;
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

UPDATE babel_2170_vu_employees SET MonthSalary = 3000 WHERE EmployeeID = 3;
GO