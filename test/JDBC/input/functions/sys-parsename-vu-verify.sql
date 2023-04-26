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

SELECT PARSENAME('tempdb.dbo.Employee',1)
GO

SELECT PARSENAME('tempdb.dbo.Employee',2)
GO

SELECT PARSENAME('tempdb.dbo.Employee',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee',5)
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

SELECT PARSENAME('tempdb.dbo.Employee.', 1)
GO

SELECT PARSENAME('tempdb.dbo.Employee', 1,2)
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

SELECT PARSENAME('[tempdb].[d[[bo].[Employee]',1)
GO

SELECT PARSENAME('[tempdb].[dbo].[Employee]',3)
GO

SELECT PARSENAME('tempdb..Employee',2)
GO

SELECT PARSENAME('tempdb..Employee',3)
GO

SELECT PARSENAME('.dbo.Employee',3)
GO

SELECT PARSENAME('.dbo.Employee.table',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee.mytable',4)
GO

SELECT PARSENAME('.dbo.Employee.table',4)
GO

SELECT PARSENAME('.dbo.Employee',5)
GO

SELECT PARSENAME('tempdb.dbo.Employee.table.mytable.database',3)
GO

SELECT PARSENAME('tempdb.dbo.Employee.table.mytable',3)
GO

SELECT PARSENAME('tempdb.dbo.Em"ployee',1)
GO

SELECT PARSENAME('tempdb.dbo.Em[ployee',1)
GO

SELECT PARSENAME('tempdb.dbo.Em]ployee',1)
GO

SELECT PARSENAME('tempdb.dbo.[Empl]oyee]',1)
GO

SELECT PARSENAME('tempdb.dbo.[Empl[oyee]',1)
GO

SELECT PARSENAME('tempdb.dbo."Emp"loyee"',1)
GO