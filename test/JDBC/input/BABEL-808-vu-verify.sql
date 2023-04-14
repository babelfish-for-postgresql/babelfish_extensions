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