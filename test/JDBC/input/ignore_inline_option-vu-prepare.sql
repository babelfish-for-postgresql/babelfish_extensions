-- Basic function with INLINE = ON
CREATE FUNCTION [dbo].[TestInlineOn](@input INT)
RETURNS INT WITH INLINE = ON
AS
BEGIN
    RETURN @input * 2
END
GO

-- Basic function with INLINE = OFF
CREATE FUNCTION [dbo].[TestInlineOff](@input INT)
RETURNS INT WITH INLINE = OFF
AS
BEGIN
    RETURN @input * 3
END
GO

-- Function without INLINE option
CREATE FUNCTION [dbo].[TestNoInline](@input INT)
RETURNS INT
AS
BEGIN
    RETURN @input * 4
END
GO

-- Function with NULL handling
CREATE FUNCTION [dbo].[TestNullHandling](@input INT)
RETURNS INT WITH INLINE = ON
AS
BEGIN
    RETURN ISNULL(@input, 0) * 5
END
GO

-- Nested function calls
CREATE FUNCTION [dbo].[TestNested](@input INT)
RETURNS INT WITH INLINE = OFF
AS
BEGIN
    RETURN [dbo].[TestInlineOn]([dbo].[TestInlineOff](@input))
END
GO

-- Function with different data types
CREATE FUNCTION [dbo].[TestDataTypes](@input1 INT, @input2 DECIMAL(10,2), @input3 VARCHAR(50))
RETURNS VARCHAR(100) WITH INLINE = ON
AS
BEGIN
    RETURN CONCAT(CAST(@input1 AS VARCHAR(10)), ',', CAST(@input2 AS VARCHAR(20)), ',', @input3)
END
GO

-- Function with table variable
CREATE FUNCTION [dbo].[TestTableVariable](@input INT)
RETURNS INT WITH INLINE = OFF
AS
BEGIN
    DECLARE @TestTable TABLE (ID INT, Value INT)
    INSERT INTO @TestTable VALUES (1, @input), (2, @input * 2)
    RETURN (SELECT SUM(Value) FROM @TestTable ORDER BY ID)
END
GO

-- Function with error handling
CREATE FUNCTION [dbo].[TestErrorHandling](@input INT)
RETURNS INT WITH INLINE = ON
AS
BEGIN
    IF @input < 0
        THROW 50000, 'Input must be non-negative', 1
    RETURN @input
END
GO

-- NOTE: SCHEMABINDING, EXECUTE AS clause and INLINE clause, all should be ignored
-- Function with SCHEMABINDING
CREATE FUNCTION [dbo].[TestSchemabinding](@input INT)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
    RETURN @input * 6
END
GO

-- Function with EXECUTE AS
CREATE FUNCTION [dbo].[TestExecuteAs](@input INT)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
    RETURN @input * 7
END
GO

-- Function with INLINE and SCHEMABINDING
CREATE FUNCTION [dbo].[TestInlineAndSchemabinding](@input INT)
RETURNS INT
WITH INLINE = ON, SCHEMABINDING
AS
BEGIN
    RETURN @input * 8
END
GO

-- Function with INLINE and EXECUTE AS
CREATE FUNCTION [dbo].[TestInlineAndExecuteAs](@input INT)
RETURNS INT
WITH INLINE = OFF, EXECUTE AS CALLER
AS
BEGIN
    RETURN @input * 9
END
GO

-- Function with SCHEMABINDING and EXECUTE AS
CREATE FUNCTION [dbo].[TestSchemabindingAndExecuteAs](@input INT)
RETURNS INT
WITH SCHEMABINDING, EXECUTE AS CALLER
AS
BEGIN
    RETURN @input * 10
END
GO

-- Function with all three options
CREATE FUNCTION [dbo].[TestAllOptions](@input INT)
RETURNS INT
WITH INLINE = ON, SCHEMABINDING, EXECUTE AS CALLER
AS
BEGIN
    RETURN @input * 11
END
GO

-- Function with RETURNS NULL ON NULL INPUT
CREATE FUNCTION [dbo].[TestReturnsNullOnNullInput](@input INT)
RETURNS INT
WITH RETURNS NULL ON NULL INPUT, INLINE = ON
AS
BEGIN
    RETURN @input * 12
END
GO

-- Function with multiple parameters and all options
CREATE FUNCTION [dbo].[TestMultiParamAllOptions]
(
    @input1 INT,
    @input2 VARCHAR(50),
    @input3 DECIMAL(10,2)
)
RETURNS VARCHAR(100)
WITH SCHEMABINDING, EXECUTE AS CALLER, INLINE = OFF
AS
BEGIN
    RETURN CONCAT(CAST(@input1 AS VARCHAR(10)), ',', @input2, ',', CAST(@input3 AS VARCHAR(20)))
END
GO

-- Create a test table for use with TestDynamicSQL
CREATE TABLE TestTable (ID INT)
GO

INSERT INTO TestTable VALUES (1), (2), (3)
GO