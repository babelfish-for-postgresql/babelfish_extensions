-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

SELECT * FROM fts_rewrite_prepare_v1;
GO

EXEC fts_rewrite_prepare_p1;
GO

SELECT fts_rewrite_prepare_f1();
GO

SELECT * FROM replace_special_chars_fts_prepare_v1;
GO

EXEC replace_special_chars_fts_prepare_p1;
GO

SELECT replace_special_chars_fts_prepare_f1();
GO

select sys.replace_special_chars_fts('"one @ @ @ @ two"');
go

select sys.babelfish_fts_rewrite('"one @ @ @ @ two"');
go

select sys.replace_special_chars_fts('"one @ two"');
go

select sys.replace_special_chars_fts('"one   @ two    ^ three"');
go

select sys.replace_special_chars_fts('"one:"');
go

select sys.replace_special_chars_fts('Arts '' grand-opening in 1987');
go

select sys.babelfish_fts_rewrite('"one   @ two    ^ three"');
go

select sys.babelfish_fts_rewrite('"one @ two"');
go

select sys.babelfish_fts_rewrite(':one');
select sys.babelfish_fts_rewrite('one:');
select sys.babelfish_fts_rewrite('one:  ');
select sys.babelfish_fts_rewrite('  :one');
select sys.babelfish_fts_rewrite('"one    :"');
select sys.babelfish_fts_rewrite('"one    :  "');
select sys.babelfish_fts_rewrite('":    one"');
select sys.babelfish_fts_rewrite('"    :     one"');
select sys.babelfish_fts_rewrite('"much of the"');
go

select sys.replace_special_chars_fts('one`two');
go

-- Search for other languages
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column, 
    nchar_column), N'"服务器"')
GO

-- Search for English phrase
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"index search"')
GO

-- Search for other language with english
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"column with インデックス"')
GO

-- Search for french text with diatrics
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"French données"')
GO

-- Search for mixed language content
DECLARE @a NVARCHAR(100)
SET @a = '"testing AND N''システム 信息''"'
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), @a)
GO

-- Search for text with special symbols
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column), '"sp$/df*"')
GO

-- Search for multi case content
SELECT * FROM fts_table WHERE CONTAINS((
    text_column,
    char_column, 
    nchar_column), '"Search SERVER wITh"')
GO

-- 21. Search for emojis
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    nvarchar_column, 
    ntext_column), '"N''🔍'' OR N''📊''"')
GO

-- Search on Views
CREATE VIEW vw_JapaneseContent AS
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column, 
    nchar_column), N'"テスト"')
GO

CREATE VIEW vw_MultilingualContent AS
SELECT * FROM fts_table WHERE CONTAINS((
    varchar_column, 
    ntext_column), '""Eng*"" AND N''"requête""''')
GO

-- Create Stored Procedures
CREATE PROCEDURE sp_SearchLanguageContent
    @language NVARCHAR(50)
AS
BEGIN
    SELECT * FROM fts_table WHERE CONTAINS((
        varchar_column, 
        ntext_column), @language)
END
GO

CREATE PROCEDURE sp_SearchMultipleColumns
    @searchTerm NVARCHAR(100),
    @includeTextColumn BIT = 1,
    @includeNVarcharColumn BIT = 1
AS
BEGIN
    IF @includeTextColumn = 1 AND @includeNVarcharColumn = 1
        SELECT * FROM fts_table WHERE CONTAINS((
            text_column, 
            nvarchar_column), @searchTerm)
    ELSE IF @includeTextColumn = 1
        SELECT * FROM fts_table WHERE CONTAINS((
            text_column), @searchTerm)
    ELSE
        SELECT * FROM fts_table WHERE CONTAINS((
            nvarchar_column), @searchTerm)
END
GO

CREATE PROCEDURE sp_SearchMixedLanguages
    @language1 NVARCHAR(50),
    @language2 NVARCHAR(50)
AS
BEGIN
    SELECT * FROM fts_table WHERE CONTAINS((
        nvarchar_column, 
        ntext_column), @language1 + ' AND ' + @language2)
END
GO

-- Common Table Expressions (Wrapped in Procedures for Reuse)
CREATE PROCEDURE sp_MultiCTESearch
AS
BEGIN
    WITH JapaneseCTE AS (
        SELECT * FROM fts_table WHERE CONTAINS((
            nvarchar_column, 
            ntext_column), N'ευρετήριο')
    ),
    EnglishCTE AS (
        SELECT * FROM fts_table WHERE CONTAINS((
            text_column, 
            varchar_column), '"English"')
    )
    SELECT j.*, e.text_column as english_text
    FROM JapaneseCTE j
    FULL OUTER JOIN EnglishCTE e ON j.id = e.id
END
GO

-- Create Function for Reusable Search
CREATE FUNCTION fn_SearchContent
(
    @searchTerm NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM fts_table WHERE CONTAINS((
        text_column, 
        varchar_column, 
        nvarchar_column), @searchTerm)
)
GO

-- Execute Views
SELECT * FROM vw_JapaneseContent
GO

SELECT * FROM vw_MultilingualContent
GO

-- Execute Stored Procedures
EXEC sp_SearchLanguageContent @language = N'" 测试"'
GO

-- Execute CTE Procedures
EXEC sp_MultiCTESearch
GO

-- Complex Execution Examples
-- Combining Function with CTE
WITH FunctionResults AS (
    SELECT * FROM fts_table 
    WHERE CONTAINS((varchar_column), '"English"')
)
SELECT * FROM FunctionResults 
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO