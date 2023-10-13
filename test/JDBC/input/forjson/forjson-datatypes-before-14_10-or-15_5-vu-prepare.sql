-- DIFFERENT CASES TO CHECK DATATYPES
-- Exact Numerics
CREATE TABLE forjson_datatypes_vu_t_exact_numerics(abigint bigint, abit bit, adecimal decimal, aint int, amoney money, anumeric numeric, asmallint smallint, asmallmoney smallmoney, atinyint tinyint)
GO
INSERT forjson_datatypes_vu_t_exact_numerics VALUES(9223372036854775807, 1, 123.2, 2147483647, 3148.29, 12345.12, 32767, 3148.29, 255)
GO

-- Approximate numerics
CREATE TABLE forjson_datatypes_vu_t_approx_numerics(afloat float, areal real)
GO
INSERT forjson_datatypes_vu_t_approx_numerics VALUES(12.05, 120.53)
GO

-- Date and time
CREATE TABLE forjson_datatypes_vu_t_date_and_time(atime time, adate date, asmalldatetime smalldatetime, adatetime datetime, adatetime2 datetime2, adatetimeoffset datetimeoffset, adatetimeoffset_2 datetimeoffset)
GO
INSERT forjson_datatypes_vu_t_date_and_time VALUES('2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560', '2012-10-12 12:34:56 +02:30')
GO

-- Character strings
CREATE TABLE forjson_datatypes_vu_t_strings(achar char, avarchar varchar(3), atext text)
GO
INSERT forjson_datatypes_vu_t_strings VALUES('a','abc','abc')
GO

-- Unicode character strings
CREATE TABLE forjson_datatypes_vu_t_unicode_strings(anchar nchar(5), anvarchar nvarchar(5), antext ntext)
GO
INSERT forjson_datatypes_vu_t_unicode_strings VALUES('abc','abc','abc')
GO

-- T-SQL does not allow raw scalars as the output of a view, so surround the FOR JSON call with a SELECT to avoid a syntax error
-- Exact Numerics
CREATE VIEW forjson_datatypes_vu_v_numerics AS
SELECT
(
    SELECT abigint, adecimal, aint, anumeric, asmallint, atinyint 
    FROM forjson_datatypes_vu_t_exact_numerics
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_bit AS
SELECT
(
    SELECT abit 
    FROM forjson_datatypes_vu_t_exact_numerics
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_money AS
SELECT
(
    SELECT amoney 
    FROM forjson_datatypes_vu_t_exact_numerics
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_smallmoney AS
SELECT
(
    SELECT asmallmoney
    FROM forjson_datatypes_vu_t_exact_numerics
    FOR JSON PATH
) as c1;
GO

-- Approximate numerics
CREATE VIEW forjson_datatypes_vu_v_approx_numerics AS
SELECT
(
    SELECT *
    FROM forjson_datatypes_vu_t_approx_numerics
    FOR JSON PATH
) as c1;
GO

-- Date and time
CREATE VIEW forjson_datatypes_vu_v_time_date AS
SELECT
(
    SELECT atime,adate 
    FROM forjson_datatypes_vu_t_date_and_time
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_smalldatetime AS
SELECT
(
    SELECT asmalldatetime
    FROM forjson_datatypes_vu_t_date_and_time
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_datetime AS
SELECT
(
    SELECT adatetime 
    FROM forjson_datatypes_vu_t_date_and_time
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_datetime2 AS
SELECT
(
    SELECT adatetime2 
    FROM forjson_datatypes_vu_t_date_and_time
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_datetimeoffset AS
SELECT
(
    SELECT adatetimeoffset, adatetimeoffset_2
    FROM forjson_datatypes_vu_t_date_and_time
    FOR JSON PATH
) as c1;
GO

-- Character strings
CREATE VIEW forjson_datatypes_vu_v_strings AS
SELECT
(
    SELECT * 
    FROM forjson_datatypes_vu_t_strings
    FOR JSON PATH
) as c1;
GO

-- Unicode character strings
CREATE VIEW forjson_datatypes_vu_v_unicode_strings AS
SELECT
(
    SELECT * 
    FROM forjson_datatypes_vu_t_unicode_strings
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_nulldatetime AS
SELECT
(
    select cast(null as datetime) for JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_nullsmalldatetime AS
SELECT
(
    select cast(null as smalldatetime) for JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_nulldatetime2 AS
SELECT
(
    select cast(null as datetime2) for JSON PATH
) as c1;
GO

CREATE VIEW forjson_datatypes_vu_v_nulldatetimeoffset AS
SELECT
(
    select cast(null as datetimeoffset) for JSON PATH
) as c1;
GO