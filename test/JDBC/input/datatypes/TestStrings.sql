-- basic testing
-- default, random, max
CREATE TABLE String_Datatype (
    char_col10 CHAR(10),
    char_col CHAR,
    varchar_col50 VARCHAR(50),
    varchar_colmax VARCHAR(MAX),
    varchar_col VARCHAR,
    nchar_col20 NCHAR(20),
    nchar_col NCHAR,
    nvarchar_col100 NVARCHAR(100),
    nvarchar_colmax NVARCHAR(MAX),
    nvarchar_col NVARCHAR,
    text_col TEXT,
    ntext_col NTEXT
);
GO

-- Basic tests for String_Datatype
INSERT INTO String_Datatype VALUES (
    'ABCDEFGHIJ', 
    'X',
    'VARCHAR50',
    REPLICATE('B', 10000),
    'V',
    N'NCHAR20NCR20NCHAR20',
    N'Z', 
    N'NVARCHAR100',
    REPLICATE(N'E', 10000),
    N'N',
    'TEXT COLUMN',
    N'NTEXT COLUMN'
);
GO

-- Empty strings
INSERT INTO String_Datatype VALUES (
    '', '', '', '', '', N'', N'', N'', N'', N'', '', N''
);
GO

-- NULL values
INSERT INTO String_Datatype VALUES (
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
);
GO

-- Special characters and Unicode
INSERT INTO String_Datatype VALUES (
    '!@#$%^&*()', 
    '!',
    '!@#$%^&*()', 
    REPLICATE('!@#$%^&*()', 1000), 
    '!',
    N'你好こんにちは안녕하세요', 
    N'你',
    N'你好こんにちは안녕하세요', 
    REPLICATE(N'你好こんにちは안녕하세요', 1000), 
    N'你',
    '!@#$%^&*()', 
    N'你好こんにちは안녕하세요'
);
GO

-- Spaces and line breaks
INSERT INTO String_Datatype VALUES (
    '  Spaces  ', 
    ' ',
    '  Spaces  ', 
    'Line1
Line2', 
    ' ',
    N'  Spaces  ', 
    N' ',
    N'  Spaces  ', 
    N'Line1
Line2', 
    N' ',
    'Line1
Line2', 
    N'Line1
Line2'
);
GO

-- Emojis (for Unicode columns)
INSERT INTO String_Datatype (
    nchar_col20, nchar_col, nvarchar_col100, nvarchar_colmax, nvarchar_col, ntext_col
) VALUES (
    N'😊🌍🌈🎉', N'😊', N'😊🌍🌈🎉', REPLICATE(N'😊🌍🌈🎉', 1000), N'😊', N'😊🌍🌈🎉'
);
GO

-- Binary data (for non-Unicode columns)
INSERT INTO String_Datatype (
    varchar_col50, varchar_colmax, text_col
) VALUES (
    CONVERT(VARCHAR(50), CAST(0x48656C6C6F20576F726C64 AS VARBINARY(50))),
    CONVERT(VARCHAR(MAX), CAST(REPLICATE(0x48, 10000) AS VARBINARY(MAX))),
    CONVERT(TEXT, CAST(0x48656C6C6F20576F726C64 AS VARBINARY(MAX)))
);
GO

-- Padding behavior, truncation cases, and special characters
INSERT INTO String_Datatype VALUES
(
    'Pad      ', -- CHAR(10), padded to 10 characters
    'C',        -- CHAR, single character, automatically padded
    'This is a varchar test with more than 50 characters and should be truncated.', -- VARCHAR(50), truncated
    'This is a VARCHAR(MAX) column. It can handle much more data than a fixed-size varchar.', -- VARCHAR(MAX), no truncation
    'Varchar default', -- VARCHAR, no length specified, behaves as VARCHAR(MAX)
    N'Unicode padding  ', -- NCHAR(20), padded to 20 characters
    N'U',       -- NCHAR, single character, automatically padded
    N'This is a nvarchar test with slightly more than 100 characters to check truncation.', -- NVARCHAR(100), truncated
    N'This is an NVARCHAR(MAX) column. It can store much more data, even Unicode characters.', -- NVARCHAR(MAX), no truncation
    N'Unicode default', -- NVARCHAR, no length specified, behaves as NVARCHAR(MAX)
    'This is a TEXT field with special characters like \n and \0. It is used to store large amounts of text data.', -- TEXT, special characters
    N'This is a NTEXT field with special characters like \n and \u263A. It can store large Unicode text.' -- NTEXT, special characters with Unicode
);
GO

-- Insert data slightly longer than the typmod
INSERT INTO String_Datatype VALUES 
(
    'LongerText', -- CHAR(10), exceeds length, will be truncated
    'D',         -- CHAR, no issue
    'This string is definitely longer than 50 characters to check truncation in VARCHAR(50)', -- VARCHAR(50), truncated
    'Another long text for VARCHAR(MAX). No truncation here.', -- VARCHAR(MAX)
    'Overflow test for varchar', -- VARCHAR, no length specified
    N'Longer text for NCHAR', -- NCHAR(20), will be padded
    N'M',       -- NCHAR, no issue
    N'This NVARCHAR(100) string is slightly longer than 100 characters to trigger truncation.', -- NVARCHAR(100), truncated
    N'No truncation for NVARCHAR(MAX).', -- NVARCHAR(MAX)
    N'NVarchar column without a length limit', -- NVARCHAR
    'Text field with binary data \x0\x1\x2 and other special characters.', -- TEXT, special characters including binary data
    N'Unicode text in NTEXT field \u263A \n \0' -- NTEXT, special characters with Unicode
);
GO

-- Basic testing with limits
CREATE TABLE String_Datatype_Limits (
    char_col1 CHAR(1),
    char_col8000 CHAR(8000),
    varchar_col1 VARCHAR(1),
    varchar_col8000 VARCHAR(8000),
    nchar_col1 NCHAR(1),
    nchar_col4000 NCHAR(4000),
    nvarchar_col1 NVARCHAR(1),
    nvarchar_col4000 NVARCHAR(4000)
);
GO

-- Basic tests for String_Datatype_Limits
INSERT INTO String_Datatype_Limits VALUES (
    'Y',
    REPLICATE('A', 8000),
    'W',
    REPLICATE('C', 8000),
    N'1',
    REPLICATE(N'D', 4000),
    N'M',
    REPLICATE(N'F', 4000)
);
GO

-- Empty strings
INSERT INTO String_Datatype_Limits VALUES (
    '', '', '', '', N'', N'', N'', N''
);
GO

-- NULL values
INSERT INTO String_Datatype_Limits VALUES (
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
);
GO

-- Special characters and Unicode
INSERT INTO String_Datatype_Limits VALUES (
    '!',
    REPLICATE('!@#$%^&*()', 800),
    '!',
    REPLICATE('!@#$%^&*()', 800),
    N'你',
    REPLICATE(N'你好こんにちは', 800),
    N'你',
    REPLICATE(N'你好こんにちは', 800)
);
GO

-- Spaces and line breaks
INSERT INTO String_Datatype_Limits VALUES (
    ' ',
    REPLICATE(' ', 8000),
    ' ',
    REPLICATE(' ', 8000),
    N' ',
    REPLICATE(N' ', 4000),
    N' ',
    REPLICATE(N' ', 4000)
);
GO

-- Emojis (for Unicode columns)
INSERT INTO String_Datatype_Limits (
    nchar_col1, nchar_col4000, nvarchar_col1, nvarchar_col4000
) VALUES (
    N'😊', REPLICATE(N'😊🌍🌈🎉', 1000), N'😊', REPLICATE(N'😊🌍🌈🎉', 1000)
);
GO

-- Binary data (for non-Unicode columns)
INSERT INTO String_Datatype_Limits (
    varchar_col1, varchar_col8000
) VALUES (
    SUBSTRING(CONVERT(VARCHAR(8000), CAST(REPLICATE(0x48, 8000) AS VARBINARY(8000))), 1, 1),
    CONVERT(VARCHAR(8000), CAST(REPLICATE(0x48, 8000) AS VARBINARY(8000)))
);
GO

-- Padding behavior and truncation cases for limit columns
INSERT INTO String_Datatype_Limits VALUES
(
    'X',        -- CHAR(1), exactly one character
    REPLICATE('A', 8000), -- CHAR(8000), full-length string
    'Y',        -- VARCHAR(1), exact length
    REPLICATE('B', 8000), -- VARCHAR(8000), maximum length of varchar
    N'Z',       -- NCHAR(1), exactly one character
    REPLICATE(N'C', 4000), -- NCHAR(4000), full-length Unicode string
    N'W',       -- NVARCHAR(1), exactly one character
    REPLICATE(N'D', 4000) -- NVARCHAR(4000), maximum length of nvarchar
);
GO

-- Insert data slightly longer than the typmod
INSERT INTO String_Datatype_Limits VALUES 
(
    'TX',         -- CHAR(1)
    REPLICATE('X', 8001), -- CHAR(8000), exceeds length, will be truncated
    'PC',        -- VARCHAR(1)
    REPLICATE('Y', 8001), -- VARCHAR(8000), exceeds length, will be truncated
    N'QC',       -- NCHAR(1)
    REPLICATE(N'Z', 4001), -- NCHAR(4000), exceeds length, will be truncated
    N'RC',       -- NVARCHAR(1)
    REPLICATE(N'S', 4001) -- NVARCHAR(4000), exceeds length, will be truncated
);
GO

-- These should fail to create
create table String_Datatype_limit_exceeds1 (
    char_col CHAR(8001),
);
GO

create table String_Datatype_limit_exceeds2 (
    varchar_col VARCHAR(8001),
);
GO

create table String_Datatype_limit_exceeds3 (
    nchar_col NCHAR(4001),
);
GO

create table String_Datatype_limit_exceeds4 (
    nvarchar_col NVARCHAR(4001),
);
GO

SELECT
    char_col10,char_col,
    varchar_col50,varchar_col,
    nchar_col20,nchar_col,nvarchar_col,
    text_col,ntext_col
FROM String_Datatype;
GO

-- Testing datalength
SELECT 
 DATALENGTH(char_col10) AS char_col10_length,
 DATALENGTH(char_col) AS char_col_length,
 DATALENGTH(varchar_col50) AS varchar_col50_length,
 DATALENGTH(varchar_colmax) AS varchar_colmax_length,
 DATALENGTH(varchar_col) AS varchar_col_length,
 DATALENGTH(nchar_col20) AS nchar_col20_length,
 DATALENGTH(nchar_col) AS nchar_col_length,
 DATALENGTH(nvarchar_col100) AS nvarchar_col100_length,
 DATALENGTH(nvarchar_colmax) AS nvarchar_colmax_length,
 DATALENGTH(nvarchar_col) AS nvarchar_col_length,
 DATALENGTH(text_col) AS text_col_length,
 DATALENGTH(ntext_col) AS ntext_col_length
FROM String_Datatype
GO

-- displaying smaller values
SELECT
    char_col1,
    varchar_col1,
    nchar_col1,
    nvarchar_col1
FROM String_Datatype_Limits
GO

-- Testing datalength
SELECT
    DATALENGTH(char_col1) AS char_col1_length,
    DATALENGTH(char_col8000) AS char_col8000_length,
    DATALENGTH(varchar_col1) AS varchar_col1_length,
    DATALENGTH(varchar_col8000) AS varchar_col8000_length,
    DATALENGTH(nchar_col1) AS nchar_col1_length,
    DATALENGTH(nchar_col4000) AS nchar_col4000_length,
    DATALENGTH(nvarchar_col1) AS nvarchar_col1_length,
    DATALENGTH(nvarchar_col4000) AS nvarchar_col4000_length
FROM String_Datatype_Limits
GO

-- Test concatenation of CHAR types
SELECT
    char_col10 + char_col AS char_concat1
FROM String_Datatype;
GO

SELECT
    DATALENGTH(char_col1 + char_col8000) AS char_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of VARCHAR types
SELECT
    varchar_col50 + varchar_colmax AS varchar_concat1,
    varchar_col AS varchar_concat2
FROM String_Datatype;
GO

SELECT
    varchar_col1 + varchar_col8000 AS varchar_concat3
FROM String_Datatype_Limits;
GO


-- Test concatenation of NCHAR types
SELECT
    nchar_col20 + nchar_col AS nchar_concat1
FROM String_Datatype;
GO

SELECT
    DATALENGTH(nchar_col1 + nchar_col4000) AS nchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of NVARCHAR types
SELECT
    DATALENGTH(nvarchar_col100 + nvarchar_colmax) AS nvarchar_concat1,
    nvarchar_col AS nvarchar_concat2
FROM String_Datatype;
GO

SELECT
    DATALENGTH(nvarchar_col1 + nvarchar_col4000) AS nvarchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of CHAR and VARCHAR
SELECT
    char_col10 + varchar_col50 AS char_varchar_concat1,
    char_col + varchar_colmax AS char_varchar_concat2
FROM String_Datatype;
GO

SELECT
    DATALENGTH(char_col1 + varchar_col8000) AS char_varchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of NCHAR and NVARCHAR
SELECT
    nchar_col20 + nvarchar_col100 AS nchar_nvarchar_concat1,
    nchar_col + nvarchar_colmax AS nchar_nvarchar_concat2
FROM String_Datatype;
GO

SELECT
    DATALENGTH(nchar_col1 + nvarchar_col4000) AS nchar_nvarchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of CHAR and NCHAR
SELECT
    char_col10 + CAST(nchar_col20 AS VARCHAR(20)) AS char_nchar_concat1,
    char_col + CAST(nchar_col AS VARCHAR(1)) AS char_nchar_concat2
FROM String_Datatype;
GO

SELECT
    DATALENGTH(char_col1 + CAST(nchar_col4000 AS VARCHAR(4000))) AS char_nchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation of VARCHAR and NVARCHAR
SELECT
    DATALENGTH(varchar_col50 + CAST(nvarchar_col100 AS VARCHAR(100))) AS varchar_nvarchar_concat1,
    DATALENGTH(varchar_col + CAST(nvarchar_colmax AS VARCHAR(MAX))) AS varchar_nvarchar_concat2
FROM String_Datatype;
GO

SELECT
    DATALENGTH(varchar_col1 + CAST(nvarchar_col4000 AS VARCHAR(4000))) AS varchar_nvarchar_concat3
FROM String_Datatype_Limits;
GO

-- Test concatenation with TEXT and NTEXT
SELECT
    text_col + varchar_col50 AS text_varchar_concat,
    CAST(ntext_col AS NVARCHAR(MAX)) + nvarchar_col100 AS ntext_nvarchar_concat
FROM String_Datatype;
GO

-- Test concatenation involving NULL values
SELECT
    char_col10 + varchar_col50 AS ConcatenationWithNulls1,
    nchar_col20 + nvarchar_col100 AS ConcatenationWithNulls2,
    ISNULL(char_col10, '') + ISNULL(varchar_col50, '') AS null_handling1,
    COALESCE(nchar_col20, N'') + COALESCE(nvarchar_col100, N'') AS null_handling2
FROM String_Datatype
WHERE char_col10 IS NULL;
GO

-- Test concatenation and truncation of VARCHAR(50) and NVARCHAR(100)
SELECT
    char_col10 + varchar_col50 AS TruncationCheck,
    nchar_col20 + nvarchar_col100 AS TruncationCheckUnicode,
    LEFT(char_col10 + varchar_col50, 50) AS potential_truncation1,
    LEFT(nchar_col20 + nvarchar_col100, 100) AS potential_truncation2
FROM String_Datatype;
GO

-- Test concatenation with empty strings
SELECT
    char_col10 + '' AS empty_concat_char,
    varchar_col50 + '' AS empty_concat_varchar,
    nchar_col20 + N'' AS empty_concat_nchar,
    nvarchar_col100 + N'' AS empty_concat_nvarchar,
    char_col10 + ' ' + varchar_col50 AS char_varchar_concat,
    nchar_col20 + N' ' + nvarchar_col100 AS nchar_nvarchar_concat,
    char_col10 + ' ' + CAST(nchar_col20 AS VARCHAR(20)) AS char_nchar_cast_concat
FROM String_Datatype;
GO

-- Test concatenation across multiple columns
SELECT
    char_col10 + char_col + varchar_col50 AS MultipleConcatenation,
    nchar_col20 + nchar_col + nvarchar_col100 AS MultipleUnicodeConcatenation
FROM
     String_Datatype;
GO

-- Test concatenation with special characters
SELECT
    char_col10 + CHAR(9) + varchar_col50 AS concat_with_tab,
    DATALENGTH(nvarchar_colmax + NCHAR(10) + nvarchar_col) AS concat_with_newline
FROM String_Datatype;
GO

-- Test concatenation with numeric data
SELECT
    char_col10 + CAST(1234 AS VARCHAR(10)) AS char_with_number,
    nvarchar_col100 + CAST(5678 AS NVARCHAR(10)) AS nvarchar_with_number
FROM String_Datatype;
GO

-- Test concatenation with large strings
SELECT 
    LEFT(varchar_colmax + REPLICATE('A', 8000), 100) AS large_string_concat1,
    LEFT(nvarchar_colmax + REPLICATE(N'あ', 4000), 100) AS large_string_concat2
FROM String_Datatype;
GO

-- Concatenation with line breaks
DECLARE @line_break CHAR(2) = CHAR(13) + CHAR(10);
SELECT
    char_col10 + @line_break +
    varchar_col50 + @line_break +
    CAST(nchar_col20 AS VARCHAR(20)) AS multiline_concat
FROM String_Datatype
WHERE char_col10 IS NOT NULL;
GO

-- Concatenation with padding
SELECT
    char_col10 + ' ' + varchar_col50 AS char_varchar_concat,
    DATALENGTH(char_col10 + ' ' + varchar_col50) AS concat_length,
    DATALENGTH(char_col10) + DATALENGTH(' ') + DATALENGTH(varchar_col50) AS sum_of_lengths
FROM String_Datatype
WHERE char_col10 IS NOT NULL AND varchar_col50 IS NOT NULL;
GO

-- Concatenation with trimming
SELECT
    RTRIM(char_col10) + ' ' + LTRIM(varchar_col50) AS trimmed_concat
FROM String_Datatype
WHERE char_col10 IS NOT NULL AND varchar_col50 IS NOT NULL;
GO

-- Test concatenation of strings of varying lengths
SELECT 
    DATALENGTH(char_col + varchar_colmax) AS ShortAndLongConcatenation,
    DATALENGTH(nchar_col +  nvarchar_colmax) AS ShortAndLongUnicodeConcatenation,
    DATALENGTH(varchar_col + varchar_colmax) AS varying_length_varchar,
    DATALENGTH(nvarchar_col + nvarchar_colmax) AS varying_length_nvarchar
FROM
     String_Datatype;
GO

SELECT
    DATALENGTH(char_col1 + char_col8000) AS varying_length_char,
    DATALENGTH(varchar_col1 + varchar_col8000) AS varying_length_varchar,
    DATALENGTH(nchar_col1 + nchar_col4000) AS varying_length_nchar,
    DATALENGTH(nvarchar_col + nvarchar_col4000) AS varying_length_nvarchar
FROM String_Datatype_Limits;
GO

-- Test concatenation in UNION queries
SELECT
    char_col10 + varchar_col50 AS ConcatenatedResult
FROM
    String_Datatype
UNION
SELECT
    char_col1 + varchar_col8000 AS ConcatenatedResult
FROM
    String_Datatype_Limits
ORDER BY ConcatenatedResult
GO

-- Test concatenation with CTE queries
WITH ConcatenatedStrings AS (
    SELECT
        char_col10 + varchar_col50 AS CombinedString
    FROM
        String_Datatype
    UNION ALL
    SELECT
        char_col1 + varchar_col8000 AS CombinedString
    FROM
        String_Datatype_Limits
)
SELECT * FROM ConcatenatedStrings;
GO

-- Declare variables for testing
DECLARE @char_var CHAR(10) = 'CHAR';
DECLARE @varchar_var VARCHAR(50) = 'VARCHAR';
DECLARE @nchar_var NCHAR(10) = N'NCHAR';
DECLARE @nvarchar_var NVARCHAR(50) = N'NVARCHAR';
DECLARE @null_var VARCHAR(50) = NULL;
DECLARE @empty_var VARCHAR(50) = '';
DECLARE @int_var INT = 42;
DECLARE @date_var DATE = '2023-05-15';
DECLARE @float_var FLOAT = 3.14159;

-- CHAR tests
SELECT @char_var + ' test' AS char_concat;
SELECT @char_var + @null_var AS char_null_concat;
SELECT COALESCE(@char_var + @null_var, 'NULL result') AS char_null_coalesce;
SELECT @char_var + @empty_var AS char_empty_concat;
SELECT @char_var + CAST(@int_var AS CHAR(10)) AS char_int_concat;
SELECT @char_var + CAST(@date_var AS CHAR(10)) AS char_date_concat;
SELECT @char_var + CAST(@float_var AS CHAR(10)) AS char_float_concat;
SELECT @char_var + CAST(@nchar_var AS CHAR(10)) AS char_nchar_concat;
SELECT @char_var + REPLICATE('A', 8000) AS char_long_concat;

-- VARCHAR tests
SELECT @varchar_var + ' test' AS varchar_concat;
SELECT @varchar_var + @null_var AS varchar_null_concat;
SELECT COALESCE(@varchar_var + @null_var, 'NULL result') AS varchar_null_coalesce;
SELECT @varchar_var + @empty_var AS varchar_empty_concat;
SELECT @varchar_var + CAST(@int_var AS VARCHAR(10)) AS varchar_int_concat;
SELECT @varchar_var + CAST(@date_var AS VARCHAR(10)) AS varchar_date_concat;
SELECT @varchar_var + CAST(@float_var AS VARCHAR(10)) AS varchar_float_concat;
SELECT @varchar_var + CAST(@nchar_var AS VARCHAR(10)) AS varchar_nchar_concat;
SELECT @varchar_var + REPLICATE('A', 8000) AS varchar_long_concat;

-- NCHAR tests
SELECT @nchar_var + N' test' AS nchar_concat;
SELECT @nchar_var + CAST(@null_var AS NCHAR(10)) AS nchar_null_concat;
SELECT COALESCE(@nchar_var + CAST(@null_var AS NCHAR(10)), N'NULL result') AS nchar_null_coalesce;
SELECT @nchar_var + CAST(@empty_var AS NCHAR(10)) AS nchar_empty_concat;
SELECT @nchar_var + CAST(@int_var AS NCHAR(10)) AS nchar_int_concat;
SELECT @nchar_var + CAST(@date_var AS NCHAR(10)) AS nchar_date_concat;
SELECT @nchar_var + CAST(@float_var AS NCHAR(10)) AS nchar_float_concat;
SELECT @nchar_var + CAST(@char_var AS NCHAR(10)) AS nchar_char_concat;
SELECT @nchar_var + REPLICATE(N'A', 4000) AS nchar_long_concat;

-- NVARCHAR tests
SELECT @nvarchar_var + N' test' AS nvarchar_concat;
SELECT @nvarchar_var + CAST(@null_var AS NVARCHAR(50)) AS nvarchar_null_concat;
SELECT COALESCE(@nvarchar_var + CAST(@null_var AS NVARCHAR(50)), N'NULL result') AS nvarchar_null_coalesce;
SELECT @nvarchar_var + CAST(@empty_var AS NVARCHAR(50)) AS nvarchar_empty_concat;
SELECT @nvarchar_var + CAST(@int_var AS NVARCHAR(10)) AS nvarchar_int_concat;
SELECT @nvarchar_var + CAST(@date_var AS NVARCHAR(10)) AS nvarchar_date_concat;
SELECT @nvarchar_var + CAST(@float_var AS NVARCHAR(10)) AS nvarchar_float_concat;
SELECT @nvarchar_var + CAST(@char_var AS NVARCHAR(10)) AS nvarchar_char_concat;
SELECT @nvarchar_var + REPLICATE(N'A', 4000) AS nvarchar_long_concat;

-- Mixed data type concatenations
SELECT @char_var + CAST(@nvarchar_var AS VARCHAR(50)) + CAST(@null_var AS VARCHAR(MAX)) AS mixed_concat1;
SELECT @nchar_var + CAST(@varchar_var AS NVARCHAR(50)) + CAST(@null_var AS NVARCHAR(MAX)) AS mixed_concat2;
SELECT CAST(@null_var AS VARCHAR(MAX)) + CAST(@null_var AS VARCHAR(MAX)) + @char_var AS mixed_concat3;
SELECT CAST(@null_var AS NVARCHAR(MAX)) + CAST(@null_var AS NVARCHAR(MAX)) + @nchar_var AS mixed_concat4;
-- Concatenation exceeding maximum length
SELECT @char_var + REPLICATE('A', 8000) AS long_concat;
-- Concatenation with Unicode and non-Unicode
SELECT @char_var + @nchar_var AS mixed_unicode_concat;
-- Concatenation with empty string
SELECT @char_var + @empty_var + @varchar_var AS empty_concat;
GO

DROP TABLE String_Datatype
GO

DROP TABLE String_Datatype_Limits
GO


