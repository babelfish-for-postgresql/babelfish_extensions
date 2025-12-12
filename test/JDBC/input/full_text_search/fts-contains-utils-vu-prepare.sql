-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- sys.babelfish_fts_rewrite()
CREATE VIEW fts_rewrite_prepare_v1 AS (SELECT sys.babelfish_fts_rewrite('"one two three"'));
GO

CREATE PROCEDURE fts_rewrite_prepare_p1 AS (SELECT sys.babelfish_fts_rewrite('one'));
GO

CREATE FUNCTION fts_rewrite_prepare_f1()
RETURNS sys.SYSNAME AS
        BEGIN
                RETURN (SELECT sys.babelfish_fts_rewrite('"one : two"'))
        END
GO

-- sys.replace_special_chars_fts()
CREATE VIEW replace_special_chars_fts_prepare_v1 AS (SELECT sys.replace_special_chars_fts('"one`two"'));
GO

CREATE PROCEDURE replace_special_chars_fts_prepare_p1 AS (SELECT sys.replace_special_chars_fts(':one'));
GO

CREATE FUNCTION replace_special_chars_fts_prepare_f1()
RETURNS sys.SYSNAME AS
        BEGIN
                RETURN (SELECT sys.replace_special_chars_fts('"one : two"'))
        END
GO

-- Create table
CREATE TABLE fts_table
(
        id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
        text_column TEXT,
        char_column CHAR(50),
        nvarchar_column NVARCHAR(150),
        varchar_column VARCHAR(100),
        ntext_column NTEXT,
        nchar_column NCHAR(75)
)
GO

DECLARE @i INT = 1
DECLARE @japanese_texts TABLE (id INT IDENTITY(1,1), text NVARCHAR(100))
DECLARE @english_phrases TABLE (id INT IDENTITY(1,1), text NVARCHAR(100))
-- Populate sample phrases
INSERT INTO @japanese_texts (text)
VALUES 
        (N'私は日本語を話します'),
        (N'こんにちは世界'),
        (N'東京は大都市です'),
        (N'寿司が好きです'),
        (N'漢字は面白いです')
INSERT INTO @english_phrases (text)
VALUES 
        ('Hello World!'),
        ('Welcome to Programming'),
        ('Database Management'),
        ('Mixed Case TeXt'),
        ('Special Ch@r∆cters')
WHILE @i <= 1000
BEGIN
        INSERT INTO fts_table (
                text_column,
                char_column,
                nvarchar_column,
                varchar_column,
                ntext_column,
                nchar_column
        )
        VALUES (
                -- text_column: Mix of English with special characters
                'Sample text #' + CAST(@i AS TEXT) + ' with §pëçïål characters ' + CHAR(169) + ' ' + CHAR(174),
                
                -- char_column: Basic English with numbers
                'Fixed-length text ' + CAST(@i AS CHAR(10)) + ' #' + CAST(@i % 10 AS VARCHAR),
                
                -- nvarchar_column: Mix of English and emojis
                'Variable text ' + CAST(@i AS NVARCHAR(10)) + N' 🌟 🎈 ' + 
                CASE @i % 3 
                WHEN 0 THEN N'😊'
                WHEN 1 THEN N'🎉'
                ELSE N'💫'
                END,
                
                -- varchar_column: Mix of languages
                N'English-日本語-' + CAST(@i AS NVARCHAR(10)) + N'-中文-Français-' +
                (SELECT text FROM @japanese_texts WHERE id = (@i % 5) + 1),
                
                -- ntext_column: Longer mixed content
                N'Long text with múltiple läñguages: ' + 
                CAST(@i AS NVARCHAR(10)) + N' - アニメが好きです - ' +
                (SELECT text FROM @english_phrases WHERE id = (@i % 5) + 1) +
                N' - 这是中文 - Café très élégant',
                
                -- nchar_column: Diacritics and special characters
                N'Fîxed léngth téxt with diàcrítics ' + CAST(@i AS NVARCHAR(10)) + N' üñíçødé'
        )
        SET @i = @i + 1
END
GO

-- Test cases for fts_table
CREATE UNIQUE INDEX ucid ON fts_table(id)
GO

CREATE FULLTEXT INDEX ON fts_table(
        text_column,
        char_column,
        varchar_column,
        nvarchar_column,
        ntext_column,
        nchar_column) KEY INDEX ucid
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO