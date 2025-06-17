-- Create UDTs
CREATE TYPE quotename_type_varchar FROM VARCHAR(256);
CREATE TYPE quotename_type_nvarchar FROM NVARCHAR(256);
GO

-- Create base tables
CREATE TABLE quotename_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputString VARCHAR(128),
    QuoteChar CHAR(1),
    ExpectedOutput VARCHAR(256),
    Description VARCHAR(100)
);
GO

CREATE TABLE quotename_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputString NVARCHAR(128),
    QuoteChar NCHAR(1),
    ExpectedOutput NVARCHAR(256),
    Description NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO quotename_t1 (InputString, QuoteChar, ExpectedOutput, Description) VALUES
('SimpleString', '[', '[SimpleString]', 'Basic string without special chars'),
('Table.Name', '[', '[Table.Name]', 'String with period'),
('Column[Name]', '[', '[Column[Name]]', 'String with brackets'),
('Schema.Table.Column', '[', '[Schema.Table.Column]', 'Multiple periods'),
('[Bracketed]', '[', '[[Bracketed]]', 'Already bracketed string'),
('', '[', '[]', 'Empty string'),
('Special@#$%', '[', '[Special@#$%]', 'Special characters'),
('Quote''String', '[', '[Quote''String]', 'String with single quote'),
('Double""Quote', '[', '[Double""Quote]', 'String with double quotes'),
('Space String', '[', '[Space String]', 'String with spaces');
GO

INSERT INTO quotename_t2 (InputString, QuoteChar, ExpectedOutput, Description) VALUES
(N'UnicodeString', N'[', N'[UnicodeString]', N'Basic Unicode string'),
(N'テーブル', N'[', N'[テーブル]', N'Japanese characters'),
(N'表名', N'[', N'[表名]', N'Chinese characters'),
(N'테이블', N'[', N'[테이블]', N'Korean characters'),
(N'таблица', N'[', N'[таблица]', N'Cyrillic characters'),
(N'Schema.テーブル', N'[', N'[Schema.テーブル]', N'Mixed ASCII and Unicode'),
(N'[テーブル]', N'[', N'[[テーブル]]', N'Already bracketed Unicode'),
(N'表[名]', N'[', N'[表[名]]', N'Unicode with brackets'),
(N'Schema.表.名', N'[', N'[Schema.表.名]', N'Unicode with periods'),
(N'テーブル@#$%', N'[', N'[テーブル@#$%]', N'Unicode with special chars');
GO

-- =============================================
-- BASIC FUNCTIONAL TESTS
-- =============================================

-- 1. Basic Quotename Tests
SELECT 
    QUOTENAME('SimpleString') AS DefaultBrackets,
    QUOTENAME('SimpleString', '[') AS SquareBrackets,
    QUOTENAME('SimpleString', '(') AS Parentheses,
    QUOTENAME('SimpleString', '''') AS SingleQuotes,
    QUOTENAME('SimpleString', '"') AS DoubleQuotes,
    QUOTENAME('SimpleString', '<') AS AngleBrackets;
GO

-- 2. Special Character Tests
SELECT 
    QUOTENAME('Table.Name') AS WithPeriod,
    QUOTENAME('Column[Name]') AS WithBrackets,
    QUOTENAME('[BracketedName]') AS AlreadyBracketed,
    QUOTENAME('Name@#$%^') AS WithSpecialChars,
    QUOTENAME('Name''WithQuote') AS WithSingleQuote,
    QUOTENAME('Name"WithQuote') AS WithDoubleQuote;
GO

-- 3. Unicode String Tests
SELECT 
    QUOTENAME(N'テーブル') AS Japanese,
    QUOTENAME(N'表名') AS Chinese,
    QUOTENAME(N'테이블') AS Korean,
    QUOTENAME(N'таблица') AS Russian,
    QUOTENAME(N'Schema.テーブル') AS MixedUnicode;
GO

-- 4. NULL and Empty String Tests
SELECT 
    QUOTENAME(NULL) AS NullString,
    QUOTENAME('') AS EmptyString,
    QUOTENAME(NULL, '[') AS NullWithBrackets,
    QUOTENAME('', '"') AS EmptyWithQuotes;
GO

-- 5. Different Quote Character Tests
SELECT 
    QUOTENAME('TestString', '[') AS SquareBracket,
    QUOTENAME('TestString', '(') AS Parenthesis,
    QUOTENAME('TestString', '''') AS SingleQuote,
    QUOTENAME('TestString', '"') AS DoubleQuote,
    QUOTENAME('TestString', '<') AS AngleBracket;
GO

-- 6. Nested Quotes Tests
SELECT 
    QUOTENAME('Outer[Inner]', '[') AS NestedBrackets,
    QUOTENAME('Outer(Inner)', '(') AS NestedParentheses,
    QUOTENAME('Outer"Inner"', '"') AS NestedDoubleQuotes,
    QUOTENAME('Outer''Inner''', '''') AS NestedSingleQuotes,
    QUOTENAME('Outer<Inner>', '<') AS NestedAngleBrackets;
GO

-- 7. Multiple Special Characters Tests
SELECT 
    QUOTENAME('Schema.Table[Name]') AS PeriodAndBrackets,
    QUOTENAME('[Schema].[Table]') AS MultipleBrackets,
    QUOTENAME('First.Second.Third') AS MultiplePeriods,
    QUOTENAME('Mix[]()"''<>') AS MixedQuotes;
GO

-- 8. Maximum Length Tests
DECLARE @MaxString VARCHAR(128) = REPLICATE('X', 128);
SELECT 
    LEN(QUOTENAME(@MaxString)) AS QuotedMaxLength,
    LEN(@MaxString) AS OriginalMaxLength;
GO

-- 9. Invalid Quote Character Tests
BEGIN TRY
    SELECT QUOTENAME('Test', 'X');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 10. Mixed Data Type Tests
SELECT 
    QUOTENAME(CAST(123 AS VARCHAR)) AS QuotedNumber,
    QUOTENAME(CAST(cast('2025-04-24 04:48:51.317' as sys.datetime) AS VARCHAR)) AS QuotedDate,
    QUOTENAME(CAST(1.23 AS VARCHAR)) AS QuotedDecimal,
    QUOTENAME(CAST(NULL AS VARCHAR)) AS QuotedNull;
GO

-- =============================================
-- ADVANCED TESTS
-- =============================================

-- 11. Database Object Name Tests
CREATE TABLE quotename_t3 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName VARCHAR(128),
    TableName VARCHAR(128),
    ColumnName VARCHAR(128)
);
GO

INSERT INTO quotename_t3 VALUES
('dbo', 'Table1', 'Column1'),
('test.schema', 'Test.Table', 'Test.Column'),
('schema[test]', 'table[test]', 'column[test]'),
('schema.test', 'table.test', 'column.test');
GO

SELECT 
    QUOTENAME(SchemaName) AS QuotedSchema,
    QUOTENAME(TableName) AS QuotedTable,
    QUOTENAME(ColumnName) AS QuotedColumn,
    QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) AS FullyQuotedName
FROM quotename_t3;
GO

-- 12. Different Collation Tests
SELECT 
    QUOTENAME('TestString' COLLATE SQL_Latin1_General_CP1_CS_AS) AS CaseSensitive,
    QUOTENAME('TestString' COLLATE SQL_Latin1_General_CP1_CI_AS) AS CaseInsensitive,
    QUOTENAME(N'テスト' COLLATE Japanese_CI_AS) AS JapaneseCollation;
GO

-- 13. Special Use Cases Tests
SELECT 
    -- Dynamic SQL safety
    'SELECT * FROM ' + QUOTENAME('Table.Name') AS SafeTableQuery,
    'SELECT ' + QUOTENAME('Column.Name') + ' FROM Table' AS SafeColumnQuery,
    -- Object concatenation
    QUOTENAME('Schema') + '.' + QUOTENAME('Table') + '.' + QUOTENAME('Column') AS FullyQualifiedName,
    -- Mixed quotes
    QUOTENAME(QUOTENAME('Inner', '"'), '[') AS NestedDifferentQuotes;
GO

-- =============================================
-- DEPENDENT OBJECTS - VIEWS
-- =============================================

-- 14. Create Views
CREATE VIEW quotename_v1 AS
SELECT 
    ID,
    InputString,
    QuoteChar,
    QUOTENAME(InputString, QuoteChar) AS QuotedResult,
    ExpectedOutput,
    CASE 
        WHEN QUOTENAME(InputString, QuoteChar) = ExpectedOutput THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM quotename_t1;
GO

CREATE VIEW quotename_v2 AS
SELECT 
    ID,
    InputString,
    QuoteChar,
    QUOTENAME(InputString, QuoteChar) AS QuotedResult,
    ExpectedOutput,
    CASE 
        WHEN QUOTENAME(InputString, QuoteChar) = ExpectedOutput THEN 'Pass'
        ELSE 'Fail'
    END AS TestResult
FROM quotename_t2;
GO

-- Test Views
SELECT * FROM quotename_v1 WHERE TestResult = 'Pass';
SELECT * FROM quotename_v2 WHERE TestResult = 'Pass';
GO

-- =============================================
-- DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- 15. Create Functions
CREATE FUNCTION quotename_fn_buildqualifiedname
(
    @Schema VARCHAR(128),
    @Table VARCHAR(128),
    @Column VARCHAR(128) = NULL
)
RETURNS VARCHAR(500)
AS
BEGIN
    DECLARE @Result VARCHAR(500);
    
    SET @Result = QUOTENAME(@Schema) + '.' + QUOTENAME(@Table);
    IF @Column IS NOT NULL
        SET @Result = @Result + '.' + QUOTENAME(@Column);
        
    RETURN @Result;
END;
GO

CREATE FUNCTION quotename_fn_validatequotename
(
    @InputString VARCHAR(128),
    @QuoteChar CHAR(1)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @InputString AS OriginalString,
        QUOTENAME(@InputString, @QuoteChar) AS QuotedString,
        CASE 
            WHEN LEFT(QUOTENAME(@InputString, @QuoteChar), 1) = @QuoteChar
                 AND RIGHT(QUOTENAME(@InputString, @QuoteChar), 1) = 
                    CASE @QuoteChar
                        WHEN '[' THEN ']'
                        WHEN '(' THEN ')'
                        WHEN '<' THEN '>'
                        ELSE @QuoteChar
                    END
            THEN 'Valid'
            ELSE 'Invalid'
        END AS ValidationResult
);
GO

-- Test Functions
SELECT dbo.quotename_fn_buildqualifiedname('dbo', 'Table1', 'Column1');
SELECT * FROM dbo.quotename_fn_validatequotename('Test.String', '[');
GO

-- =============================================
-- DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- 16. Create Procedures
CREATE PROCEDURE quotename_sp_quoteidentifier
    @ObjectName VARCHAR(128),
    @QuoteChar CHAR(1) = '['
AS
BEGIN
    IF @ObjectName IS NULL
    BEGIN
        RAISERROR('Object name cannot be NULL', 16, 1);
        RETURN;
    END

    SELECT 
        @ObjectName AS OriginalName,
        QUOTENAME(@ObjectName, @QuoteChar) AS QuotedName,
        @QuoteChar AS QuoteCharacterUsed;
END;
GO

CREATE PROCEDURE quotename_sp_buildquotedpath
    @Schema VARCHAR(128),
    @Table VARCHAR(128),
    @Column VARCHAR(128) = NULL
AS
BEGIN
    DECLARE @QuotedPath VARCHAR(500);
    
    SET @QuotedPath = QUOTENAME(@Schema) + '.' + QUOTENAME(@Table);
    IF @Column IS NOT NULL
        SET @QuotedPath = @QuotedPath + '.' + QUOTENAME(@Column);
        
    SELECT @QuotedPath AS QuotedPath;
END;
GO

-- Test Procedures
EXEC quotename_sp_quoteidentifier 'Test.Table';
EXEC quotename_sp_buildquotedpath 'dbo', 'Table1', 'Column1';
GO

-- =============================================
-- DEPENDENT OBJECTS - COMPUTED COLUMNS
-- =============================================

-- 17. Create Table with Computed Columns
CREATE TABLE quotename_computed_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName VARCHAR(128),
    TableName VARCHAR(128),
    ColumnName VARCHAR(128),
    QuotedSchema AS QUOTENAME(SchemaName) PERSISTED,
    QuotedTable AS QUOTENAME(TableName) PERSISTED,
    QuotedColumn AS QUOTENAME(ColumnName) PERSISTED
);
GO

-- Test Computed Columns
INSERT INTO quotename_computed_t1 (SchemaName, TableName, ColumnName) VALUES
('dbo', 'Table1', 'Column1'),
('test.schema', 'test.table', 'test.column');

SELECT * FROM quotename_computed_t1;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW quotename_v1;
DROP VIEW quotename_v2;
GO

-- Drop Functions
DROP FUNCTION quotename_fn_buildqualifiedname;
DROP FUNCTION quotename_fn_validatequotename;
GO

-- Drop Procedures
DROP PROCEDURE quotename_sp_quoteidentifier;
DROP PROCEDURE quotename_sp_buildquotedpath;
GO

-- Drop Tables
DROP TABLE quotename_computed_t1;
DROP TABLE quotename_t3;
DROP TABLE quotename_t2;
DROP TABLE quotename_t1;
GO

-- Drop Types
DROP TYPE quotename_type_varchar;
DROP TYPE quotename_type_nvarchar;
GO
