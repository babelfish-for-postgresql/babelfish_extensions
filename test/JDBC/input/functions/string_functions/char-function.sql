-- Create UDTs
CREATE TYPE char_type_output FROM CHAR(10);
CREATE TYPE char_type_varchar FROM VARCHAR(50);
GO

-- Create base tables
CREATE TABLE char_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS CHAR(InputValue) PERSISTED,
    ExpectedOutput CHAR(1),
    Description VARCHAR(100)
);
GO

CREATE TABLE char_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    SingleChar AS CHAR(InputValue) PERSISTED,
    CharacterDescription VARCHAR(100)
);
GO

-- Insert test data
INSERT INTO char_t1 (InputValue, ExpectedOutput, Description) VALUES
(ASCII('A'), 'A', 'Capital A'),
(ASCII('a'), 'a', 'Lowercase a'),
(ASCII(' '), ' ', 'Space'),
(ASCII(CHAR(9)), CHAR(9), 'Tab'),
(ASCII(CHAR(13)), CHAR(13), 'Carriage Return'),
(ASCII(CHAR(10)), CHAR(10), 'Line Feed');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic Character Tests
SELECT 
    CHAR(ASCII('A')) AS CapitalA,
    CHAR(ASCII('Z')) AS CapitalZ,
    CHAR(ASCII('a')) AS LowercaseA,
    CHAR(ASCII('z')) AS LowercaseZ,
    CHAR(ASCII('0')) AS Number0,
    CHAR(ASCII('9')) AS Number9,
    CHAR(ASCII(' ')) AS Space;
GO

-- 2. Control Characters Tests
SELECT 
    CHAR(ASCII(CHAR(9))) AS Tab,
    CHAR(ASCII(CHAR(10))) AS LineFeed,
    CHAR(ASCII(CHAR(13))) AS CarriageReturn,
    CHAR(ASCII(CHAR(27))) AS EscapeChar;
GO

SELECT CHAR(ASCII(CHAR(0))) AS NullChar
GO

-- 3. Special Characters Tests
SELECT 
    CHAR(ASCII('!')) AS ExclamationMark,
    CHAR(ASCII('"')) AS DoubleQuote,
    CHAR(ASCII('#')) AS HashSign,
    CHAR(ASCII('$')) AS DollarSign,
    CHAR(ASCII('%')) AS PercentSign;
GO

-- 4. Range Tests
SELECT 
    CHAR(1) AS StartRange,
    CHAR(126) AS EndPrintableRange,
    CHAR(255) AS MaxRange;
GO

-- 5. String Building with CHAR
SELECT 
    CHAR(ASCII('H')) + 
    CHAR(ASCII('E')) + 
    CHAR(ASCII('L')) + 
    CHAR(ASCII('L')) + 
    CHAR(ASCII('O')) AS HelloString;
GO

-- 6. NULL and Edge Cases
SELECT 
    CHAR(NULL) AS NullInput,
    CHAR(255) AS MaxValidCode;
GO

SELECT CHAR(0) AS ZeroCode
GO

-- 7. Error Cases
BEGIN TRY
    SELECT CHAR(-1) AS ShouldFail;
END TRY
BEGIN CATCH
    SELECT 
        'CHAR() with negative value' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    SELECT CHAR(256) AS ShouldFail;
END TRY
BEGIN CATCH
    SELECT 
        'CHAR() with value > 255' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 8. Verification Tests
SELECT 
    InputValue,
    CharOutput,
    ExpectedOutput,
    CASE WHEN CharOutput = ExpectedOutput THEN 'Pass' ELSE 'Fail' END AS TestResult
FROM char_t1;
GO

-- 9. Printable Character Range Test
WITH Numbers AS (
    SELECT generate_series AS Num
    FROM GENERATE_SERIES(32, 126)
)
SELECT 
    Num AS ASCIIValue,
    CHAR(Num) AS CharacterValue,
    CASE 
        WHEN Num BETWEEN ASCII('A') AND ASCII('Z') THEN 'Uppercase'
        WHEN Num BETWEEN ASCII('a') AND ASCII('z') THEN 'Lowercase'
        WHEN Num BETWEEN ASCII('0') AND ASCII('9') THEN 'Digit'
        ELSE 'Special'
    END AS CharacterType
FROM Numbers;
GO

-- 10. String Function Tests
SELECT 
    LEN(CHAR(ASCII('A'))) AS CharLength,
    DATALENGTH(CHAR(ASCII('A'))) AS CharDataLength,
    ASCII(CHAR(ASCII('A'))) AS CharToAsciiAndBack,
    UPPER(CHAR(ASCII('a'))) AS UppercaseChar,
    LOWER(CHAR(ASCII('A'))) AS LowercaseChar;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 11. Create Views
CREATE VIEW char_v1 AS
SELECT 
    v.Num AS InputValue,
    CHAR(v.Num) AS CharValue,
    CASE 
        WHEN v.Num BETWEEN 32 AND 126 
        THEN 'Printable'
        ELSE 'Control'
    END AS CharacterType
FROM (VALUES (65), (9), (32), (127)) AS v(Num);
GO

CREATE VIEW char_v2 AS
WITH Numbers AS (
    SELECT generate_series AS Num
    FROM GENERATE_SERIES(65, 90)
)
SELECT 
    Num AS InputValue,
    CHAR(Num) AS CharacterValue,
    CHAR(Num + 32) AS LowercaseEquivalent
FROM Numbers;
GO

-- Test Views
SELECT * FROM char_v1;
GO
SELECT * FROM char_v2;
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 12. Create Functions
CREATE FUNCTION char_fn_isvalid
(
    @InputValue INT
)
RETURNS BIT
AS
BEGIN
    RETURN CASE 
        WHEN @InputValue BETWEEN 0 AND 255 
        AND CHAR(@InputValue) IS NOT NULL 
        THEN 1 
        ELSE 0 
    END;
END;
GO

CREATE FUNCTION char_fn_buildstring
(
    @StartChar INT,
    @Length INT
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @Result VARCHAR(MAX) = '';
    DECLARE @Counter INT = 0;
    
    WHILE @Counter < @Length AND @StartChar + @Counter <= 255
    BEGIN
        SET @Result = @Result + CHAR(@StartChar + @Counter);
        SET @Counter = @Counter + 1;
    END
    
    RETURN @Result;
END;
GO

-- Test Functions
SELECT dbo.char_fn_isvalid(65) AS IsValidA;
SELECT dbo.char_fn_isvalid(256) AS IsValid256;
SELECT dbo.char_fn_buildstring(65, 5) AS FiveCharsFromA;
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 13. Create Stored Procedures
CREATE PROCEDURE char_sp_generate
    @StartValue INT,
    @Count INT
AS
BEGIN
    IF @StartValue < 0 OR @StartValue > 255
        THROW 50000, 'Start value must be between 0 and 255', 1;
        
    WITH Numbers AS (
        SELECT generate_series AS Num
        FROM GENERATE_SERIES(@StartValue, @StartValue + @Count - 1)
        WHERE generate_series <= 255
    )
    SELECT 
        Num AS InputValue,
        CHAR(Num) AS CharacterValue,
        CASE 
            WHEN Num < 32 THEN 'Control'
            WHEN Num BETWEEN 32 AND 126 THEN 'Printable'
            ELSE 'Extended'
        END AS CharacterType
    FROM Numbers;
END;
GO

CREATE PROCEDURE char_sp_compare
    @Value1 INT,
    @Value2 INT
AS
BEGIN
    SELECT 
        @Value1 AS Input1,
        @Value2 AS Input2,
        CHAR(@Value1) AS Char1,
        CHAR(@Value2) AS Char2,
        CASE 
            WHEN CHAR(@Value1) = CHAR(@Value2) THEN 'Equal'
            WHEN CHAR(@Value1) > CHAR(@Value2) THEN 'First Greater'
            ELSE 'Second Greater'
        END AS Comparison;
END;
GO

-- Test Procedures
EXEC char_sp_generate @StartValue = 65, @Count = 5;
EXEC char_sp_compare @Value1 = 65, @Value2 = 97;
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS AND CONSTRAINTS
-- =============================================

-- 14. Create Table with Computed Columns
CREATE TABLE char_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS CHAR(InputValue) PERSISTED,
    IsPrintable AS CASE 
                    WHEN CHAR(InputValue) BETWEEN CHAR(32) AND CHAR(126) 
                    THEN 1 
                    ELSE 0 
                  END PERSISTED,
    CharCategory AS CASE
                    WHEN InputValue BETWEEN 65 AND 90 THEN 'Uppercase'
                    WHEN InputValue BETWEEN 97 AND 122 THEN 'Lowercase'
                    WHEN InputValue BETWEEN 48 AND 57 THEN 'Digit'
                    ELSE 'Other'
                  END PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO char_t3 (InputValue) 
VALUES (65), (97), (48), (32), (9);
GO

SELECT * FROM char_t3;
GO

-- 15. Create Table with Constraints
CREATE TABLE char_t4 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS CHAR(InputValue) PERSISTED,
    CONSTRAINT char_chk_valid CHECK (InputValue BETWEEN 0 AND 255),
    CONSTRAINT char_chk_printable CHECK (CHAR(InputValue) BETWEEN CHAR(32) AND CHAR(126))
);
GO

-- Test Constraints
INSERT INTO char_t4 (InputValue) VALUES (65);
GO

BEGIN TRY
    INSERT INTO char_t4 (InputValue) VALUES (31);
END TRY
BEGIN CATCH
    SELECT 
        'Control character insert' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW char_v1;
DROP VIEW char_v2;
GO

-- Drop Functions
DROP FUNCTION char_fn_isvalid;
DROP FUNCTION char_fn_buildstring;
GO

-- Drop Procedures
DROP PROCEDURE char_sp_generate;
DROP PROCEDURE char_sp_compare;
GO

-- Drop Tables
DROP TABLE char_t4;
DROP TABLE char_t3;
DROP TABLE char_t2;
DROP TABLE char_t1;
GO

-- Drop Types
DROP TYPE char_type_output;
DROP TYPE char_type_varchar;
GO
