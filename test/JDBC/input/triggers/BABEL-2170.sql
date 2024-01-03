CREATE TABLE babel_2170_employees
(
    EmployeeID      int NOT NULL,
    EmployeeName    VARCHAR(50),
    EmployeeAddress VARCHAR(50),
    MonthSalary     NUMERIC(10, 2)
)
GO

INSERT INTO babel_2170_employees VALUES(1, 'ash', '1st Street', '1000');
INSERT INTO babel_2170_employees VALUES(2, 'bob', '1st Street', '2000');
GO

CREATE VIEW babel_2170_employees_view AS
SELECT EmployeeID,
       EmployeeName,
       EmployeeAddress,
       MonthSalary
FROM babel_2170_employees;
GO

-- Instead of Insert Trigger on View 
CREATE TRIGGER babel_2170_employees_view_iot_insert ON babel_2170_employees_view
INSTEAD OF INSERT
AS
BEGIN
    SELECT 'Trigger babel_2170_employees_view_iot_insert Invoked'
END
GO

INSERT INTO babel_2170_employees_view VALUES(3, 'john', '1st Street', '3000');
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_employees_view ORDER BY EmployeeID;
GO

-- Instead of Update Trigger on View 
CREATE TRIGGER babel_2170_employees_view_iot_update ON babel_2170_employees_view
INSTEAD OF UPDATE
AS
BEGIN
    SELECT 'Trigger babel_2170_employees_view_iot_update Invoked'
END
GO

UPDATE babel_2170_employees_view SET MonthSalary = MonthSalary +1 WHERE EmployeeID = 2;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_employees_view ORDER BY EmployeeID;
GO

-- Instead of Delete Trigger on View 

CREATE TRIGGER babel_2170_employees_view_iot_delete ON babel_2170_employees_view
INSTEAD OF DELETE
AS
BEGIN
    SELECT 'Trigger babel_2170_employees_view_iot_delete Invoked'
END
GO

BEGIN TRANSACTION
    DELETE FROM babel_2170_employees_view WHERE EmployeeID IN (1, 2);
COMMIT TRANSACTION;
GO

SELECT EmployeeID, EmployeeName, EmployeeAddress, MonthSalary FROM babel_2170_employees_view ORDER BY EmployeeID;
GO

DROP TRIGGER IF EXISTS babel_2170_employees_view_iot_insert;
GO

DROP TRIGGER IF EXISTS babel_2170_employees_view_iot_update;
GO

DROP TRIGGER IF EXISTS babel_2170_employees_view_iot_delete;
GO

DROP VIEW IF EXISTS babel_2170_employees_view;
GO

DROP TABLE IF EXISTS babel_2170_employees;
GO