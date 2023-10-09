-- We will create two databases db1_BABEL2170, db2_BABEL2170
CREATE DATABASE db1_BABEL2170;
GO

USE db1_BABEL2170;
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
INSERT INTO babel_2170_vu_employees VALUES(3, 'ana', '1st Street', '3000');
INSERT INTO babel_2170_vu_employees VALUES(4, 'adam', '1st Street', '4000');
GO

CREATE VIEW babel_2170_vu_employees_view AS
SELECT EmployeeID,
       EmployeeName,
       EmployeeAddress,
       MonthSalary
FROM babel_2170_vu_employees
WHERE EmployeeName LIKE 'a%';
GO

CREATE VIEW babel_2170_vu_employees_view_bulkinsert AS
SELECT EmployeeID,
       EmployeeName,
       EmployeeAddress,
       MonthSalary
FROM babel_2170_vu_employees
WHERE EmployeeName LIKE 'b%';
GO

CREATE SCHEMA schema_2170;
GO

CREATE TABLE schema_2170.babel_2170_vu_employees
(
    EmployeeID      int NOT NULL,
    EmployeeName    VARCHAR(50),
    EmployeeAddress VARCHAR(50),
    MonthSalary     NUMERIC(10, 2)
)
GO

INSERT INTO schema_2170.babel_2170_vu_employees VALUES(1, 'amber', '1st Street', '1000');
INSERT INTO schema_2170.babel_2170_vu_employees VALUES(2, 'angel', '1st Street', '2000');
INSERT INTO schema_2170.babel_2170_vu_employees VALUES(3, 'ana', '1st Street', '3000');
INSERT INTO schema_2170.babel_2170_vu_employees VALUES(4, 'adam', '1st Street', '4000');
GO

CREATE VIEW schema_2170.babel_2170_vu_employees_view AS
SELECT EmployeeID,
       EmployeeName,
       EmployeeAddress,
       MonthSalary
FROM schema_2170.babel_2170_vu_employees
WHERE EmployeeName LIKE 'a%';
GO