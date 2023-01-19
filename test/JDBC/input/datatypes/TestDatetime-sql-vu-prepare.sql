-- Test sql_variant cast (Test for BABEL-3404)
CREATE VIEW Datetime_view1
AS(
    SELECT 
        CAST(CAST(2.5 as BIT) as DATETIME) as re1,
        CAST(CAST(2.5 as DECIMAL) as DATETIME)as re2,
        CAST(CAST(2.5 as NUMERIC(30,8)) as DATETIME)as re3,
        CAST(CAST(2.5 as FLOAT) as DATETIME)as re4,
        CAST(CAST(2.5 as REAL) as DATETIME)as re5,
        CAST(CAST(2.5 as INT) as DATETIME)as re6,
        CAST(CAST(2.5 as BIGINT) as DATETIME)as re7,
        CAST(CAST(2.5 as SMALLINT) as DATETIME)as re8,
        CAST(CAST(2.5 as TINYINT) as DATETIME)as re9,
        CAST(CAST(2.5 as MONEY) as DATETIME)as re10,
        CAST(CAST(2.5 as SMALLMONEY) as DATETIME)as re11,
        CAST(CAST(-2.5 as BIT) as DATETIME) as re12,
        CAST(CAST(-2.5 as DECIMAL) as DATETIME)as re13,
        CAST(CAST(-2.5 as NUMERIC(30,8)) as DATETIME)as re14,
        CAST(CAST(-2.5 as FLOAT) as DATETIME)as re15,
        CAST(CAST(-2.5 as REAL) as DATETIME)as re16,
        CAST(CAST(-2.5 as INT) as DATETIME)as re17,
        CAST(CAST(-2.5 as BIGINT) as DATETIME)as re18,
        CAST(CAST(-2.5 as SMALLINT) as DATETIME)as re19,
        CAST(CAST(-2.5 as MONEY) as DATETIME)as re20,
        CAST(CAST(-2.5 as SMALLMONEY) as DATETIME)as re21,
        CAST(NULL as DATETIME)as res22
);
GO

CREATE VIEW Datetime_view2
AS(
    SELECT 
        CAST(CAST(2.5 as BIT) as SMALLDATETIME) as re1,
        CAST(CAST(2.5 as DECIMAL) as SMALLDATETIME)as re2,
        CAST(CAST(2.5 as NUMERIC(30,8)) as SMALLDATETIME)as re3,
        CAST(CAST(2.5 as FLOAT) as SMALLDATETIME)as re4,
        CAST(CAST(2.5 as REAL) as SMALLDATETIME)as re5,
        CAST(CAST(2.5 as INT) as SMALLDATETIME)as re6,
        CAST(CAST(2.5 as BIGINT) as SMALLDATETIME)as re7,
        CAST(CAST(2.5 as SMALLINT) as SMALLDATETIME)as re8,
        CAST(CAST(2.5 as TINYINT) as SMALLDATETIME)as re9,
        CAST(CAST(2.5 as MONEY) as SMALLDATETIME)as re10,
        CAST(CAST(2.5 as SMALLMONEY) as SMALLDATETIME)as re11,
        CAST(CAST(-2.5 as BIT) as SMALLDATETIME) as re12,
        CAST(NULL as SMALLDATETIME)as res13
);
GO

-- Should all fail
SELECT CAST(CAST(-2.5 as NUMERIC(30,8)) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as FLOAT) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as REAL) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as INT) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as BIGINT) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as SMALLINT) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as MONEY) as SMALLDATETIME)
GO
SELECT CAST(CAST(-2.5 as SMALLMONEY) as SMALLDATETIME)
GO
       
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
        DATEADD(minute, CAST(1 as BIT), CAST(2.5 as DECIMAL)) as re1,
        DATEADD(minute, CAST(1 as DECIMAL), CAST(2.5 as DECIMAL)) as re2,
        DATEADD(minute, CAST(1 as NUMERIC(30,8)), CAST(2.5 as NUMERIC(30,8))) as re3,
        DATEADD(minute, CAST(1 as FLOAT), CAST(2.5 as FLOAT)) as re4,
        DATEADD(minute, CAST(1 as REAL), CAST(2.5 as REAL)) as re5,
        DATEADD(minute, CAST(1 as INT), CAST(2.5 as INT)) as re6,
        DATEADD(minute, CAST(1 as BIGINT), CAST(2.5 as BIGINT)) as re7,
        DATEADD(minute, CAST(1 as SMALLINT), CAST(2.5 as SMALLINT)) as re8,
        DATEADD(minute, CAST(1 as TINYINT), CAST(2.5 as TINYINT)) as re9,
        DATEADD(minute, CAST(1 as MONEY), CAST(2.5 as MONEY)) as re10,
        DATEADD(minute, CAST(1 as SMALLMONEY), CAST(2.5 as SMALLMONEY)) as re11,
        DATEADD(minute, CAST(-1 as BIT), CAST(-2.5 as BIT)) as re12,
        DATEADD(minute, CAST(-1 as DECIMAL), CAST(-2.5 as DECIMAL)) as re13,
        DATEADD(minute, CAST(-1 as NUMERIC(30,8)), CAST(-2.5 as NUMERIC(30,8))) as re14,
        DATEADD(minute, CAST(-1 as FLOAT), CAST(-2.5 as FLOAT)) as re15,
        DATEADD(minute, CAST(-1 as REAL), CAST(-2.5 as REAL)) as re16,
        DATEADD(minute, CAST(-1 as INT), CAST(-2.5 as INT)) as re17,
        DATEADD(minute, CAST(-1 as BIGINT), CAST(-2.5 as BIGINT)) as re18,
        DATEADD(minute, CAST(-1 as SMALLINT), CAST(-2.5 as SMALLINT)) as re19,
        DATEADD(minute, CAST(-1 as MONEY), CAST(-2.5 as MONEY)) as re20,
        DATEADD(minute, CAST(-1 as SMALLMONEY), CAST(-2.5 as SMALLMONEY)) as re21
);
GO

CREATE VIEW Datetime_view6 as (
    SELECT 
        DATEDIFF(minute, CAST(1 as BIT), CAST(2.5 AS BIT)) as re1,
        DATEDIFF(minute, CAST(1 as DECIMAL), CAST(2.5 AS DECIMAL)) as re2,
        DATEDIFF(minute, CAST(1 as NUMERIC(30,8)), CAST(2.5 AS NUMERIC(30,8))) as re3,
        DATEDIFF(minute, CAST(1 as FLOAT), CAST(2.5 AS FLOAT)) as re4,
        DATEDIFF(minute, CAST(1 as REAL), CAST(2.5 AS REAL)) as re5,
        DATEDIFF(minute, CAST(1 as INT), CAST(2.5 AS INT)) as re6,
        DATEDIFF(minute, CAST(1 as BIGINT), CAST(2.5 AS BIGINT)) as re7,
        DATEDIFF(minute, CAST(1 as SMALLINT), CAST(2.5 AS SMALLINT)) as re8,
        DATEDIFF(minute, CAST(1 as TINYINT), CAST(2.5 AS TINYINT)) as re9,
        DATEDIFF(minute, CAST(1 as MONEY), CAST(2.5 AS MONEY)) as re10,
        DATEDIFF(minute, CAST(1 as SMALLMONEY), CAST(-2.5 AS SMALLMONEY)) as re11,
        DATEDIFF(minute, CAST(-1 as BIT), CAST(-2.5 AS BIT)) as re12,
        DATEDIFF(minute, CAST(-1 as DECIMAL), CAST(-2.5 AS DECIMAL)) as re13,
        DATEDIFF(minute, CAST(-1 as NUMERIC(30,8)), CAST(-2.5 AS NUMERIC(30,8))) as re14,
        DATEDIFF(minute, CAST(-1 as FLOAT), CAST(-2.5 AS FLOAT)) as re15,
        DATEDIFF(minute, CAST(-1 as REAL), CAST(-2.5 AS REAL)) as re16,
        DATEDIFF(minute, CAST(-1 as INT), CAST(-2.5 AS INT)) as re17,
        DATEDIFF(minute, CAST(-1 as BIGINT), CAST(-2.5 AS BIGINT)) as re18,
        DATEDIFF(minute, CAST(-1 as SMALLINT), CAST(-2.5 AS SMALLINT)) as re19,
        DATEDIFF(minute, CAST(-1 as MONEY), CAST(-2.5 AS MONEY)) as re20,
        DATEDIFF(minute, CAST(-1 as SMALLMONEY), CAST(-2.5 AS SMALLMONEY)) as re21
);
GO


CREATE TABLE Datetime_Operators_tbl1 (col DATETIME)
GO
INSERT INTO Datetime_Operators_tbl1 VALUES('1900-01-05 00:00:00.000');
INSERT INTO Datetime_Operators_tbl1 VALUES('1900-01-05 23:40:30.000');
INSERT INTO Datetime_Operators_tbl1 VALUES('1900-01-01 23:40:30.000');
INSERT INTO Datetime_Operators_tbl1 VALUES('1900-01-02 00:00:00.000');
INSERT INTO Datetime_Operators_tbl1 VALUES(NULL);
GO

CREATE TABLE Datetime_Operators_tbl2 (col SMALLDATETIME)
GO
INSERT INTO Datetime_Operators_tbl2 VALUES('1900-01-05 00:00:00.000');
INSERT INTO Datetime_Operators_tbl2 VALUES('1900-01-05 23:40:30.000');
INSERT INTO Datetime_Operators_tbl2 VALUES('1900-01-01 23:40:30.000');
INSERT INTO Datetime_Operators_tbl2 VALUES('1900-01-02 00:00:00.000');
INSERT INTO Datetime_Operators_tbl2 VALUES(NULL);
GO

CREATE TABLE Datetime_tbl1 (c1 DATETIME, c2 as DATEDIFF(day,'1900-01-01 00:00:00.000',c1))
GO

CREATE TABLE Datetime_tbl2 (c1 SMALLDATETIME, c2 as DATEDIFF(day,'1900-01-01 00:00:00.000',c1))
GO

CREATE PROCEDURE Datetime_proc1 (@a DATETIME, @b BIT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc2 (@a DATETIME, @b DECIMAL) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc3 (@a DATETIME, @b NUMERIC(30,8)) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc4 (@a DATETIME, @b FLOAT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc5 (@a DATETIME, @b REAL) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (@a) as result1;
   SELECT (@c) as result2;
END
GO

CREATE PROCEDURE Datetime_proc6 (@a DATETIME, @b INT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc7 (@a DATETIME, @b BIGINT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc8 (@a DATETIME, @b SMALLINT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc9 (@a DATETIME, @b TINYINT) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc10 (@a DATETIME, @b MONEY) AS
BEGIN
   DECLARE @c DATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE Datetime_proc11 (@a DATETIME, @b SMALLMONEY) AS
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

CREATE PROCEDURE SMALLDatetime_proc2 (@a SMALLDATETIME, @b DECIMAL) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc3 (@a SMALLDATETIME, @b NUMERIC(30,8)) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc4 (@a SMALLDATETIME, @b FLOAT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc5 (@a SMALLDATETIME, @b REAL) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (@a) as result1;
   SELECT (@c) as result2;
END
GO

CREATE PROCEDURE SMALLDatetime_proc6 (@a SMALLDATETIME, @b INT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc7 (@a SMALLDATETIME, @b BIGINT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc8 (@a SMALLDATETIME, @b SMALLINT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc9 (@a SMALLDATETIME, @b TINYINT) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc10 (@a SMALLDATETIME, @b MONEY) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO

CREATE PROCEDURE SMALLDatetime_proc11 (@a SMALLDATETIME, @b SMALLMONEY) AS
BEGIN
   DECLARE @c SMALLDATETIME = @b;
   SELECT (CASE WHEN @a = @c THEN 'pass' ELSE 'fail' END) as result;
END
GO


CREATE TABLE Datetime_target_type_table (
    datetimetype datetime,
    smalldatetimetype smalldatetime
);
GO

CREATE TABLE Datetime_source_type_table (
    bittype bit,
    decimaltype decimal,
    numerictype numeric(30,8),
    floattype float,
    realtype real,
    inttype int,
    biginttype bigint,
    smallinttype smallint,
    tinyinttype tinyint, 
    moneytype money, 
    smallmonettype smallmoney, 
    nulltype int
);
GO

INSERT INTO Datetime_target_type_table VALUES ('20120618 10:34:09 AM', '2018-07-24 06:30:50.000');
GO

INSERT INTO Datetime_source_type_table VALUES (0,1.9,2.0,3.1,4.2,5.4,6.2,7,8,9,10,null);
GO

