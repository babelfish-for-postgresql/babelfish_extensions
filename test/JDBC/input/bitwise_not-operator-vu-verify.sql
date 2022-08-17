USE master
GO

SELECT ~CAST(1 AS BIT)
GO

SELECT ~CAST(0 AS BIT)
GO

SELECT * FROM bitwise_not_vu_prepare_table
GO

EXEC bitwise_not_vu_prepare_procedure
GO

SELECT dbo.bitwise_not_vu_prepare_function()
GO