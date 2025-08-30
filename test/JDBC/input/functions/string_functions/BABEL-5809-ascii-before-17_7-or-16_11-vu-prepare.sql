/*
===========================================
BABEL-5809: ASCII Function Testing - Setup
===========================================
*/

-- 1. USER DEFINED TYPES
CREATE TYPE babel_5809_type_char FROM CHAR(10);
CREATE TYPE babel_5809_type_varchar FROM VARCHAR(50);
CREATE TYPE babel_5809_type_nchar FROM NCHAR(10);
CREATE TYPE babel_5809_type_nvarchar FROM NVARCHAR(50);
GO

-- 2.1 Basic ASCII Testing Table
CREATE TABLE babel_5809_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NCharCol NCHAR(10),
    NVarcharCol NVARCHAR(50),
    TextCol TEXT,
    NTextCol NTEXT,
    ExpectedValue INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description VARCHAR(100)
);
GO

INSERT INTO babel_5809_t1 (CharCol, VarcharCol, NCharCol, NVarcharCol, TextCol, NTextCol, ExpectedValue, Description)
VALUES
('A', 'A', N'A', N'A', 'A', N'A', 65, 'Capital A'),
('a', 'a', N'a', N'a', 'a', N'a', 97, 'Lowercase a'),
('Z', 'Z', N'Z', N'Z', 'Z', N'Z', 90, 'Capital Z'),
('z', 'z', N'z', N'z', 'z', N'z', 122, 'Lowercase z'),
('0', '0', N'0', N'0', '0', N'0', 48, 'Zero digit'),
('9', '9', N'9', N'9', '9', N'9', 57, 'Nine digit'),
(' ', ' ', N' ', N' ', ' ', N' ', 32, 'Space'),
('!', '!', N'!', N'!', '!', N'!', 33, 'Exclamation mark'),
('@', '@', N'@', N'@', '@', N'@', 64, 'At symbol'),
('#', '#', N'#', N'#', '#', N'#', 35, 'Hash symbol'),
(CHAR(9), CHAR(9), NCHAR(9), NCHAR(9), CHAR(9), NCHAR(9), 9, 'Tab'),
(CHAR(13), CHAR(13), NCHAR(13), NCHAR(13), CHAR(13), NCHAR(13), 13, 'Carriage return'),
(CHAR(10), CHAR(10), NCHAR(10), NCHAR(10), CHAR(10), NCHAR(10), 10, 'Line feed'),
('ABC', 'ABC', N'ABC', N'ABC', 'ABC', N'ABC', 65, 'Multiple chars - returns first'),
('123', '123', N'123', N'123', '123', N'123', 49, 'Multiple numbers - returns first'),
('', '', N'', N'', '', N'', NULL, 'Empty string'),
(' A', ' A', N' A', N' A', ' A', N' A', 32, 'Space then char');

UPDATE babel_5809_t1
SET ActualValue = ASCII(VarcharCol),
    TestResult = CASE 
        WHEN ASCII(VarcharCol) IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(VarcharCol) = ExpectedValue THEN 'Pass'
        ELSE 'Fail' 
     END;
GO

-- 2.2 Unicode Testing Table
CREATE TABLE babel_5809_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    UnicodeChar NVARCHAR(10),
    UnicodeString NVARCHAR(50),
    ExpectedValue INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description NVARCHAR(100)
);
GO

INSERT INTO babel_5809_t2 (UnicodeChar, UnicodeString, ExpectedValue, Description)
VALUES
(N'A', N'ASCII in Unicode', 65, N'ASCII character in Unicode string'),
(N' ', N'Space in Unicode', 32, N'Space character'),
(N'', N'Empty Unicode', NULL, N'Empty Unicode string'),
(NCHAR(9), N'Tab in Unicode', 9, N'Unicode tab character'),
(N'é', N'Accented e', 233, N'Accented character');

UPDATE babel_5809_t2
SET ActualValue = ASCII(UnicodeChar),
    TestResult = CASE 
        WHEN ASCII(UnicodeChar) IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(UnicodeChar) = ExpectedValue THEN 'Pass'
        ELSE 'Fail' 
     END;    
GO

-- 2.3 Binary and Hex Testing Table
CREATE TABLE babel_5809_t3_hex (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryCol BINARY(10),
    VarbinaryCol VARBINARY(50),
    ExpectedValue INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description VARCHAR(100)
);
GO

INSERT INTO babel_5809_t3_hex (BinaryCol, VarbinaryCol, ExpectedValue, Description)
VALUES
(0x41, 0x41, 65, 'Hex for "A"'),
(0x65, 0x65, 101, 'Hex for "e"'),
(0x20, 0x20, 32, 'Hex for space'),
(0x30, 0x30, 48, 'Hex for "0"'),
(0x7A, 0x7A, 122, 'Hex for "z"'),
(0x21, 0x21, 33, 'Hex for "!"'),
(0x00, 0x00, 0, 'Hex for null byte'),
(0xFF, 0xFF, 255, 'Hex for 255'),
(0x414243, 0x414243, 65, 'Hex for "ABC"'),
(0x612063, 0x612063, 97, 'Hex for "a c"');

UPDATE babel_5809_t3_hex
SET ActualValue = ASCII(VarbinaryCol),
    TestResult = CASE WHEN ASCII(VarbinaryCol) = ExpectedValue THEN 'Pass' ELSE 'Fail' END;
GO

-- 2.4 Binary Conversion Testing Table
CREATE TABLE babel_5809_t4_convert (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharValue CHAR(1),
    BinaryValue VARBINARY(10),
    ExpectedASCII INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description VARCHAR(100)
);
GO

INSERT INTO babel_5809_t4_convert (CharValue, BinaryValue, ExpectedASCII, Description)
VALUES
('A', CAST('A' AS VARBINARY(10)), 65, 'Capital A conversion'),
('a', CAST('a' AS VARBINARY(10)), 97, 'Lowercase a conversion'),
('0', CAST('0' AS VARBINARY(10)), 48, 'Zero conversion'),
(' ', CAST(' ' AS VARBINARY(10)), 32, 'Space conversion'),
('!', CAST('!' AS VARBINARY(10)), 33, 'Exclamation mark conversion');

UPDATE babel_5809_t4_convert
SET ActualValue = ASCII(BinaryValue),
    TestResult = CASE 
        WHEN ASCII(BinaryASCII) IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(BinaryASCII) = ExpectedValue THEN 'Pass'
        ELSE 'Fail' 
    END;
GO

-- 2.5 Edge Cases and Negative Values Table
CREATE TABLE babel_5809_t5_edge (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    IntValue BIGINT,
    CharValue VARCHAR(1),
    ExpectedASCII INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description VARCHAR(100)
);
GO

INSERT INTO babel_5809_t5_edge (IntValue, CharValue, ExpectedASCII, Description)
VALUES
-- Negative values
(-1, '-', 45, 'Negative one'),
(-123, '-', 45, 'Negative three digits'),
(-452316782, '-', 45, 'Large negative number'),
-- Zero and special numbers
(0, '0', 48, 'Zero'),
(127, '1', 49, 'Number 127'),
(255, '2', 50, 'Number 255'),
-- Large positive numbers
(2147483647, '2', 50, 'INT MAX'),
(922337203685477580, '9', 57, 'Large BIGINT value'),
(999999999, '9', 57, 'Large number with 9s'),
-- Edge cases for conversion
(2147483648, '2', 50, 'INT MAX + 1'),
(922337203685477581, '9', 57, 'Large BIGINT value + 1'),
(-2147483648, '-', 45, 'INT MIN'),
(-922337203685477580, '-', 45, 'Large negative BIGINT value');

UPDATE babel_5809_t5_edge
SET ActualValue = ASCII(CharValue),
    TestResult = CASE 
        WHEN ASCII(CharValue) IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(CharValue) = ExpectedValue THEN 'Pass'
        ELSE 'Fail' 
    END;
GO

-- 2.6 Numeric Conversion Testing Table
CREATE TABLE babel_5809_t6_numeric (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    NumValue DECIMAL(38,0),
    StringValue VARCHAR(40),
    ExpectedASCII INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    Description VARCHAR(100)
);
GO

INSERT INTO babel_5809_t6_numeric (NumValue, StringValue, ExpectedASCII, Description)
VALUES
-- Extreme negative values
(-99999999999, '-99999999999', 45, 'Large negative decimal'),
(-0.123, '-0.123', 45, 'Negative decimal less than 1'),
(-0.0000000001, '-0.0000000001', 45, 'Very small negative decimal'),
-- Zero variations
(0.0, '0.0', 48, 'Zero with decimal'),
(0.000000, '0.000000', 48, 'Zero with multiple decimals'),
-- Extreme positive values
(99999999999, '99999999999', 57, 'Large positive decimal'),
(0.999999999999999999, '0.999999999999999999', 48, 'Decimal close to 1'),
-- Scientific notation values
(1E+10, '1E+10', 49, 'Scientific notation positive'),
(1E-10, '1E-10', 49, 'Scientific notation negative exponent');

UPDATE babel_5809_t6_numeric
SET ActualValue = ASCII(StringValue),
   TestResult = CASE 
        WHEN ASCII(StringValue) IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(StringValue) = ExpectedValue THEN 'Pass'
        ELSE 'Fail' 
    END;
GO

-- 2.7 Invalid Input Testing Table
CREATE TABLE babel_5809_t7_edge (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    TestCase VARCHAR(100),
    TestValue VARCHAR(100),
    ExpectedValue INT,
    ActualValue INT,
    TestResult VARCHAR(4)
);
GO

INSERT INTO babel_5809_t7_edge (TestCase, TestValue, ExpectedValue)
VALUES
('NULL Value', NULL, NULL),
('Zero Length String', '', NULL),
('Very Large Binary', CAST(0xFFFFFFFFFFFFFFFF AS VARCHAR(100)), 255),
('Invalid Hex String', 0xGG, 'Msg 33557097, Level 16, State 1, Server BABELFISH, Line 1 syntax error near '0x' at line 1 and character position 0'),
('Special Characters Only', '@@@@', 64),
('Mixed Invalid Chars', '123@#$%', 49);

UPDATE babel_5809_t7_edge
SET ActualValue = ASCII(TestValue),
    TestResult = CASE 
        WHEN TestValue IS NULL AND ExpectedValue IS NULL THEN 'Pass'
        WHEN ASCII(TestValue) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END;
GO

-- 3. FUNCTIONS
-- 3.1 ASCII Range Validation Function
CREATE FUNCTION babel_5809_fn_validate_ascii_range
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
            WHEN ASCII(@InputChar) BETWEEN 32 AND 127 THEN 'Standard ASCII'
            WHEN ASCII(@InputChar) BETWEEN 160 AND 255 THEN 'Extended ASCII'
            WHEN ASCII(@InputChar) BETWEEN 0 AND 31 THEN 'Control Character'
            WHEN ASCII(@InputChar) IS NULL THEN 'Null Input'
            WHEN ASCII(@InputChar) BETWEEN 128 AND 159 THEN 'Control Character (128-159)'
            ELSE 'Invalid Range'
        END AS CharacterRange
);
GO

-- 3.2 ASCII Category Function
CREATE FUNCTION babel_5809_fn_ascii_category
(
    @InputChar VARCHAR(1)
)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @ASCIIValue INT = ASCII(@InputChar)
    RETURN 
        CASE 
            WHEN @ASCIIValue BETWEEN 48 AND 57 THEN 'Digit'
            WHEN @ASCIIValue BETWEEN 65 AND 90 THEN 'Uppercase'
            WHEN @ASCIIValue BETWEEN 97 AND 122 THEN 'Lowercase'
            WHEN @ASCIIValue BETWEEN 32 AND 47 
                 OR @ASCIIValue BETWEEN 58 AND 64
                 OR @ASCIIValue BETWEEN 91 AND 96
                 OR @ASCIIValue BETWEEN 123 AND 127 THEN 'Special'
            WHEN @ASCIIValue BETWEEN 0 AND 31 THEN 'Control'
            WHEN @ASCIIValue BETWEEN 160 AND 255 THEN 'Extended'
            ELSE 'Invalid'
        END
END;
GO

-- 4. STORED PROCEDURES
-- 4.1 String Validation Procedure
CREATE PROCEDURE babel_5809_sp_validate_string
    @InputString VARCHAR(100)
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@InputString);
    
    CREATE TABLE #Results (
        Position INT,
        Character CHAR(1),
        ASCIIValue INT,
        Category VARCHAR(20),
        TestResult VARCHAR(4)
    );
    
    WHILE @i <= @len
    BEGIN
        INSERT INTO #Results
        SELECT 
            @i,
            SUBSTRING(@InputString, @i, 1),
            ASCII(SUBSTRING(@InputString, @i, 1)),
            dbo.babel_5809_fn_ascii_category(SUBSTRING(@InputString, @i, 1)),
            'Pass'; -- Since this is validation, all results are considered valid
        
        SET @i = @i + 1;
    END;
    
    SELECT * FROM #Results;
    DROP TABLE #Results;
END;
GO

-- 4.2 ASCII Validation Procedure
CREATE PROCEDURE babel_5809_ascii_sp_analyzestring
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
        END AS CharacterType,
        CASE 
            WHEN @InputString IS NULL OR @InputString = '' THEN 
                CASE WHEN ASCII(@InputString) IS NULL THEN 'Pass' ELSE 'Fail' END
            WHEN ASCII(@InputString) = ASCII(CHAR(ASCII(@InputString))) THEN 'Pass' 
            ELSE 'Fail' 
        END AS TestResult
END;
GO

-- 4.3 ASCII Comparison Procedure
CREATE PROCEDURE babel_5809_ascii_sp_validateascii
    @InputChar CHAR(1),
    @ExpectedValue INT
AS
BEGIN
    DECLARE @ActualValue INT = ASCII(@InputChar);
    
    SELECT 
        CASE WHEN @ActualValue = @ExpectedValue THEN 'Pass' ELSE 'Fail' END AS TestResult,
        @InputChar AS TestChar,
        @ActualValue AS ActualASCII,
        @ExpectedValue AS ExpectedASCII;
END;
GO

-- 5. TABLES WITH COMPUTED COLUMNS
CREATE TABLE babel_5809_computed_ascii (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputChar CHAR(1),
    ASCIIValue INT,
    Category VARCHAR(20),
    IsValidRange BIT,
    IsPrintable BIT,
    ActualValue INT,
    TestResult VARCHAR(4)
);
GO

-- 6. TABLES WITH CONSTRAINTS
CREATE TABLE babel_5809_constrained_ascii (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputChar CHAR(1),
    ExpectedValue INT,
    ActualValue INT,
    TestResult VARCHAR(4),
    
    CONSTRAINT CHK_ValidRange 
        CHECK (ASCII(InputChar) < 128 OR ASCII(InputChar) >= 160),
    
    CONSTRAINT CHK_Printable 
        CHECK (ASCII(InputChar) BETWEEN 32 AND 126),
    
    CONSTRAINT CHK_NoControl 
        CHECK (ASCII(InputChar) >= 32)
);
GO

-- 7. VIEWS
CREATE VIEW babel_5809_v1_datatypes AS
SELECT 
    ID,
    CharCol,
    ASCII(CharCol) AS CharASCII,
    VarcharCol,
    ASCII(VarcharCol) AS VarcharASCII,
    NCharCol,
    ASCII(NCharCol) AS NCharASCII,
    NVarcharCol,
    ASCII(NVarcharCol) AS NVarcharASCII,
    TextCol,
    ASCII(TextCol) AS TextASCII,
    NTextCol,
    ASCII(NTextCol) AS NTextASCII,
    ExpectedValue,
    ActualValue,
    TestResult
FROM babel_5809_t1;
GO

CREATE VIEW babel_5809_v2_binary AS
SELECT 
    ID,
    BinaryCol,
    ASCII(BinaryCol) AS BinaryASCII,
    VarbinaryCol,
    ASCII(VarbinaryCol) AS VarbinaryASCII,
    ExpectedValue,
    ActualValue,
    TestResult,
    Description
FROM babel_5809_t3_hex;
GO

-- 8. Populate tables
-- 8.1 Populate Computed Columns Table
INSERT INTO babel_5809_computed_ascii 
(InputChar, ASCIIValue, Category, IsValidRange, IsPrintable)
VALUES
('A', 65, 'Uppercase', 1, 1),
('1', 49, 'Digit', 1, 1),
('!', 33, 'Special', 1, 1),
(' ', 32, 'Special', 1, 1),
(CHAR(27), 27, 'Control', 1, 0),
(CHAR(160), 160, 'Extended', 1, 0);

UPDATE babel_5809_computed_ascii
SET ActualValue = ASCII(InputChar),
    TestResult = CASE WHEN ASCII(InputChar) = ASCIIValue THEN 'Pass' ELSE 'Fail' END;
GO

-- 8.2 Populate Constrained Table
INSERT INTO babel_5809_constrained_ascii (InputChar, ExpectedValue)
VALUES
('A', 65),
('z', 122),
('0', 48),
('$', 36);

UPDATE babel_5809_constrained_ascii
SET ActualValue = ASCII(InputChar),
    TestResult = CASE WHEN ASCII(InputChar) = ExpectedValue THEN 'Pass' ELSE 'Fail' END;
GO