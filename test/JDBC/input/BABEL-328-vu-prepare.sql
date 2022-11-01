--Script #1 - Creating some temporary objects to work on...
CREATE TABLE [babel_328_vu_t1]( 
    [DepartmentID] [int] NOT NULL PRIMARY KEY, 
    [Name] VARCHAR(250) NOT NULL, 
) ON [PRIMARY] 
GO

INSERT [babel_328_vu_t1] ([DepartmentID], [Name])  
VALUES (1, N'Engineering')
INSERT [babel_328_vu_t1] ([DepartmentID], [Name])  
VALUES (2, N'Administration')
INSERT [babel_328_vu_t1] ([DepartmentID], [Name])  
VALUES (3, N'Sales')
INSERT [babel_328_vu_t1] ([DepartmentID], [Name])  
VALUES (4, N'Marketing')
INSERT [babel_328_vu_t1] ([DepartmentID], [Name])  
VALUES (5, N'Finance')
GO

CREATE TABLE [babel_328_vu_t2]( 
    [EmployeeID] [int] NOT NULL PRIMARY KEY, 
    [FirstName] VARCHAR(250) NOT NULL, 
    [LastName] VARCHAR(250) NOT NULL, 
    [DepartmentID] [int] NOT NULL REFERENCES [babel_328_vu_t1](DepartmentID), 
) ON [PRIMARY] 
GO

INSERT [babel_328_vu_t2] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (1, N'Orlando', N'Gee', 1 ) 
INSERT [babel_328_vu_t2] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (2, N'Keith', N'Harris', 2 ) 
INSERT [babel_328_vu_t2] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (3, N'Donna', N'Carreras', 3 ) 
INSERT [babel_328_vu_t2] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (4, N'Janet', N'Gates', 3 ) 
GO

--Script #2 - CROSS APPLY and INNER JOIN
CREATE VIEW babel_328_vu_v1 as
SELECT Name FROM babel_328_vu_t1 D
CROSS APPLY
(
    SELECT * FROM babel_328_vu_t2 E
    WHERE E.DepartmentID = D.DepartmentID
) A
GO

CREATE VIEW babel_328_vu_v2 as
    SELECT Name FROM babel_328_vu_t1 D 
    INNER JOIN babel_328_vu_t2 E ON D.DepartmentID = E.DepartmentID 
GO

--Script #3 - OUTER APPLY and LEFT OUTER JOIN
CREATE VIEW babel_328_vu_v3 as
SELECT Name FROM babel_328_vu_t1 D
OUTER APPLY
(
    SELECT * FROM babel_328_vu_t2 E
    WHERE E.DepartmentID = D.DepartmentID
) A
GO

CREATE VIEW babel_328_vu_v4 as
    SELECT Name FROM babel_328_vu_t1 D
    LEFT OUTER JOIN babel_328_vu_t2 E ON D.DepartmentID = E.DepartmentID
GO

--Script #4 - APPLY with table-valued function 
CREATE FUNCTION babel_328_vu_f1(@DeptID AS INT)  
RETURNS TABLE 
AS 
RETURN 
( 
    SELECT * FROM babel_328_vu_t2 E 
    WHERE E.DepartmentID = @DeptID 
) 
GO

CREATE PROC babel_328_vu_p1 AS
    SELECT * FROM babel_328_vu_t1 D
    CROSS APPLY babel_328_vu_f1(D.DepartmentID)
GO

CREATE PROC babel_328_vu_p2 AS
    SELECT * FROM babel_328_vu_t1 D
    CROSS APPLY babel_328_vu_f1(D.DepartmentID) E
    WHERE E.DepartmentID = 3
GO

CREATE PROC babel_328_vu_p3 AS
    SELECT * FROM babel_328_vu_t1 D 
    OUTER APPLY babel_328_vu_f1(D.DepartmentID) 
GO

CREATE PROC babel_328_vu_p4 AS
    SELECT * FROM babel_328_vu_t1 D
    OUTER APPLY babel_328_vu_f1(D.DepartmentID) E
    WHERE E.DepartmentID = 3
GO

-- chaining apply calls
create table babel_328_vu_t3 (a int, b int)
create table babel_328_vu_t4 (c int, d int)
insert into babel_328_vu_t3 values (1, 1),(2, 2)
insert into babel_328_vu_t4 values (3, 3),(4, 4)
go

CREATE VIEW babel_328_vu_v5 AS
select * from babel_328_vu_t3 outer apply babel_328_vu_t4 outer apply (values (5,5),(6,6)) t3 (e, f)
go

CREATE VIEW babel_328_vu_v6 AS
select * from babel_328_vu_t3 cross apply babel_328_vu_t4 cross apply (values (5,5),(6,6)) t3 (e, f)
go

CREATE FUNCTION babel_328_vu_f2 () RETURNS TABLE AS 
RETURN
(
    WITH RowNumbers AS
    (
        SELECT TOP (1)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [Row]
        FROM       sys.all_columns AS R1
        CROSS JOIN sys.all_columns AS R2
    )
    SELECT CAST('20211212' AS DATETIME) AS [Date] FROM   RowNumbers
    CROSS APPLY
    (
        SELECT [Direction] = 1
    ) AS XS
)
GO
