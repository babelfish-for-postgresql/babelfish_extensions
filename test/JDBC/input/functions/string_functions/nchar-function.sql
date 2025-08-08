-- Create UDTs
CREATE TYPE nchar_type_output FROM NCHAR(10);
CREATE TYPE nchar_type_nvarchar FROM NVARCHAR(50);
GO

-- Create base tables
CREATE TABLE nchar_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS NCHAR(InputValue) PERSISTED,
    ExpectedOutput NCHAR(1),
    Description NVARCHAR(100)
);
GO

CREATE TABLE nchar_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    SingleChar AS NCHAR(InputValue) PERSISTED,
    CharacterDescription NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO nchar_t1 (InputValue, ExpectedOutput, Description) VALUES
(ASCII('A'), N'A', N'Capital A'),
(ASCII('a'), N'a', N'Lowercase a'),
(ASCII(' '), N' ', N'Space'),
(ASCII(NCHAR(9)), NCHAR(9), N'Tab'),
(ASCII(NCHAR(13)), NCHAR(13), N'Carriage Return'),
(ASCII(NCHAR(10)), NCHAR(10), N'Line Feed'),
(0x0410, NCHAR(0x0410), N'Cyrillic A'),
(0x0411, NCHAR(0x0411), N'Cyrillic B'),
(0x3042, NCHAR(0x3042), N'Hiragana A'),
(0x4E00, NCHAR(0x4E00), N'CJK Ideograph');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic Character Tests
SELECT 
    NCHAR(ASCII('A')) AS CapitalA,
    NCHAR(ASCII('Z')) AS CapitalZ,
    NCHAR(ASCII('a')) AS LowercaseA,
    NCHAR(ASCII('z')) AS LowercaseZ,
    NCHAR(ASCII('0')) AS Number0,
    NCHAR(ASCII('9')) AS Number9,
    NCHAR(ASCII(' ')) AS Space;
GO

-- 2. Unicode Character Tests
SELECT 
    NCHAR(0x0410) AS CyrillicA,
    NCHAR(0x0411) AS CyrillicB,
    NCHAR(0x3042) AS HiraganaA,
    NCHAR(0x4E00) AS CJKIdeograph,
    NCHAR(0x0E01) AS ThaiCharacter,
    NCHAR(0x0627) AS ArabicCharacter;
GO

-- 3. Control Characters Tests
SELECT
    NCHAR(ASCII(CHAR(9))) AS Tab,
    NCHAR(ASCII(CHAR(10))) AS LineFeed,
    NCHAR(ASCII(CHAR(13))) AS CarriageReturn,
    NCHAR(ASCII(CHAR(27))) AS EscapeChar;
GO

SELECT NCHAR(ASCII(CHAR(0))) AS NullChar
GO

-- 4. Special Characters Tests
SELECT 
    NCHAR(ASCII('!')) AS ExclamationMark,
    NCHAR(ASCII('"')) AS DoubleQuote,
    NCHAR(ASCII('#')) AS HashSign,
    NCHAR(ASCII('$')) AS DollarSign,
    NCHAR(ASCII('%')) AS PercentSign;
GO

-- 5. Range Tests
SELECT 
    NCHAR(1) AS StartRange,
    NCHAR(126) AS EndAsciiPrintable,
    NCHAR(255) AS ExtendedAscii,
    NCHAR(0x0410) AS UnicodeStart, -- Cyrillic A
    NCHAR(0xFFFF) AS MaxUnicode;
GO

-- 6. NULL and Edge Cases
SELECT 
    NCHAR(0) AS NullInput,
    NCHAR(65535) AS MaxValidCode;
GO

SELECT NCHAR(NULL) AS ZeroCode
GO

-- 7. Error Cases
BEGIN TRY
    SELECT NCHAR(-1) AS ShouldFail;
END TRY
BEGIN CATCH
    SELECT 
        'NCHAR() with negative value' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    SELECT NCHAR(65536) AS ShouldFail;
END TRY
BEGIN CATCH
    SELECT 
        'NCHAR() with value > 65535' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 8. Unicode Block Tests
-- Basic Latin (ASCII)
SELECT NCHAR(generate_series) AS BasicLatin
FROM GENERATE_SERIES(32, 126)
WHERE generate_series BETWEEN 32 AND 126;
GO

-- Latin-1 Supplement
SELECT NCHAR(generate_series) AS Latin1Supplement
FROM GENERATE_SERIES(160, 255)
WHERE generate_series BETWEEN 160 AND 255;
GO

-- Cyrillic Basic
SELECT NCHAR(generate_series) AS CyrillicChar
FROM GENERATE_SERIES(0x0410, 0x042F)
WHERE generate_series BETWEEN 0x0410 AND 0x042F;
GO

-- 9. String Building with NCHAR
SELECT 
    NCHAR(ASCII('H')) + 
    NCHAR(ASCII('E')) + 
    NCHAR(ASCII('L')) + 
    NCHAR(ASCII('L')) + 
    NCHAR(ASCII('O')) + 
    NCHAR(0x0410) AS HelloWithCyrillic;
GO

-- 10. Comparison Tests
SELECT 
    CASE WHEN NCHAR(ASCII('A')) = N'A' THEN 'Pass' ELSE 'Fail' END AS AsciiTest,
    CASE WHEN NCHAR(0x0410) = N'А' THEN 'Pass' ELSE 'Fail' END AS CyrillicTest,
    CASE WHEN NCHAR(0x3042) = N'あ' THEN 'Pass' ELSE 'Fail' END AS HiraganaTest;
GO

-- =============================================
-- TESTS WITH STRING FUNCTIONS
-- =============================================

-- 11. NCHAR with String Functions
SELECT 
    -- Basic string functions
    LEN(NCHAR(ASCII('A'))) AS CharLength,
    DATALENGTH(NCHAR(ASCII('A'))) AS CharDataLength,
    DATALENGTH(NCHAR(0x0410)) AS UnicodeCharDataLength,
    ASCII(NCHAR(ASCII('A'))) AS CharToAsciiAndBack,
    UNICODE(NCHAR(0x0410)) AS UnicodeValue,
    UPPER(NCHAR(ASCII('a'))) AS UppercaseChar,
    LOWER(NCHAR(ASCII('A'))) AS LowercaseChar;
GO

-- 12. String Concatenation with NCHAR
SELECT
    -- Building strings using NCHAR
    NCHAR(ASCII('S')) + NCHAR(ASCII('Q')) + NCHAR(ASCII('L')) AS SqlString,
    CONCAT(NCHAR(0x0410), NCHAR(0x0411), NCHAR(0x0412)) AS CyrillicString,
    STRING_AGG(NCHAR(generate_series), N'') WITHIN GROUP (ORDER BY generate_series) AS CharSequence
FROM GENERATE_SERIES(65, 70);
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 13. Create Views
CREATE VIEW nchar_v1 AS
SELECT 
    v.Num AS InputValue,
    NCHAR(v.Num) AS CharValue,
    CASE 
        WHEN v.Num < 128 THEN 'ASCII'
        WHEN v.Num < 256 THEN 'Extended ASCII'
        ELSE 'Unicode'
    END AS CharacterSet
FROM (VALUES (65), (0x0410), (0x3042), (0x4E00)) AS v(Num);
GO

CREATE VIEW nchar_v2 AS
WITH Numbers AS (
    SELECT generate_series AS Num
    FROM GENERATE_SERIES(0x0410, 0x042F) -- Cyrillic Capital Letters
)
SELECT 
    Num AS InputValue,
    NCHAR(Num) AS CharacterValue,
    UNICODE(NCHAR(Num)) AS UnicodeValue
FROM Numbers;
GO

-- Test Views
SELECT * FROM nchar_v1;
GO
SELECT * FROM nchar_v2;
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 14. Create Functions
CREATE FUNCTION nchar_fn_isvalid
(
    @InputValue INT
)
RETURNS BIT
AS
BEGIN
    RETURN CASE 
        WHEN @InputValue BETWEEN 0 AND 65535 
        AND NCHAR(@InputValue) IS NOT NULL 
        THEN 1 
        ELSE 0 
    END;
END;
GO

CREATE FUNCTION nchar_fn_buildstring
(
    @StartChar INT,
    @Length INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX) = N'';
    DECLARE @Counter INT = 0;
    
    WHILE @Counter < @Length AND @StartChar + @Counter <= 65535
    BEGIN
        SET @Result = @Result + NCHAR(@StartChar + @Counter);
        SET @Counter = @Counter + 1;
    END
    
    RETURN @Result;
END;
GO

-- Test Functions
SELECT 
    dbo.nchar_fn_isvalid(65) AS IsValidASCII,
    dbo.nchar_fn_isvalid(0x0410) AS IsValidCyrillic,
    dbo.nchar_fn_isvalid(65536) AS IsValidTooLarge;
GO

SELECT 
    dbo.nchar_fn_buildstring(0x0410, 5) AS CyrillicSequence,
    dbo.nchar_fn_buildstring(0x3042, 5) AS HiraganaSequence;
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 15. Create Stored Procedures
CREATE PROCEDURE nchar_sp_generate
    @StartValue INT,
    @Count INT
AS
BEGIN
    IF @StartValue < 0 OR @StartValue > 65535
        THROW 50000, 'Start value must be between 0 and 65535', 1;
        
    WITH Numbers AS (
        SELECT generate_series AS Num
        FROM GENERATE_SERIES(@StartValue, @StartValue + @Count - 1)
        WHERE generate_series <= 65535
    )
    SELECT 
        Num AS InputValue,
        NCHAR(Num) AS CharacterValue,
        UNICODE(NCHAR(Num)) AS UnicodeValue,
        CASE 
            WHEN Num < 128 THEN 'ASCII'
            WHEN Num < 256 THEN 'Extended ASCII'
            ELSE 'Unicode'
        END AS CharacterSet
    FROM Numbers;
END;
GO

CREATE PROCEDURE nchar_sp_compare
    @Value1 INT,
    @Value2 INT
AS
BEGIN
    SELECT 
        @Value1 AS Input1,
        @Value2 AS Input2,
        NCHAR(@Value1) AS Char1,
        NCHAR(@Value2) AS Char2,
        UNICODE(NCHAR(@Value1)) AS Unicode1,
        UNICODE(NCHAR(@Value2)) AS Unicode2,
        CASE 
            WHEN NCHAR(@Value1) = NCHAR(@Value2) THEN 'Equal'
            WHEN NCHAR(@Value1) > NCHAR(@Value2) THEN 'First Greater'
            ELSE 'Second Greater'
        END AS Comparison;
END;
GO

-- Test Procedures
EXEC nchar_sp_generate @StartValue = 0x0410, @Count = 5;
EXEC nchar_sp_compare @Value1 = 65, @Value2 = 0x0410;
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS AND CONSTRAINTS
-- =============================================

-- 16. Create Table with Computed Columns
CREATE TABLE nchar_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS NCHAR(InputValue) PERSISTED,
    IsAscii AS CASE 
                WHEN InputValue < 128 THEN 1 
                ELSE 0 
              END PERSISTED,
    CharCategory AS CASE
                    WHEN InputValue < 128 THEN 'ASCII'
                    WHEN InputValue < 256 THEN 'Extended ASCII'
                    WHEN InputValue < 0x0500 THEN 'Cyrillic'
                    WHEN InputValue < 0x3100 THEN 'CJK'
                    ELSE 'Other Unicode'
                  END PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO nchar_t3 (InputValue) 
VALUES (65), (0x0410), (0x3042), (0x4E00);
GO

SELECT * FROM nchar_t3;
GO

-- 17. Create Table with Constraints
CREATE TABLE nchar_t4 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue INT,
    CharOutput AS NCHAR(InputValue) PERSISTED,
    CONSTRAINT nchar_chk_valid CHECK (InputValue BETWEEN 0 AND 65535),
    CONSTRAINT nchar_chk_printable CHECK (
        InputValue >= 32 OR 
        InputValue >= 0x0410 -- Allow Cyrillic and other Unicode
    )
);
GO

-- Test Constraints
INSERT INTO nchar_t4 (InputValue) VALUES (65), (0x0410);
GO

BEGIN TRY
    INSERT INTO nchar_t4 (InputValue) VALUES (65536);
END TRY
BEGIN CATCH
    SELECT 
        'Invalid Unicode value' AS TestCase,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW nchar_v1;
DROP VIEW nchar_v2;
GO

-- Drop Functions
DROP FUNCTION nchar_fn_isvalid;
DROP FUNCTION nchar_fn_buildstring;
GO

-- Drop Procedures
DROP PROCEDURE nchar_sp_generate;
DROP PROCEDURE nchar_sp_compare;
GO

-- Drop Tables
DROP TABLE nchar_t4;
DROP TABLE nchar_t3;
DROP TABLE nchar_t2;
DROP TABLE nchar_t1;
GO

-- Drop Types
DROP TYPE nchar_type_output;
DROP TYPE nchar_type_nvarchar;
GO

select nchar(cast(45 as binary))
go
select nchar(cast(45 as varbinary))
go
select nchar(0)
go
select nchar(63535)
go
select nchar(65536)
go
-- Test with UDF named char in a schema other than sys
CREATE SCHEMA test_schema;
GO
create function test_schema.nchar(@x int)
returns integer as 
BEGIN
    return 1;
END;
GO
select test_schema.nchar(255);
GO
drop function test_schema.nchar;
GO
drop schema test_schema;
go
select Nchar(63535)
go
select NcHaR(63535)
go
create type user_UDT_int from int
go
select nchar(cast(63535 as user_UDT_int))
go
drop type user_UDT_int
go
SET QUOTED_IDENTIFIER ON
go
select "char"(256)
go
select "nchar"(63535)
go
set QUOTED_IDENTIFIER OFF
go
select nchar(0);
go

