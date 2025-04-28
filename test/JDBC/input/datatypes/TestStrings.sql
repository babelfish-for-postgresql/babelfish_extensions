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

-- =============================================
-- Misc tests for Table Valued Functions
-- =============================================

CREATE FUNCTION itvf_fn_1 (@InputChar VARCHAR(10))
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO

CREATE FUNCTION itvf_fn_2 (@InputChar NVARCHAR(10))
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO

CREATE FUNCTION itvf_fn_3 (@InputChar CHAR(10))
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO

CREATE FUNCTION itvf_fn_4 (@InputChar NCHAR(10))
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO

CREATE FUNCTION itvf_fn_5 (@InputChar TEXT)
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO

CREATE FUNCTION itvf_fn_6 (@InputChar NTEXT)
RETURNS TABLE
AS RETURN
(
    SELECT @InputChar AS InputChar
);
GO


DROP FUNCTION itvf_fn_1
DROP FUNCTION itvf_fn_2
DROP FUNCTION itvf_fn_5
DROP FUNCTION itvf_fn_6
GO

DROP FUNCTION itvf_fn_3
GO

DROP FUNCTION itvf_fn_4
GO


-- =============================================
-- Tests for Operators
-- =============================================

CREATE TABLE string_operators_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NCharCol NCHAR(10),
    NVarcharCol NVARCHAR(50),
    TextCol TEXT,
    NTextCol NTEXT
);
GO

CREATE TABLE string_operators_t2 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NCharCol NCHAR(10),
    NVarcharCol NVARCHAR(50),
    TextCol TEXT,
    NTextCol NTEXT
);
GO

-- Insert test data
INSERT INTO string_operators_t1 VALUES
('ABC', 'ABC String', N'ABC', N'ABC String', 'ABC Text', N'ABC Text'),
('DEF', 'DEF String', N'DEF', N'DEF String', 'DEF Text', N'DEF Text'),
('GHI', 'GHI String', N'GHI', N'GHI String', 'GHI Text', N'GHI Text'),
('abc', 'abc string', N'abc', N'abc string', 'abc text', N'abc text'),
('   ABC   ', ' ABC String ', N'   ABC   ', N' ABC String ', '   ABC   ', N'   ABC   '),
('123', '123 String', N'123', N'123 String', '123 Text', N'123 Text'),
('ABC-DEF', 'ABC-DEF Str', N'ABC-DEF', N'ABC-DEF Str', 'ABC-DEF', N'ABC-DEF'),
('Test!@#', 'Test!@#$%^', N'Test!@#', N'Test!@#$%^', 'Test!@#', N'Test!@#');
GO

INSERT INTO string_operators_t2 VALUES
('ABC', 'ABC String', N'ABC', N'ABC String', 'ABC Text', N'ABC Text'),
('XYZ', 'XYZ String', N'XYZ', N'XYZ String', 'XYZ Text', N'XYZ Text'),
('123', '123 String', N'123', N'123 String', '123 Text', N'123 Text'),
('abc', 'abc string', N'abc', N'abc string', 'abc text', N'abc text'),
('   XYZ   ', ' XYZ String ', N'   XYZ   ', N' XYZ String ', '   XYZ   ', N'   XYZ   ');
GO

-- =============================================
-- 1. COMPARISON OPERATORS TESTS (=, <>, >, <, >=, <=, !<, !>)
-- =============================================

-- Test equality operator (=)
SELECT 'Equality Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol = t2.CharCol THEN 'Equal' ELSE 'Not Equal' END AS Char_Equality,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol = t2.VarcharCol THEN 'Equal' ELSE 'Not Equal' END AS Varchar_Equality,
    -- NCHAR tests
    CASE WHEN t1.NCharCol = t2.NCharCol THEN 'Equal' ELSE 'Not Equal' END AS NChar_Equality,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol = t2.NVarcharCol THEN 'Equal' ELSE 'Not Equal' END AS NVarchar_Equality,
    -- TEXT tests
    CASE WHEN t1.TextCol = t2.TextCol THEN 'Equal' ELSE 'Not Equal' END AS Text_Equality,
    -- NTEXT tests
    CASE WHEN t1.NTextCol = t2.NTextCol THEN 'Equal' ELSE 'Not Equal' END AS NText_Equality
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 1;
GO

-- Test inequality operator (<>)
SELECT 'Inequality Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol <> t2.CharCol THEN 'Not Equal' ELSE 'Equal' END AS Char_Inequality,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol <> t2.VarcharCol THEN 'Not Equal' ELSE 'Equal' END AS Varchar_Inequality,
    -- NCHAR tests
    CASE WHEN t1.NCharCol <> t2.NCharCol THEN 'Not Equal' ELSE 'Equal' END AS NChar_Inequality,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol <> t2.NVarcharCol THEN 'Not Equal' ELSE 'Equal' END AS NVarchar_Inequality,
    -- TEXT tests
    CASE WHEN t1.TextCol <> t2.TextCol THEN 'Not Equal' ELSE 'Equal' END AS Text_Inequality,
    -- NTEXT tests
    CASE WHEN t1.NTextCol <> t2.NTextCol THEN 'Not Equal' ELSE 'Equal' END AS NText_Inequality
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 1;
GO

-- Test greater than operator (>)
SELECT 'Greater Than Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol > t2.CharCol THEN 'Greater' ELSE 'Not Greater' END AS Char_GreaterThan,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol > t2.VarcharCol THEN 'Greater' ELSE 'Not Greater' END AS Varchar_GreaterThan,
    -- NCHAR tests
    CASE WHEN t1.NCharCol > t2.NCharCol THEN 'Greater' ELSE 'Not Greater' END AS NChar_GreaterThan,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol > t2.NVarcharCol THEN 'Greater' ELSE 'Not Greater' END AS NVarchar_GreaterThan,
    -- TEXT tests
    CASE WHEN t1.TextCol > t2.TextCol THEN 'Greater' ELSE 'Not Greater' END AS Text_GreaterThan,
    -- NTEXT tests
    CASE WHEN t1.NTextCol > t2.NTextCol THEN 'Greater' ELSE 'Not Greater' END AS NText_GreaterThan
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 2;
GO

-- Test less than operator (<)
SELECT 'Less Than Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol < t2.CharCol THEN 'Less' ELSE 'Not Less' END AS Char_LessThan,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol < t2.VarcharCol THEN 'Less' ELSE 'Not Less' END AS Varchar_LessThan,
    -- NCHAR tests
    CASE WHEN t1.NCharCol < t2.NCharCol THEN 'Less' ELSE 'Not Less' END AS NChar_LessThan,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol < t2.NVarcharCol THEN 'Less' ELSE 'Not Less' END AS NVarchar_LessThan,
    -- TEXT tests
    CASE WHEN t1.TextCol < t2.TextCol THEN 'Less' ELSE 'Not Less' END AS Text_LessThan,
    -- NTEXT tests
    CASE WHEN t1.NTextCol < t2.NTextCol THEN 'Less' ELSE 'Not Less' END AS NText_LessThan
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 1;
GO

-- Test greater than or equal operator (>=)
SELECT 'Greater Than or Equal Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol >= t2.CharCol THEN 'Greater/Equal' ELSE 'Less' END AS Char_GreaterEqual,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol >= t2.VarcharCol THEN 'Greater/Equal' ELSE 'Less' END AS Varchar_GreaterEqual,
    -- NCHAR tests
    CASE WHEN t1.NCharCol >= t2.NCharCol THEN 'Greater/Equal' ELSE 'Less' END AS NChar_GreaterEqual,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol >= t2.NVarcharCol THEN 'Greater/Equal' ELSE 'Less' END AS NVarchar_GreaterEqual,
    -- TEXT tests
    CASE WHEN t1.TextCol >= t2.TextCol THEN 'Greater/Equal' ELSE 'Less' END AS Text_GreaterEqual,
    -- NTEXT tests
    CASE WHEN t1.NTextCol >= t2.NTextCol THEN 'Greater/Equal' ELSE 'Less' END AS NText_GreaterEqual
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 1;
GO

-- Test less than or equal operator (<=)
SELECT 'Less Than or Equal Tests' AS TestType;
SELECT 
    t1.ID AS T1_ID,
    t2.ID AS T2_ID,
    -- CHAR tests
    CASE WHEN t1.CharCol <= t2.CharCol THEN 'Less/Equal' ELSE 'Greater' END AS Char_LessEqual,
    -- VARCHAR tests
    CASE WHEN t1.VarcharCol <= t2.VarcharCol THEN 'Less/Equal' ELSE 'Greater' END AS Varchar_LessEqual,
    -- NCHAR tests
    CASE WHEN t1.NCharCol <= t2.NCharCol THEN 'Less/Equal' ELSE 'Greater' END AS NChar_LessEqual,
    -- NVARCHAR tests
    CASE WHEN t1.NVarcharCol <= t2.NVarcharCol THEN 'Less/Equal' ELSE 'Greater' END AS NVarchar_LessEqual,
    -- TEXT tests
    CASE WHEN t1.TextCol <= t2.TextCol THEN 'Less/Equal' ELSE 'Greater' END AS Text_LessEqual,
    -- NTEXT tests
    CASE WHEN t1.NTextCol <= t2.NTextCol THEN 'Less/Equal' ELSE 'Greater' END AS NText_LessEqual
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2
WHERE t1.ID = 1;
GO

-- =============================================
-- 2. PATTERN MATCHING OPERATOR (LIKE) TESTS
-- =============================================

-- Basic LIKE patterns
SELECT 'Basic LIKE Pattern Tests' AS TestType;
SELECT 
    ID,
    -- Exact match
    CASE WHEN CharCol LIKE 'ABC' THEN 'Match' ELSE 'No Match' END AS Exact_Match_Char,
    CASE WHEN VarcharCol LIKE 'ABC String' THEN 'Match' ELSE 'No Match' END AS Exact_Match_Varchar,
    
    -- Start with pattern
    CASE WHEN CharCol LIKE 'A%' THEN 'Match' ELSE 'No Match' END AS Starts_With_Char,
    CASE WHEN VarcharCol LIKE 'ABC%' THEN 'Match' ELSE 'No Match' END AS Starts_With_Varchar,
    
    -- End with pattern
    CASE WHEN NCharCol LIKE '%C' THEN 'Match' ELSE 'No Match' END AS Ends_With_NChar,
    CASE WHEN NVarcharCol LIKE '%String' THEN 'Match' ELSE 'No Match' END AS Ends_With_NVarchar,
    
    -- Contains pattern
    CASE WHEN TextCol LIKE '%BC%' THEN 'Match' ELSE 'No Match' END AS Contains_Text,
    CASE WHEN NTextCol LIKE '%BC%' THEN 'Match' ELSE 'No Match' END AS Contains_NText
FROM string_operators_t1;
GO

-- Wildcard character tests
SELECT 'Wildcard Character Tests' AS TestType;
SELECT 
    ID,
    -- Single character wildcard (_)
    CASE WHEN CharCol LIKE '_BC' THEN 'Match' ELSE 'No Match' END AS Single_Char_Wildcard,
    CASE WHEN VarcharCol LIKE '_BC%' THEN 'Match' ELSE 'No Match' END AS Single_Char_With_Any,
    
    -- Character range ([])
    CASE WHEN CharCol LIKE '[A-Z]BC' THEN 'Match' ELSE 'No Match' END AS Char_Range,
    CASE WHEN VarcharCol LIKE '[ABC]%' THEN 'Match' ELSE 'No Match' END AS Char_Set,
    
    -- Negative character range ([^])
    CASE WHEN CharCol LIKE '[^X-Z]BC' THEN 'Match' ELSE 'No Match' END AS Negative_Range,
    
    -- Multiple patterns
    CASE WHEN VarcharCol LIKE '_[A-Z]C%' THEN 'Match' ELSE 'No Match' END AS Complex_Pattern
FROM string_operators_t1;
GO

-- Special character LIKE tests
SELECT 'Special Character LIKE Tests' AS TestType;
SELECT 
    ID,
    -- Escape character tests
    CASE WHEN VarcharCol LIKE '%[%]%' THEN 'Match' ELSE 'No Match' END AS Percent_Sign_Match,
    CASE WHEN VarcharCol LIKE '%[_]%' THEN 'Match' ELSE 'No Match' END AS Underscore_Match,
    CASE WHEN VarcharCol LIKE '%[[]%' THEN 'Match' ELSE 'No Match' END AS LeftBracket_Match,
    
    -- Special characters in patterns
    CASE WHEN CharCol LIKE '%!%' THEN 'Match' ELSE 'No Match' END AS Exclamation_Match,
    CASE WHEN VarcharCol LIKE '%@%' THEN 'Match' ELSE 'No Match' END AS At_Sign_Match
FROM string_operators_t1
WHERE ID = 8;  -- Row with special characters
GO

-- =============================================
-- 3. CONCATENATION OPERATOR (+) TESTS
-- =============================================

-- Basic concatenation
SELECT 'Basic Concatenation Tests' AS TestType;
SELECT 
    ID,
    -- Same type concatenation
    CharCol + CharCol AS Char_Concat,
    VarcharCol + VarcharCol AS Varchar_Concat,
    NCharCol + NCharCol AS NChar_Concat,
    NVarcharCol + NVarcharCol AS NVarchar_Concat,
    TextCol + TextCol AS Text_Concat,
    NTextCol + NTextCol AS NText_Concat,
    
    -- Mixed type concatenation
    CharCol + VarcharCol AS Char_Varchar_Concat,
    NCharCol + NVarcharCol AS NChar_NVarchar_Concat,
    VarcharCol + TextCol AS Varchar_Text_Concat,
    NVarcharCol + NTextCol AS NVarchar_NText_Concat
FROM string_operators_t1
WHERE ID = 1;
GO

-- Concatenation with literals and spaces
SELECT 'Concatenation with Literals Tests' AS TestType;
SELECT 
    ID,
    CharCol + ' Suffix' AS Char_With_Literal,
    'Prefix ' + VarcharCol AS Varchar_With_Literal,
    NCharCol + N' Suffix' AS NChar_With_Literal,
    N'Prefix ' + NVarcharCol AS NVarchar_With_Literal,
    
    -- Multiple concatenations
    'Start-' + CharCol + '-End' AS Multiple_Concat_Char,
    N'Start-' + NVarcharCol + N'-End' AS Multiple_Concat_NVarchar
FROM string_operators_t1
WHERE ID = 1;
GO

-- NULL concatenation tests
SELECT 'NULL Concatenation Tests' AS TestType;
SELECT 
    -- NULL with string
    NULL + 'String' AS Null_Plus_String,
    'String' + NULL AS String_Plus_Null,
    NULL + NULL AS Null_Plus_Null,
    
    -- NULL with different types
    CAST(NULL AS VARCHAR(10)) + CharCol AS Null_Varchar_Plus_Char,
    NCharCol + CAST(NULL AS NVARCHAR(10)) AS NChar_Plus_Null_NVarchar
FROM string_operators_t1
WHERE ID = 1;
GO

-- =============================================
-- 4. IN AND BETWEEN OPERATOR TESTS
-- =============================================

-- IN operator tests
SELECT 'IN Operator Tests' AS TestType;
SELECT 
    ID,
    -- Single type IN
    CASE WHEN CharCol IN ('ABC', 'DEF', 'GHI') THEN 'Found' ELSE 'Not Found' END AS Char_IN,
    CASE WHEN VarcharCol IN ('ABC String', 'DEF String') THEN 'Found' ELSE 'Not Found' END AS Varchar_IN,
    CASE WHEN NCharCol IN (N'ABC', N'DEF') THEN 'Found' ELSE 'Not Found' END AS NChar_IN,
    CASE WHEN NVarcharCol IN (N'ABC String', N'XYZ String') THEN 'Found' ELSE 'Not Found' END AS NVarchar_IN
FROM string_operators_t1;
GO

-- BETWEEN operator tests
SELECT 'BETWEEN Operator Tests' AS TestType;
SELECT 
    ID,
    -- Basic BETWEEN
    CASE WHEN CharCol BETWEEN 'A' AND 'Z' THEN 'In Range' ELSE 'Out of Range' END AS Char_Between,
    CASE WHEN VarcharCol BETWEEN 'A' AND 'Z' THEN 'In Range' ELSE 'Out of Range' END AS Varchar_Between,
    CASE WHEN NCharCol BETWEEN N'A' AND N'Z' THEN 'In Range' ELSE 'Out of Range' END AS NChar_Between,
    
    -- NOT BETWEEN
    CASE WHEN CharCol NOT BETWEEN 'X' AND 'Z' THEN 'Not In Range' ELSE 'In Range' END AS Char_Not_Between,
    CASE WHEN VarcharCol NOT BETWEEN 'X' AND 'Z' THEN 'Not In Range' ELSE 'In Range' END AS Varchar_Not_Between
FROM string_operators_t1;
GO

-- =============================================
-- 5. CASE SENSITIVITY AND COLLATION TESTS
-- =============================================

SELECT 'Case Sensitivity Tests' AS TestType;
SELECT 
    ID,
    -- Case-sensitive comparisons
    CASE WHEN CharCol = 'abc' COLLATE SQL_Latin1_General_CP1_CS_AS THEN 'Match' ELSE 'No Match' END AS CS_Char,
    CASE WHEN VarcharCol = 'abc string' COLLATE SQL_Latin1_General_CP1_CS_AS THEN 'Match' ELSE 'No Match' END AS CS_Varchar,
    
    -- Case-insensitive comparisons
    CASE WHEN CharCol = 'abc' COLLATE SQL_Latin1_General_CP1_CI_AS THEN 'Match' ELSE 'No Match' END AS CI_Char,
    CASE WHEN VarcharCol = 'abc string' COLLATE SQL_Latin1_General_CP1_CI_AS THEN 'Match' ELSE 'No Match' END AS CI_Varchar,
    
    -- LIKE with collation
    CASE WHEN CharCol LIKE 'abc%' COLLATE SQL_Latin1_General_CP1_CS_AS THEN 'Match' ELSE 'No Match' END AS CS_Like,
    CASE WHEN VarcharCol LIKE 'abc%' COLLATE SQL_Latin1_General_CP1_CI_AS THEN 'Match' ELSE 'No Match' END AS CI_Like
FROM string_operators_t1
WHERE ID IN (1, 4);  -- Rows with 'ABC' and 'abc'
GO

-- =============================================
-- 6. DEPENDENT OBJECTS - VIEWS
-- =============================================

-- Create view for string comparison operations
CREATE VIEW string_operators_v1 AS
SELECT 
    t1.ID,
    t1.CharCol,
    t1.VarcharCol,
    t2.CharCol AS CharCol2,
    t2.VarcharCol AS VarcharCol2,
    -- Comparison operators
    CASE WHEN t1.CharCol = t2.CharCol THEN 'Equal' ELSE 'Not Equal' END AS EqualityTest,
    CASE WHEN t1.VarcharCol > t2.VarcharCol THEN 'Greater' ELSE 'Not Greater' END AS GreaterThanTest,
    -- Pattern matching
    CASE WHEN t1.CharCol LIKE t2.CharCol + '%' THEN 'Matches' ELSE 'No Match' END AS LikeTest,
    -- Concatenation
    t1.CharCol + ' - ' + t2.CharCol AS ConcatenatedResult
FROM string_operators_t1 t1
CROSS JOIN string_operators_t2 t2;
GO

-- Create view for Unicode string operations
CREATE VIEW string_operators_v2 AS
SELECT 
    t1.ID,
    t1.NCharCol,
    t1.NVarcharCol,
    t1.NTextCol,
    -- String operations with Unicode data
    CASE WHEN t1.NCharCol LIKE N'%[0-9]%' THEN 'Contains Numbers' ELSE 'No Numbers' END AS ContainsNumbers,
    CASE WHEN t1.NVarcharCol BETWEEN N'A' AND N'Z' THEN 'A-Z Range' ELSE 'Outside Range' END AS AlphaRange,
    N'Prefix-' + t1.NCharCol + N'-Suffix' AS DecoratedString
FROM string_operators_t1 t1;
GO

-- Create view for complex pattern matching
CREATE VIEW string_operators_v3 AS
SELECT 
    ID,
    CharCol,
    VarcharCol,
    TextCol,
    -- Complex LIKE patterns
    CASE WHEN CharCol LIKE '[A-Z]%[0-9]' THEN 'Matches Pattern' ELSE 'No Match' END AS ComplexPattern1,
    CASE WHEN VarcharCol LIKE '%[^a-z]%' COLLATE SQL_Latin1_General_CP1_CS_AS THEN 'Has Non-Lowercase' 
         ELSE 'All Lowercase' END AS ComplexPattern2,
    CASE WHEN TextCol LIKE '%[aeiou]%[aeiou]%' THEN 'Multiple Vowels' ELSE 'Less Than 2 Vowels' END AS VowelPattern
FROM string_operators_t1;
GO

-- Test Views
SELECT * FROM string_operators_v1 WHERE ID = 1;
SELECT * FROM string_operators_v2 WHERE ID = 1;
SELECT * FROM string_operators_v3;
GO

-- =============================================
-- 7. DEPENDENT OBJECTS - FUNCTIONS
-- =============================================

-- Create function for string pattern analysis
CREATE FUNCTION string_operators_fn_analyze
(
    @InputString VARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @InputString AS InputString,
        CASE 
            WHEN @InputString LIKE '[A-Z]%' THEN 'Starts with Uppercase'
            WHEN @InputString LIKE '[a-z]%' THEN 'Starts with Lowercase'
            WHEN @InputString LIKE '[0-9]%' THEN 'Starts with Number'
            ELSE 'Starts with Other'
        END AS StartPattern,
        CASE 
            WHEN @InputString LIKE '%[A-Z]' THEN 'Ends with Uppercase'
            WHEN @InputString LIKE '%[a-z]' THEN 'Ends with Lowercase'
            WHEN @InputString LIKE '%[0-9]' THEN 'Ends with Number'
            ELSE 'Ends with Other'
        END AS EndPattern,
        CASE 
            WHEN @InputString LIKE '%[^A-Za-z0-9]%' THEN 'Contains Special Characters'
            ELSE 'Alphanumeric Only'
        END AS ContentType
);
GO

-- Create function for string comparison
CREATE FUNCTION string_operators_fn_compare
(
    @String1 NVARCHAR(MAX),
    @String2 NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @String1 AS String1,
        @String2 AS String2,
        CASE 
            WHEN @String1 = @String2 THEN 'Equal'
            WHEN @String1 > @String2 THEN 'String1 Greater'
            ELSE 'String2 Greater'
        END AS ComparisonResult,
        CASE 
            WHEN @String1 LIKE @String2 THEN 'Exact Match'
            WHEN @String1 LIKE @String2 + '%' THEN 'String1 Starts With String2'
            WHEN @String1 LIKE '%' + @String2 THEN 'String1 Ends With String2'
            WHEN @String1 LIKE '%' + @String2 + '%' THEN 'String1 Contains String2'
            ELSE 'No Pattern Match'
        END AS PatternMatch,
        @String1 + ' - ' + @String2 AS Concatenated
);
GO

-- Test Functions
SELECT * FROM string_operators_fn_analyze('Test123!');
SELECT * FROM string_operators_fn_analyze('ABC-DEF');
SELECT * FROM string_operators_fn_compare('TestString', 'Test');
SELECT * FROM string_operators_fn_compare('ABC', 'XYZ');
GO

-- =============================================
-- 8. DEPENDENT OBJECTS - STORED PROCEDURES
-- =============================================

-- Create procedure for string pattern matching
CREATE PROCEDURE string_operators_sp_findpatterns
    @SearchPattern VARCHAR(100),
    @CaseSensitive BIT = 0
AS
BEGIN
    IF @CaseSensitive = 1
    BEGIN
        SELECT 
            ID,
            CharCol,
            VarcharCol,
            NCharCol,
            NVarcharCol
        FROM string_operators_t1
        WHERE CharCol LIKE @SearchPattern COLLATE SQL_Latin1_General_CP1_CS_AS
           OR VarcharCol LIKE @SearchPattern COLLATE SQL_Latin1_General_CP1_CS_AS
           OR NCharCol LIKE @SearchPattern COLLATE SQL_Latin1_General_CP1_CS_AS
           OR NVarcharCol LIKE @SearchPattern COLLATE SQL_Latin1_General_CP1_CS_AS;
    END
    ELSE
    BEGIN
        SELECT 
            ID,
            CharCol,
            VarcharCol,
            NCharCol,
            NVarcharCol
        FROM string_operators_t1
        WHERE CharCol LIKE @SearchPattern
           OR VarcharCol LIKE @SearchPattern
           OR NCharCol LIKE @SearchPattern
           OR NVarcharCol LIKE @SearchPattern;
    END
END;
GO

-- Create procedure for string comparison operations
CREATE PROCEDURE string_operators_sp_compare
    @String1 NVARCHAR(100),
    @String2 NVARCHAR(100)
AS
BEGIN
    SELECT 
        @String1 AS String1,
        @String2 AS String2,
        -- Comparison tests
        CASE WHEN @String1 = @String2 THEN 'Equal' ELSE 'Not Equal' END AS EqualityTest,
        CASE WHEN @String1 > @String2 THEN 'Greater' ELSE 'Not Greater' END AS GreaterThanTest,
        CASE WHEN @String1 < @String2 THEN 'Less' ELSE 'Not Less' END AS LessThanTest,
        -- Pattern matching
        CASE WHEN @String1 LIKE @String2 THEN 'Matches' ELSE 'No Match' END AS ExactPattern,
        CASE WHEN @String1 LIKE @String2 + '%' THEN 'Starts With' ELSE 'Different Start' END AS StartPattern,
        CASE WHEN @String1 LIKE '%' + @String2 THEN 'Ends With' ELSE 'Different End' END AS EndPattern,
        -- Concatenation
        @String1 + ' - ' + @String2 AS Concatenated;
END;
GO

-- Test Procedures
EXEC string_operators_sp_findpatterns 'A%';
EXEC string_operators_sp_findpatterns '%String%', 1;
EXEC string_operators_sp_compare 'TestString', 'Test';
EXEC string_operators_sp_compare 'ABC', 'XYZ';
GO

-- =============================================
-- 9. COMPLEX OPERATOR COMBINATIONS
-- =============================================

-- Create table for complex operator tests
CREATE TABLE string_operators_complex_t1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    StringValue NVARCHAR(100),
    SearchPattern NVARCHAR(100),
    ReplacePattern NVARCHAR(100)
);
GO

INSERT INTO string_operators_complex_t1 VALUES
('Test-String-123', 'String', 'Text'),
('ABC-DEF-GHI', 'DEF', 'XYZ'),
('123-456-789', '456', '000'),
('Test!@#Test', 'Test', 'Best');
GO

-- Complex operator combinations
SELECT 
    ID,
    StringValue,
    SearchPattern,
    ReplacePattern,
    -- Combination of LIKE and concatenation
    CASE 
        WHEN StringValue LIKE '%' + SearchPattern + '%'
        THEN 'Contains: ' + SearchPattern
        ELSE 'No match: ' + SearchPattern
    END AS PatternTest,
    -- Combination of comparison and concatenation
    CASE 
        WHEN StringValue > ReplacePattern
        THEN StringValue + ' > ' + ReplacePattern
        ELSE StringValue + ' <= ' + ReplacePattern
    END AS ComparisonTest,
    -- Complex pattern matching
    CASE 
        WHEN StringValue LIKE '[A-Z]%[0-9]' AND SearchPattern LIKE '[A-Z]%'
        THEN 'Both match pattern'
        WHEN StringValue LIKE '[A-Z]%[0-9]'
        THEN 'Only StringValue matches'
        WHEN SearchPattern LIKE '[A-Z]%'
        THEN 'Only SearchPattern matches'
        ELSE 'Neither matches'
    END AS ComplexPattern
FROM string_operators_complex_t1;
GO

-- =============================================
-- CLEANUP
-- =============================================

-- Drop Views
DROP VIEW string_operators_v1;
DROP VIEW string_operators_v2;
DROP VIEW string_operators_v3;
GO

-- Drop Functions
DROP FUNCTION string_operators_fn_analyze;
DROP FUNCTION string_operators_fn_compare;
GO

-- Drop Procedures
DROP PROCEDURE string_operators_sp_findpatterns;
DROP PROCEDURE string_operators_sp_compare;
GO

-- Drop Tables
DROP TABLE string_operators_complex_t1;
DROP TABLE string_operators_t2;
DROP TABLE string_operators_t1;
GO


-- =============================================
-- Explicit Casting using Cast Function
-- =============================================

-- Create table with all data types
CREATE TABLE cast_source (
    -- Integer Types
    IntCol INT,
    BigintCol BIGINT,
    SmallintCol SMALLINT,
    TinyintCol TINYINT,
    BitCol BIT,

    -- Decimal Types
    DecimalCol DECIMAL(18,2),
    NumericCol NUMERIC(18,2),
    FloatCol FLOAT,
    RealCol REAL,
    MoneyCol MONEY,
    SmallmoneyCol SMALLMONEY,

    -- Date/Time Types
    DatetimeCol DATETIME,
    DateCol DATE,
    TimeCol TIME,
    Datetime2Col DATETIME2,
    SmalldatetimeCol SMALLDATETIME,
    DatetimeoffsetCol DATETIMEOFFSET,

    -- String Types
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NcharCol NCHAR(10),
    NvarcharCol NVARCHAR(50),
    TextCol TEXT,
    NtextCol NTEXT,

    -- Binary and Other Types
    BinaryCol BINARY(10),
    VarbinaryCol VARBINARY(50),
    ImageCol IMAGE,
    UniqueidCol UNIQUEIDENTIFIER,
    XmlCol XML,
    GeometryCol GEOMETRY,
    GeographyCol GEOGRAPHY,
    SqlvariantCol SQL_VARIANT
);
GO

-- Insert test data
INSERT INTO cast_source VALUES (
    -- Integer Types
    123, 123456789, 12345, 255, 1,
    
    -- Decimal Types
    123.45, 123.45, 123.45, 123.45, 123.45, 123.45,
    
    -- Date/Time Types
    '2024-01-15 12:34:56', '2024-01-15', '12:34:56',
    '2024-01-15 12:34:56.1234567', '2024-01-15 12:34:00',
    '2024-01-15 12:34:56.1234567 +00:00',
    
    -- String Types
    'Test', 'Test String', N'Test', N'Test String',
    'Test Text', N'Test NText',
    
    -- Binary and Other Types
    0x4142434445, 0x4142434445, 0x4142434445,
    '9641D381-A27F-40A0-8FB9-42216F635D4A', '<root>test</root>',
    geometry::STGeomFromText('POINT (3 4)', 0),
    geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326),
    123
);
GO

-- Integer Types
SELECT CAST(IntCol AS CHAR(10)), CAST(IntCol AS VARCHAR(10)), CAST(IntCol AS NCHAR(10)), CAST(IntCol AS NVARCHAR(10)), CAST(IntCol AS TEXT), CAST(IntCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(BigintCol AS CHAR(20)), CAST(BigintCol AS VARCHAR(20)), CAST(BigintCol AS NCHAR(20)), CAST(BigintCol AS NVARCHAR(20)), CAST(BigintCol AS TEXT), CAST(BigintCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(SmallintCol AS CHAR(10)), CAST(SmallintCol AS VARCHAR(10)), CAST(SmallintCol AS NCHAR(10)), CAST(SmallintCol AS NVARCHAR(10)), CAST(SmallintCol AS TEXT), CAST(SmallintCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(TinyintCol AS CHAR(10)), CAST(TinyintCol AS VARCHAR(10)), CAST(TinyintCol AS NCHAR(10)), CAST(TinyintCol AS NVARCHAR(10)), CAST(TinyintCol AS TEXT), CAST(TinyintCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(BitCol AS CHAR(10)), CAST(BitCol AS VARCHAR(10)), CAST(BitCol AS NCHAR(10)), CAST(BitCol AS NVARCHAR(10)), CAST(BitCol AS TEXT), CAST(BitCol AS NTEXT) FROM cast_source;
GO

-- Decimal Types
SELECT CAST(DecimalCol AS CHAR(10)), CAST(DecimalCol AS VARCHAR(10)), CAST(DecimalCol AS NCHAR(10)), CAST(DecimalCol AS NVARCHAR(10)), CAST(DecimalCol AS TEXT), CAST(DecimalCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(NumericCol AS CHAR(10)), CAST(NumericCol AS VARCHAR(10)), CAST(NumericCol AS NCHAR(10)), CAST(NumericCol AS NVARCHAR(10)), CAST(NumericCol AS TEXT), CAST(NumericCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(FloatCol AS CHAR(20)), CAST(FloatCol AS VARCHAR(20)), CAST(FloatCol AS NCHAR(20)), CAST(FloatCol AS NVARCHAR(20)), CAST(FloatCol AS TEXT), CAST(FloatCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(RealCol AS CHAR(20)), CAST(RealCol AS VARCHAR(20)), CAST(RealCol AS NCHAR(20)), CAST(RealCol AS NVARCHAR(20)), CAST(RealCol AS TEXT), CAST(RealCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(MoneyCol AS CHAR(20)), CAST(MoneyCol AS VARCHAR(20)), CAST(MoneyCol AS NCHAR(20)), CAST(MoneyCol AS NVARCHAR(20)), CAST(MoneyCol AS TEXT), CAST(MoneyCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(SmallmoneyCol AS CHAR(20)), CAST(SmallmoneyCol AS VARCHAR(20)), CAST(SmallmoneyCol AS NCHAR(20)), CAST(SmallmoneyCol AS NVARCHAR(20)), CAST(SmallmoneyCol AS TEXT), CAST(SmallmoneyCol AS NTEXT) FROM cast_source;
GO

-- Date/Time Types
SELECT CAST(DatetimeCol AS CHAR(30)), CAST(DatetimeCol AS VARCHAR(30)), CAST(DatetimeCol AS NCHAR(30)), CAST(DatetimeCol AS NVARCHAR(30)), CAST(DatetimeCol AS TEXT), CAST(DatetimeCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(DateCol AS CHAR(30)), CAST(DateCol AS VARCHAR(30)), CAST(DateCol AS NCHAR(30)), CAST(DateCol AS NVARCHAR(30)), CAST(DateCol AS TEXT), CAST(DateCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(TimeCol AS CHAR(30)), CAST(TimeCol AS VARCHAR(30)), CAST(TimeCol AS NCHAR(30)), CAST(TimeCol AS NVARCHAR(30)), CAST(TimeCol AS TEXT), CAST(TimeCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(Datetime2Col AS CHAR(30)), CAST(Datetime2Col AS VARCHAR(30)), CAST(Datetime2Col AS NCHAR(30)), CAST(Datetime2Col AS NVARCHAR(30)), CAST(Datetime2Col AS TEXT), CAST(Datetime2Col AS NTEXT) FROM cast_source;
GO

SELECT CAST(SmalldatetimeCol AS CHAR(30)), CAST(SmalldatetimeCol AS VARCHAR(30)), CAST(SmalldatetimeCol AS NCHAR(30)), CAST(SmalldatetimeCol AS NVARCHAR(30)), CAST(SmalldatetimeCol AS TEXT), CAST(SmalldatetimeCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(DatetimeoffsetCol AS CHAR(50)), CAST(DatetimeoffsetCol AS VARCHAR(50)), CAST(DatetimeoffsetCol AS NCHAR(50)), CAST(DatetimeoffsetCol AS NVARCHAR(50)), CAST(DatetimeoffsetCol AS TEXT), CAST(DatetimeoffsetCol AS NTEXT) FROM cast_source;
GO

-- String Types
SELECT CAST(CharCol AS CHAR(20)), CAST(CharCol AS VARCHAR(20)), CAST(CharCol AS NCHAR(20)), CAST(CharCol AS NVARCHAR(20)), CAST(CharCol AS TEXT), CAST(CharCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(VarcharCol AS CHAR(50)), CAST(VarcharCol AS VARCHAR(50)), CAST(VarcharCol AS NCHAR(50)), CAST(VarcharCol AS NVARCHAR(50)), CAST(VarcharCol AS TEXT), CAST(VarcharCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(NcharCol AS CHAR(20)), CAST(NcharCol AS VARCHAR(20)), CAST(NcharCol AS NCHAR(20)), CAST(NcharCol AS NVARCHAR(20)), CAST(NcharCol AS TEXT), CAST(NcharCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(NvarcharCol AS CHAR(50)), CAST(NvarcharCol AS VARCHAR(50)), CAST(NvarcharCol AS NCHAR(50)), CAST(NvarcharCol AS NVARCHAR(50)), CAST(NvarcharCol AS TEXT), CAST(NvarcharCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(TextCol AS CHAR(50)), CAST(TextCol AS VARCHAR(50)), CAST(TextCol AS NCHAR(50)), CAST(TextCol AS NVARCHAR(50)), CAST(TextCol AS TEXT), CAST(TextCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(NtextCol AS CHAR(50)), CAST(NtextCol AS VARCHAR(50)), CAST(NtextCol AS NCHAR(50)), CAST(NtextCol AS NVARCHAR(50)), CAST(NtextCol AS TEXT), CAST(NtextCol AS NTEXT) FROM cast_source;
GO

-- Binary and Other Types
SELECT CAST(BinaryCol AS CHAR(20)), CAST(BinaryCol AS VARCHAR(20)), CAST(BinaryCol AS NCHAR(20)), CAST(BinaryCol AS NVARCHAR(20)), CAST(BinaryCol AS TEXT), CAST(BinaryCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(VarbinaryCol AS CHAR(20)), CAST(VarbinaryCol AS VARCHAR(20)), CAST(VarbinaryCol AS NCHAR(20)), CAST(VarbinaryCol AS NVARCHAR(20)), CAST(VarbinaryCol AS TEXT), CAST(VarbinaryCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(ImageCol AS CHAR(20)), CAST(ImageCol AS VARCHAR(20)), CAST(ImageCol AS NCHAR(20)), CAST(ImageCol AS NVARCHAR(20)), CAST(ImageCol AS TEXT), CAST(ImageCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(UniqueidCol AS CHAR(36)), CAST(UniqueidCol AS VARCHAR(36)), CAST(UniqueidCol AS NCHAR(36)), CAST(UniqueidCol AS NVARCHAR(36)), CAST(UniqueidCol AS TEXT), CAST(UniqueidCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(XmlCol AS CHAR(50)), CAST(XmlCol AS VARCHAR(50)), CAST(XmlCol AS NCHAR(50)), CAST(XmlCol AS NVARCHAR(50)), CAST(XmlCol AS TEXT), CAST(XmlCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(GeometryCol AS CHAR(50)), CAST(GeometryCol AS VARCHAR(50)), CAST(GeometryCol AS NCHAR(50)), CAST(GeometryCol AS NVARCHAR(50)), CAST(GeometryCol AS TEXT), CAST(GeometryCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(GeographyCol AS CHAR(50)), CAST(GeographyCol AS VARCHAR(50)), CAST(GeographyCol AS NCHAR(50)), CAST(GeographyCol AS NVARCHAR(50)), CAST(GeographyCol AS TEXT), CAST(GeographyCol AS NTEXT) FROM cast_source;
GO

SELECT CAST(SqlvariantCol AS CHAR(20)), CAST(SqlvariantCol AS VARCHAR(20)), CAST(SqlvariantCol AS NCHAR(20)), CAST(SqlvariantCol AS NVARCHAR(20)), CAST(SqlvariantCol AS TEXT), CAST(SqlvariantCol AS NTEXT) FROM cast_source;
GO

-- Cleanup
DROP TABLE cast_source;
GO

-- =============================================
-- Expicit Casting using Try Cast Function
-- =============================================

-- Create table with all data types
CREATE TABLE try_cast_source (
    -- Integer Types
    IntCol INT,
    BigintCol BIGINT,
    SmallintCol SMALLINT,
    TinyintCol TINYINT,
    BitCol BIT,

    -- Decimal Types
    DecimalCol DECIMAL(18,2),
    NumericCol NUMERIC(18,2),
    FloatCol FLOAT,
    RealCol REAL,
    MoneyCol MONEY,
    SmallmoneyCol SMALLMONEY,

    -- Date/Time Types
    DatetimeCol DATETIME,
    DateCol DATE,
    TimeCol TIME,
    Datetime2Col DATETIME2,
    SmalldatetimeCol SMALLDATETIME,
    DatetimeoffsetCol DATETIMEOFFSET,

    -- String Types
    CharCol CHAR(10),
    VarcharCol VARCHAR(50),
    NcharCol NCHAR(10),
    NvarcharCol NVARCHAR(50),
    TextCol TEXT,
    NtextCol NTEXT,

    -- Binary and Other Types
    BinaryCol BINARY(10),
    VarbinaryCol VARBINARY(50),
    ImageCol IMAGE,
    UniqueidCol UNIQUEIDENTIFIER,
    XmlCol XML,
    GeometryCol GEOMETRY,
    GeographyCol GEOGRAPHY,
    SqlvariantCol SQL_VARIANT
);
GO

-- Insert test data
INSERT INTO try_cast_source VALUES (
    -- Integer Types
    123, 123456789, 12345, 255, 1,
    
    -- Decimal Types
    123.45, 123.45, 123.45, 123.45, 123.45, 123.45,
    
    -- Date/Time Types
    '2024-01-15 12:34:56', '2024-01-15', '12:34:56',
    '2024-01-15 12:34:56.1234567', '2024-01-15 12:34:00',
    '2024-01-15 12:34:56.1234567 +00:00',
    
    -- String Types
    'Test', 'Test String', N'Test', N'Test String',
    'Test Text', N'Test NText',
    
    -- Binary and Other Types
    0x4142434445, 0x4142434445, 0x4142434445,
    '9641D381-A27F-40A0-8FB9-42216F635D4A', '<root>test</root>',
    geometry::STGeomFromText('POINT (3 4)', 0),
    geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326),
    123
);
GO

-- Integer Types
SELECT TRY_CAST(IntCol AS VARCHAR(10)), TRY_CAST(IntCol AS NVARCHAR(10)), TRY_CAST(IntCol AS TEXT), TRY_CAST(IntCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(BigintCol AS VARCHAR(20)), TRY_CAST(BigintCol AS NVARCHAR(20)), TRY_CAST(BigintCol AS TEXT), TRY_CAST(BigintCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(SmallintCol AS VARCHAR(10)), TRY_CAST(SmallintCol AS NVARCHAR(10)), TRY_CAST(SmallintCol AS TEXT), TRY_CAST(SmallintCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(TinyintCol AS VARCHAR(10)), TRY_CAST(TinyintCol AS NVARCHAR(10)), TRY_CAST(TinyintCol AS TEXT), TRY_CAST(TinyintCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(BitCol AS VARCHAR(10)), TRY_CAST(BitCol AS NVARCHAR(10)), TRY_CAST(BitCol AS TEXT), TRY_CAST(BitCol AS NTEXT) FROM try_cast_source;
GO

-- Decimal Types
SELECT TRY_CAST(DecimalCol AS VARCHAR(10)), TRY_CAST(DecimalCol AS NVARCHAR(10)), TRY_CAST(DecimalCol AS TEXT), TRY_CAST(DecimalCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(NumericCol AS VARCHAR(10)), TRY_CAST(NumericCol AS NVARCHAR(10)), TRY_CAST(NumericCol AS TEXT), TRY_CAST(NumericCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(FloatCol AS VARCHAR(20)), TRY_CAST(FloatCol AS NVARCHAR(20)), TRY_CAST(FloatCol AS TEXT), TRY_CAST(FloatCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(RealCol AS VARCHAR(20)), TRY_CAST(RealCol AS NVARCHAR(20)), TRY_CAST(RealCol AS TEXT), TRY_CAST(RealCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(MoneyCol AS VARCHAR(20)), TRY_CAST(MoneyCol AS NVARCHAR(20)), TRY_CAST(MoneyCol AS TEXT), TRY_CAST(MoneyCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(SmallmoneyCol AS VARCHAR(20)), TRY_CAST(SmallmoneyCol AS NVARCHAR(20)), TRY_CAST(SmallmoneyCol AS TEXT), TRY_CAST(SmallmoneyCol AS NTEXT) FROM try_cast_source;
GO

-- Date/Time Types
SELECT TRY_CAST(DatetimeCol AS VARCHAR(30)), TRY_CAST(DatetimeCol AS NVARCHAR(30)), TRY_CAST(DatetimeCol AS TEXT), TRY_CAST(DatetimeCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(DateCol AS VARCHAR(30)), TRY_CAST(DateCol AS NVARCHAR(30)), TRY_CAST(DateCol AS TEXT), TRY_CAST(DateCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(TimeCol AS VARCHAR(30)), TRY_CAST(TimeCol AS NVARCHAR(30)), TRY_CAST(TimeCol AS TEXT), TRY_CAST(TimeCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(Datetime2Col AS VARCHAR(30)), TRY_CAST(Datetime2Col AS NVARCHAR(30)), TRY_CAST(Datetime2Col AS TEXT), TRY_CAST(Datetime2Col AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(SmalldatetimeCol AS VARCHAR(30)), TRY_CAST(SmalldatetimeCol AS NVARCHAR(30)), TRY_CAST(SmalldatetimeCol AS TEXT), TRY_CAST(SmalldatetimeCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(DatetimeoffsetCol AS VARCHAR(50)), TRY_CAST(DatetimeoffsetCol AS NVARCHAR(50)), TRY_CAST(DatetimeoffsetCol AS TEXT), TRY_CAST(DatetimeoffsetCol AS NTEXT) FROM try_cast_source;
GO

-- String Types
SELECT TRY_CAST(CharCol AS VARCHAR(20)), TRY_CAST(CharCol AS NVARCHAR(20)), TRY_CAST(CharCol AS TEXT), TRY_CAST(CharCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(VarcharCol AS VARCHAR(50)), TRY_CAST(VarcharCol AS NVARCHAR(50)), TRY_CAST(VarcharCol AS TEXT), TRY_CAST(VarcharCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(NcharCol AS VARCHAR(20)), TRY_CAST(NcharCol AS NVARCHAR(20)), TRY_CAST(NcharCol AS TEXT), TRY_CAST(NcharCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(NvarcharCol AS VARCHAR(50)), TRY_CAST(NvarcharCol AS NVARCHAR(50)), TRY_CAST(NvarcharCol AS TEXT), TRY_CAST(NvarcharCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(TextCol AS VARCHAR(50)), TRY_CAST(TextCol AS NVARCHAR(50)), TRY_CAST(TextCol AS TEXT), TRY_CAST(TextCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(NtextCol AS VARCHAR(50)), TRY_CAST(NtextCol AS NVARCHAR(50)), TRY_CAST(NtextCol AS TEXT), TRY_CAST(NtextCol AS NTEXT) FROM try_cast_source;
GO

-- Binary and Other Types
SELECT TRY_CAST(BinaryCol AS VARCHAR(20)), TRY_CAST(BinaryCol AS NVARCHAR(20)), TRY_CAST(BinaryCol AS TEXT), TRY_CAST(BinaryCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(VarbinaryCol AS VARCHAR(20)), TRY_CAST(VarbinaryCol AS NVARCHAR(20)), TRY_CAST(VarbinaryCol AS TEXT), TRY_CAST(VarbinaryCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(ImageCol AS VARCHAR(20)), TRY_CAST(ImageCol AS NVARCHAR(20)), TRY_CAST(ImageCol AS TEXT), TRY_CAST(ImageCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(UniqueidCol AS VARCHAR(36)), TRY_CAST(UniqueidCol AS NVARCHAR(36)), TRY_CAST(UniqueidCol AS TEXT), TRY_CAST(UniqueidCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(XmlCol AS VARCHAR(50)), TRY_CAST(XmlCol AS NVARCHAR(50)), TRY_CAST(XmlCol AS TEXT), TRY_CAST(XmlCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(GeometryCol AS VARCHAR(50)), TRY_CAST(GeometryCol AS NVARCHAR(50)), TRY_CAST(GeometryCol AS TEXT), TRY_CAST(GeometryCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(GeographyCol AS VARCHAR(50)), TRY_CAST(GeographyCol AS NVARCHAR(50)), TRY_CAST(GeographyCol AS TEXT), TRY_CAST(GeographyCol AS NTEXT) FROM try_cast_source;
GO

SELECT TRY_CAST(SqlvariantCol AS VARCHAR(20)), TRY_CAST(SqlvariantCol AS NVARCHAR(20)), TRY_CAST(SqlvariantCol AS TEXT), TRY_CAST(SqlvariantCol AS NTEXT) FROM try_cast_source;
GO

-- Cleanup
DROP TABLE try_cast_source;
GO


-- =============================================
-- Test Combinations of CAST and CONVERT
-- =============================================

CREATE TABLE cast_convert_test (
    ID INT IDENTITY(1,1),
    StringValue NVARCHAR(100),
    DateValue DATETIME,
    NumericValue DECIMAL(18,2),
    BinaryValue VARBINARY(50)
);
GO

-- Insert test data
INSERT INTO cast_convert_test (StringValue, DateValue, NumericValue, BinaryValue)
VALUES 
('123.45', '2024-01-15 14:30:00', 123.45, 0x414243),
('ABC', '2024-02-20 09:15:00', 456.78, 0x444546),
(NULL, NULL, NULL, NULL);
GO

-- Test 1: Nested CAST and CONVERT
SELECT 
    ID,
    -- Convert to VARCHAR then CAST to DECIMAL
    TRY_CAST(CONVERT(VARCHAR(20), NumericValue, 1) AS DECIMAL(18,2)) AS Numeric_ConvertCast,
    
    -- Cast to VARCHAR then CONVERT with style
    CONVERT(VARCHAR(20), CAST(NumericValue AS VARCHAR(20)), 1) AS Numeric_CastConvert,
    
    -- Multiple levels of conversion
    CAST(CONVERT(VARCHAR(20), CAST(NumericValue AS INT)) AS DECIMAL(18,2)) AS Numeric_MultiLevel
FROM cast_convert_test;
GO

-- Test 2: Date Formatting Combinations
SELECT 
    ID,
    -- Convert to VARCHAR with style, then CAST back to DATETIME
    TRY_CAST(CONVERT(VARCHAR(20), DateValue, 120) AS DATETIME) AS Date_ConvertCast,
    
    -- Cast to VARCHAR then CONVERT with style
    CONVERT(VARCHAR(20), CAST(DateValue AS VARCHAR(20)), 120) AS Date_CastConvert,
    
    -- Multiple date format conversions
    CONVERT(VARCHAR(20), 
        CAST(
            CONVERT(VARCHAR(20), DateValue, 120) 
            AS DATETIME
        ), 
    103) AS Date_MultiFormat
FROM cast_convert_test;
GO

-- Test 3: String and Binary Combinations
SELECT 
    ID,
    -- Convert binary to string then CAST
    TRY_CAST(CONVERT(VARCHAR(20), BinaryValue, 1) AS VARBINARY(20)) AS Binary_ConvertCast,
    
    -- Cast string to binary then CONVERT
    CONVERT(VARCHAR(20), CAST(StringValue AS VARBINARY(20)), 1) AS String_CastConvert,
    
    -- Multiple conversions with different styles
    CONVERT(VARCHAR(20), 
        CAST(
            CONVERT(VARCHAR(20), BinaryValue, 1) 
            AS VARBINARY(20)
        ), 
    2) AS Binary_MultiStyle
FROM cast_convert_test;
GO

-- Test 4: Error Handling with Invalid Conversions
SELECT 
    ID,
    -- Invalid numeric conversion with TRY_CAST and CONVERT
    TRY_CAST(CONVERT(VARCHAR(20), StringValue, 1) AS DECIMAL(18,2)) AS Invalid_NumericConversion,
    
    -- Invalid date conversion with TRY_CAST and CONVERT
    TRY_CAST(CONVERT(VARCHAR(20), StringValue, 120) AS DATETIME) AS Invalid_DateConversion,
    
    -- Invalid binary conversion with TRY_CAST and CONVERT
    TRY_CAST(CONVERT(VARCHAR(20), StringValue, 1) AS VARBINARY(20)) AS Invalid_BinaryConversion
FROM cast_convert_test;
GO

-- Test 5: NULL Handling
SELECT 
    ID,
    -- NULL handling with CAST and CONVERT combinations
    CAST(CONVERT(VARCHAR(20), NULL, 120) AS DATETIME) AS Null_DateConversion,
    CONVERT(VARCHAR(20), CAST(NULL AS DECIMAL(18,2)), 1) AS Null_NumericConversion,
    TRY_CAST(CONVERT(VARCHAR(20), NULL, 1) AS VARBINARY(20)) AS Null_BinaryConversion
FROM cast_convert_test;
GO

-- Cleanup
DROP TABLE cast_convert_test;
GO

-- =============================================
-- Test Implicit Casting to String Datatypes
-- =============================================

-- Create test table with all datatypes
CREATE TABLE ImplicitToStringTest (
    -- Numeric Types
    IntCol INT,
    BigIntCol BIGINT,
    SmallIntCol SMALLINT,
    TinyIntCol TINYINT,
    BitCol BIT,
    DecimalCol DECIMAL(18,2),
    NumericCol NUMERIC(18,2),
    FloatCol FLOAT,
    RealCol REAL,
    MoneyCol MONEY,
    SmallMoneyCol SMALLMONEY,

    -- Date/Time Types
    DateTimeCol DATETIME,
    SmallDateTimeCol SMALLDATETIME,
    DateCol DATE,
    TimeCol TIME,
    DateTime2Col DATETIME2,
    DateTimeOffsetCol DATETIMEOFFSET,

    -- Binary Types
    BinaryCol BINARY(10),
    VarBinaryCol VARBINARY(50),
    ImageCol IMAGE,

    -- Special Types
    UniqueIdentifierCol UNIQUEIDENTIFIER,
    XmlCol XML,
    SqlVariantCol SQL_VARIANT,
    GeometryCol GEOMETRY,
    GeographyCol GEOGRAPHY
);
GO

-- Insert test data
INSERT INTO ImplicitToStringTest VALUES (
    -- Numeric Types
    123,                    -- INT
    123456789,             -- BIGINT
    12345,                 -- SMALLINT
    255,                   -- TINYINT
    1,                     -- BIT
    123.45,                -- DECIMAL
    123.45,                -- NUMERIC
    123.45,                -- FLOAT
    123.45,                -- REAL
    123.45,                -- MONEY
    123.45,                -- SMALLMONEY

    -- Date/Time Types
    '2024-01-15 14:30:00',  -- DATETIME
    '2024-01-15 14:30:00',  -- SMALLDATETIME
    '2024-01-15',           -- DATE
    '14:30:00',             -- TIME
    '2024-01-15 14:30:00',  -- DATETIME2
    '2024-01-15 14:30:00 +00:00',  -- DATETIMEOFFSET

    -- Binary Types
    0x414243,              -- BINARY
    0x414243,              -- VARBINARY
    0x414243,              -- IMAGE

    -- Special Types
    '9641D381-A27F-40A0-8FB9-42216F635D4A',               -- UNIQUEIDENTIFIER
    '<root>Test</root>',   -- XML
    'Test',                -- SQL_VARIANT
    geometry::STGeomFromText('POINT(1 1)', 0),  -- GEOMETRY
    geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326)  -- GEOGRAPHY
);
GO

CREATE FUNCTION dbo.implicit_cast_to_char(@input CHAR(50))
RETURNS CHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO

CREATE FUNCTION dbo.implicit_cast_to_varchar(@input VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO

CREATE FUNCTION dbo.implicit_cast_to_nvarchar(@input NVARCHAR(50))
RETURNS NVARCHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO

CREATE FUNCTION dbo.implicit_cast_to_nchar(@input NCHAR(50))
RETURNS NCHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO

CREATE FUNCTION dbo.implicit_cast_to_text(@input TEXT)
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO

CREATE FUNCTION dbo.implicit_cast_to_ntext(@input NTEXT)
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN @input;
END;
GO


-- =============================================
-- Test Implicit cast
-- =============================================

-- Numeric Types
SELECT dbo.implicit_cast_to_char(IntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(IntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(IntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(IntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(IntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(IntCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(BigIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(BigIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(BigIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(BigIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(BigIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(BigIntCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(SmallIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(SmallIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(SmallIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(SmallIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(SmallIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(SmallIntCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(TinyIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(TinyIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(TinyIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(TinyIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(TinyIntCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(TinyIntCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(BitCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(BitCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(BitCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(BitCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(BitCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(BitCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(DecimalCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(DecimalCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(DecimalCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(DecimalCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(DecimalCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(DecimalCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(NumericCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(NumericCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(NumericCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(NumericCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(NumericCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(NumericCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(FloatCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(FloatCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(FloatCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(FloatCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(FloatCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(FloatCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(RealCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(RealCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(RealCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(RealCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(RealCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(RealCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(MoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(MoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(MoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(MoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(MoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(MoneyCol) FROM ImplicitToStringTest;
GO

SELECT dbo.implicit_cast_to_char(SmallMoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_varchar(SmallMoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nchar(SmallMoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_nvarchar(SmallMoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_text(SmallMoneyCol) FROM ImplicitToStringTest;
GO
SELECT dbo.implicit_cast_to_ntext(SmallMoneyCol) FROM ImplicitToStringTest;
GO

-- Date/Time Types
SELECT dbo.implicit_cast_to_char(DateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(DateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(DateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(DateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(DateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(DateTimeCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(SmallDateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(SmallDateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(SmallDateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(SmallDateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(SmallDateTimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(SmallDateTimeCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(DateCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(DateCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(DateCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(DateCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(DateCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(DateCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(TimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(TimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(TimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(TimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(TimeCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(TimeCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(DateTime2Col) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(DateTime2Col) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(DateTime2Col) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(DateTime2Col) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(DateTime2Col) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(DateTime2Col) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(DateTimeOffsetCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(DateTimeOffsetCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(DateTimeOffsetCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(DateTimeOffsetCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(DateTimeOffsetCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(DateTimeOffsetCol) FROM ImplicitToStringTest
GO

-- Binary Types
SELECT dbo.implicit_cast_to_char(BinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(BinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(BinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(BinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(BinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(BinaryCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(VarBinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(VarBinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(VarBinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(VarBinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(VarBinaryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(VarBinaryCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(ImageCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(ImageCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(ImageCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(ImageCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(ImageCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(ImageCol) FROM ImplicitToStringTest
GO


-- Special Types
SELECT dbo.implicit_cast_to_char(UniqueIdentifierCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(UniqueIdentifierCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(UniqueIdentifierCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(UniqueIdentifierCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(UniqueIdentifierCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(UniqueIdentifierCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(XmlCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(XmlCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(XmlCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(XmlCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(XmlCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(XmlCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(SqlVariantCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(SqlVariantCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(SqlVariantCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(SqlVariantCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(SqlVariantCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(SqlVariantCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(GeometryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(GeometryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(GeometryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(GeometryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(GeometryCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(GeometryCol) FROM ImplicitToStringTest
GO

SELECT dbo.implicit_cast_to_char(GeographyCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_varchar(GeographyCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nchar(GeographyCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_nvarchar(GeographyCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_text(GeographyCol) FROM ImplicitToStringTest
GO
SELECT dbo.implicit_cast_to_ntext(GeographyCol) FROM ImplicitToStringTest
GO

-- Cleanup
DROP FUNCTION dbo.implicit_cast_to_char;
DROP FUNCTION dbo.implicit_cast_to_varchar;
DROP FUNCTION dbo.implicit_cast_to_nchar;
DROP FUNCTION dbo.implicit_cast_to_nvarchar;
DROP FUNCTION dbo.implicit_cast_to_text;
DROP FUNCTION dbo.implicit_cast_to_ntext;
GO


-- =============================================
-- Test: Test Concatenation with Individual Queries
-- =============================================

-- Numeric Types
-- INT
SELECT 'Prefix_' + IntCol AS IntConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + IntCol AS IntConcatN FROM ImplicitToStringTest;
GO

-- BIGINT
SELECT 'Prefix_' + BigIntCol AS BigIntConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + BigIntCol AS BigIntConcatN FROM ImplicitToStringTest;
GO

-- SMALLINT
SELECT 'Prefix_' + SmallIntCol AS SmallIntConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + SmallIntCol AS SmallIntConcatN FROM ImplicitToStringTest;
GO

-- TINYINT
SELECT 'Prefix_' + TinyIntCol AS TinyIntConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + TinyIntCol AS TinyIntConcatN FROM ImplicitToStringTest;
GO

-- BIT
SELECT 'Prefix_' + BitCol AS BitConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + BitCol AS BitConcatN FROM ImplicitToStringTest;
GO

-- DECIMAL
SELECT 'Prefix_' + DecimalCol AS DecimalConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + DecimalCol AS DecimalConcatN FROM ImplicitToStringTest;
GO

-- NUMERIC
SELECT 'Prefix_' + NumericCol AS NumericConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + NumericCol AS NumericConcatN FROM ImplicitToStringTest;
GO

-- FLOAT
SELECT 'Prefix_' + FloatCol AS FloatConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + FloatCol AS FloatConcatN FROM ImplicitToStringTest;
GO

-- REAL
SELECT 'Prefix_' + RealCol AS RealConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + RealCol AS RealConcatN FROM ImplicitToStringTest;
GO

-- MONEY
SELECT 'Prefix_' + MoneyCol AS MoneyConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + MoneyCol AS MoneyConcatN FROM ImplicitToStringTest;
GO

-- SMALLMONEY
SELECT 'Prefix_' + SmallMoneyCol AS SmallMoneyConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + SmallMoneyCol AS SmallMoneyConcatN FROM ImplicitToStringTest;
GO

-- Date/Time Types
-- DATETIME
SELECT 'Prefix_' + DateTimeCol AS DateTimeConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + DateTimeCol AS DateTimeConcatN FROM ImplicitToStringTest;
GO

-- SMALLDATETIME
SELECT 'Prefix_' + SmallDateTimeCol AS SmallDateTimeConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + SmallDateTimeCol AS SmallDateTimeConcatN FROM ImplicitToStringTest;
GO

-- DATE
SELECT 'Prefix_' + DateCol AS DateConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + DateCol AS DateConcatN FROM ImplicitToStringTest;
GO

-- TIME
SELECT 'Prefix_' + TimeCol AS TimeConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + TimeCol AS TimeConcatN FROM ImplicitToStringTest;
GO

-- DATETIME2
SELECT 'Prefix_' + DateTime2Col AS DateTime2Concat FROM ImplicitToStringTest;
SELECT N'Prefix_' + DateTime2Col AS DateTime2ConcatN FROM ImplicitToStringTest;
GO

-- DATETIMEOFFSET
SELECT 'Prefix_' + DateTimeOffsetCol AS DateTimeOffsetConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + DateTimeOffsetCol AS DateTimeOffsetConcatN FROM ImplicitToStringTest;
GO

-- Binary Types
-- BINARY
SELECT 'Prefix_' + BinaryCol AS BinaryConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + BinaryCol AS BinaryConcatN FROM ImplicitToStringTest;
GO

-- VARBINARY
SELECT 'Prefix_' + VarBinaryCol AS VarBinaryConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + VarBinaryCol AS VarBinaryConcatN FROM ImplicitToStringTest;
GO

-- IMAGE
SELECT 'Prefix_' + ImageCol AS ImageConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + ImageCol AS ImageConcatN FROM ImplicitToStringTest;
GO

-- Special Types
-- UNIQUEIDENTIFIER
SELECT 'Prefix_' + UniqueIdentifierCol AS UniqueIdentifierConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + UniqueIdentifierCol AS UniqueIdentifierConcatN FROM ImplicitToStringTest;
GO

-- XML
SELECT 'Prefix_' + XmlCol AS XmlConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + XmlCol AS XmlConcatN FROM ImplicitToStringTest;
GO

-- SQL_VARIANT
SELECT 'Prefix_' + SqlVariantCol AS SqlVariantConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + SqlVariantCol AS SqlVariantConcatN FROM ImplicitToStringTest;
GO

-- GEOMETRY
SELECT 'Prefix_' + GeometryCol AS GeometryConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + GeometryCol AS GeometryConcatN FROM ImplicitToStringTest;
GO

-- GEOGRAPHY
SELECT 'Prefix_' + GeographyCol AS GeographyConcat FROM ImplicitToStringTest;
SELECT N'Prefix_' + GeographyCol AS GeographyConcatN FROM ImplicitToStringTest;
GO

-- =============================================
-- Test Implicit casting in expressions like:  UNION, UNION ALL, 
-- CASE EXPR, COALESCE, INTERSECT, EXCEPT, VALUES, ISNULL 
-- In common type selection
-- =============================================

-- Test 1: UNION with different string and binary types
SELECT CAST('String' AS CHAR(20)) AS Result
UNION
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
UNION
SELECT CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
ORDER BY Result
GO

SELECT CAST(N'Unicode' AS NCHAR(20)) AS Result
UNION
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
UNION
SELECT CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
ORDER BY Result
GO

SELECT CAST('Text' AS TEXT) AS Result
UNION
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
UNION
SELECT CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
ORDER BY Result
GO

-- Test 2: CASE with different string and binary types
SELECT 
    CASE 1
        WHEN 1 THEN CAST('Fixed String' AS CHAR(20))  -- CHAR(20)
        WHEN 2 THEN CAST(0x414243 AS BINARY(10))  -- BINARY(10)
        ELSE CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
    END AS CaseResult_1,
    
    CASE 1
        WHEN 1 THEN CAST(N'Unicode' AS NVARCHAR(30))  -- NVARCHAR(30)
        WHEN 2 THEN CAST('Text' AS TEXT)  -- TEXT
        ELSE CAST(0x414243 AS BINARY(10))  -- BINARY(10)
    END AS CaseResult_2;
GO

-- Test 3: COALESCE with different string and binary types
SELECT 
    COALESCE(
        CAST('Fixed' AS CHAR(20)),  -- CHAR(20)
        CAST(0x414243 AS BINARY(10)),  -- BINARY(10)
        CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
    ) AS CoalesceResult_1,
    
    COALESCE(
        CAST(N'Unicode' AS NTEXT),  -- NTEXT
        CAST('Text' AS TEXT),  -- TEXT
        CAST(0x414243 AS BINARY(10))  -- BINARY(10)
    ) AS CoalesceResult_2;
GO

-- Test 4: Testing VARCHAR with different typmods
SELECT CAST(REPLICATE('S', 10) AS VARCHAR(10)) AS Result  -- 10 characters
UNION
SELECT CAST(REPLICATE('M', 50) AS VARCHAR(50))  -- 50 characters
UNION
SELECT CAST(REPLICATE('L', 100) AS VARCHAR(100))  -- 100 characters
ORDER BY Result
GO

SELECT 
    CASE 1
        WHEN 1 THEN CAST(REPLICATE('S', 10) AS VARCHAR(10))  -- 10 characters
        WHEN 2 THEN CAST(REPLICATE('M', 50) AS VARCHAR(50))  -- 50 characters
        ELSE CAST(REPLICATE('L', 100) AS VARCHAR(100))  -- 100 characters
    END AS VarcharTypmod_Case;
GO

SELECT 
    COALESCE(
        CAST(REPLICATE('S', 10) AS VARCHAR(10)),  -- 10 characters
        CAST(REPLICATE('M', 50) AS VARCHAR(50)),  -- 50 characters
        CAST(REPLICATE('L', 100) AS VARCHAR(100))  -- 100 characters
    ) AS VarcharTypmod_Coalesce;
GO

-- Test 5: Testing NVARCHAR with different typmods
SELECT CAST(REPLICATE(N'S', 10) AS NVARCHAR(10)) AS Result  -- 10 characters
UNION
SELECT CAST(REPLICATE(N'M', 50) AS NVARCHAR(50))  -- 50 characters
UNION
SELECT CAST(REPLICATE(N'L', 100) AS NVARCHAR(100))  -- 100 characters
ORDER BY Result
GO

-- Test 6: Mixed string types with different lengths
SELECT CAST(REPLICATE('S', 10) AS VARCHAR(10)) AS Result  -- 10 characters
UNION
SELECT CAST(REPLICATE('F', 20) AS CHAR(20))  -- 20 characters
UNION
SELECT CAST(REPLICATE(N'U', 30) AS NVARCHAR(30))  -- 30 characters
UNION
SELECT CAST(REPLICATE(N'N', 40) AS NCHAR(40))  -- 40 characters
ORDER BY Result
GO

-- Test 7: INTERSECT with string and binary types
SELECT CAST('Fixed String' AS CHAR(20)) AS Result
INTERSECT
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
INTERSECT
SELECT CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
ORDER BY Result
GO

-- Test 8: EXCEPT with string and binary types
SELECT CAST(N'Unicode String' AS NVARCHAR(50)) AS Result
EXCEPT
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
EXCEPT
SELECT CAST(0x414243 AS VARBINARY(50))  -- VARBINARY(50)
ORDER BY Result
GO

-- Test 9: VALUES with mixed string types
SELECT v.Result
FROM (
    VALUES 
        (CAST(REPLICATE('S', 10) AS VARCHAR(10))),  -- 10 characters
        (CAST(REPLICATE('M', 50) AS VARCHAR(50))),  -- 50 characters
        (CAST(REPLICATE('L', 100) AS VARCHAR(100))),  -- 100 characters
        (CAST(0x414243 AS BINARY(10)))  -- 10 bytes
) AS v(Result);
GO

-- Test 10: Complex nested expressions with different string types
SELECT 
    CASE 1
        WHEN 1 THEN 
            COALESCE(
                CAST(REPLICATE('S', 10) AS VARCHAR(10)),  -- 10 characters
                CAST(REPLICATE('M', 50) AS VARCHAR(50)),  -- 50 characters
                CAST(REPLICATE('L', 100) AS VARCHAR(100))  -- 100 characters
            )
        ELSE 
            CAST(0x414243 AS BINARY(10))  -- 10 bytes
    END AS ComplexResult_1,
    
    CASE 1
        WHEN 1 THEN 
            COALESCE(
                CAST(REPLICATE(N'S', 10) AS NVARCHAR(10)),  -- 10 characters
                CAST(REPLICATE(N'M', 50) AS NVARCHAR(50)),  -- 50 characters
                CAST(REPLICATE(N'L', 100) AS NVARCHAR(100))  -- 100 characters
            )
        ELSE 
            CAST(0x414243 AS VARBINARY(50))  -- 50 bytes
    END AS ComplexResult_2;
GO

-- Test 11: Testing TEXT and NTEXT with other string types
SELECT CAST('Regular Text' AS TEXT) AS Result
UNION
SELECT CAST('Small' AS VARCHAR(10))  -- VARCHAR(10)
UNION
SELECT CAST(N'Unicode' AS NVARCHAR(50))  -- NVARCHAR(50)
UNION
SELECT CAST(0x414243 AS VARBINARY(100))  -- VARBINARY(100)
ORDER BY Result
GO

SELECT CAST(N'Unicode Text' AS NTEXT) AS Result
UNION
SELECT CAST('Fixed' AS CHAR(20))  -- CHAR(20)
UNION
SELECT CAST(N'Small' AS NVARCHAR(10))  -- NVARCHAR(10)
UNION
SELECT CAST(0x414243 AS BINARY(10))  -- BINARY(10)
ORDER BY Result
GO

-- Test 12: ISNULL with different string lengths
SELECT 
    ISNULL(CAST(REPLICATE('S', 10) AS VARCHAR(10)), 
           CAST(REPLICATE('L', 100) AS VARCHAR(100))) AS Result1,  -- 10 vs 100 characters
    ISNULL(CAST(REPLICATE(N'S', 10) AS NVARCHAR(10)), 
           CAST(REPLICATE(N'L', 100) AS NVARCHAR(100))) AS Result2;  -- 10 vs 100 characters
GO

-- Additional tests with exact length strings
-- Test with VARCHAR
SELECT 
    CASE 1
        WHEN 1 THEN CAST(REPLICATE('A', 20) AS VARCHAR(20))  -- Exactly 20 characters
        WHEN 2 THEN CAST(REPLICATE('B', 30) AS VARCHAR(30))  -- Exactly 30 characters
        WHEN 3 THEN CAST(REPLICATE('C', 40) AS VARCHAR(40))  -- Exactly 40 characters
    END AS ExactLength_Varchar;
GO

-- Test with NVARCHAR
SELECT 
    COALESCE(
        CAST(REPLICATE(N'X', 15) AS NVARCHAR(15)),  -- Exactly 15 characters
        CAST(REPLICATE(N'Y', 25) AS NVARCHAR(25)),  -- Exactly 25 characters
        CAST(REPLICATE(N'Z', 35) AS NVARCHAR(35))   -- Exactly 35 characters
    ) AS ExactLength_Nvarchar;
GO

-- Test with CHAR and NCHAR
SELECT CAST(REPLICATE('A', 10) AS CHAR(10)) AS Result  -- Exactly 10 characters
UNION
SELECT CAST(REPLICATE(N'B', 10) AS NCHAR(10))  -- Exactly 10 characters
UNION
SELECT CAST(REPLICATE('C', 10) AS VARCHAR(10))  -- Exactly 10 characters
UNION
SELECT CAST(REPLICATE(N'D', 10) AS NVARCHAR(10))  -- Exactly 10 characters
ORDER BY Result
GO

-- Test with binary types of exact lengths
SELECT CAST(REPLICATE('X', 20) AS VARCHAR(20)) AS Result  -- Exactly 20 characters
UNION
SELECT CAST(CAST(REPLICATE(0x41, 20) AS BINARY(20)) AS VARCHAR(20))  -- Exactly 20 bytes
UNION
SELECT CAST(CAST(REPLICATE(0x42, 20) AS VARBINARY(20)) AS VARCHAR(20))  -- Exactly 20 bytes
ORDER BY Result
GO

-- Cleanup
DROP TABLE ImplicitToStringTest
GO
