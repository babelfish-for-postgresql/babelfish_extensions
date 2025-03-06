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

-- Create a test table for use with TestDynamicSQL
CREATE TABLE TestTable (ID INT)
GO

INSERT INTO TestTable VALUES (1), (2), (3)
GO