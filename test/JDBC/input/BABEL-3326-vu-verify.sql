
-- Verification

-- Check support for following syntax 
-- ALTER TABLE { database_name.schema_name.table_name | schema_name.table_name | table_name }
--  { ENABLE | DISABLE } TRIGGER
--      { ALL | trigger_name [ ,...n ] }
use master;
go

-- triggers should be enabled by default
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE babel_3326_Employees DISABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE babel_3326_Employees ENABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE dbo.babel_3326_Employees DISABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE dbo.babel_3326_Employees ENABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE master.dbo.babel_3326_Employees DISABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ALTER TABLE master.dbo.babel_3326_Employees ENABLE TRIGGER TR_ins_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

-- TR_upd_babel_3326_Employees should be enabled by default
UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ALTER TABLE babel_3326_Employees DISABLE TRIGGER ALL
GO

-- All triggers on table babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ALTER TABLE babel_3326_Employees ENABLE TRIGGER ALL
GO

-- All triggers on table babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ALTER TABLE babel_3326_Employees DISABLE TRIGGER TR_ins_babel_3326_Employees, TR_upd_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees and TR_upd_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ALTER TABLE babel_3326_Employees ENABLE TRIGGER TR_ins_babel_3326_Employees, TR_upd_babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees and TR_upd_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO


-- Check support for following syntax
-- { ENABLE | DISABLE } TRIGGER { [ schema_name . ] trigger_name [ ,...n ] | ALL }  
-- ON { table_name } [ ; ]

DISABLE TRIGGER TR_ins_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ENABLE TRIGGER TR_ins_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

DISABLE TRIGGER dbo.TR_ins_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

ENABLE TRIGGER dbo.TR_ins_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO


DISABLE TRIGGER ALL ON babel_3326_Employees
GO

-- All triggers on table babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ENABLE TRIGGER ALL ON babel_3326_Employees
GO

-- All triggers on table babel_3326_Employees  should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO


DISABLE TRIGGER TR_ins_babel_3326_Employees, TR_upd_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees and TR_upd_babel_3326_Employees should be disabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO

ENABLE TRIGGER TR_ins_babel_3326_Employees, TR_upd_babel_3326_Employees ON babel_3326_Employees
GO

-- TR_ins_babel_3326_Employees and TR_upd_babel_3326_Employees should be enabled
INSERT INTO dbo.babel_3326_Employees ( EmployeeName , EmployeeAddress ,MonthSalary )
VALUES ( 'Temp Name5' , 'Address Name 5', 4000)
GO

UPDATE dbo.babel_3326_Employees
SET MonthSalary = 3333
WHERE EmployeeID = 2;
GO
