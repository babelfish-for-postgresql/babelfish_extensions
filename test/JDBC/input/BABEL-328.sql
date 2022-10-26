--Script #1 - Creating some temporary objects to work on...
CREATE TABLE [Department]( 
    [DepartmentID] [int] NOT NULL PRIMARY KEY, 
    [Name] VARCHAR(250) NOT NULL, 
) ON [PRIMARY] 
GO

INSERT [Department] ([DepartmentID], [Name])  
VALUES (1, N'Engineering')
INSERT [Department] ([DepartmentID], [Name])  
VALUES (2, N'Administration')
INSERT [Department] ([DepartmentID], [Name])  
VALUES (3, N'Sales')
INSERT [Department] ([DepartmentID], [Name])  
VALUES (4, N'Marketing')
INSERT [Department] ([DepartmentID], [Name])  
VALUES (5, N'Finance')
GO

CREATE TABLE [Employee]( 
    [EmployeeID] [int] NOT NULL PRIMARY KEY, 
    [FirstName] VARCHAR(250) NOT NULL, 
    [LastName] VARCHAR(250) NOT NULL, 
    [DepartmentID] [int] NOT NULL REFERENCES [Department](DepartmentID), 
) ON [PRIMARY] 
GO

INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (1, N'Orlando', N'Gee', 1 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (2, N'Keith', N'Harris', 2 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (3, N'Donna', N'Carreras', 3 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (4, N'Janet', N'Gates', 3 ) 
GO

--Script #2 - CROSS APPLY and INNER JOIN
SELECT * FROM Department D 
CROSS APPLY 
( 
    SELECT * FROM Employee E 
    WHERE E.DepartmentID = D.DepartmentID 
) A 
GO

SELECT * FROM Department D 
INNER JOIN Employee E ON D.DepartmentID = E.DepartmentID 
GO

--Script #3 - OUTER APPLY and LEFT OUTER JOIN
SELECT * FROM Department D 
OUTER APPLY 
( 
    SELECT * FROM Employee E 
    WHERE E.DepartmentID = D.DepartmentID 
) A 
GO

SELECT * FROM Department D 
LEFT OUTER JOIN Employee E ON D.DepartmentID = E.DepartmentID 
GO

--Script #4 - APPLY with table-valued function 
CREATE FUNCTION dbo.fn_GetAllEmployeeOfADepartment(@DeptID AS INT)  
RETURNS TABLE 
AS 
RETURN 
( 
    SELECT * FROM Employee E 
    WHERE E.DepartmentID = @DeptID 
) 
GO

SELECT * FROM Department D 
CROSS APPLY dbo.fn_GetAllEmployeeOfADepartment(D.DepartmentID) 
GO

SELECT * FROM Department D 
OUTER APPLY dbo.fn_GetAllEmployeeOfADepartment(D.DepartmentID) 
GO

DROP FUNCTION dbo.fn_GetAllEmployeeOfADepartment
GO

--Script #5 - Regression test to make sure CROSS/OUTER are still parsed correctly
--These calls should return an error
SELECT * FROM Department D
CROSS Employee E
GO

-- chaining apply calls
SELECT * FROM Department D
OUTER Employee E
GO

DROP TABLE [Employee]
GO
DROP TABLE [Department]
GO

create table t1 (a int, b int)
create table t2 (c int, d int)
insert into t1 values (1, 1),(2, 2)
insert into t2 values (3, 3),(4, 4)
go

select * from t1 outer apply t2 outer apply (values (5,5),(6,6)) t3 (e, f)
go

select * from t1 cross apply t2 cross apply (values (5,5),(6,6)) t3 (e, f)
go

drop table t1
go

drop table t2
go

