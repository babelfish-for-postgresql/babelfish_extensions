-- Preparation
use master;
go

CREATE TABLE babel_3326_Employees(
    EmployeeID      INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeName    VARCHAR(50) NOT NULL,
    EmployeeAddress VARCHAR(50) NOT NULL,
    MonthSalary     NUMERIC(10,2) NOT NULL
)
GO
 
INSERT INTO dbo.babel_3326_Employees
(
    EmployeeName,
    EmployeeAddress,
    MonthSalary
)
VALUES
(   'Temp Name1',
    'Temp Address 1',
    10000
    ),
(   'Temp Name2',
    'Temp Address 2',
    10000
),
(   'Temp Name3',
    'Temp Address 3',
    30000
),
(   'Temp Name4',
    'Temp Address 4',
    10000
)
GO

CREATE TRIGGER [dbo].[TR_ins_babel_3326_Employees] ON [dbo].[babel_3326_Employees]
FOR INSERT
AS
    SELECT 'Entry Inserted'
GO

CREATE TRIGGER [dbo].[TR_upd_babel_3326_Employees] ON [dbo].[babel_3326_Employees]
FOR UPDATE
AS
    SELECT 'Entry Updated'
GO