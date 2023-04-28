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

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 1) AS 'Object Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 2) AS 'Schema Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 3) AS 'Database Name';
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 4) AS 'Server Name';  
GO