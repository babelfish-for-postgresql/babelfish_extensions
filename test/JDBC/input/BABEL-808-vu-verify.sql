SELECT PARSENAME('tempdb.dbo.Employee', 3) AS [Database Name],
PARSENAME('tempdb.dbo.Employee', 2) AS [Schema Name],
PARSENAME('tempdb.dbo.Employee', 1) AS [Table Name],
*
FROM
Employee
ORDER BY HireDate DESC;
GO

SELECT * FROM EmployeeDatabaseView1
GO

EXEC GetEmployeeDatabaseName1
GO

SELECT * FROM EmployeeDatabaseView2
GO

EXEC GetEmployeeDatabaseName2
GO

SELECT * FROM EmployeeDatabaseView3
GO

EXEC GetEmployeeDatabaseName3
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

SELECT PARSENAME('tempdb.dbo.Employeeddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',1)
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