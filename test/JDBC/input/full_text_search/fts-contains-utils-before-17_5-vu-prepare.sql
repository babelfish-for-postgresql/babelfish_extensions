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