SELECT PARSENAME('tempdb.dbo.Employee', 3) AS [Database Name],
PARSENAME('tempdb.dbo.Employee', 2) AS [Schema Name],
PARSENAME('tempdb.dbo.Employee', 1) AS [Table Name],
*
FROM
parsename_Employee
ORDER BY HireDate DESC;
GO

SELECT * FROM parsename_EmployeeDatabaseView1
GO

EXEC parsename_GetEmployeeDatabaseName1
GO

SELECT * FROM parsename_EmployeeDatabaseView2
GO

EXEC parsename_GetEmployeeDatabaseName2
GO

SELECT * FROM parsename_EmployeeDatabaseView3
GO

EXEC parsename_GetEmployeeDatabaseName3
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',1)
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',2)
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',4)
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',5)
GO

SELECT PARSENAME('tempdb.dbo.Employee',1)
GO

SELECT PARSENAME('tempdb.dbo.Employee',2)
GO

SELECT PARSENAME('tempdb.dbo.Employee',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee',5)
GO

SELECT PARSENAME('.dbo.Employee',1)
GO

SELECT PARSENAME('.dbo.Employee',2)
GO

SELECT PARSENAME('.dbo.Employee',3)
GO

SELECT PARSENAME('..Employee',1)
GO

SELECT PARSENAME('..Employee',2)
GO

SELECT PARSENAME('..Employee',3)
GO

SELECT PARSENAME('..',1)
GO

SELECT PARSENAME('tempdb..Employee',2)
GO

SELECT PARSENAME('tempdb..Employee',3)
GO

SELECT PARSENAME('.dbo.Employee',3)
GO

SELECT PARSENAME('.dbo.Employee.table',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee.', 1)
GO

SELECT PARSENAME('tempdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd.dbo.Employee',2)
GO

SELECT PARSENAME('tempdbvddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd.dbo.Employee',2)
GO

SELECT PARSENAME('tempdb.dbopdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd.Employee',1)
GO

SELECT PARSENAME('tempdb.dbo.Employeeddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',1)
GO

SELECT PARSENAME('[tempdb].[dbo].[Employee]',1)
GO

SELECT PARSENAME('[tempdb].[dbo].[Employee]',2)
GO

SELECT PARSENAME('[tempdb].[dbo].[Employee]',3)
GO

SELECT PARSENAME('tempdb.dbo.[Empl[oyee]',1)
GO

SELECT PARSENAME('tempdb.dbo.[Empl]oyee]',1)
GO

SELECT PARSENAME('tempdb.dbo.[Empl]]oyee]',1)
GO

--If there is continuous double close brackets inside open and close bracket it should escape one bracket evertime if it encounter a continuous close bracket.
SELECT PARSENAME('tempdb.dbo.[Empl]]oy]]ee]',1)
GO

SELECT PARSENAME('tempdb.dbo.[Employe]e',1)
GO

SELECT PARSENAME('[tempdb].[dbo].[Empl"oyee]',1)
GO

SELECT PARSENAME('[tempdb].[dbo].[Empl""oyee]',1)
GO

SELECT PARSENAME('tempdb.dbo.Em[ployee]',1)
GO

SELECT PARSENAME('tempdb.dbo.Em[ployee',1)
GO

SELECT PARSENAME('tempdb.dbo.Em]ployee',1)
GO

SELECT PARSENAME('[tempdb.dbo.Employee]',1)
GO

SELECT PARSENAME('tempdb.dbo."Emp"loyee"',1)
GO

SELECT PARSENAME('tempdb.dbo."Emp""loyee"',1)
GO

SELECT PARSENAME('tempdb.dbo."Emp""loy""ee"',1)
GO

SELECT PARSENAME('tempdb.dbo."Empl]oyee"',1)
GO

SELECT PARSENAME('tempdb.dbo."Empl]]oyee"',1)
GO

SELECT PARSENAME('tempdb.dbo."Employe"e',1)
GO

SELECT PARSENAME('tempdb.dbo.Em"ployee',1)
GO

SELECT PARSENAME('tempdb.dbo.Em"ployee"',1)
GO

SELECT PARSENAME('"tempdb.dbo.Employee"',1)
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 1) AS 'Object Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 2) AS 'Schema Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 3) AS 'Database Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 4) AS 'Server Name';  
GO

SELECT PARSENAME('tempdbvddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbopdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddEmployeedddddddddddddddddddddddddddtempdbvddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbopdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddEmployeedddddddddddddddddddddddddddtempdbvddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbopdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddEmployeedddddddddddddddddddddddddddtempdbvddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbopdbvdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddEmployeeddddddddddddddddddddddddddd',1)
GO

--128 unicode characters
SELECT PARSENAME('ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち',1)
GO

--129 unicode characters
SELECT PARSENAME('ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち',1)
GO