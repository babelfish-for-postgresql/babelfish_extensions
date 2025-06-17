-- Create UDTs
CREATE TYPE ascii_type_char FROM CHAR(10);
CREATE TYPE ascii_type_varchar FROM VARCHAR(50);
CREATE TYPE ascii_type_nchar FROM NCHAR(10);
CREATE TYPE ascii_type_nvarchar FROM NVARCHAR(50);
GO

-- Create base tables
CREATE TABLE ascii_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NCharCol NCHAR(10),
    NVarcharCol NVARCHAR(50),
    TextCol TEXT,
    NTextCol NTEXT,
    ExpectedValue INT,
    Description VARCHAR(100)
);
GO

-- Insert test data for basic ASCII values
INSERT INTO ascii_t1 VALUES
-- Basic ASCII characters
('A', 'A', N'A', N'A', 'A', N'A', 65, 'Capital A'),
('a', 'a', N'a', N'a', 'a', N'a', 97, 'Lowercase a'),
('Z', 'Z', N'Z', N'Z', 'Z', N'Z', 90, 'Capital Z'),
('z', 'z', N'z', N'z', 'z', N'z', 122, 'Lowercase z'),
('0', '0', N'0', N'0', '0', N'0', 48, 'Zero digit'),
('9', '9', N'9', N'9', '9', N'9', 57, 'Nine digit'),

-- Special characters
(' ', ' ', N' ', N' ', ' ', N' ', 32, 'Space'),
('!', '!', N'!', N'!', '!', N'!', 33, 'Exclamation mark'),
('@', '@', N'@', N'@', '@', N'@', 64, 'At symbol'),
('#', '#', N'#', N'#', '#', N'#', 35, 'Hash symbol'),

-- Control characters
(CHAR(9), CHAR(9), NCHAR(9), NCHAR(9), CHAR(9), NCHAR(9), 9, 'Tab'),
(CHAR(13), CHAR(13), NCHAR(13), NCHAR(13), CHAR(13), NCHAR(13), 13, 'Carriage return'),
(CHAR(10), CHAR(10), NCHAR(10), NCHAR(10), CHAR(10), NCHAR(10), 10, 'Line feed'),

-- Multiple characters (should take first character)
('ABC', 'ABC', N'ABC', N'ABC', 'ABC', N'ABC', 65, 'Multiple chars - returns first'),
('123', '123', N'123', N'123', '123', N'123', 49, 'Multiple numbers - returns first'),

-- Empty and spaces
('', '', N'', N'', '', N'', NULL, 'Empty string'),
(' A', ' A', N' A', N' A', ' A', N' A', 32, 'Space then char');
GO

-- Create table for Unicode tests
CREATE TABLE ascii_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    UnicodeChar NCHAR(10),
    UnicodeString NVARCHAR(50),
    ExpectedValue INT,
    Description NVARCHAR(100)
);
GO

-- Insert Unicode test data
INSERT INTO ascii_t2 VALUES
(N'A', N'ASCII in Unicode', 65, N'ASCII character in Unicode string'),
(N'あ', N'Japanese character', NULL, N'Japanese character'),
(N'한', N'Korean character', NULL, N'Korean character'),
(N'☺', N'Smiley face', NULL, N'Unicode symbol'),
(N'é', N'Accented e', NULL, N'Accented character'),
(N'★', N'Star symbol', NULL, N'Unicode star'),
(N'⌘', N'Command symbol', NULL, N'Unicode command'),
(N' ', N'Space in Unicode', 32, N'Space character'),
(N'', N'Empty Unicode', NULL, N'Empty Unicode string'),
(NCHAR(9), N'Tab in Unicode', 9, N'Unicode tab character');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic ASCII Character Tests
SELECT 
    ASCII('A') AS CapitalA,
    ASCII('a') AS LowercaseA,
    ASCII('Z') AS CapitalZ,
    ASCII('z') AS LowercaseZ,
    ASCII('0') AS Zero,
    ASCII('9') AS Nine;
GO

-- 2. Special Character Tests
SELECT 
    ASCII(' ') AS Space,
    ASCII('!') AS ExclamationMark,
    ASCII('@') AS AtSymbol,
    ASCII('#') AS HashSymbol,
    ASCII('$') AS DollarSign,
    ASCII('%') AS PercentSign;
GO

-- 3. Control Character Tests
SELECT 
    ASCII(CHAR(9)) AS Tab,
    ASCII(CHAR(10)) AS LineFeed,
    ASCII(CHAR(13)) AS CarriageReturn,
    ASCII(CHAR(27)) AS EscapeChar;
GO

-- following throws error in babelfish
SELECT ASCII(CHAR(0)) AS NullChar
GO

-- 4. Tests with Different Data Types
SELECT 
    -- Fixed length character tests
    ASCII(CharCol) AS CharValue,
    -- Variable length character tests
    ASCII(VarcharCol) AS VarcharValue,
    -- Unicode fixed length tests
    ASCII(NCharCol) AS NCharValue,
    -- Unicode variable length tests
    ASCII(NVarcharCol) AS NVarcharValue,
    -- Text type tests
    ASCII(TextCol) AS TextValue,
    -- NText type tests
    ASCII(NTextCol) AS NTextValue
FROM ascii_t1
WHERE ID <= 5;
GO

-- 5. NULL and Empty String Tests
SELECT 
    ASCII(NULL) AS NullInput,
    ASCII('') AS EmptyString,
    ASCII('  ') AS MultipleSpaces,
    ASCII(CAST(NULL AS VARCHAR)) AS NullVarchar,
    ASCII(CAST(NULL AS NVARCHAR)) AS NullNVarchar;
GO

-- 6. Multiple Character String Tests
SELECT 
    ASCII('ABC') AS FirstCharOfABC,
    ASCII('123') AS FirstCharOf123,
    ASCII('!@#') AS FirstCharOfSpecial,
    ASCII('   ABC') AS FirstCharOfSpacedString,
    ASCII(CHAR(13) + 'ABC') AS FirstCharOfCRString;
GO

-- 7. Unicode Character Tests
SELECT 
    UnicodeChar,
    UnicodeString,
    ASCII(UnicodeChar) AS CharASCII,
    ASCII(UnicodeString) AS StringASCII,
    ExpectedValue,
    CASE 
        WHEN ASCII(UnicodeChar) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM ascii_t2;
GO

-- 8. Edge Case Tests
SELECT 
    -- Extended ASCII characters (128-255)
    ASCII(CHAR(128)) AS Char128,
    ASCII(CHAR(255)) AS Char255,
    
    -- Control characters
    ASCII(CHAR(1)) AS StartOfHeading,
    ASCII(CHAR(31)) AS UnitSeparator
GO

SELECT
    -- ASCII on out of input range (> 255)
    ASCII(CHAR(256)) AS Char256,
    ASCII(CHAR(12121)) AS Char12121
GO

-- =============================================
-- ADVANCED TEST CASES
-- =============================================

-- 9. Character Range Tests
WITH Numbers AS (
    SELECT generate_series AS Num
    FROM GENERATE_SERIES(1, 255)
)
SELECT 
    Num,
    CHAR(Num) AS CharacterValue,
    ASCII(CHAR(Num)) AS ASCIIValue,
    CASE 
        WHEN ASCII(CHAR(Num)) = Num THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM Numbers;
GO

-- 10. Data Type Conversion Tests
CREATE TABLE ascii_conversion_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    IntValue INT,
    FloatValue FLOAT,
    DateValue DATETIME,
    BinaryValue BINARY(10)
);
GO

INSERT INTO ascii_conversion_t3 VALUES
(65, 65.0, '2023-01-01', 0x41),  -- 'A' in different forms
(97, 97.0, '2023-02-01', 0x61),  -- 'a' in different forms
(32, 32.0, '2023-03-01', 0x20);  -- Space in different forms
GO

SELECT 
    ASCII(IntValue) AS IntToASCII,
    ASCII(FloatValue) AS FloatToASCII,
    ASCII(DateValue) AS DateToASCII,
    ASCII(BinaryValue) AS BinaryToASCII
FROM ascii_conversion_t3;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 11. Create Views
CREATE VIEW ascii_v1 AS
SELECT 
    ID,
    CharCol,
    ASCII(CharCol) AS CharASCII,
    VarcharCol,
    ASCII(VarcharCol) AS VarcharASCII,
    TextCol,
    ASCII(TextCol) AS TextASCII,
    ExpectedValue,
    CASE 
        WHEN ASCII(CharCol) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM ascii_t1;
GO

CREATE VIEW ascii_v2 AS
SELECT 
    ID,
    NCharCol,
    ASCII(NCharCol) AS NCharASCII,
    NVarcharCol,
    ASCII(NVarcharCol) AS NVarcharASCII,
    NTextCol,
    ASCII(NTextCol) AS NTextASCII,
    ExpectedValue,
    CASE 
        WHEN ASCII(NCharCol) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM ascii_t1;
GO

-- Test Views
SELECT * FROM ascii_v1 WHERE TestResult = 'Fail';
SELECT * FROM ascii_v2 WHERE TestResult = 'Fail';
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 12. Create Functions
CREATE FUNCTION ascii_fn_validatechar
(
    @InputChar VARCHAR(1)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @InputChar AS InputChar,
        ASCII(@InputChar) AS ASCIIValue,
        CASE 
            WHEN ASCII(@InputChar) BETWEEN 32 AND 126 THEN 'Printable'
            WHEN ASCII(@InputChar) < 32 THEN 'Control'
            ELSE 'Extended'
        END AS CharacterType
);
GO

CREATE FUNCTION ascii_fn_comparetypes
(
    @Input VARCHAR(10)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ASCII(CAST(@Input AS CHAR(10))) AS CharASCII,
        ASCII(CAST(@Input AS VARCHAR(10))) AS VarcharASCII,
        ASCII(CAST(@Input AS NCHAR(10))) AS NCharASCII,
        ASCII(CAST(@Input AS NVARCHAR(10))) AS NVarcharASCII,
        ASCII(CAST(@Input AS TEXT)) AS TextASCII,
        ASCII(CAST(@Input AS NTEXT)) AS NTextASCII
);
GO

-- Test Functions
SELECT * FROM ascii_fn_validatechar('A');
SELECT * FROM ascii_fn_comparetypes('Test');
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 13. Create Procedures
CREATE PROCEDURE ascii_sp_analyzestring
    @InputString VARCHAR(MAX)
AS
BEGIN
    SELECT 
        @InputString AS InputString,
        ASCII(@InputString) AS FirstCharASCII,
        CHAR(ASCII(@InputString)) AS ASCIIToChar,
        CASE 
            WHEN ASCII(@InputString) BETWEEN 65 AND 90 THEN 'Uppercase'
            WHEN ASCII(@InputString) BETWEEN 97 AND 122 THEN 'Lowercase'
            WHEN ASCII(@InputString) BETWEEN 48 AND 57 THEN 'Digit'
            ELSE 'Other'
        END AS CharacterType;
END;
GO

CREATE PROCEDURE ascii_sp_validateascii
    @InputChar CHAR(1),
    @ExpectedValue INT
AS
BEGIN
    DECLARE @ActualValue INT = ASCII(@InputChar);
    
    IF @ActualValue = @ExpectedValue
        SELECT 'Pass' AS TestResult, 
               @InputChar AS TestChar, 
               @ActualValue AS ActualASCII, 
               @ExpectedValue AS ExpectedASCII;
    ELSE
        SELECT 'Fail' AS TestResult, 
               @InputChar AS TestChar, 
               @ActualValue AS ActualASCII, 
               @ExpectedValue AS ExpectedASCII;
END;
GO

-- Test Procedures
EXEC ascii_sp_analyzestring 'Test String';
EXEC ascii_sp_validateascii 'A', 65;
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS
-- =============================================

-- 14. Create Tables with Computed Columns
CREATE TABLE ascii_computed_t4 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputChar CHAR(1),
    InputVarchar VARCHAR(10),
    InputNChar NCHAR(1),
    
    -- Computed columns
    CharASCII AS ASCII(InputChar) PERSISTED,
    VarcharASCII AS ASCII(InputVarchar) PERSISTED,
    NCharASCII AS ASCII(InputNChar) PERSISTED,
    
    IsUpper AS CASE 
                WHEN ASCII(InputChar) BETWEEN 65 AND 90 THEN 1 
                ELSE 0 
              END PERSISTED,
    IsLower AS CASE 
                WHEN ASCII(InputChar) BETWEEN 97 AND 122 THEN 1 
                ELSE 0 
              END PERSISTED,
    IsDigit AS CASE 
                WHEN ASCII(InputChar) BETWEEN 48 AND 57 THEN 1 
                ELSE 0 
              END PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO ascii_computed_t4 (InputChar, InputVarchar, InputNChar)
VALUES
('A', 'ABC', N'A'),
('a', 'abc', N'a'),
('1', '123', N'1'),
('@', '@#$', N'@');

SELECT * FROM ascii_computed_t4;
GO

-- =============================================
-- DEPENDENT OBJECTS - CONSTRAINTS
-- =============================================

-- 15. Create Tables with Constraints
CREATE TABLE ascii_constrained_t5 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputChar CHAR(1),
    
    -- Only allow printable ASCII characters
    CONSTRAINT CHK_PrintableASCII 
        CHECK (ASCII(InputChar) BETWEEN 32 AND 126),
    
    -- No digits allowed
    CONSTRAINT CHK_NoDigits 
        CHECK (ASCII(InputChar) NOT BETWEEN 48 AND 57)
);
GO

CREATE TABLE ascii_constrained_t6 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputString VARCHAR(10),
    
    -- First character must be uppercase
    CONSTRAINT CHK_StartsWithUpper 
        CHECK (ASCII(InputString) BETWEEN 65 AND 90),
    
    -- No control characters allowed
    CONSTRAINT CHK_NoControl 
        CHECK (ASCII(InputString) >= 32)
);
GO

-- Test Constraints
-- Valid inserts
BEGIN TRY
    INSERT INTO ascii_constrained_t5 (InputChar) VALUES ('A'), ('z'), ('#');
    INSERT INTO ascii_constrained_t6 (InputString) VALUES ('Test'), ('ABC');
    SELECT 'Valid inserts succeeded' AS Status;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- Invalid inserts
BEGIN TRY
    -- Try to insert a digit
    INSERT INTO ascii_constrained_t5 (InputChar) VALUES ('5');
END TRY
BEGIN CATCH
    SELECT 'Digit constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    -- Try to insert lowercase first character
    INSERT INTO ascii_constrained_t6 (InputString) VALUES ('test');
END TRY
BEGIN CATCH
    SELECT 'Uppercase constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW ascii_v1;
DROP VIEW ascii_v2;
GO

-- Drop Functions
DROP FUNCTION ascii_fn_validatechar;
DROP FUNCTION ascii_fn_comparetypes;
GO

-- Drop Procedures
DROP PROCEDURE ascii_sp_analyzestring;
DROP PROCEDURE ascii_sp_validateascii;
GO

-- Drop Tables
DROP TABLE ascii_constrained_t6;
DROP TABLE ascii_constrained_t5;
DROP TABLE ascii_computed_t4;
DROP TABLE ascii_conversion_t3;
DROP TABLE ascii_t2;
DROP TABLE ascii_t1;
GO

-- Drop Types
DROP TYPE ascii_type_char;
DROP TYPE ascii_type_varchar;
DROP TYPE ascii_type_nchar;
DROP TYPE ascii_type_nvarchar;
GO

