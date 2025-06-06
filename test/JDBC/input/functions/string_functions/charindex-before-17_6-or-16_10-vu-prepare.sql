-- Create a schema for the test tables
CREATE SCHEMA charindex_tests;
GO

-- varchar
CREATE TABLE charindex_tests.TestChar (col1 varchar(50))
INSERT INTO charindex_tests.TestChar VALUES ('Hello World')
GO

-- nvarchar (Unicode)
CREATE TABLE charindex_tests.TestNChar (col1 nvarchar(50))
INSERT INTO charindex_tests.TestNChar VALUES (N'Hello World')
GO

-- char
CREATE TABLE charindex_tests.TestFixedChar (col1 char(20))
INSERT INTO charindex_tests.TestFixedChar VALUES ('Hello World')
GO

-- Nchar
CREATE TABLE charindex_tests.TestFixedNChar (col1 nchar(20))
INSERT INTO charindex_tests.TestFixedNChar VALUES (N'Hello World')
GO

/*
 * Chinese collation tests
 * Chinese_PRC_CI_AS, Chinese_PRC_CS_AS, 
 */
-- Create tables with diff chars type and different collations
CREATE TABLE charindex_tests.chinese_variants (
    id INT,
    char_col CHAR(100) COLLATE Chinese_PRC_CI_AS,         -- Fixed-length CHAR + CI_AS
    varchar_col VARCHAR(100) COLLATE Chinese_PRC_CS_AS,    -- Variable-length VARCHAR + CS_AS
    nchar_col NCHAR(100) COLLATE Chinese_PRC_CS_AS,       -- Unicode fixed-length + Chinese_PRC_CS_AS
    nvarchar_col NVARCHAR(100) COLLATE Chinese_PRC_CI_AI  -- Unicode variable-length + Chinese_PRC_CI_AI
);
-- Insert test data
INSERT INTO charindex_tests.chinese_variants VALUES
(1, '中国人', '中国人', N'中国人', N'中国人'),
(2, '测试ABC', '测试ABC', N'测试ABC', N'测试ABC'),
(3, '你好世界', '你好世界', N'你好世界', N'你好世界');
GO

-- Create table with different character types and Japanese collations
CREATE TABLE charindex_tests.japanese_variants (
    id INT,
    char_col CHAR(100) COLLATE Japanese_CI_AS,            
    varchar_col VARCHAR(100) COLLATE Japanese_CS_AS,       
    nchar_col NCHAR(100) COLLATE Japanese_CI_AI,           
    nvarchar_col NVARCHAR(100) COLLATE Japanese_CS_AS
);
-- Insert test data with different Japanese character types
INSERT INTO charindex_tests.japanese_variants VALUES
-- Hiragana
(1, 'こんにちは', 'こんにちは', N'こんにちは', N'こんにちは'),
-- Katakana
(2, 'テスト', 'テスト', N'テスト', N'テスト'),
-- Kanji
(3, '日本語', '日本語', N'日本語', N'日本語'),
-- Mixed characters
(4, 'テストABC123', 'テストABC123', N'テストABC123', N'テストABC123'),
-- Hiragana and Katakana mix
(5, 'こんにちはテスト', 'こんにちはテスト', N'こんにちはテスト', N'こんにちはテスト'),
-- Kanji and Kana mix
(6, '日本語でテスト', '日本語でテスト', N'日本語でテスト', N'日本語でテスト');
GO

CREATE TABLE charindex_tests.UnicodeTest (
    ID INT,
    Content_CI NVARCHAR(100) COLLATE Latin1_General_CI_AS,  -- Case Insensitive
    Content_CS NVARCHAR(100) COLLATE Latin1_General_CS_AS   -- Case Sensitive
);
INSERT INTO charindex_tests.UnicodeTest VALUES (1, 'Test', 'Test'), (2, 'test', 'test'), (3, 'TEST', 'TEST');
GO

------------------------------------- Test VAR[BINARY] arguments ----------------------------------------

-- Create test table
CREATE TABLE charindex_tests.BinaryTypes ( ID INT, FixedBinary BINARY(10), VarBinary VARBINARY(10));
INSERT INTO charindex_tests.BinaryTypes VALUES
(1, CAST('ABC' AS BINARY(10)), CAST('ABC' AS VARBINARY(10))),
(2, 0x414243, 0x414243);  -- 'ABC' in hex
GO

CREATE TABLE charindex_tests.NullTests ( FixedBinary BINARY(10), VarBinary VARBINARY(10));
INSERT INTO charindex_tests.NullTests VALUES
(NULL, NULL),
(0x, 0x),
(CAST('' AS BINARY(10)), CAST('' AS VARBINARY(10)));
GO

-- Create test table with multiple binary columns
CREATE TABLE charindex_tests.ComplexBinary (Fixed1 BINARY(20), Fixed2 BINARY(20), Var1 VARBINARY(20), Var2 VARBINARY(20))
-- Insert complex patterns
INSERT INTO charindex_tests.ComplexBinary VALUES(
 0x4142435C30204445465C30, -- 'ABC\0 DEF\0'
 0x4142434445465C305C305C30, -- 'ABCDEF\0\0\0'
 0x4142435C30204445465C30, -- 'ABC\0 DEF\0'
 0x414243444546        -- 'ABCDEF'
);
GO

CREATE TABLE charindex_tests.SpecialBinary ( BinaryData BINARY(50), VarbinaryData VARBINARY(MAX), Description VARCHAR(100));
-- Insert test data
INSERT INTO charindex_tests.SpecialBinary (BinaryData, VarbinaryData, Description)
VALUES 
    (CAST('Hello123' AS BINARY(50)), CAST('Hello123World' AS VARBINARY(MAX)), 'Basic test'),
    (0x48656C6C6F313233, 0x48656C6C6F313233576F726C64, 'Hex encoded Hello123World'),
    (CAST(REPLICATE('A', 50) AS BINARY(50)), CAST(REPLICATE('A', 1000) AS VARBINARY(MAX)), 'Repeated characters'),
    ( CAST('Test©®™' AS BINARY(50)), CAST('Special©Characters®™' AS VARBINARY(MAX)), 'Special characters' );
GO

CREATE TYPE charindex_tests.varbinary_udt FROM VARBINARY(MAX)
GO
CREATE TYPE charindex_tests.binary_udt FROM BINARY(20)
GO

------------------------------------------------ Test dependent objects ---------------------------------------------

-- Base table with NVARCHAR column and Japanese collation
CREATE TABLE charindex_tests.text_base (
    id INT PRIMARY KEY,
    content NVARCHAR(100) COLLATE Japanese_CI_AS
);
-- Insert test data
INSERT INTO charindex_tests.text_base VALUES
(1, N'こんにちは'),
(2, N'テストABC'),
(3, N'日本語テスト');
GO

-- Add computed column
ALTER TABLE charindex_tests.text_base ADD test_pos AS CHARINDEX(N'テスト', content);
GO

-- test view for varchar, varchar
CREATE VIEW charindex_tests.text_view AS
SELECT id, content,
    CHARINDEX(N'テスト', content) as pattern_pos
FROM charindex_tests.text_base;
GO

-- test view for varchar, anyelement 
CREATE VIEW charindex_tests.text_view1 AS
SELECT id, content,
    CHARINDEX(content, 0x6162) as pattern_pos
FROM charindex_tests.text_base;
GO

-- functions
CREATE FUNCTION charindex_tests.find_text(
    @search_pattern NVARCHAR(10)    -- Need @ for parameter in SQL Server
)
RETURNS TABLE                       -- SQL Server table-valued function syntax is different
AS
RETURN                             -- Use RETURN instead of RETURNS TABLE ... AS $$ BEGIN
    SELECT 
        t.id,
        CHARINDEX(@search_pattern, t.content) as found_position
    FROM charindex_tests.text_base t;
GO

-- Create trigger function
CREATE TRIGGER trg_validate_text
ON charindex_tests.text_base
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted 
        WHERE CHARINDEX(N'ABC', content) > 0
    )
    BEGIN
        THROW 50000, 'Pattern ABC not allowed', 1;
    END
    ELSE
    BEGIN
        -- For INSERT
        INSERT INTO charindex_tests.text_base(id, content)
        SELECT id, content FROM inserted;
        
        -- For UPDATE
        UPDATE t
        SET content = i.content
        FROM charindex_tests.text_base t
        INNER JOIN inserted i ON t.id = i.id;
    END
END
GO

------------- dependent object test on var[binary]

-- Binary base table 
CREATE TABLE charindex_tests.binary_base ( id INT, binary_data BINARY(4), varbinary_data VARBINARY(100) );
INSERT INTO charindex_tests.binary_base VALUES (1, 0x4865, 0x48656C6C6F)
GO

-- Binary search function
CREATE VIEW charindex_tests.find_binary AS
SELECT id, 
    CHARINDEX(binary_data, cast(0x31324865 as binary(8))) as binary_position
FROM charindex_tests.binary_base;
GO

CREATE VIEW charindex_tests.find_binary1 AS
SELECT id, 
    CHARINDEX(binary_data, 'abc') as binary_position
FROM charindex_tests.binary_base;
GO

-- Binary search function
CREATE VIEW charindex_tests.find_varbinary AS
SELECT id, 
    CHARINDEX(0x65, varbinary_data) as varbinary_position
FROM charindex_tests.binary_base;
GO

CREATE VIEW charindex_tests.find_varbinary1 AS
SELECT id, 
    CHARINDEX(0x65, 'abc') as varbinary_position
FROM charindex_tests.binary_base;
GO