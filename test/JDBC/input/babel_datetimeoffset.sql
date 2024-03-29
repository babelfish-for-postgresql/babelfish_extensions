-- Testing inserting into the table
create table datetimeoffset_testing (df datetimeoffset);
go
INSERT INTO datetimeoffset_testing VALUES('23:40:29.998');
go
INSERT INTO datetimeoffset_testing VALUES('1900-01-01 00:00+0:00');
go
INSERT INTO datetimeoffset_testing VALUES('0001-01-01 00:00:00 +0:00');
go
INSERT INTO datetimeoffset_testing VALUES('2020-03-15 09:00:00 +8:00');
go
INSERT INTO datetimeoffset_testing VALUES('2020-03-15 09:00:00 +9:00');
go
INSERT INTO datetimeoffset_testing VALUES('1800-03-15 09:00:00 +12:00');
go
INSERT INTO datetimeoffset_testing VALUES('2020-03-15 09:00:00 -8:20');
go
INSERT INTO datetimeoffset_testing VALUES('1992-03-15 09:00:00');
go
-- out of range
INSERT INTO datetimeoffset_testing VALUES('10000-01-01 00:00:00 +0:00');
go
select * from datetimeoffset_testing;
go
CREATE INDEX df_hash ON datetimeoffset_testing (df);
go

-- Test comparision with datetime/smalldatetime/date
select * from datetimeoffset_testing where df >= '2020-03-15 00:00:00';
go
select * from datetimeoffset_testing where df >= '2020-03-15 09:00:00 +7';
go
select * from datetimeoffset_testing where df >= '2020-03-15 09:00:00 +8' 
                    and df < '2020-03-15 09:00:00';
go
select * from datetimeoffset_testing where df < '1992-05-24';
go

-- Test datetimeoffset default value
create table t1 (a datetimeoffset, b int);
go
insert into t1 (b) values (1);
go
select a from t1 where b = 1;
go

-- Testing rounding for different typmod
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset);
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(0));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(1));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(2));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(3));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(4));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(5));
go
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(6));
go
-- Testing edge cases
select CAST('1900-06-06 20:00:00.499 +0:00' AS datetimeoffset(0));
go
select CAST('1900-06-06 20:00:00.500 +0:00' AS datetimeoffset(0));
go
select CAST('1900-06-06 20:00:00.501 +0:00' AS datetimeoffset(0));
go
select CAST('2079-06-06 20:00:00.499 +0:00' AS datetimeoffset(0));
go
select CAST('2079-06-06 20:00:00.500 +0:00' AS datetimeoffset(0));
go
select CAST('2079-06-06 20:00:00.501 +0:00' AS datetimeoffset(0));
go
select CAST('1979-06-06 20:00:00.000499 +0:00' AS datetimeoffset(3));
go
select CAST('1979-06-06 20:00:00.000500 +0:00' AS datetimeoffset(3));
go
select CAST('1979-06-06 20:00:00.000501 +0:00' AS datetimeoffset(3));
go
select CAST('2079-06-06 20:00:00.000499 +0:00' AS datetimeoffset(3));
go
select CAST('2079-06-06 20:00:00.000500 +0:00' AS datetimeoffset(3));
go
select CAST('2079-06-06 20:00:00.000501 +0:00' AS datetimeoffset(3));
go
select CAST('1979-06-06 20:00:00.000049 +0:00' AS datetimeoffset(4));
go
select CAST('1979-06-06 20:00:00.000050 +0:00' AS datetimeoffset(4));
go
select CAST('1979-06-06 20:00:00.000051 +0:00' AS datetimeoffset(4));
go
select CAST('2079-06-06 20:00:00.000049 +0:00' AS datetimeoffset(4));
go
select CAST('2079-06-06 20:00:00.000050 +0:00' AS datetimeoffset(4));
go
select CAST('2079-06-06 20:00:00.000051 +0:00' AS datetimeoffset(4));
go
select CAST('1979-06-06 20:00:00.000004 +0:00' AS datetimeoffset(5));
go
select CAST('1979-06-06 20:00:00.000005 +0:00' AS datetimeoffset(5));
go
select CAST('2079-06-06 20:00:00.000004 +0:00' AS datetimeoffset(5));
go
select CAST('2079-06-06 20:00:00.000005 +0:00' AS datetimeoffset(5));
go
-- out of range
select CAST('2079-06-06 23:59:29.123456 -9:30' AS datetimeoffset(7));
go

-- Test type cast to/from other time formats
-- Test datetime/dateime2
select CAST(CAST('2020-03-15 23:59:29.99' AS datetime) AS datetimeoffset);
go
select CAST(CAST('2079-06-06 23:59:29.998 +8:00' AS datetimeoffset) AS datetime);
go
select CAST(CAST('2079-06-06 23:59:29.998 -9:30' AS datetimeoffset) AS datetime);
go
select CAST(CAST('1920-05-25 00:59:29.99' AS datetime2) AS datetimeoffset);
go
select CAST(CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) AS datetime2);
go

-- Test date
select CAST(CAST('1999-12-31' AS date) AS datetimeoffset);
go
select CAST(CAST('0001-12-31' AS date) AS datetimeoffset);
go
select CAST(CAST('2000-01-01 23:59:59.999' AS datetimeoffset) AS date);
go
select CAST(CAST('2000-01-01 23:59:59.999+8' AS datetimeoffset) AS date);
go
select CAST(CAST('1900-05-06 23:59:29.998+8:20' AS datetimeoffset) AS date);
go
-- out of range
select CAST(CAST('12000-01-01' AS date) AS datetimeoffset);
go

-- Test time
select CAST(CAST('23:59:59.999' AS time) AS datetimeoffset);
go
select CAST(CAST('00:30:31' AS time) AS datetimeoffset);
go
select CAST(CAST('1900-05-06 23:59:29.998+8:00' AS datetimeoffset) AS time);
go
select CAST(CAST('1920-05-25 00:59:29.99 +0' AS datetimeoffset) AS time);
go
select CAST(CAST('2050-05-06 00:00:00 +0' AS datetimeoffset) AS time);
go
select CAST(CAST('2050-05-06 12:00:00 +0' AS datetimeoffset) AS time);
go
select CAST(CAST('2050-05-06 15:31:22 +0' AS datetimeoffset) AS time);
go
select CAST(CAST('2050-05-06 23:59:29.998+8:00' AS datetimeoffset) AS time);
go

-- Test smalldatetime
select CAST(CAST('2000-06-06 23:59:29.998 -9:30' AS datetimeoffset) AS smalldatetime);
go
select CAST(CAST('2079-06-06 23:59:29.998 +8:00' AS datetimeoffset) AS smalldatetime);
go
select CAST(CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) AS smalldatetime);
go
select CAST(CAST('2020-03-15 23:59:29.99' AS smalldatetime) AS datetimeoffset);
go
select CAST(CAST('1920-05-25 00:59:29.99' AS smalldatetime) AS datetimeoffset);
go
-- out of range
select CAST(CAST('8000-05-25 00:59:29.99' AS smalldatetime) AS datetimeoffset);
go

-- Test datetimeoffset value ranges
select cast('0001-01-01 +0' as datetimeoffset);
go
select cast('0001-01-01 -1' as datetimeoffset);
go 
select cast('2079-06-06 23:59:29.998 +0' as datetimeoffset);
go
select cast('9999-12-31 23:59:29.998 +0' as datetimeoffset);
go
-- out of range
select cast('0001-01-01 +0 BC' as datetimeoffset);
go
-- out of range
select cast('0001-01-01 +1' as datetimeoffset);
go
-- out of range
select cast('0001-01-01 +0:20' as datetimeoffset);
go
-- out of range
select cast('9999-12-31 23:59:29.998 -1' as datetimeoffset);
go
-- out of range
select cast('10000-01-01 00:00' as datetimeoffset);
go

-- Testing arithmetic operators
-- Testing datetimeoffset adding interval
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(1);
go
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0,1);
go
select CAST('1900-01-30 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0,1);
go
select CAST('1900-12-31 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0,1);
go
select CAST('2000-02-29 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(1,0);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0,1,3);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0,0,1);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(1,0,3);
go
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(1, 2, 3, 4, 5, 6, 7);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(1, 2, 3, 4, 5, 6, 7);
go
-- SQL Server does not support named parameters in functions, only in prodecures
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0, 0, 0, 0, 0, 70);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) + make_interval(0, 0, 0, 0, 0, -70);
go
-- Testing interval adding datetimeoffset
select make_interval(1) + CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset);
go
select make_interval(1, 2, 3, 4, 5, 6, 7) + CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) ;
go
select make_interval(0, 0, 0, 0, 0, 70) + CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset);
go
-- Testing datetimeoffset subtracting interval
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1);
go
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0,1);
go
select CAST('1900-01-31 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0,1);
go
select CAST('2000-02-29 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1,0);
go
select CAST('2000-03-31 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1,0);
go
select CAST('2050-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0,1,3);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0,0,1);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1,0,3);
go
select CAST('1900-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1, 2, 3, 4, 5, 6, 7);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(1, 2, 3, 4, 5, 6, 7);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0, 0, 0, 0, 0, 70);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - make_interval(0, 0, 0, 0, 0, -70);
go
-- Testing datetimeoffset subtracting datetimeoffset
select CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) - CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - CAST('2030-05-06 13:59:29.998 +8:20' AS datetimeoffset);
go
select CAST('2030-05-06 13:59:29.998 -8:00' AS datetimeoffset) - CAST('1992-05-06 13:20:29.998 +0:00' AS datetimeoffset);
go
select CAST('0001-05-06 13:59:29.998 -8:00' AS datetimeoffset) - CAST('9950-05-06 13:20:29.998 +0:00' AS datetimeoffset);
go

-- Test date functions
select ISDATE('2030-05-06 13:59:29.998 -8:00');
go
-- TODO Fix [BABEL-883] missing TDS support for type regtype (was pg_typeof produces error in sqlcmd)
select pg_typeof(sysdatetimeoffset());
go
-- TODO:[BABEL-739] DATETIMEOFFSETFROMPARTS()
-- TOOD:[BABEL-740] TODATETIMEOFFSET()
-- TODO:[BABEL-744] SWITCHOFFSET()

-- Test data type precedence
select pg_typeof(c1) FROM (SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1 UNION SELECT CAST('2016-12-26 23:30:05' AS datetime) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1 UNION SELECT CAST('2016-12-26 23:30:05' AS datetime2) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1 UNION SELECT CAST('2016-12-26 23:30:05' AS smalldatetime) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1 UNION SELECT CAST('23:30:05' AS time) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1 UNION SELECT CAST('2016-12-26' AS date) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2016-12-26 23:30:05' AS datetime) as C1 UNION SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset)as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2016-12-26 23:30:05' AS datetime2) as C1 UNION SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2016-12-26 23:30:05' AS smalldatetime) as C1 UNION SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('23:30:05' AS time) as C1 UNION SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1) T;
go
select pg_typeof(c1) FROM (SELECT CAST('2016-12-26' AS date) as C1 UNION SELECT CAST('2030-05-06 13:59:29.998 +0:00' AS datetimeoffset) as C1) T;
go

-- test casting datetimeoffset inside procedure
-- NOTE: This is not supported behavior in tsql and will fail
CREATE PROCEDURE cast_datetimeoffset (@val datetimeoffset) AS
BEGIN
    DECLARE @DF datetimeoffset = @val
    PRINT @DF
    PRINT cast(@DF as datetimeoffset(5))
END;
go
DECLARE @dto datetimeoffset = CAST('2030-05-06 13:39:29.123456 +0:00' AS datetimeoffset);
exec cast_datetimeoffset @dto;
go
DECLARE @dto datetimeoffset = CAST('1920-05-06 13:39:29.123456 +0:00' AS datetimeoffset);
exec cast_datetimeoffset @dto;
go
-- expect error
DECLARE @dto datetimeoffset = CAST('19200-05-06 13:39:29.123456 +0:00' AS datetimeoffset);
exec cast_datetimeoffset @dto;
go

-- test comparing datetimeoffset inside procedure
CREATE PROCEDURE cmp_datetimeoffset (@val datetimeoffset) AS
BEGIN
    IF @val > CAST('2000-01-01 13:39:29.123456 +0:00' AS datetimeoffset)
        PRINT @val - make_interval(1)
    ELSE
        PRINT @val + make_interval(1)
END;
go
DECLARE @dto datetimeoffset = CAST('2030-05-06 13:39:29.123456 +0:00' AS datetimeoffset);
exec cmp_datetimeoffset @dto;
go
DECLARE @dto datetimeoffset = CAST('1930-05-06 13:39:29.123456 +0:00' AS datetimeoffset);
exec cmp_datetimeoffset @dto;
go

DECLARE @lvDateEastern DATETIME, @lvDateUTC DATETIME
SET @lvDateUTC = '2021-01-01'
SET @lvDateEastern = @lvDateUTC AT TIME ZONE  'UTC' AT TIME ZONE 'US Eastern Standard Time'
SELECT @lvDateUTC, @lvDateEastern
go

DECLARE @lvDateEastern DATETIME2, @lvDateUTC DATETIME
SET @lvDateUTC = '2021-01-01'
SET @lvDateEastern = @lvDateUTC AT TIME ZONE  'UTC' AT TIME ZONE 'US Eastern Standard Time'
SELECT @lvDateUTC, @lvDateEastern
go

DECLARE @lvDateEastern SMALLDATETIME, @lvDateUTC DATETIME
SET @lvDateUTC = '2021-01-01'
SET @lvDateEastern = @lvDateUTC AT TIME ZONE  'UTC' AT TIME ZONE 'US Eastern Standard Time'
SELECT @lvDateUTC, @lvDateEastern
go

DECLARE @lvDateEastern DATE, @lvDateUTC DATETIME
SET @lvDateUTC = '2021-01-01'
SET @lvDateEastern = @lvDateUTC AT TIME ZONE  'UTC' AT TIME ZONE 'US Eastern Standard Time'
SELECT @lvDateUTC, @lvDateEastern
go

DECLARE @lvDateEastern TIME, @lvDateUTC DATETIME
SET @lvDateUTC = '2021-01-01'
SET @lvDateEastern = @lvDateUTC AT TIME ZONE  'UTC' AT TIME ZONE 'US Eastern Standard Time'
SELECT @lvDateUTC, @lvDateEastern
go

Create table implicit_cast ( a datetime)
go
insert into implicit_cast values (cast('1900-05-06 13:59:29.998 -8:00' as datetimeoffset))
go
Select * from implicit_cast
go

-- Clean up
drop table datetimeoffset_testing;
go
drop table t1;
go
drop table implicit_cast;
go
drop procedure cast_datetimeoffset;
go
drop procedure cmp_datetimeoffset;
go
