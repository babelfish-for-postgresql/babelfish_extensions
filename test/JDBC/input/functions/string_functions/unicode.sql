-- Create UDTs
CREATE TYPE unicode_type_char FROM CHAR(10);
CREATE TYPE unicode_type_varchar FROM VARCHAR(50);
CREATE TYPE unicode_type_nchar FROM NCHAR(10);
CREATE TYPE unicode_type_nvarchar FROM NVARCHAR(50);
GO

-- Create base tables
CREATE TABLE unicode_t1 (
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

-- Create table for Unicode range tests
CREATE TABLE unicode_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    UnicodeChar NCHAR(1),
    UnicodeString NVARCHAR(50),
    ExpectedValue INT,
    CharacterType NVARCHAR(50),
    Description NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO unicode_t1 VALUES
-- Basic ASCII characters
('A', 'A', N'A', N'A', 'A', N'A', 65, 'Capital A'),
('a', 'a', N'a', N'a', 'a', N'a', 97, 'Lowercase a'),
('Z', 'Z', N'Z', N'Z', 'Z', N'Z', 90, 'Capital Z'),
('1', '1', N'1', N'1', '1', N'1', 49, 'Number 1'),

-- Special ASCII characters
(' ', ' ', N' ', N' ', ' ', N' ', 32, 'Space'),
('!', '!', N'!', N'!', '!', N'!', 33, 'Exclamation mark'),

-- Empty and NULL
('', '', N'', N'', '', N'', NULL, 'Empty string'),
(NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NULL value'),

-- Multiple characters (should take first)
('ABC', 'ABC', N'ABC', N'ABC', 'ABC', N'ABC', 65, 'Multiple characters'),
('123', '123', N'123', N'123', '123', N'123', 49, 'Multiple numbers');
GO

-- Insert Unicode test data
INSERT INTO unicode_t2 VALUES
-- ASCII range
(N'A', N'ASCII uppercase', 65, 'ASCII', 'Basic Latin uppercase'),
(N'a', N'ASCII lowercase', 97, 'ASCII', 'Basic Latin lowercase'),

-- Latin-1 Supplement
(N'é', N'Latin-1 character', 233, 'Latin-1', 'Latin-1 character é'),
(N'ñ', N'Latin-1 character', 241, 'Latin-1', 'Latin-1 character ñ'),

-- Greek
(N'α', N'Greek character', 945, 'Greek', 'Greek character alpha'),
(N'Ω', N'Greek character', 937, 'Greek', 'Greek character omega'),

-- Cyrillic
(N'Я', N'Cyrillic character', 1071, 'Cyrillic', 'Cyrillic character ya'),
(N'И', N'Cyrillic character', 1048, 'Cyrillic', 'Cyrillic character i'),

-- Japanese Hiragana
(N'あ', N'Hiragana character', 12354, 'Hiragana', 'Hiragana a'),
(N'ん', N'Hiragana character', 12435, 'Hiragana', 'Hiragana n'),

-- Japanese Katakana
(N'ア', N'Katakana character', 12450, 'Katakana', 'Katakana a'),
(N'ン', N'Katakana character', 12531, 'Katakana', 'Katakana n'),

-- Chinese/Japanese Kanji
(N'日', N'Kanji character', 26085, 'Kanji', 'Kanji for sun/day'),
(N'本', N'Kanji character', 26412, 'Kanji', 'Kanji for origin/book'),

-- Korean Hangul
(N'한', N'Hangul character', 54620, 'Hangul', 'Hangul character han'),
(N'글', N'Hangul character', 44544, 'Hangul', 'Hangul character gul'),

-- Symbols
(N'☺', N'Smiling face', 9786, 'Symbol', 'White smiling face'),
(N'★', N'Star', 9733, 'Symbol', 'Black star'),
(N'©', N'Copyright', 169, 'Symbol', 'Copyright sign'),

-- Emoji
(N'😀', N'Grinning face', 128512, 'Emoji', 'Grinning face emoji'),
(N'🌟', N'Glowing star', 127775, 'Emoji', 'Glowing star emoji');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic ASCII Range Tests
SELECT 
    UNICODE(N'A') AS CapitalA,
    UNICODE(N'a') AS LowercaseA,
    UNICODE(N'Z') AS CapitalZ,
    UNICODE(N'z') AS LowercaseZ,
    UNICODE(N'0') AS Zero,
    UNICODE(N'9') AS Nine;
GO

-- 2. Special Character Tests
SELECT 
    UNICODE(N' ') AS Space,
    UNICODE(N'!') AS ExclamationMark,
    UNICODE(N'@') AS AtSymbol,
    UNICODE(N'#') AS HashSymbol,
    UNICODE(N'$') AS DollarSign,
    UNICODE(N'%') AS PercentSign;
GO

-- 3. NULL and Empty String Tests
SELECT 
    UNICODE(NULL) AS NullInput,
    UNICODE(N'') AS EmptyString,
    UNICODE(N'  ') AS MultipleSpaces,
    UNICODE(CAST(NULL AS NVARCHAR)) AS NullNVarchar;
GO

-- 4. Unicode Range Tests by Category
SELECT 
    UnicodeChar,
    UNICODE(UnicodeChar) AS UnicodeValue,
    CharacterType,
    Description,
    CASE 
        WHEN UNICODE(UnicodeChar) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM unicode_t2
ORDER BY CharacterType, UnicodeValue;
GO

-- 5. Multiple Character String Tests
SELECT 
    UNICODE(N'ABC') AS FirstOfABC,
    UNICODE(N'123') AS FirstOf123,
    UNICODE(N'!@#') AS FirstOfSpecial,
    UNICODE(N'   ABC') AS FirstOfSpacedString,
    UNICODE(NCHAR(13) + N'ABC') AS FirstOfCRString;
GO

-- 6. Data Type Tests
SELECT 
    -- Non-Unicode types (implicit conversion)
    UNICODE('A') AS CharA,
    UNICODE('ABC') AS VarcharABC,
    
    -- Unicode types
    UNICODE(N'A') AS NCharA,
    UNICODE(N'ABC') AS NVarcharABC,
    
    -- Text types
    UNICODE(CAST('A' AS TEXT)) AS TextA,
    UNICODE(CAST(N'A' AS NTEXT)) AS NTextA;
GO

-- 7. Control Character Tests
SELECT 
    UNICODE(NCHAR(0)) AS NullChar,
    UNICODE(NCHAR(9)) AS Tab,
    UNICODE(NCHAR(10)) AS LineFeed,
    UNICODE(NCHAR(13)) AS CarriageReturn,
    UNICODE(NCHAR(27)) AS EscapeChar;
GO

-- 8. Extended Character Tests
SELECT 
    -- Latin-1 Supplement
    UNICODE(N'é') AS LatinE_Acute,
    UNICODE(N'ñ') AS LatinN_Tilde,
    
    -- Greek
    UNICODE(N'α') AS GreekAlpha,
    UNICODE(N'Ω') AS GreekOmega,
    
    -- Cyrillic
    UNICODE(N'Я') AS CyrillicYa,
    
    -- CJK
    UNICODE(N'日') AS Kanji_Sun,
    UNICODE(N'한') AS Hangul_Han;
GO

-- 9. Surrogate Pair Tests (Emoji and other supplementary characters)
SELECT 
    UNICODE(N'😀') AS GrinningFace,
    UNICODE(N'🌟') AS GlowingStar,
    UNICODE(N'🎮') AS VideoGame,
    LEN(N'😀') AS EmojiLength,
    DATALENGTH(N'😀') AS EmojiDataLength;
GO

-- 10. Conversion Tests
SELECT 
    -- Implicit conversions
    UNICODE('A') AS FromChar,
    UNICODE(CAST('A' AS VARCHAR)) AS FromVarchar,
    
    -- Explicit conversions
    UNICODE(CAST('A' AS NCHAR)) AS ToNChar,
    UNICODE(CAST('A' AS NVARCHAR)) AS ToNVarchar;
GO

-- =============================================
-- ADVANCED TEST CASES
-- =============================================

-- 11. Unicode Block Range Tests
CREATE TABLE unicode_blocks_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BlockStart INT,
    BlockEnd INT,
    BlockName NVARCHAR(100)
);
GO

INSERT INTO unicode_blocks_t3 VALUES
(0, 127, 'Basic Latin'),
(128, 255, 'Latin-1 Supplement'),
(256, 383, 'Latin Extended-A'),
(384, 591, 'Latin Extended-B'),
(880, 1023, 'Greek and Coptic'),
(1024, 1279, 'Cyrillic'),
(12352, 12447, 'Hiragana'),
(12448, 12543, 'Katakana'),
(19968, 40959, 'CJK Unified Ideographs'),
(44032, 55215, 'Hangul Syllables');
GO

-- Test characters from each Unicode block
WITH BlockCharacters AS (
    SELECT 
        BlockName,
        BlockStart,
        NCHAR(BlockStart) AS StartChar,
        UNICODE(NCHAR(BlockStart)) AS StartCharCode
    FROM unicode_blocks_t3
    WHERE BlockStart <= 55215  -- Maximum safe value for NCHAR
)
SELECT * FROM BlockCharacters;
GO

-- 12. String Length vs Unicode Tests
CREATE TABLE unicode_length_t4 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    StringValue NVARCHAR(100),
    StringLength AS LEN(StringValue),
    DataLength AS DATALENGTH(StringValue),
    FirstCharUnicode AS UNICODE(StringValue)
);
GO

INSERT INTO unicode_length_t4 (StringValue) VALUES
(N'ASCII Only'),                    -- ASCII
(N'Latin é à ù'),                   -- Latin-1
(N'Кириллица'),                     -- Cyrillic
(N'日本語'),                        -- CJK
(N'한글'),                          -- Hangul
(N'Mixed 日本語 ASCII'),            -- Mixed
(N'Emoji 😀 🌟'),                   -- With Emoji
(N'');                              -- Empty string
GO

SELECT *, 
    DataLength/2 AS CharacterCount,
    CASE 
        WHEN DataLength/2 = StringLength THEN 'Match'
        ELSE 'Mismatch'
    END AS LengthCheck
FROM unicode_length_t4;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 13. Create Views
CREATE VIEW unicode_v1 AS
SELECT 
    ID,
    UnicodeChar,
    UnicodeString,
    UNICODE(UnicodeChar) AS CharUnicode,
    ExpectedValue,
    CASE 
        WHEN UNICODE(UnicodeChar) = ExpectedValue THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult,
    CharacterType,
    Description
FROM unicode_t2;
GO

CREATE VIEW unicode_v2 AS
SELECT 
    ID,
    StringValue,
    StringLength,
    DataLength,
    FirstCharUnicode,
    NCHAR(FirstCharUnicode) AS ReconstructedChar,
    CASE 
        WHEN NCHAR(FirstCharUnicode) = LEFT(StringValue, 1) THEN 'Pass'
        ELSE 'Fail'
    END AS RoundTripTest
FROM unicode_length_t4;
GO

-- Test Views
SELECT * FROM unicode_v1 WHERE TestResult = 'Fail';
SELECT * FROM unicode_v2 WHERE RoundTripTest = 'Fail';
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 14. Create Functions
CREATE FUNCTION unicode_fn_analyze
(
    @InputString NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @InputString AS InputString,
        UNICODE(@InputString) AS FirstCharCode,
        CASE 
            WHEN UNICODE(@InputString) <= 127 THEN 'ASCII'
            WHEN UNICODE(@InputString) <= 255 THEN 'Latin-1'
            WHEN UNICODE(@InputString) <= 1279 THEN 'Cyrillic'
            WHEN UNICODE(@InputString) <= 12447 THEN 'Hiragana'
            WHEN UNICODE(@InputString) <= 12543 THEN 'Katakana'
            WHEN UNICODE(@InputString) <= 40959 THEN 'CJK'
            WHEN UNICODE(@InputString) <= 55215 THEN 'Hangul'
            ELSE 'Other'
        END AS CharacterSet
);
GO

CREATE FUNCTION unicode_fn_validaterange
(
    @StartCode INT,
    @EndCode INT
)
RETURNS TABLE
AS
RETURN
(
    WITH Numbers AS (
        SELECT generate_series AS CodePoint
        FROM GENERATE_SERIES(@StartCode, @EndCode)
    )
    SELECT 
        CodePoint,
        NCHAR(CodePoint) AS CharacterValue,
        UNICODE(NCHAR(CodePoint)) AS RoundTrip,
        CASE 
            WHEN CodePoint = UNICODE(NCHAR(CodePoint)) THEN 'Valid'
            ELSE 'Invalid'
        END AS ValidationResult
    FROM Numbers
);
GO

-- Test Functions
SELECT * FROM unicode_fn_analyze(N'Hello');
SELECT * FROM unicode_fn_analyze(N'こんにちは');
SELECT * FROM unicode_fn_validaterange(65, 70);  -- A-F range
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 15. Create Procedures
CREATE PROCEDURE unicode_sp_analyzestring
    @InputString NVARCHAR(MAX)
AS
BEGIN
    SELECT 
        Position = generate_series,
        Character = SUBSTRING(@InputString, generate_series, 1),
        UnicodeValue = UNICODE(SUBSTRING(@InputString, generate_series, 1))
    FROM GENERATE_SERIES(1, LEN(@InputString));
END;
GO

CREATE PROCEDURE unicode_sp_validatecharacter
    @Char NCHAR(1),
    @ExpectedValue INT = NULL
AS
BEGIN
    DECLARE @ActualValue INT = UNICODE(@Char);
    
    SELECT 
        @Char AS TestChar,
        @ActualValue AS UnicodeValue,
        @ExpectedValue AS ExpectedValue,
        CASE 
            WHEN @ExpectedValue IS NULL THEN 'No Expected Value'
            WHEN @ActualValue = @ExpectedValue THEN 'Pass'
            ELSE 'Fail'
        END AS TestResult,
        CASE 
            WHEN @ActualValue <= 127 THEN 'ASCII'
            WHEN @ActualValue <= 255 THEN 'Latin-1'
            WHEN @ActualValue <= 1279 THEN 'Cyrillic'
            ELSE 'Other'
        END AS CharacterSet;
END;
GO

-- Test Procedures
EXEC unicode_sp_analyzestring N'Hello世界';
EXEC unicode_sp_validatecharacter N'A', 65;
EXEC unicode_sp_validatecharacter N'世';
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS
-- =============================================

-- 16. Create Tables with Computed Columns
CREATE TABLE unicode_computed_t5 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharValue NCHAR(1),
    StringValue NVARCHAR(100),
    
    -- Computed columns
    CharUnicode AS UNICODE(CharValue) PERSISTED,
    FirstCharUnicode AS UNICODE(StringValue) PERSISTED,
    
    IsASCII AS CASE 
                WHEN UNICODE(CharValue) <= 127 THEN 1 
                ELSE 0 
              END PERSISTED,
    
    CharacterSet AS CASE 
                    WHEN UNICODE(CharValue) <= 127 THEN 'ASCII'
                    WHEN UNICODE(CharValue) <= 255 THEN 'Latin-1'
                    WHEN UNICODE(CharValue) <= 1279 THEN 'Cyrillic'
                    ELSE 'Other'
                   END PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO unicode_computed_t5 (CharValue, StringValue) VALUES
(N'A', N'ASCII String'),
(N'é', N'Latin-1 String'),
(N'Я', N'Cyrillic String'),
(N'日', N'CJK String');

SELECT * FROM unicode_computed_t5;
GO

-- =============================================
-- DEPENDENT OBJECTS - CONSTRAINTS
-- =============================================

-- 17. Create Tables with Constraints
CREATE TABLE unicode_constrained_t6 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharValue NCHAR(1),
    
    -- Only allow ASCII characters
    CONSTRAINT CHK_ASCIIOnly 
        CHECK (UNICODE(CharValue) <= 127),
    
    -- No control characters
    CONSTRAINT CHK_NoControl 
        CHECK (UNICODE(CharValue) >= 32)
);
GO

CREATE TABLE unicode_constrained_t7 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    StringValue NVARCHAR(100),
    
    -- First character must be uppercase ASCII
    CONSTRAINT CHK_StartsUpperASCII 
        CHECK (UNICODE(StringValue) BETWEEN 65 AND 90),
    
    -- No emoji allowed
    CONSTRAINT CHK_NoEmoji 
        CHECK (UNICODE(StringValue) < 128512)
);
GO

-- Test Constraints
-- Valid inserts
BEGIN TRY
    INSERT INTO unicode_constrained_t6 (CharValue) VALUES (N'A'), (N'z'), (N'#');
    INSERT INTO unicode_constrained_t7 (StringValue) VALUES (N'Test'), (N'ASCII');
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
    -- Try to insert non-ASCII character
    INSERT INTO unicode_constrained_t6 (CharValue) VALUES (N'é');
END TRY
BEGIN CATCH
    SELECT 'Non-ASCII constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    -- Try to insert emoji
    INSERT INTO unicode_constrained_t7 (StringValue) VALUES (N'😀 Test');
END TRY
BEGIN CATCH
    SELECT 'Emoji constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW unicode_v1;
DROP VIEW unicode_v2;
GO

-- Drop Functions
DROP FUNCTION unicode_fn_analyze;
DROP FUNCTION unicode_fn_validaterange;
GO

-- Drop Procedures
DROP PROCEDURE unicode_sp_analyzestring;
DROP PROCEDURE unicode_sp_validatecharacter;
GO

-- Drop Tables
DROP TABLE unicode_constrained_t7;
DROP TABLE unicode_constrained_t6;
DROP TABLE unicode_computed_t5;
DROP TABLE unicode_length_t4;
DROP TABLE unicode_blocks_t3;
DROP TABLE unicode_t2;
DROP TABLE unicode_t1;
GO

-- Drop Types
DROP TYPE unicode_type_char;
DROP TYPE unicode_type_varchar;
DROP TYPE unicode_type_nchar;
DROP TYPE unicode_type_nvarchar;
GO
