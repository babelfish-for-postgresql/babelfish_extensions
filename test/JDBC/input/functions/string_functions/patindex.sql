-- Create UDTs
CREATE TYPE patindex_type_varchar FROM VARCHAR(100);
CREATE TYPE patindex_type_nvarchar FROM NVARCHAR(100);
CREATE TYPE patindex_type_text FROM TEXT;
GO

-- Create base tables
CREATE TABLE patindex_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Pattern VARCHAR(50),
    SourceText VARCHAR(200),
    ExpectedPosition INT,
    Description VARCHAR(100)
);
GO

CREATE TABLE patindex_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Pattern NVARCHAR(50),
    SourceText NVARCHAR(200),
    ExpectedPosition INT,
    Description NVARCHAR(100)
);
GO

-- Insert test data for pattern matching
INSERT INTO patindex_t1 (Pattern, SourceText, ExpectedPosition, Description) VALUES
('%test%', 'This is a test string', 11, 'Basic wildcard pattern'),
('_est%', 'This is a test string', 11, 'Single character wildcard'),
('%[aeiou]%', 'This is a test string', 3, 'Character class search'),
('%[^aeiou]%', 'This is a test string', 1, 'Negated character class'),
('[A-Z]%', 'This is a test string', 1, 'Character range'),
('%[0-9]%', 'Test1 string', 5, 'Numeric character search'),
('___s%', 'This is a test string', 1, 'Fixed length prefix'),
('%ing', 'This is a test string', 16, 'Pattern at end'),
('This%', 'This is a test string', 1, 'Pattern at start'),
('%[%]%', 'Test % string', 6, 'Search for % character'),
('%[_]%', 'Test _ string', 6, 'Search for _ character'),
('%test%string%', 'This is a test in a string here', 11, 'Multiple wildcards'),
('_[^aeiou]%', 'This is a test', 1, 'Combined wildcards'),
('%[aeiou][aeiou]%', 'book test', 1, 'Consecutive vowels'),
('[0-9][0-9]%', '12test', 1, 'Consecutive numbers');
GO

INSERT INTO patindex_t2 (Pattern, SourceText, ExpectedPosition, Description) VALUES
(N'%テスト%', N'これはテストです', 4, N'Basic Japanese pattern'),
(N'_スト%', N'テストです', 2, N'Japanese with single char wildcard'),
(N'%[あ-お]%', N'これはテストです', 3, N'Japanese character range'),
(N'%[^あ-お]%', N'これはテストです', 1, N'Negated Japanese range'),
(N'%test%', N'これはtestです', 4, N'Mixed Japanese and English'),
(N'%[0-9]%', N'テスト123テスト', 5, N'Numbers in Japanese text'),
(N'%です', N'これはテストです', 7, N'Japanese pattern at end'),
(N'これ%', N'これはテストです', 1, N'Japanese pattern at start');
GO

-- Create table for special pattern tests
CREATE TABLE patindex_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Pattern VARCHAR(50),
    SourceText TEXT,
    ExpectedPosition INT,
    Description VARCHAR(100)
);
GO

INSERT INTO patindex_t3 (Pattern, SourceText, ExpectedPosition, Description) VALUES
('%[0-9][0-9][0-9][0-9]%', '1234', 1, 'Exactly four digits'),
('%[A-Z][0-9]%', 'TestA1Test', 5, 'Letter followed by number'),
('%[0-9][-][0-9]%', 'Test1-2Test', 5, 'Number-dash-number pattern'),
('%[aeiou][^aeiou]%', 'Test', 1, 'Vowel followed by non-vowel'),
('%[@#$]%', 'Test@Test', 5, 'Special characters');
GO

-- =============================================
-- BASIC PATTERN TESTS
-- =============================================

-- 1. Basic Wildcard Tests
SELECT 
    PATINDEX('%test%', 'This is a test string') AS BasicWildcard,
    PATINDEX('_est%', 'This is a test string') AS SingleCharWildcard,
    PATINDEX('%ing', 'This is a testing string') AS EndPattern,
    PATINDEX('This%', 'This is a test string') AS StartPattern;
GO

-- 2. Character Class Tests
SELECT 
    PATINDEX('%[aeiou]%', 'This is a test') AS VowelSearch,
    PATINDEX('%[^aeiou]%', 'This is a test') AS NonVowelSearch,
    PATINDEX('%[0-9]%', 'Test1 string') AS DigitSearch,
    PATINDEX('%[A-Z]%', 'test STRING') AS UppercaseSearch;
GO

-- 3. Complex Pattern Tests
SELECT 
    PATINDEX('_[^aeiou][aeiou]%', 'This is a test') AS ComplexPattern1,
    PATINDEX('%[0-9][A-Z]%', 'Test1A test') AS ComplexPattern2,
    PATINDEX('%[[]%]%', 'Test [abc] test') AS EscapedBrackets,
    PATINDEX('%[%]%', 'Test % test') AS EscapedPercent;
GO

-- 4. NULL and Empty String Tests
SELECT 
    PATINDEX(NULL, 'Test String') AS NullPattern,
    PATINDEX('%test%', NULL) AS NullSource,
    PATINDEX('', 'Test String') AS EmptyPattern,
    PATINDEX('%test%', '') AS EmptySource;
GO

-- 5. Unicode String Tests
SELECT 
    PATINDEX(N'%テスト%', N'これはテストです') AS JapanesePattern,
    PATINDEX(N'_スト%', N'テストです') AS JapaneseWithWildcard,
    PATINDEX(N'%[あ-お]%', N'これはテストです') AS JapaneseCharRange,
    PATINDEX(N'%test%', N'これはtestです') AS MixedLanguagePattern;
GO

-- 6. Multiple Pattern Tests
SELECT 
    PATINDEX('%[aeiou]%[aeiou]%', 'This is a test') AS MultipleVowels,
    PATINDEX('%[0-9]%[0-9]%', 'Test12Test') AS MultipleDigits,
    PATINDEX('%test%string%', 'This is a test and a string') AS MultipleWords,
    PATINDEX('___[aeiou]%', 'This is a test') AS FixedLengthPrefix;
GO

-- 7. Special Character Tests
SELECT 
    PATINDEX('%[%]%', 'Test % string') AS PercentSign,
    PATINDEX('%[_]%', 'Test _ string') AS Underscore,
    PATINDEX('%[\[]%', 'Test [ string') AS OpenBracket,
    PATINDEX('%[\]]%', 'Test ] string') AS CloseBracket;
GO

-- 8. Boundary Tests
SELECT 
    PATINDEX('This%', 'This is a test') AS StartBoundary,
    PATINDEX('%test', 'This is a test') AS EndBoundary,
    PATINDEX('This is a test', 'This is a test') AS ExactMatch,
    PATINDEX('%', 'This is a test') AS AllWildcard;
GO

-- 9. Character Range Tests
SELECT 
    PATINDEX('%[A-Z][a-z]%', 'TestString') AS MixedCase,
    PATINDEX('%[0-9][A-Z]%', 'Test1A') AS NumberLetter,
    PATINDEX('%[A-Z][0-9][a-z]%', 'TestA1b') AS LetterNumberLetter,
    PATINDEX('%[^A-Za-z]%', 'Test123Test') AS NonLetter;
GO

-- 10. Consecutive Pattern Tests
SELECT 
    PATINDEX('%[0-9][0-9]%', '12Test') AS TwoDigits,
    PATINDEX('%[aeiou][aeiou]%', 'boolean') AS TwoVowels,
    PATINDEX('%[A-Z][A-Z]%', 'TestSTRING') AS TwoUppercase,
    PATINDEX('%[^0-9][0-9]%', 'Test1') AS NonDigitDigit;
GO

-- =============================================
-- ADVANCED PATTERN TESTS
-- =============================================

-- 11. Complex Wildcard Combinations
SELECT 
    PATINDEX('_[0-9]_%[aeiou]%', 'A1_test') AS ComplexWildcard1,
    PATINDEX('%[^0-9]_[0-9]%', 'testA1') AS ComplexWildcard2,
    PATINDEX('[A-Z]%[0-9]%[a-z]', 'Test1string') AS ComplexWildcard3,
    PATINDEX('___[^aeiou]%[aeiou]%', 'TestString') AS ComplexWildcard4;
GO

-- 12. Pattern with Different Data Types
CREATE TABLE patindex_datatype_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharField CHAR(20),
    VarcharField VARCHAR(50),
    NcharField NCHAR(20),
    NvarcharField NVARCHAR(50),
    TextField TEXT
);
GO

INSERT INTO patindex_datatype_t1 VALUES
('Test123', 'Test123String', N'Test123', N'Test123String', 'Test123Text'),
('ABC456', 'ABC456String', N'ABC456', N'ABC456String', 'ABC456Text');
GO

SELECT 
    PATINDEX('%[0-9]%', CharField) AS CharMatch,
    PATINDEX('%[0-9]%', VarcharField) AS VarcharMatch,
    PATINDEX('%[0-9]%', NcharField) AS NcharMatch,
    PATINDEX('%[0-9]%', NvarcharField) AS NvarcharMatch,
    PATINDEX('%[0-9]%', TextField) AS TextMatch
FROM patindex_datatype_t1;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 13. Create Views
CREATE VIEW patindex_v1 AS
SELECT 
    ID,
    Pattern,
    SourceText,
    PATINDEX(Pattern, SourceText) AS FoundPosition,
    CASE 
        WHEN PATINDEX(Pattern, SourceText) = ExpectedPosition THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM patindex_t1;
GO

CREATE VIEW patindex_v2 AS
SELECT 
    ID,
    Pattern,
    SourceText,
    PATINDEX(Pattern, SourceText) AS FoundPosition,
    CASE 
        WHEN PATINDEX(Pattern, SourceText) > 0 
        THEN SUBSTRING(SourceText, PATINDEX(Pattern, SourceText), 10)
        ELSE 'Not Found'
    END AS MatchedText
FROM patindex_t2;
GO

-- Test Views
SELECT * FROM patindex_v1 WHERE TestResult = 'Pass';
SELECT * FROM patindex_v2 WHERE FoundPosition > 0;
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 14. Create Functions
CREATE FUNCTION patindex_fn_findall
(
    @Pattern VARCHAR(100),
    @SourceText VARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    WITH Positions AS (
        SELECT 
            cast(1 as bigint) AS StartPos,
            PATINDEX(@Pattern, @SourceText) AS FoundPos
        
        UNION ALL
        
        SELECT 
            FoundPos + 1,
            PATINDEX(@Pattern, SUBSTRING(@SourceText, FoundPos + 1, LEN(@SourceText)))
            + FoundPos
        FROM Positions
        WHERE PATINDEX(@Pattern, SUBSTRING(@SourceText, FoundPos + 1, LEN(@SourceText))) > 0
    )
    SELECT FoundPos
    FROM Positions
    WHERE FoundPos > 0
);
GO

CREATE FUNCTION patindex_fn_countmatches
(
    @Pattern VARCHAR(100),
    @SourceText VARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT = 0;
    DECLARE @Position INT = 1;
    DECLARE @Found INT;

    WHILE 1 = 1
    BEGIN
        SET @Found = PATINDEX(@Pattern, SUBSTRING(@SourceText, @Position, LEN(@SourceText)));
        IF @Found = 0 BREAK;
        
        SET @Count = @Count + 1;
        SET @Position = @Position + @Found;
    END

    RETURN @Count;
END;
GO

-- Test Functions
SELECT * FROM patindex_fn_findall('%[0-9]%', 'Test1Test2Test3');
SELECT dbo.patindex_fn_countmatches('%[0-9]%', 'Test1Test2Test3');
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 15. Create Procedures
CREATE PROCEDURE patindex_sp_analyze
    @Pattern VARCHAR(100),
    @SourceText VARCHAR(MAX)
AS
BEGIN
    SELECT 
        @Pattern AS Pattern,
        @SourceText AS SourceText,
        PATINDEX(@Pattern, @SourceText) AS FirstPosition,
        dbo.patindex_fn_countmatches(@Pattern, @SourceText) AS TotalMatches,
        CASE 
            WHEN PATINDEX(@Pattern, @SourceText) > 0 THEN 'Found'
            ELSE 'Not Found'
        END AS Result;
END;
GO

CREATE PROCEDURE patindex_sp_validatepattern
    @Pattern VARCHAR(100),
    @SourceText VARCHAR(MAX)
AS
BEGIN
    IF @Pattern IS NULL OR @SourceText IS NULL
    BEGIN
        SELECT 'NULL values not allowed' AS Result;
        RETURN;
    END

    IF LEN(@Pattern) = 0
    BEGIN
        SELECT 'Empty pattern not allowed' AS Result;
        RETURN;
    END

    SELECT 
        CASE 
            WHEN PATINDEX(@Pattern, @SourceText) > 0 THEN 'Valid match found'
            ELSE 'No match found'
        END AS Result,
        PATINDEX(@Pattern, @SourceText) AS Position;
END;
GO

-- Test Procedures
EXEC patindex_sp_analyze '%[0-9]%', 'Test123Test';
EXEC patindex_sp_validatepattern '%test%', 'This is a test string';
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS AND CONSTRAINTS
-- =============================================

-- 16. Create Tables with Computed Columns
CREATE TABLE patindex_computed_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Pattern VARCHAR(100),
    SourceText VARCHAR(MAX),
    MatchPosition AS PATINDEX(Pattern, SourceText) PERSISTED,
    HasMatch AS CASE 
                WHEN PATINDEX(Pattern, SourceText) > 0 THEN 1 
                ELSE 0 
               END PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO patindex_computed_t1 (Pattern, SourceText) VALUES
('%[0-9]%', 'Test123Test'),
('%test%', 'This is a test'),
('%[A-Z]%', 'test');

SELECT * FROM patindex_computed_t1;
GO

-- 17. Create Tables with Constraints
CREATE TABLE patindex_constrained_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Pattern VARCHAR(100),
    SourceText VARCHAR(MAX),
    CONSTRAINT patindex_chk_pattern CHECK (LEN(Pattern) > 0),
    CONSTRAINT patindex_chk_match CHECK (PATINDEX(Pattern, SourceText) > 0)
);
GO

-- Test Constraints
BEGIN TRY
    INSERT INTO patindex_constrained_t1 (Pattern, SourceText)
    VALUES ('%test%', 'This is a test');
    
    -- This should fail
    INSERT INTO patindex_constrained_t1 (Pattern, SourceText)
    VALUES ('%xyz%', 'This is a test');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW patindex_v1;
DROP VIEW patindex_v2;
GO

-- Drop Functions
DROP FUNCTION patindex_fn_findall;
DROP FUNCTION patindex_fn_countmatches;
GO

-- Drop Procedures
DROP PROCEDURE patindex_sp_analyze;
DROP PROCEDURE patindex_sp_validatepattern;
GO

-- Drop Tables
DROP TABLE patindex_constrained_t1;
DROP TABLE patindex_computed_t1;
DROP TABLE patindex_datatype_t1;
DROP TABLE patindex_t3;
DROP TABLE patindex_t2;
DROP TABLE patindex_t1;
GO

-- Drop Types
DROP TYPE patindex_type_varchar;
DROP TYPE patindex_type_nvarchar;
DROP TYPE patindex_type_text;
GO
