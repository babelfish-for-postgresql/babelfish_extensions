USE master
GO

SELECT * FROM datetime_table
GO

EXEC datetime_procedure
GO

SELECT dbo.datetime_function (cast(345.3 AS SMALLMONEY))
GO
