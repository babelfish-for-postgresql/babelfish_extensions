CREATE VIEW Datetime_view3
AS(
    SELECT 
        CONVERT(DATETIME, CAST(2.5 as BIT)) as re1,
        CONVERT(DATETIME, CAST(2.5 as DECIMAL))as re2,
        CONVERT(DATETIME, CAST(2.5 as NUMERIC(30,8)))as re3,
        CONVERT(DATETIME, CAST(2.5 as FLOAT))as re4,
        CONVERT(DATETIME, CAST(2.5 as REAL))as re5,
        CONVERT(DATETIME, CAST(2.5 as INT))as re6,
        CONVERT(DATETIME, CAST(2.5 as BIGINT))as re7,
        CONVERT(DATETIME, CAST(2.5 as SMALLINT))as re8,
        CONVERT(DATETIME, CAST(2.5 as TINYINT))as re9,
        CONVERT(DATETIME, CAST(2.5 as MONEY))as re10,
        CONVERT(DATETIME, CAST(2.5 as SMALLMONEY))as re11,
        CONVERT(DATETIME, CAST(-2.5 as BIT)) as re12,
        CONVERT(DATETIME, CAST(-2.5 as DECIMAL))as re13,
        CONVERT(DATETIME, CAST(-2.5 as NUMERIC(30,8)))as re14,
        CONVERT(DATETIME, CAST(-2.5 as FLOAT))as re15,
        CONVERT(DATETIME, CAST(-2.5 as REAL))as re16,
        CONVERT(DATETIME, CAST(-2.5 as INT))as re17,
        CONVERT(DATETIME, CAST(-2.5 as BIGINT))as re18,
        CONVERT(DATETIME, CAST(-2.5 as SMALLINT))as re19,
        CONVERT(DATETIME, CAST(-2.5 as MONEY))as re20,
        CONVERT(DATETIME, CAST(-2.5 as SMALLMONEY))as re21,
        CONVERT(DATETIME, NULL)as res22
);
GO

CREATE VIEW Datetime_view4
AS(
    SELECT 
        CONVERT(SMALLDATETIME, CAST(2.5 as BIT)) as re1,
        CONVERT(SMALLDATETIME, CAST(2.5 as DECIMAL)) as re2,
        CONVERT(SMALLDATETIME, CAST(2.5 as NUMERIC(30,8))) as re3,
        CONVERT(SMALLDATETIME, CAST(2.5 as FLOAT)) as re4,
        CONVERT(SMALLDATETIME, CAST(2.5 as REAL)) as re5,
        CONVERT(SMALLDATETIME, CAST(2.5 as INT)) as re6,
        CONVERT(SMALLDATETIME, CAST(2.5 as BIGINT)) as re7,
        CONVERT(SMALLDATETIME, CAST(2.5 as SMALLINT)) as re8,
        CONVERT(SMALLDATETIME, CAST(2.5 as TINYINT)) as re9,
        CONVERT(SMALLDATETIME, CAST(2.5 as MONEY)) as re10,
        CONVERT(SMALLDATETIME, CAST(2.5 as SMALLMONEY)) as re11,
        CONVERT(SMALLDATETIME, CAST(-2.5 as BIT)) as re12,
        CONVERT(SMALLDATETIME, NULL) as res13
);
GO

-- Should all fail
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as DECIMAL))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as NUMERIC(30,8)))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as FLOAT))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as REAL))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as INT))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as BIGINT))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as SMALLINT))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as MONEY))
GO
SELECT CONVERT(SMALLDATETIME, CAST(-2.5 as SMALLMONEY))
GO


CREATE VIEW Datetime_view5 as (
    SELECT 
        DATEADD(minute, CAST(1 as DECIMAL), CAST(2.5 as DECIMAL)) as re1,
        DATEADD(minute, CAST(1 as NUMERIC(30,8)), CAST(2.5 as NUMERIC(30,8))) as re2,
        DATEADD(minute, CAST(1 as FLOAT), CAST(2.5 as FLOAT)) as re3,
        DATEADD(minute, CAST(1 as REAL), CAST(2.5 as REAL)) as re4,
        DATEADD(minute, CAST(1 as INT), CAST(2.5 as INT)) as re5,
        DATEADD(minute, CAST(1 as BIGINT), CAST(2.5 as BIGINT)) as re6,
        DATEADD(minute, CAST(1 as SMALLINT), CAST(2.5 as SMALLINT)) as re7,
        DATEADD(minute, CAST(1 as TINYINT), CAST(2.5 as TINYINT)) as re8,
        DATEADD(minute, CAST(1 as MONEY), CAST(2.5 as MONEY)) as re9,
        DATEADD(minute, CAST(1 as SMALLMONEY), CAST(2.5 as SMALLMONEY)) as re10,
        DATEADD(minute, CAST(-1 as DECIMAL), CAST(-2.5 as DECIMAL)) as re11,
        DATEADD(minute, CAST(-1 as NUMERIC(30,8)), CAST(-2.5 as NUMERIC(30,8))) as re12,
        DATEADD(minute, CAST(-1 as FLOAT), CAST(-2.5 as FLOAT)) as re13,
        DATEADD(minute, CAST(-1 as REAL), CAST(-2.5 as REAL)) as re14,
        DATEADD(minute, CAST(-1 as INT), CAST(-2.5 as INT)) as re15,
        DATEADD(minute, CAST(-1 as BIGINT), CAST(-2.5 as BIGINT)) as re16,
        DATEADD(minute, CAST(-1 as SMALLINT), CAST(-2.5 as SMALLINT)) as re17,
        DATEADD(minute, CAST(-1 as MONEY), CAST(-2.5 as MONEY)) as re18,
        DATEADD(minute, CAST(-1 as SMALLMONEY), CAST(-2.5 as SMALLMONEY)) as re19
);
GO

CREATE PROCEDURE Datetime_proc1 (@a DATETIME, @b BIT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc1 (@a SMALLDATETIME, @b BIT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE VIEW dateadd_numeric_representation_helper_year_view AS
SELECT 
dateadd_numeric_representation_helper('year',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('year',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('year',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('year',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('year',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('year',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('year',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('year',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('year',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_quarter_view AS
SELECT 
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('quarter',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_month_view AS
SELECT 
dateadd_numeric_representation_helper('month',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('month',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('month',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('month',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('month',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('month',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('month',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('month',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('month',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_dayofyear_view AS
SELECT 
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('dayofyear',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_day_view AS
SELECT 
dateadd_numeric_representation_helper('day',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('day',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('day',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('day',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('day',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('day',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('day',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('day',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('day',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_week_view AS
SELECT 
dateadd_numeric_representation_helper('week',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('week',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('week',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('week',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('week',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('week',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('week',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('week',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('week',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_weekday_view AS
SELECT 
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('weekday',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_hour_view AS
SELECT 
dateadd_numeric_representation_helper('hour',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('hour',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_minute_view AS
SELECT 
dateadd_numeric_representation_helper('minute',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('minute',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_second_view AS
SELECT 
dateadd_numeric_representation_helper('second',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('second',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('second',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('second',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('second',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('second',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('second',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('second',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('second',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO

CREATE VIEW dateadd_numeric_representation_helper_millisecond_view AS
SELECT 
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as BIGINT)) AS BIT_INT,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as INT)) AS REG_INT,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as SMALLINT)) AS SMALL_INT,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as TINYINT)) AS TINY_INT,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as NUMERIC)) AS NUMERIC_REP,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as FLOAT)) AS FLOAT_REP,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as REAL)) AS REAL_REP,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as MONEY)) AS MONEY_REP,
dateadd_numeric_representation_helper('millisecond',1,cast(1.5 as SMALLMONEY)) AS SMALLMONEY_REP
GO


CREATE VIEW dateadd_view_1 AS
SELECT * FROM sys.dateadd('year',1,cast(1.5 as REAL))
GO

CREATE VIEW dateadd_view_2 AS
SELECT * FROM sys.dateadd('year',1,cast(1.5 as NUMERIC(30,8)))
GO

CREATE VIEW dateadd_view_3 AS
SELECT * FROM sys.dateadd('year',1,cast(1.5 as DECIMAL))
GO

CREATE VIEW dateadd_view_4 AS
SELECT * FROM sys.dateadd('year',1,cast(1 as BIT))
GO

CREATE VIEW dateadd_view_5 AS
SELECT * FROM sys.dateadd('year',1,cast(1.5 as FLOAT))
GO

CREATE VIEW dateadd_view_6 AS
SELECT * FROM sys.dateadd('year',1,cast(1.5 as FLOAT))
GO
