-- Drop the table if it already exists (safety)
IF OBJECT_ID('dbo.MyTestTable', 'U') IS NOT NULL
    DROP TABLE dbo.MyTestTable;
GO

-- Create the table
CREATE TABLE MyTestTable (
    id     INT IDENTITY(1,1) PRIMARY KEY,
    init   INT,
    name1  CHAR(10),       -- fixed-length non-Unicode
    name2  NCHAR(10),      -- fixed-length Unicode
    name3  VARCHAR(10),    -- variable-length non-Unicode
    name4  NVARCHAR(10)    -- variable-length Unicode
);
GO

-- Insert 5 rows
INSERT INTO MyTestTable (init, name1, name2, name3, name4) VALUES
(10, 'Alpha',   N'Αλφα',   'One',   N'Uno'),
(20, 'Beta',    N'Бета',   'Two',   N'Dos'),
(30, 'Gamma',   N'Γάμμα',  'Three', N'Tres'),
(40, 'Delta',   N'Дельта', 'Four',  N'Quattro'),
(50, 'Epsilon', N'إبسيلون', 'Five', N'Cinco');
GO

----------------------------------------------------------------------------------------------------------------
-- Test Table Outputs
----------------------------------------------------------------------------------------------------------------

-- Test CHAR to SQLVARIANT Conversion
DECLARE     @testVar1 CHAR(10);
SET         @testVar1 = (SELECT TOP 1 name1 FROM MyTestTable);
SELECT		@testVar1 as Expected;
DECLARE     @result_sql_variant_1 sql_variant;
SET         @result_sql_variant_1 = ( @testVar1 );
SELECT      @result_sql_variant_1 AS Result;
GO


-- Test NCHAR to SQLVARIANT Conversion
DECLARE     @testVar2 NCHAR(10);
SET         @testVar2 = (SELECT TOP 1 name2 FROM MyTestTable);
SELECT		@testVar2 as Expected;
DECLARE     @result_sql_variant_2 sql_variant;
SET         @result_sql_variant_2 = ( @testVar2 );
SELECT      @result_sql_variant_2 AS Result;
GO


-- Test VARCHAR to SQLVARIANT Conversion
DECLARE     @testVar3 VARCHAR(10);
SET         @testVar3 = (SELECT TOP 1 name3 FROM MyTestTable);
SELECT		@testVar3 as Expected;
DECLARE     @result_sql_variant_3 sql_variant;
SET         @result_sql_variant_3 = ( @testVar3 );
SELECT      @result_sql_variant_3 AS Result;
GO

 
 -- Test NVARCHAR to SQLVARIANT Conversion
DECLARE     @testVar4 NVARCHAR(10);
SET         @testVar4 = (SELECT TOP 1 name4 FROM MyTestTable);
SELECT		@testVar4 as Expected;
DECLARE     @result_sql_variant_4 sql_variant;
SET         @result_sql_variant_4 = ( @testVar4 );
SELECT      @result_sql_variant_4 AS Result;
GO

DROP TABLE dbo.MyTestTable;
GO


----------------------------------------------------------------------------------------------------------------
-- Test Short Inputs (SV_CAN_USE_SHORT_VALENA macro)
----------------------------------------------------------------------------------------------------------------

-- CHAR -> SQL_VARIANT implicit conversion with different sizes (SHORT HEADER(SV_CAN_USE_SHORT_VALENA))
DECLARE @counter INT = 1;
DECLARE @max_length INT = 121; -- Max size for SHORT HEADERS
DECLARE @char_var CHAR(121);
DECLARE @sql_variant_var SQL_VARIANT;

WHILE @counter <= @max_length
BEGIN
    -- Initialize @char_var with @counter times 'A'
    SET @char_var = REPLICATE('A', @counter);
    
    -- Conversion to SQL_VARIANT
    SET @sql_variant_var = @char_var;
    
    -- Show results
    SELECT 
        @counter AS StringLength,
        @char_var AS OriginalValue,
        @sql_variant_var AS ConvertedValue,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
        DATALENGTH(@sql_variant_var) AS ActualDataLength;
    
    SET @counter = @counter + 1;
END
GO


-- NCHAR -> SQL_VARIANT implicit conversion with different sizes (SHORT HEADER(SV_CAN_USE_SHORT_VALENA))
DECLARE @counter INT = 1;
DECLARE @max_length INT = 121; -- Max size for SHORT HEADERS
DECLARE @nchar_var NCHAR(121);
DECLARE @sql_variant_var SQL_VARIANT;

WHILE @counter <= @max_length
BEGIN
    -- Initialize @nchar_var with @counter times 'A'
    SET @nchar_var = REPLICATE(N'A', @counter);
    
    -- Conversion to SQL_VARIANT
    SET @sql_variant_var = @nchar_var;
    
    -- Show results
    SELECT 
        @counter AS StringLength,
        @nchar_var AS OriginalValue,
        @sql_variant_var AS ConvertedValue,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation,
        DATALENGTH(@sql_variant_var) AS ActualDataLength;
    
    SET @counter = @counter + 1;
END
GO


-- VARCHAR -> SQL_VARIANT implicit conversion with different sizes (SHORT HEADER(SV_CAN_USE_SHORT_VALENA))
DECLARE @counter INT = 1;
DECLARE @max_length INT = 121; -- Max size for SHORT HEADERS
DECLARE @varchar_var VARCHAR(121);
DECLARE @sql_variant_var SQL_VARIANT;

WHILE @counter <= @max_length
BEGIN
    -- Initialize @varchar_var with @counter times 'A'
    SET @varchar_var = REPLICATE('A', @counter);
    
    -- Conversion to SQL_VARIANT
    SET @sql_variant_var = @varchar_var;
    
    -- Show results
    SELECT 
        @counter AS StringLength,
        @varchar_var AS OriginalValue,
        @sql_variant_var AS ConvertedValue,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
        DATALENGTH(@sql_variant_var) AS ActualDataLength,
        LEN(@varchar_var) AS OriginalLength,
        LEN(CAST(@sql_variant_var AS VARCHAR(MAX))) AS ConvertedLength;
    
    SET @counter = @counter + 1;
END
GO


----------------------------------------------------------------------------------------------------------------
-- Test Long Inputs
----------------------------------------------------------------------------------------------------------------

-- NVARCHAR -> SQL_VARIANT implicit conversion with different sizes (SHORT HEADER(SV_CAN_USE_SHORT_VALENA macro))
DECLARE @counter INT = 1;
DECLARE @max_length INT = 121;
DECLARE @nvarchar_var NVARCHAR(121);
DECLARE @sql_variant_var SQL_VARIANT;

WHILE @counter <= @max_length
BEGIN
    -- @counter kadar 'A' karakteri ile NVARCHAR değişkeni initialize et
    -- Initialize @nvarchar_var with @counter times 'A'
    SET @nvarchar_var = REPLICATE(N'A', @counter);
    
    -- Conversion to SQL_VARIANT
    SET @sql_variant_var = @nvarchar_var;
    
    -- Show results
    SELECT 
        @counter AS StringLength,
        @nvarchar_var AS OriginalValue,
        @sql_variant_var AS ConvertedValue,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
        SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation;
    
    SET @counter = @counter + 1;
END
GO

-- CHAR -> SQL_VARIANT implicit conversion with different sizes (LONG HEADER, size > 121)
DECLARE @test_length INT = 122;
DECLARE @long_char_var CHAR(122) = REPLICATE('A', @test_length);
DECLARE @sql_variant_var SQL_VARIANT;
SET @sql_variant_var = @long_char_var;

SELECT 
    @test_length AS StringLength,
    @long_char_var AS OriginalValue,
    @sql_variant_var AS ConvertedValue,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation;
GO

-- NCHAR -> SQL_VARIANT implicit conversion with different sizes (LONG HEADER, size > 121)
DECLARE @test_length INT = 122;
DECLARE @long_nchar_var NCHAR(122) = REPLICATE('A', @test_length);
DECLARE @sql_variant_var SQL_VARIANT;
SET @sql_variant_var = @long_nchar_var;

SELECT 
    @test_length AS StringLength,
    @long_nchar_var AS OriginalValue,
    @sql_variant_var AS ConvertedValue,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation;
GO

-- VARCHAR -> SQL_VARIANT implicit conversion with different sizes (LONG HEADER, size > 121)
DECLARE @test_length INT = 122;
DECLARE @long_varchar_var VARCHAR(122) = REPLICATE('A', @test_length);
DECLARE @sql_variant_var SQL_VARIANT;
SET @sql_variant_var = @long_varchar_var;

SELECT 
    @test_length AS StringLength,
    @long_varchar_var AS OriginalValue,
    @sql_variant_var AS ConvertedValue,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation;
GO


-- NVARCHAR -> SQL_VARIANT implicit conversion with different sizes (LONG HEADER, size > 121)
DECLARE @test_length INT = 122;
DECLARE @long_nvarchar_var NVARCHAR(122) = REPLICATE('A', @test_length);
DECLARE @sql_variant_var SQL_VARIANT;
SET @sql_variant_var = @long_nvarchar_var;

SELECT 
    @test_length AS StringLength,
    @long_nvarchar_var AS OriginalValue,
    @sql_variant_var AS ConvertedValue,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'BaseType') AS BaseType,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'MaxLength') AS MaxLength,
    SQL_VARIANT_PROPERTY(@sql_variant_var, 'Collation') AS Collation;
GO

