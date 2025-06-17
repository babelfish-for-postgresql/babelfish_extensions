-- Create UDTs
CREATE TYPE charindex_type_varchar FROM VARCHAR(100);
CREATE TYPE charindex_type_nvarchar FROM NVARCHAR(100);
CREATE TYPE charindex_type_binary FROM VARBINARY(100);
GO

-- Create base tables for string tests
CREATE TABLE charindex_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SearchPattern VARCHAR(50),
    SourceText VARCHAR(200),
    StartLocation INT,
    ExpectedPosition INT,
    Description VARCHAR(100)
);
GO

CREATE TABLE charindex_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SearchPattern NVARCHAR(50),
    SourceText NVARCHAR(200),
    StartLocation INT,
    ExpectedPosition INT,
    Description NVARCHAR(100)
);
GO

-- Create base tables for binary tests
CREATE TABLE charindex_binary_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryPattern VARBINARY(100),
    BinarySource VARBINARY(MAX),
    StartLocation INT,
    ExpectedPosition INT,
    Description VARCHAR(100)
);
GO

-- Insert test data for string tests
INSERT INTO charindex_t1 (SearchPattern, SourceText, StartLocation, ExpectedPosition, Description) VALUES
('test', 'This is a test string', 1, 11, 'Basic search'),
('TEST', 'This is a test string', 1, 11, 'Case-insensitive search'),
('is', 'This is a test string', 1, 3, 'Search at beginning'),
('string', 'This is a test string', 1, 16, 'Search at end'),
('x', 'This is a test string', 1, 0, 'Pattern not found'),
('is', 'This is a test is here', 5, 14, 'Search with start position'),
(' ', 'This is a test string', 1, 5, 'Search for space'),
('  ', 'This  is  a  test  string', 1, 5, 'Search multiple spaces'),
('', 'This is a test string', 1, 0, 'Empty search pattern'),
('test', '', 1, 0, 'Empty source string');
GO

INSERT INTO charindex_t2 (SearchPattern, SourceText, StartLocation, ExpectedPosition, Description) VALUES
(N'テスト', N'これはテストです', 1, 4, N'Basic Unicode search'),
(N'テスト', N'これはテストですテスト', 6, 11, N'Unicode search with start position'),
(N'Test', N'This is a Test string', 1, 11, N'Mixed case search'),
(N'は', N'これはテストです', 1, 3, N'Single Unicode character'),
(N'マ', N'これはテストです', 1, 0, N'Unicode character not found'),
(N'  ', N'これは  テストです', 1, 4, N'Unicode with spaces'),
(N'', N'これはテストです', 1, 0, N'Empty pattern with Unicode'),
(N'テスト', N'', 1, 0, N'Empty source with Unicode');
GO

-- Insert test data for binary tests
INSERT INTO charindex_binary_t1 (BinaryPattern, BinarySource, StartLocation, ExpectedPosition, Description) VALUES
(0x4142, 0x41424344, 1, 1, 'Simple binary pattern AB in ABCD'),
(0x43, 0x41424344, 1, 3, 'Single byte in sequence'),
(0x4344, 0x41424344, 1, 3, 'Pattern at end'),
(0x45, 0x41424344, 1, 0, 'Pattern not found'),
(NULL, 0x41424344, 1, NULL, 'NULL pattern'),
(0x41, NULL, 1, NULL, 'NULL source'),
(0x00, 0x41420043, 1, 3, 'Search for NULL byte'),
(0x4142, 0x414241424142, 2, 3, 'Multiple occurrences with start position');
GO

-- Create table for long string tests
CREATE TABLE charindex_large_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    LargeText VARCHAR(MAX),
    LargeNText NVARCHAR(MAX),
    LargeBinary VARBINARY(MAX)
);
GO

-- Populate large string test data
INSERT INTO charindex_large_t1 (LargeText, LargeNText, LargeBinary)
SELECT 
    REPLICATE('ABC', 10000),
    REPLICATE(N'あいう', 10000),
    CAST(REPLICATE('ABC', 10000) AS VARBINARY(MAX));
GO

-- =============================================
-- BASIC STRING PATTERN TESTS
-- =============================================

-- 1. Basic Pattern Search Tests
SELECT
    CHARINDEX('test', 'This is a test string') AS SimpleSearch,
    CHARINDEX('TEST', 'This is a test string') AS CaseInsensitiveSearch,
    CHARINDEX('xyz', 'This is a test string') AS PatternNotFound,
    CHARINDEX('', 'This is a test string') AS EmptyPattern,
    CHARINDEX('test', '') AS EmptySource;
GO

-- 2. Start Position Tests
SELECT
    CHARINDEX('is', 'This is a test is string', 1) AS FirstOccurrence,
    CHARINDEX('is', 'This is a test is string', 5) AS SecondOccurrence,
    CHARINDEX('is', 'This is a test is string', 15) AS SearchFromLater,
    CHARINDEX('is', 'This is a test is string', 50) AS StartBeyondLength;
GO

-- 3. Unicode String Tests
SELECT
    CHARINDEX(N'テスト', N'これはテストです') AS UnicodeSearch,
    CHARINDEX(N'テスト', N'これはテストですテスト', 6) AS UnicodeWithStart,
    CHARINDEX(N'TEST', N'This is a TEST string') AS MixedUnicodeAscii;
GO

-- 4. Special Characters Tests
SELECT
    CHARINDEX(' ', 'This is a test') AS SpaceSearch,
    CHARINDEX(CHAR(9), 'Tab' + CHAR(9) + 'character') AS TabSearch,
    CHARINDEX(CHAR(13) + CHAR(10), 'Line 1' + CHAR(13) + CHAR(10) + 'Line 2') AS NewlineSearch,
    CHARINDEX('[](){}', 'Special [](){} chars') AS SpecialCharsSearch;
GO

-- 5. NULL Handling Tests
SELECT
    CHARINDEX(NULL, 'Test String') AS NullPattern,
    CHARINDEX('test', NULL) AS NullSource,
    CHARINDEX('test', 'Test String', NULL) AS NullStartPos,
    CHARINDEX(NULL, NULL) AS BothNull;
GO

-- =============================================
-- BINARY AND VARBINARY PATTERN TESTS
-- =============================================

-- 6. Basic Binary Pattern Tests
SELECT 
    CHARINDEX(CAST(0x4142 AS VARBINARY), CAST(0x41424344 AS VARBINARY)) AS SimpleBinarySearch,
    CHARINDEX(0x43, 0x41424344) AS SingleByteSearch,
    CHARINDEX(CAST(0x4344 AS BINARY(2)), CAST(0x41424344 AS BINARY(4))) AS BinaryTypeSearch,
    CHARINDEX(0x45, 0x41424344) AS PatternNotFound;
GO

-- 7. Binary NULL and Empty Tests
SELECT
    CHARINDEX(CAST(NULL AS VARBINARY), 0x41424344) AS NullPattern,
    CHARINDEX(0x41, CAST(NULL AS VARBINARY)) AS NullSource,
    CHARINDEX(0x41, 0x) AS EmptySource,
    CHARINDEX(0x, 0x41424344) AS EmptyPattern;
GO

-- 8. Binary Pattern with Start Position
SELECT
    CHARINDEX(0x4142, 0x414241424142, 1) AS FirstOccurrence,
    CHARINDEX(0x4142, 0x414241424142, 3) AS SecondOccurrence,
    CHARINDEX(0x4142, 0x414241424142, 5) AS ThirdOccurrence;
GO

-- 9. Cross Type Binary Tests
CREATE TABLE charindex_binary_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryCol BINARY(10),
    VarbinaryCol VARBINARY(10),
    VarbinaryMaxCol VARBINARY(MAX)
);
GO

INSERT INTO charindex_binary_t2 (BinaryCol, VarbinaryCol, VarbinaryMaxCol) VALUES
(0x414243444546474849, 0x414243, 0x414243444546474849),
(0x414243000000000000, 0x4142, 0x41424344),
(0x414200000000000000, 0x41, 0x41);
GO

SELECT 
    CHARINDEX(0x4142, BinaryCol) AS BinarySearch,
    CHARINDEX(0x4142, VarbinaryCol) AS VarbinarySearch,
    CHARINDEX(0x4142, VarbinaryMaxCol) AS VarbinaryMaxSearch
FROM charindex_binary_t2;
GO

-- =============================================
-- ADVANCED PATTERN TESTS
-- =============================================

-- 10. Multiple Occurrence Pattern Tests
WITH TestStrings AS (
    SELECT 'test test test' AS SourceText, 'test' AS Pattern
    UNION ALL SELECT 'testtest', 'test'
    UNION ALL SELECT 'ttest test testt', 'test'
)
SELECT 
    SourceText,
    Pattern,
    CHARINDEX(Pattern, SourceText) AS FirstOccurrence,
    CHARINDEX(Pattern, SourceText, 
    CHARINDEX(Pattern, SourceText) + 1) AS SecondOccurrence
FROM TestStrings;
GO

-- 11. Nested CHARINDEX Tests
SELECT
    -- Find second occurrence using nested CHARINDEX
    CHARINDEX('test', 'test another test string',
        CHARINDEX('test', 'test another test string') + 1
    ) AS SecondOccurrence,
    
    -- Find pattern after another pattern
    CHARINDEX('World', 'Hello World',
        CHARINDEX('Hello', 'Hello World') + 1
    ) AS PatternAfterPattern;
GO

-- 12. Mixed Data Type Tests
SELECT
    -- String and binary combinations
    CHARINDEX(CAST('AB' AS VARBINARY), CAST('ABCD' AS VARBINARY)) AS StringAsBinary,
    CHARINDEX('ABC', CAST(CAST('ABCD' AS VARBINARY) AS VARCHAR(10))) AS BinaryAsString;
GO

-- =============================================
-- COLLATION TESTS
-- =============================================

-- 13. Case Sensitivity Tests
SELECT
    CHARINDEX('test' COLLATE SQL_Latin1_General_CP1_CS_AS, 
             'TEST string' COLLATE SQL_Latin1_General_CP1_CS_AS) AS CaseSensitive,
    CHARINDEX('test' COLLATE SQL_Latin1_General_CP1_CI_AS, 
             'TEST string' COLLATE SQL_Latin1_General_CP1_CI_AS) AS CaseInsensitive;
GO

-- 14. Different Collation Tests
SELECT
    CHARINDEX('hello' COLLATE Japanese_CI_AS,
             'Hello World' COLLATE Japanese_CI_AS) AS JapaneseCollation,
    CHARINDEX('hello' COLLATE Turkish_CI_AS,
             'Hello World' COLLATE Turkish_CI_AS) AS TurkishCollation;
GO

-- 15. Accent Sensitivity Tests
SELECT
    CHARINDEX('e' COLLATE Latin1_General_CI_AI, 
             'é' COLLATE Latin1_General_CI_AI) AS AccentInsensitive,
    CHARINDEX('e' COLLATE Latin1_General_CI_AS, 
             'é' COLLATE Latin1_General_CI_AS) AS AccentSensitive;
GO

-- 16. Mixed Character Set Tests
SELECT
    CHARINDEX(N'テスト' COLLATE Japanese_CI_AS,
             N'これはテストです' COLLATE Japanese_CI_AS) AS JapaneseText,
    CHARINDEX(N'test' COLLATE Japanese_CI_AS,
             N'TEST' COLLATE Japanese_CI_AS) AS LatinInJapanese;
GO

-- 17. Width Sensitivity Tests
SELECT
    CHARINDEX(N'ｱ' COLLATE Japanese_CI_AS, -- Half-width katakana
             N'ア' COLLATE Japanese_CI_AS) AS WidthSensitive -- Full-width katakana
GO

-- 18. Binary Collation Tests
SELECT
    CHARINDEX('test' COLLATE Latin1_General_BIN2,
             'TEST' COLLATE Latin1_General_BIN2) AS BinaryCollation2;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 19. Create Views
CREATE VIEW charindex_v1 AS
SELECT 
    t1.ID,
    t1.SearchPattern,
    t1.SourceText,
    CHARINDEX(t1.SearchPattern, t1.SourceText) AS FoundPosition,
    CASE 
        WHEN CHARINDEX(t1.SearchPattern, t1.SourceText) = t1.ExpectedPosition 
        THEN 'Pass' 
        ELSE 'Fail' 
    END AS TestResult
FROM charindex_t1 t1;
GO

CREATE VIEW charindex_v2 AS
WITH PatternLocations AS (
    SELECT 
        ID,
        SearchPattern,
        SourceText,
        StartLocation,
        CHARINDEX(SearchPattern, SourceText, StartLocation) AS FoundPosition
    FROM charindex_t2
)
SELECT 
    ID,
    SearchPattern,
    SourceText,
    FoundPosition,
    CASE
        WHEN FoundPosition > 0 THEN SUBSTRING(SourceText, FoundPosition, LEN(SearchPattern))
        ELSE 'Not Found'
    END AS MatchedText
FROM PatternLocations;
GO

CREATE VIEW charindex_v3 AS
SELECT 
    ID,
    BinaryPattern,
    BinarySource,
    CHARINDEX(BinaryPattern, BinarySource) AS FoundPosition,
    ExpectedPosition,
    CASE 
        WHEN CHARINDEX(BinaryPattern, BinarySource) = ExpectedPosition 
        THEN 'Pass' 
        ELSE 'Fail' 
    END AS TestResult
FROM charindex_binary_t1;
GO

-- Test Views
SELECT * FROM charindex_v1 WHERE TestResult = 'Pass';
SELECT * FROM charindex_v2 WHERE FoundPosition > 0;
SELECT * FROM charindex_v3;
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 20. Create Functions
CREATE FUNCTION charindex_fn_countoccurrences
(
    @Pattern VARCHAR(100),
    @Source VARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT = 0;
    DECLARE @Pos INT = 1;
    DECLARE @Found INT;

    WHILE 1=1
    BEGIN
        SET @Found = CHARINDEX(@Pattern, @Source, @Pos);
        IF @Found = 0 BREAK;
        
        SET @Count = @Count + 1;
        SET @Pos = @Found + 1;
    END

    RETURN @Count;
END;
GO

CREATE FUNCTION charindex_fn_getallpositions
(
    @Pattern NVARCHAR(100),
    @Source NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN (
    WITH Positions AS (
        SELECT 
            1 AS StartPos,
            CHARINDEX(@Pattern, @Source, 1) AS FoundPos
        
        UNION ALL
        
        SELECT 
            FoundPos + 1,
            CHARINDEX(@Pattern, @Source, FoundPos + 1)
        FROM Positions
        WHERE FoundPos > 0
    )
    SELECT FoundPos
    FROM Positions
    WHERE FoundPos > 0
);
GO

CREATE FUNCTION charindex_fn_findinbinary
(
    @Pattern VARBINARY(100),
    @Source VARBINARY(MAX),
    @StartPos INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        CHARINDEX(@Pattern, @Source, @StartPos) AS Position,
        CAST(@Pattern AS VARCHAR(100)) AS PatternAsString,
        CAST(@Source AS VARCHAR(100)) AS SourceAsString
);
GO

-- Test Functions
SELECT dbo.charindex_fn_countoccurrences('test', 'test another test final test');
SELECT * FROM dbo.charindex_fn_getallpositions('test', 'test another test final test');
SELECT * FROM dbo.charindex_fn_findinbinary(0x4142, 0x414241424142, 1);
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 21. Create Procedures
CREATE PROCEDURE charindex_sp_findpattern
    @Pattern NVARCHAR(100),
    @Source NVARCHAR(MAX),
    @CaseSensitive BIT = 0
AS
BEGIN
    IF @CaseSensitive = 1
    BEGIN
        SELECT 
            CHARINDEX(@Pattern COLLATE SQL_Latin1_General_CP1_CS_AS, 
                     @Source COLLATE SQL_Latin1_General_CP1_CS_AS) AS Position,
            'Case Sensitive' AS SearchType;
    END
    ELSE
    BEGIN
        SELECT 
            CHARINDEX(@Pattern, @Source) AS Position,
            'Case Insensitive' AS SearchType;
    END
END;
GO

CREATE PROCEDURE charindex_sp_analyzepattern
    @Pattern NVARCHAR(100),
    @Source NVARCHAR(MAX)
AS
BEGIN
    SELECT 
        CHARINDEX(@Pattern, @Source) AS FirstPosition,
        dbo.charindex_fn_countoccurrences(@Pattern, @Source) AS TotalOccurrences,
        CASE 
            WHEN CHARINDEX(@Pattern, @Source) > 0 
            THEN 'Found' 
            ELSE 'Not Found' 
        END AS SearchResult;
END;
GO

-- Test Procedures
EXEC charindex_sp_findpattern 'TEST', 'This is a test string', 0;
EXEC charindex_sp_findpattern 'TEST', 'This is a test string', 1;
EXEC charindex_sp_analyzepattern 'test', 'test another test string';
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS
-- =============================================

-- 22. Create Tables with Computed Columns
CREATE TABLE charindex_computed_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SearchPattern VARCHAR(100),
    SourceText VARCHAR(MAX),
    FirstPosition AS CHARINDEX(SearchPattern, SourceText),
    HasPattern AS CASE 
                    WHEN CHARINDEX(SearchPattern, SourceText) > 0 
                    THEN 1 
                    ELSE 0 
                 END,
    PatternCount AS dbo.charindex_fn_countoccurrences(SearchPattern, SourceText)
);
GO

CREATE TABLE charindex_computed_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryPattern VARBINARY(100),
    BinarySource VARBINARY(MAX),
    FirstPosition AS CHARINDEX(BinaryPattern, BinarySource),
    HasPattern AS CASE 
                    WHEN CHARINDEX(BinaryPattern, BinarySource) > 0 
                    THEN 1 
                    ELSE 0 
                 END
);
GO

-- Test Computed Columns
INSERT INTO charindex_computed_t1 (SearchPattern, SourceText) VALUES
('test', 'test another test string'),
('xyz', 'test string'),
('', 'empty pattern test');

INSERT INTO charindex_computed_t2 (BinaryPattern, BinarySource) VALUES
(0x4142, 0x414241424142),
(0x4344, 0x414241424142);

SELECT * FROM charindex_computed_t1;
SELECT * FROM charindex_computed_t2;
GO

-- =============================================
-- DEPENDENT OBJECTS - CONSTRAINTS
-- =============================================

-- 23. Create Tables with Constraints
CREATE TABLE charindex_constrained_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SearchPattern VARCHAR(100),
    SourceText VARCHAR(MAX),
    CONSTRAINT charindex_chk_pattern CHECK (LEN(SearchPattern) > 0),
    CONSTRAINT charindex_chk_exists CHECK (CHARINDEX(SearchPattern, SourceText) > 0)
);
GO

CREATE TABLE charindex_constrained_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryPattern VARBINARY(100),
    BinarySource VARBINARY(MAX),
    CONSTRAINT charindex_chk_binpattern CHECK (DATALENGTH(BinaryPattern) > 0),
    CONSTRAINT charindex_chk_binexists CHECK (CHARINDEX(BinaryPattern, BinarySource) > 0)
);
GO

-- Test Constraints
BEGIN TRY
    INSERT INTO charindex_constrained_t1 (SearchPattern, SourceText) 
    VALUES ('test', 'test string');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    INSERT INTO charindex_constrained_t2 (BinaryPattern, BinarySource)
    VALUES (0x4142, 0x414241424142);
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

DROP VIEW charindex_v1;
DROP VIEW charindex_v2;
DROP VIEW charindex_v3;
GO

DROP TABLE charindex_constrained_t2;
DROP TABLE charindex_constrained_t1;
DROP TABLE charindex_computed_t2;
GO

DROP TABLE charindex_computed_t1;
GO

DROP FUNCTION charindex_fn_countoccurrences;
DROP FUNCTION charindex_fn_getallpositions;
DROP FUNCTION charindex_fn_findinbinary;
GO

DROP PROCEDURE charindex_sp_findpattern;
DROP PROCEDURE charindex_sp_analyzepattern;
GO

DROP TABLE charindex_binary_t2;
DROP TABLE charindex_binary_t1;
DROP TABLE charindex_large_t1;
DROP TABLE charindex_t2;
DROP TABLE charindex_t1;
GO

DROP TYPE charindex_type_varchar;
DROP TYPE charindex_type_nvarchar;
DROP TYPE charindex_type_binary;
GO
