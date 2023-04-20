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