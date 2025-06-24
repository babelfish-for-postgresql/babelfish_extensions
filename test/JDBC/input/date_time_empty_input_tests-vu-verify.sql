-- Test support for empty input string casts to DATE and TIME datatypes

-- Test direct casts
SELECT CAST('' AS date) AS empty_string_date;
SELECT CAST(' ' AS date) AS space_string_date;
GO

SELECT CAST('' AS time) AS empty_string_time;
SELECT CAST(' ' AS time) AS space_string_time;
GO


-- Test DECLARE and variable assignment
DECLARE @d1 date, @d2 date;
SET @d1 = '';                          -- Empty string
SET @d2 = '    ';                      -- Spaces
SELECT @d1 AS empty, @d2 AS spaces;
GO

DECLARE @t1 time, @t2 time;
SET @t1 = '';                          -- Empty string
SET @t2 = '    ';                      -- Spaces
SELECT @t1 AS empty, @t2 AS spaces;
GO


-- Test table insertions
INSERT INTO test_empty_strings VALUES 
(1, '', ''),                            -- Empty strings
(2, '   ', '   ');                      -- Spaces
GO

SELECT * FROM test_empty_strings;
GO


-- Test casts from declared string variables with whitespace
DECLARE @varchar_empty varchar(10) = '';
DECLARE @varchar_spaces varchar(10) = '          ';
DECLARE @nvarchar_empty nvarchar(10) = N'';
DECLARE @nvarchar_spaces nvarchar(10) = N'          ';

SELECT 
    CAST(@varchar_empty AS date) AS empty_varchar_to_date,
    CAST(@nvarchar_empty AS date) AS empty_nvarchar_to_date,
    CAST(@varchar_spaces AS date) AS varchar_to_date,
    CAST(@nvarchar_spaces AS date) AS nvarchar_to_date,
    CAST(@varchar_empty AS time) AS empty_varchar_to_time,
    CAST(@nvarchar_empty AS time) AS empty_nvarchar_to_time,
    CAST(@varchar_spaces AS time) AS varchar_to_time,
    CAST(@nvarchar_spaces AS time) AS nvarchar_to_time;
GO

SELECT CAST(CAST('' AS VARCHAR) AS DATE) AS empty_varchar_date;
SELECT CAST(CAST('   ' AS VARCHAR(10)) AS DATE) AS spaces_varchar_date;
GO

SELECT CAST(CAST('' AS VARCHAR) AS TIME) AS empty_varchar_time;
SELECT CAST(CAST('   ' AS VARCHAR(1)) AS TIME) AS spaces_varchar_time;
GO


-- Test whitespace date casts to other datetime datatypes
select CAST(CAST(' ' AS date) AS datetime)
go

select CAST(CAST(' ' AS date) AS datetime2)
go

select CAST(CAST(' ' AS date) AS smalldatetime)
go

select CAST(CAST(' ' AS date) AS datetimeoffset)
go

-- Test whitespace time casts to other datetime datatypes
select CAST(CAST(' ' AS time) AS datetime)
go

select CAST(CAST(' ' AS time) AS datetime2)
go

select CAST(CAST(' ' AS time) AS smalldatetime)
go

select CAST(CAST(' ' AS time) AS datetimeoffset)
go


-- Test with views
SELECT * FROM empty_string_date_time_view;
GO

SELECT * FROM string_vars_to_date_view;
GO

SELECT * FROM string_vars_to_time_view;
GO


-- Test in computed columns
CREATE TABLE #test_computed (
    str_col varchar(10),
    date_col AS CAST(str_col AS date),
    time_col AS CAST(str_col AS time)
);
GO

INSERT INTO #test_computed (str_col) VALUES 
(''),                   -- Empty string
('   ');                -- Spaces
GO

SELECT * FROM #test_computed;
GO


-- BABEL-5923 - NOT SUPPORTED YET: TAB space
SELECT CAST(CHAR(9) AS date) AS tab_string_date;
GO

SELECT CAST(CHAR(9) AS time) AS tab_string_time;
GO

DECLARE @d3 date;
SET @d3 = CHAR(9);                     -- Tab
SELECT @d3 AS tab;
GO

INSERT INTO test_empty_strings VALUES
(3, CHAR(9), CHAR(9));
GO

SELECT * FROM test_empty_strings WHERE id = 3;
GO

DECLARE @char_tab char(10) = CHAR(9);
DECLARE @nchar_tab nchar(10) = NCHAR(9);
SELECT    
    CAST(@char_tab AS date) AS char_tab_to_date,
    CAST(@char_tab AS time) AS char_tab_to_time,
    CAST(@nchar_tab AS date) AS nchar_tab_to_date,
    CAST(@nchar_tab AS time) AS nchar_tab_to_time;
GO

DECLARE @varchar_tab varchar(10) = CHAR(9);
DECLARE @nvarchar_tab nvarchar(10) = NCHAR(9);
SELECT    
    CAST(@varchar_tab AS date) AS varchar_tab_to_date,
    CAST(@varchar_tab AS time) AS varchar_tab_to_time,
    CAST(@nvarchar_tab AS date) AS nvarchar_tab_to_date,
    CAST(@nvarchar_tab AS time) AS nvarchar_tab_to_time;
GO

SELECT CAST(CAST(CHAR(9) AS VARCHAR) AS DATE) AS tab_varchar_date;
SELECT CAST(CAST(CHAR(9) AS VARCHAR(1)) AS TIME) AS tab_varchar_time;
GO

INSERT INTO #test_computed (str_col) VALUES 
(CHAR(9));              -- Tab
GO

SELECT * FROM #test_computed;
GO

DROP TABLE #test_computed;
GO

SELECT * FROM tab_space_dates_view;
GO

-- support for char/nchar casts to date/time
DECLARE @char_empty char(10) = '';
DECLARE @char_spaces char(10) = '          ';
DECLARE @nchar_empty nchar(10) = N'';
DECLARE @nchar_spaces nchar(10) = N'          ';
SELECT    
    CAST(@char_empty AS date) AS char_empty_to_date,
    CAST(@char_spaces AS date) AS char_spaces_to_date,
    CAST(@nchar_empty AS time) AS nchar_empty_to_time,
    CAST(@nchar_spaces AS time) AS nchar_spaces_to_time;
GO


-- support for text/ntext casts to date/time
SELECT    
    CAST(CAST('' AS text) AS date) AS text_empty_to_date,
    CAST(CAST('  ' AS text) AS date) AS text_spaces_to_date,
    CAST(CAST('' AS ntext) AS date) AS ntext_empty_to_date,
    CAST(CAST('  ' AS ntext) AS date) AS ntext_spaces_to_date;
GO

SELECT    
    CAST(CAST('' AS text) AS time) AS text_empty_to_time,
    CAST(CAST('  ' AS text) AS time) AS text_spaces_to_time,
    CAST(CAST('' AS ntext) AS time) AS ntext_empty_to_time,
    CAST(CAST('  ' AS ntext) AS time) AS ntext_spaces_to_time;
GO
