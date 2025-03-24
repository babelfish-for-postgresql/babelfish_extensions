-- Test basic functions
SELECT * FROM [dbo].[TestInlineOn](5)
SELECT * FROM [dbo].[TestInlineOff](5)
SELECT * FROM [dbo].[TestNoInline](5)
GO

-- Test NULL handling
SELECT * FROM [dbo].[TestNullHandling](NULL)
SELECT * FROM [dbo].[TestNullHandling](10)
GO

-- Test nested function calls
SELECT * FROM [dbo].[TestNested](5)
GO

-- Test different data types
SELECT * FROM [dbo].[TestDataTypes](10, 20.5, 'test')
GO

-- Test table variable
SELECT * FROM [dbo].[TestTableVariable](5)
GO

-- Test error handling
BEGIN TRY
    SELECT * FROM [dbo].[TestErrorHandling](-5)
END TRY
BEGIN CATCH
    SELECT * FROM ERROR_MESSAGE()
END CATCH
SELECT * FROM [dbo].[TestErrorHandling](5)
GO

-- Test with table aliases
SELECT t.ID, [dbo].[TestInlineOn](t.ID) AS Result
FROM TestTable t ORDER BY t.ID
GO

-- Boundary testing
SELECT * FROM [dbo].[TestInlineOn](2147483647) -- MAX_INT
GO

SELECT * FROM [dbo].[TestInlineOn](-2147483648) -- MIN_INT
GO

-- Arbitrary input
DECLARE @i INT = 0
WHILE @i < 10
BEGIN
    SELECT * FROM [dbo].[TestInlineOn](@i * 100)
    SET @i = @i + 1
END
GO

-- Test SCHEMABINDING
SELECT [dbo].[TestSchemabinding](5)
GO

-- Test EXECUTE AS
SELECT [dbo].[TestExecuteAs](5)
GO

-- Test combinations of options
SELECT [dbo].[TestInlineAndSchemabinding](5)
SELECT [dbo].[TestInlineAndExecuteAs](5)
SELECT [dbo].[TestSchemabindingAndExecuteAs](5)
SELECT [dbo].[TestAllOptions](5)
GO

-- Test RETURNS NULL ON NULL INPUT
SELECT [dbo].[TestReturnsNullOnNullInput](5)
SELECT [dbo].[TestReturnsNullOnNullInput](NULL)
GO

-- Test multiple parameters and all options
SELECT [dbo].[TestMultiParamAllOptions](5, 'Test', 15.75)
GO