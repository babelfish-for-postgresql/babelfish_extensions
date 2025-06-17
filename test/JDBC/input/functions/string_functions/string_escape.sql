-- Create User-Defined Types
CREATE TYPE JsonText FROM NVARCHAR(MAX);
GO
CREATE TYPE UrlText FROM VARCHAR(MAX);
GO

-- Create base test tables
CREATE TABLE string_escape_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PlainText NVARCHAR(1000),
    JsonText NVARCHAR(1000),
    UrlText VARCHAR(1000)
);
GO

CREATE TABLE string_escape_types_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(100),
    VarcharCol VARCHAR(100),
    NCharCol NCHAR(100),
    NVarcharCol NVARCHAR(100),
    TextCol TEXT,
    NTextCol NTEXT
);
GO

CREATE TABLE string_escape_udt_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    JsonContent JsonText,
    UrlContent UrlText
);
GO

-- Insert test data
INSERT INTO string_escape_t1 (PlainText, JsonText, UrlText) VALUES
(N'Regular text', N'Text with "quotes"', 'Text with spaces'),
(N'Line 1\nLine 2', N'{"key":"value"}', 'http://example.com'),
(N'Tab\tText', N'Back\\slash', 'special!@#$chars'),
(N'Unicode テスト', N'Unicode テスト in json', 'Unicode テスト in url'),
(N'Control chars:' + CHAR(13) + CHAR(10), N'With\r\nbreaks', 'Path/to/resource');
GO

INSERT INTO string_escape_types_t2 
    (CharCol, VarcharCol, NCharCol, NVarcharCol, TextCol, NTextCol)
VALUES
    ('Text"with"quotes', 'Back\slash', N'Line\nbreak', N'Tab\there', 'Special@#$', N'Unicode テスト'),
    ('Control' + CHAR(13), 'Space test', N'Quote"test', N'Slash/test', 'Hash#test', N'Mixed\n"test"');
GO

INSERT INTO string_escape_udt_t3 (JsonContent, UrlContent) VALUES
(N'{"test":"value"}', 'http://test.com'),
(N'Unicode テスト', 'Path with spaces'),
(N'Control\nchars', 'Special!@#$chars');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic JSON escaping tests
SELECT 
    STRING_ESCAPE(N'Simple "quoted" text', 'json') AS SimpleQuotes,
    STRING_ESCAPE(N'Back\\slash text', 'json') AS Backslash,
    STRING_ESCAPE(N'Line 1\nLine 2', 'json') AS LineBreak,
    STRING_ESCAPE(N'Tab\tText', 'json') AS TabChar;
GO

-- 2. Basic URL escaping tests
SELECT 
    STRING_ESCAPE('Simple space test', 'url') AS SpaceEscape,
    STRING_ESCAPE('Test!@#$%^&*()', 'url') AS SpecialChars,
    STRING_ESCAPE('Path/to/resource?param=value', 'url') AS UrlPath;
GO

-- 3. NULL and Empty String Tests
SELECT 
    STRING_ESCAPE(NULL, 'json') AS NullJson,
    STRING_ESCAPE(NULL, 'url') AS NullUrl,
    STRING_ESCAPE('', 'json') AS EmptyJson,
    STRING_ESCAPE('', 'url') AS EmptyUrl;
GO

-- 4. Unicode Character Tests
SELECT 
    STRING_ESCAPE(N'Unicode テスト 测试', 'json') AS UnicodeJson,
    STRING_ESCAPE(N'Unicode テスト 测试', 'url') AS UnicodeUrl,
    STRING_ESCAPE(N'Emoji 👍 test', 'json') AS EmojiJson,
    STRING_ESCAPE(N'Emoji 👍 test', 'url') AS EmojiUrl;
GO

-- 5. Control Characters Tests
DECLARE @ControlChars NVARCHAR(1000) = 
    'Form Feed' + CHAR(12) + 
    'Tab' + CHAR(9) + 
    'Carriage Return' + CHAR(13) + 
    'Line Feed' + CHAR(10) + 
    'Backspace' + CHAR(8);

SELECT 
    STRING_ESCAPE(@ControlChars, 'json') AS ControlCharsJson,
    STRING_ESCAPE(@ControlChars, 'url') AS ControlCharsUrl;
GO

-- 6. Test with all string types
SELECT 
    STRING_ESCAPE(CharCol, 'json') AS CharJson,
    STRING_ESCAPE(VarcharCol, 'json') AS VarcharJson,
    STRING_ESCAPE(NCharCol, 'json') AS NCharJson,
    STRING_ESCAPE(NVarcharCol, 'json') AS NVarcharJson,
    STRING_ESCAPE(TextCol, 'json') AS TextJson,
    STRING_ESCAPE(NTextCol, 'json') AS NTextJson
FROM string_escape_types_t2;
GO

SELECT 
    STRING_ESCAPE(CharCol, 'url') AS CharUrl,
    STRING_ESCAPE(VarcharCol, 'url') AS VarcharUrl,
    STRING_ESCAPE(NCharCol, 'url') AS NCharUrl,
    STRING_ESCAPE(NVarcharCol, 'url') AS NVarcharUrl,
    STRING_ESCAPE(TextCol, 'url') AS TextUrl,
    STRING_ESCAPE(NTextCol, 'url') AS NTextUrl
FROM string_escape_types_t2;
GO

-- 7. Special JSON Characters Tests
SELECT 
    STRING_ESCAPE(N'{"key":"value"}', 'json') AS JsonObject,
    STRING_ESCAPE(N'["item1","item2"]', 'json') AS JsonArray,
    STRING_ESCAPE(N'{"key":null}', 'json') AS JsonNull,
    STRING_ESCAPE(N'{"key":true}', 'json') AS JsonBoolean;
GO

-- 8. Special URL Characters Tests
SELECT 
    STRING_ESCAPE('http://user:pass@example.com:8080/path?param=value#fragment', 'url') AS CompleteUrl,
    STRING_ESCAPE('param=value&other=value2', 'url') AS QueryParams,
    STRING_ESCAPE('user@domain.com', 'url') AS EmailAddress,
    STRING_ESCAPE('C:/path/to/file.txt', 'url') AS FilePath;
GO

-- 9. Maximum Length Tests
DECLARE @LongText NVARCHAR(MAX) = REPLICATE(N'Long text with "quotes" and \backslashes\', 1000);
DECLARE @LongUrl VARCHAR(MAX) = REPLICATE('http://example.com/path with spaces/', 1000);

SELECT 
    LEN(STRING_ESCAPE(@LongText, 'json')) AS LongJsonLength,
    LEN(STRING_ESCAPE(@LongUrl, 'url')) AS LongUrlLength;
GO

-- 10. Combination with Other String Functions
SELECT 
    STRING_ESCAPE(UPPER('test"quote"'), 'json') AS UpperJson,
    STRING_ESCAPE(LOWER('TEST@EXAMPLE.COM'), 'url') AS LowerUrl,
    STRING_ESCAPE(SUBSTRING('test"quote"test', 1, 5), 'json') AS SubstringJson,
    STRING_ESCAPE(REPLACE('test space test', ' ', '_'), 'url') AS ReplaceUrl;
GO


-- =============================================
-- EDGE CASES AND ERROR HANDLING
-- =============================================

-- 11. Edge Cases with Special Patterns
SELECT 
    STRING_ESCAPE('\\\\', 'json') AS MultipleBackslashes,
    STRING_ESCAPE('""""', 'json') AS MultipleQuotes,
    STRING_ESCAPE('http://test.com/////test', 'url') AS MultipleSlashes,
    STRING_ESCAPE('?????param=value', 'url') AS MultipleQuestionMarks;
GO

-- 12. Mixed Control Characters and Special Characters
SELECT 
    STRING_ESCAPE('Test' + CHAR(13) + CHAR(10) + '"quote"' + CHAR(9) + '\slash', 'json') AS MixedSpecialJson,
    STRING_ESCAPE('Test' + CHAR(13) + CHAR(10) + '@#$%' + CHAR(9) + '&*()', 'url') AS MixedSpecialUrl;
GO

-- 13. Invalid Escape Type Tests
BEGIN TRY
    SELECT STRING_ESCAPE('test', 'invalid_type');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 14. Collation Tests
SELECT 
    STRING_ESCAPE(N'Test' COLLATE SQL_Latin1_General_CP1_CI_AS, 'json') AS DefaultCollation,
    STRING_ESCAPE(N'Test' COLLATE Japanese_CI_AS, 'json') AS JapaneseCollation;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 15. Create Views
CREATE VIEW string_escape_v1 AS
SELECT 
    ID,
    STRING_ESCAPE(JsonText, 'json') AS EscapedJson,
    STRING_ESCAPE(UrlText, 'url') AS EscapedUrl
FROM string_escape_t1;
GO

CREATE VIEW string_escape_v2 AS
SELECT 
    ID,
    STRING_ESCAPE(NVarcharCol, 'json') AS EscapedNVarchar,
    STRING_ESCAPE(VarcharCol, 'url') AS EscapedVarchar
FROM string_escape_types_t2;
GO

-- Test Views
SELECT * FROM string_escape_v1;
GO
SELECT * FROM string_escape_v2;
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 16. Create Scalar Function
CREATE FUNCTION string_escape_fn_JsonEscape
(
    @InputText NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN STRING_ESCAPE(@InputText, 'json');
END;
GO

CREATE FUNCTION string_escape_fn_UrlEscape
(
    @InputText VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    RETURN STRING_ESCAPE(@InputText, 'url');
END;
GO

-- 17. Create Table-Valued Function
CREATE FUNCTION string_escape_fn_GetEscaped()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ID,
        STRING_ESCAPE(JsonContent, 'json') AS EscapedJson,
        STRING_ESCAPE(UrlContent, 'url') AS EscapedUrl
    FROM string_escape_udt_t3
);
GO

-- Test Functions
SELECT dbo.string_escape_fn_JsonEscape(N'Test"quote"\newline');
GO
SELECT dbo.string_escape_fn_UrlEscape('Test space&special');
GO
SELECT * FROM dbo.string_escape_fn_GetEscaped();
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 18. Create Stored Procedures
CREATE PROCEDURE string_escape_sp_EscapeAndInsert
    @JsonText NVARCHAR(1000),
    @UrlText VARCHAR(1000)
AS
BEGIN
    INSERT INTO string_escape_t1 (PlainText, JsonText, UrlText)
    VALUES (
        @JsonText,
        STRING_ESCAPE(@JsonText, 'json'),
        STRING_ESCAPE(@UrlText, 'url')
    );
END;
GO

CREATE PROCEDURE string_escape_sp_GetEscaped
    @MinID INT
AS
BEGIN
    SELECT 
        ID,
        STRING_ESCAPE(JsonText, 'json') AS EscapedJson,
        STRING_ESCAPE(UrlText, 'url') AS EscapedUrl
    FROM string_escape_t1
    WHERE ID >= @MinID;
END;
GO

-- Test Procedures
EXEC string_escape_sp_EscapeAndInsert 
    @JsonText = N'New "quoted" text',
    @UrlText = 'New space & special';
GO

EXEC string_escape_sp_GetEscaped @MinID = 1;
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS
-- =============================================

-- 19. Create Table with Computed Columns
CREATE TABLE string_escape_computed_t4 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    OriginalJson NVARCHAR(1000),
    OriginalUrl VARCHAR(1000),
    EscapedJson AS (STRING_ESCAPE(OriginalJson, 'json')),
    EscapedUrl AS (STRING_ESCAPE(OriginalUrl, 'url'))
);
GO

INSERT INTO string_escape_computed_t4 (OriginalJson, OriginalUrl)
VALUES 
(N'Test"quote"\newline', 'Test space&special'),
(N'{"key":"value"}', 'http://test.com?param=value');
GO

SELECT * FROM string_escape_computed_t4;
GO

-- =============================================
-- DEPENDENT OBJECTS - CHECK CONSTRAINTS
-- =============================================

-- 20. Create Table with Check Constraints
CREATE TABLE string_escape_constrained_t5 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    JsonContent NVARCHAR(1000),
    UrlContent VARCHAR(1000),
    CONSTRAINT CHK_ValidJson CHECK (STRING_ESCAPE(JsonContent, 'json') IS NOT NULL),
    CONSTRAINT CHK_ValidUrl CHECK (STRING_ESCAPE(UrlContent, 'url') IS NOT NULL)
);
GO

-- Test Constraints
INSERT INTO string_escape_constrained_t5 (JsonContent, UrlContent)
VALUES (N'Valid"json"', 'Valid url');
GO

-- =============================================
-- DEPENDENT OBJECTS - TRIGGERS
-- =============================================

-- 21. Create Trigger
CREATE TRIGGER string_escape_tr_ValidateEscape
ON string_escape_t1
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted 
        WHERE STRING_ESCAPE(JsonText, 'json') IS NULL 
           OR STRING_ESCAPE(UrlText, 'url') IS NULL
    )
    BEGIN
        RAISERROR ('Invalid characters in text that cannot be escaped', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test Trigger
INSERT INTO string_escape_t1 (PlainText, JsonText, UrlText)
VALUES (N'Test trigger', N'Test"trigger"', 'Test trigger');
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Triggers
DROP TRIGGER string_escape_tr_ValidateEscape;
GO

-- Drop Views
DROP VIEW string_escape_v1;
DROP VIEW string_escape_v2;
GO

-- Drop Functions
DROP FUNCTION string_escape_fn_JsonEscape;
DROP FUNCTION string_escape_fn_UrlEscape;
DROP FUNCTION string_escape_fn_GetEscaped;
GO

-- Drop Procedures
DROP PROCEDURE string_escape_sp_EscapeAndInsert;
DROP PROCEDURE string_escape_sp_GetEscaped;
GO

-- Drop Tables
DROP TABLE string_escape_computed_t4;
DROP TABLE string_escape_constrained_t5;
DROP TABLE string_escape_udt_t3;
DROP TABLE string_escape_types_t2;
DROP TABLE string_escape_t1;
GO

-- Drop User-Defined Types
DROP TYPE JsonText;
DROP TYPE UrlText;
GO
