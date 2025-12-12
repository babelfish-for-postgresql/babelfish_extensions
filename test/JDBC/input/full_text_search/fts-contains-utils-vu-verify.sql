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

-- 1. Search for Japanese content
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column, 
    nchar_column), N'"日本語"')
GO

-- 2. Search for English phrase with special characters
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"Special Ch@r∆cters"')
GO

-- 3. Search for French text with diacritics
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"Café très élégant"')
GO

-- 4. Search for Database related content
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"Database Management"')
GO

-- 5. Search for Chinese content
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), N'"中文"')
GO

-- 6. Search for Programming related content
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"Programming"')
GO

-- 7. Search for mixed language content
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"English" AND "日本語"')
GO

-- 8. Search for Welcome messages
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"Welcome"')
GO

-- 9. Search for text with special symbols
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column), '"§pëçï*"')
GO

-- 10. Search for Japanese anime related content
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), N'"アニメ*"')
GO

-- 11. Search for multiple language combinations
SELECT * FROM fts_table WHERE CONTAINS((
    varchar_column, 
    ntext_column), '"English" AND "Fran*"')
GO

-- 12. Search for fixed-length content
SELECT * FROM fts_table WHERE CONTAINS((
    char_column, 
    nchar_column), '"Fixed-length text"')
GO

-- 13. Search for mixed case specific content
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column), '"TeXt"')
GO

-- 14. Search for content with copyright symbol
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column), '"©"')
GO

-- 15. Search for multi-word phrases
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"Long text with múltiple läñguages"')
GO

-- 16. Search for specific numbered content
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    char_column, 
    varchar_column), '"Sample text #1"')
GO

-- 17. Search for unicode specific content
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column, 
    nchar_column), '"üñíçødé"')
GO

-- 18. Search for mixed language greetings
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"Hello" OR "こんにちは"')
GO

-- 19. Search for specific character combinations
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column, 
    ntext_column), '"Ch@r"')
GO

-- 20. Search for complex language patterns
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column), '"English-日本語" AND "中文-Français"')
GO

-- 21. Search for emojis
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    nvarchar_column, 
    ntext_column), N'🎈')
GO

-- Create Views
CREATE VIEW vw_JapaneseContent AS
SELECT * FROM fts_table WHERE CONTAINS((
    nvarchar_column, 
    ntext_column, 
    nchar_column), N'"日本語"')
GO

CREATE VIEW vw_MultilingualContent AS
SELECT * FROM fts_table WHERE CONTAINS((
    varchar_column, 
    ntext_column), '"English" AND "França*"')
GO

CREATE VIEW vw_SpecialCharContent AS
SELECT * FROM fts_table WHERE CONTAINS((
    text_column, 
    varchar_column), '"§pëçïål"')
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
CREATE PROCEDURE sp_WithCTESearch
AS
BEGIN
    WITH ContentCTE AS (
        SELECT * FROM fts_table WHERE CONTAINS((
            text_column, 
            varchar_column, 
            ntext_column), '"Database Management"')
    )
    SELECT * FROM ContentCTE
END
GO

CREATE PROCEDURE sp_MultiCTESearch
AS
BEGIN
    WITH JapaneseCTE AS (
        SELECT * FROM fts_table WHERE CONTAINS((
            nvarchar_column, 
            ntext_column), N'"日本語"')
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

SELECT * FROM vw_SpecialCharContent
GO

-- Execute Stored Procedures
EXEC sp_SearchLanguageContent @language = N'"日本語"'
GO

EXEC sp_SearchLanguageContent @language = '"English"'
GO

EXEC sp_SearchMultipleColumns 
    @searchTerm = '"Database"',
    @includeTextColumn = 1,
    @includeNVarcharColumn = 1
GO

EXEC sp_SearchMultipleColumns 
    @searchTerm = '"Programming"',
    @includeTextColumn = 1,
    @includeNVarcharColumn = 0
GO

EXEC sp_SearchMixedLanguages 
    @language1 = '"English"',
    @language2 = N'"日本語"'
GO

-- Execute CTE Procedures
EXEC sp_WithCTESearch
GO

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

-- Using View with Procedure
SELECT v.* 
FROM vw_JapaneseContent v
INNER JOIN fn_SearchContent('"Programming"') f 
ON v.id = f.id
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO