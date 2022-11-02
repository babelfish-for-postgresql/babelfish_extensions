CREATE PROCEDURE babel_2812_vu_p1 @dt1 VARCHAR(20), @dt2 VARCHAR(20)
AS
SELECT CONVERT(DATETIME, @dt1,14) + @dt2 AS NextTime;
GO

CREATE PROCEDURE babel_2812_vu_p2 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT @dt1 + @dt2 AS NextTime;
GO

CREATE PROCEDURE babel_2812_vu_p3 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT @dt2 - @dt1 AS NextTime;
GO

CREATE PROCEDURE babel_2812_vu_p4 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT DATEADD(day ,DATEDIFF(day, 0, @dt2) ,@dt1) as NextTime;
GO

-- test newly defined function
-- CREATE VIEW babel_2812_vu_v1 AS
-- SELECT datediff_internal_date('day', CAST('20201010' AS DATE), CAST('20201001' AS DATE))
-- GO

-- DATETIME + DATETIME, DATETIME - DATETIME
CREATE VIEW babel_2812_vu_v2 AS
SELECT  (CAST('17:30:00' AS DATETIME) + CAST('20211212' AS DATETIME)) c1, 
        (CAST('20211212' AS DATETIME) - CAST('17:30:00' AS DATETIME)) c2
GO

-- DATETIME + Exact numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v3 AS
SELECT  (CAST('20211212' AS DATETIME) + CAST(55.55 AS BIGINT)) c1, (CAST(55.55 AS BIGINT) + CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS BIT)) c3, (CAST(55.55 AS BIT) + CAST('20211212' AS DATETIME)) c4, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS DECIMAL)) c5, (CAST(55.55 AS DECIMAL) + CAST('20211212' AS DATETIME)) c6, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS INT)) c7, (CAST(55.55 AS INT) + CAST('20211212' AS DATETIME)) c8, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS MONEY)) c9, (CAST(55.55 AS MONEY) + CAST('20211212' AS DATETIME)) c10, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS NUMERIC)) c11, (CAST(55.55 AS NUMERIC) + CAST('20211212' AS DATETIME)) c12, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS SMALLINT)) c13, (CAST(55.55 AS SMALLINT) + CAST('20211212' AS DATETIME)) c14, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS SMALLMONEY)) c15, (CAST(55.55 AS SMALLMONEY) + CAST('20211212' AS DATETIME)) c16, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS TINYINT)) c17, (CAST(55.55 AS TINYINT) + CAST('20211212' AS DATETIME)) c18
GO

-- DATETIME - Exact numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v4 AS
SELECT  (CAST('20211212' AS DATETIME) - CAST(55.55 AS BIGINT)) c1, (CAST(55.55 AS BIGINT) - CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS BIT)) c3, (CAST(55.55 AS BIT) - CAST('20211212' AS DATETIME)) c4, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS DECIMAL)) c5, (CAST(55.55 AS DECIMAL) - CAST('20211212' AS DATETIME)) c6, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS INT)) c7, (CAST(55.55 AS INT) - CAST('20211212' AS DATETIME)) c8, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS MONEY)) c9, (CAST(55.55 AS MONEY) - CAST('20211212' AS DATETIME)) c10, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS NUMERIC)) c11, (CAST(55.55 AS NUMERIC) - CAST('20211212' AS DATETIME)) c12, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS SMALLINT)) c13, (CAST(55.55 AS SMALLINT) - CAST('20211212' AS DATETIME)) c14, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS SMALLMONEY)) c15, (CAST(55.55 AS SMALLMONEY) - CAST('20211212' AS DATETIME)) c16, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS TINYINT)) c17, (CAST(55.55 AS TINYINT) - CAST('20211212' AS DATETIME)) c18
GO

-- DATETIME + Approximate numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v5 AS
SELECT  (CAST('20211212' AS DATETIME) + CAST(55.55 AS FLOAT)) c1, (CAST(55.55 AS FLOAT) + CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) + CAST(55.55 AS REAL)) c3, (CAST(55.55 AS REAL) + CAST('20211212' AS DATETIME)) c4
GO

-- DATETIME - Approximate numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v6 AS
SELECT  (CAST('20211212' AS DATETIME) - CAST(55.55 AS FLOAT)) c1, (CAST(55.55 AS FLOAT) - CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) - CAST(55.55 AS REAL)) c3, (CAST(55.55 AS REAL) - CAST('20211212' AS DATETIME)) c4
GO

-- DATETIME + Date and time (and vice-versa) - only DATETME and SMALLDATETIME are valid operands with DATETIME + x in SQL Server
CREATE VIEW babel_2812_vu_v7 AS
SELECT  (CAST('20211212' AS DATETIME) + CAST('19000103' AS DATETIME)) c1, (CAST('19000103' AS DATETIME) + CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) + CAST('19000103' AS SMALLDATETIME)) c3, (CAST('19000103' AS SMALLDATETIME) + CAST('20211212' AS DATETIME)) c4
GO

-- DATETIME - Date and time (and vice-versa) - only DATETME and SMALLDATETIME are valid operands with DATETIME + x in SQL Server
CREATE VIEW babel_2812_vu_v8 AS
SELECT  (CAST('20211212' AS DATETIME) - CAST('19000103' AS DATETIME)) c1, (CAST('19000103' AS DATETIME) - CAST('20211212' AS DATETIME)) c2, 
        (CAST('20211212' AS DATETIME) - CAST('19000103' AS SMALLDATETIME)) c3, (CAST('19000103' AS SMALLDATETIME) - CAST('20211212' AS DATETIME)) c4
GO

-- DATETIME + Character strings - text is not valid in SQL Server
CREATE VIEW babel_2812_vu_v9 AS
SELECT  --(CAST('20211212' AS DATETIME) + CAST('19000103' AS char)) c1, (CAST('19000103' AS char) + CAST('20211212' AS DATETIME)) c2, --char currently not working
        (CAST('20211212' AS DATETIME) + CAST('19000103' AS varchar)) c5, (CAST('19000103' AS varchar) + CAST('20211212' AS DATETIME)) c6
GO

-- DATETIME - Character strings - text is not valid in SQL Server
CREATE VIEW babel_2812_vu_v10 AS
SELECT  --(CAST('20211212' AS DATETIME) - CAST('19000103' AS char)) c1, (CAST('19000103' AS char) - CAST('20211212' AS DATETIME)) c2, --char currently not working
        (CAST('20211212' AS DATETIME) - CAST('19000103' AS varchar)) c5, (CAST('19000103' AS varchar) - CAST('20211212' AS DATETIME)) c6
GO

-- DATETIME + Unicode character strings - ntext is not valid in SQL Server
CREATE VIEW babel_2812_vu_v11 AS
SELECT  --(CAST('20211212' AS DATETIME) + CAST('19000103' AS nchar)) c1, (CAST('19000103' AS nchar) + CAST('20211212' AS DATETIME)) c2, --nchar currently not working
        (CAST('20211212' AS DATETIME) + CAST('19000103' AS nvarchar)) c5, (CAST('19000103' AS nvarchar) + CAST('20211212' AS DATETIME)) c6
GO

-- DATETIME - Unicode character strings - ntext is not valid in SQL Server
CREATE VIEW babel_2812_vu_v12 AS
SELECT  --(CAST('20211212' AS DATETIME) - CAST('19000103' AS nchar)) c1, (CAST('19000103' AS char) - CAST('20211212' AS DATETIME)) c2, --nchar currently not working
        (CAST('20211212' AS DATETIME) - CAST('19000103' AS nvarchar)) c5, (CAST('19000103' AS nvarchar) - CAST('20211212' AS DATETIME)) c6
GO

-- SMALLDATETIME + SMALLDATETIME, SMALLDATETIME - SMALLDATETIME
CREATE VIEW babel_2812_vu_v13 AS
SELECT (CAST('17:30:00' AS SMALLDATETIME) + CAST('20211212' AS SMALLDATETIME)) c1, (CAST('20211212' AS SMALLDATETIME) - CAST('17:30:00' AS SMALLDATETIME)) c2
GO

-- SMALLDATETIME + Exact numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v14 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS BIGINT)) c1, (CAST(55.55 AS BIGINT) + CAST('20211212' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS BIT)) c3, (CAST(55.55 AS BIT) + CAST('20211212' AS SMALLDATETIME)) c4, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS DECIMAL)) c5, (CAST(55.55 AS DECIMAL) + CAST('20211212' AS SMALLDATETIME)) c6, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS INT)) c7, (CAST(55.55 AS INT) + CAST('20211212' AS SMALLDATETIME)) c8, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS MONEY)) c9, (CAST(55.55 AS MONEY) + CAST('20211212' AS SMALLDATETIME)) c10, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS NUMERIC)) c11, (CAST(55.55 AS NUMERIC) + CAST('20211212' AS SMALLDATETIME)) c12, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS SMALLINT)) c13, (CAST(55.55 AS SMALLINT) + CAST('20211212' AS SMALLDATETIME)) c14, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS SMALLMONEY)) c15, (CAST(55.55 AS SMALLMONEY) + CAST('20211212' AS SMALLDATETIME)) c16, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS TINYINT)) c17, (CAST(55.55 AS TINYINT) + CAST('20211212' AS SMALLDATETIME)) c18
GO

-- SMALLDATETIME - Exact numerics (and vice-versa) -- smalldatetime has a min of 1900-01-01 so need to prevent underflow
CREATE VIEW babel_2812_vu_v15 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS BIGINT)) c1, (CAST(55.55 AS BIGINT) - CAST('19000103' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS BIT)) c3, (CAST(55.55 AS BIT) - CAST('19000101' AS SMALLDATETIME)) c4,
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS DECIMAL)) c5, (CAST(55.55 AS DECIMAL) - CAST('19000103' AS SMALLDATETIME)) c6, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS INT)) c7, (CAST(55.55 AS INT) - CAST('19000103' AS SMALLDATETIME)) c8, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS MONEY)) c9, (CAST(55.55 AS MONEY) - CAST('19000103' AS SMALLDATETIME)) c10, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS NUMERIC)) c11, (CAST(55.55 AS NUMERIC) - CAST('19000103' AS SMALLDATETIME)) c12, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS SMALLINT)) c13, (CAST(55.55 AS SMALLINT) - CAST('19000103' AS SMALLDATETIME)) c14, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS SMALLMONEY)) c15, (CAST(55.55 AS SMALLMONEY) - CAST('19000103' AS SMALLDATETIME)) c16, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS TINYINT)) c17, (CAST(55.55 AS TINYINT) - CAST('19000103' AS SMALLDATETIME)) c18
GO

-- SMALLDATETIME + Approximate numerics (and vice-versa)
CREATE VIEW babel_2812_vu_v16 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS FLOAT)) c1, (CAST(55.55 AS FLOAT) + CAST('20211212' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) + CAST(55.55 AS REAL)) c3, (CAST(55.55 AS REAL) + CAST('20211212' AS SMALLDATETIME)) c4
GO

-- SMALLDATETIME - Approximate numerics (and vice-versa) -- smalldatetime has a min of 1900-01-01 so need to prevent underflow
CREATE VIEW babel_2812_vu_v17 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS FLOAT)) c1, (CAST(55.55 AS FLOAT) - CAST('19000103' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) - CAST(55.55 AS REAL)) c3, (CAST(55.55 AS REAL) - CAST('19000103' AS SMALLDATETIME)) c4
GO

-- SMALLDATETIME + Date and time (and vice-versa) - only DATETIME and SMALLDATETIME are valid operands with SMALLDATETIME + x in SQL Server
CREATE VIEW babel_2812_vu_v18 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS SMALLDATETIME)) c1, (CAST('19000103' AS SMALLDATETIME) + CAST('20211212' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS DATETIME)) c3, (CAST('19000103' AS DATETIME) + CAST('20211212' AS SMALLDATETIME)) c4
GO

-- SMALLDATETIME - Date and time (and vice-versa) - only SMALLDATETIME and SMALLDATETIME are valid operands with SMALLDATETIME - x in SQL Server
CREATE VIEW babel_2812_vu_v19 AS
SELECT  (CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS SMALLDATETIME)) c1, (CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS SMALLDATETIME)) c2, 
        (CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS DATETIME)) c3, (CAST('20211212' AS DATETIME) - CAST('19000103' AS SMALLDATETIME)) c4
GO

-- SMALLDATETIME + Character strings - text is not valid in SQL Server
CREATE VIEW babel_2812_vu_v20 AS
SELECT  --(CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS char)) c1, (CAST('19000103' AS char) + CAST('20211212' AS SMALLDATETIME)) c2, --char currently not working
        (CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS varchar)) c5, (CAST('19000103' AS varchar) + CAST('20211212' AS SMALLDATETIME)) c6
GO

-- SMALLDATETIME - Character strings - text is not valid in SQL Server
CREATE VIEW babel_2812_vu_v21 AS
SELECT  --(CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS char)) c1, (CAST('19000103' AS char) - CAST('20211212' AS SMALLDATETIME)) c2, --char currently not working
        (CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS varchar)) c5, (CAST('19000103' AS varchar) - CAST('19000103' AS SMALLDATETIME)) c6
GO

-- SMALLDATETIME + Unicode character strings - ntext is not valid in SQL Server
CREATE VIEW babel_2812_vu_v22 AS
SELECT  --(CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS nchar)) c1, (CAST('19000103' AS nchar) + CAST('20211212' AS SMALLDATETIME)) c2, --nchar currently not working
        (CAST('20211212' AS SMALLDATETIME) + CAST('19000103' AS nvarchar)) c5, (CAST('19000103' AS nvarchar) + CAST('20211212' AS SMALLDATETIME)) c6
GO

-- SMALLDATETIME - Unicode character strings - ntext is not valid in SQL Server
CREATE VIEW babel_2812_vu_v23 AS
SELECT  --(CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS nchar)) c1, (CAST('19000103' AS char) - CAST('20211212' AS SMALLDATETIME)) c2, --nchar currently not working
        (CAST('20211212' AS SMALLDATETIME) - CAST('19000103' AS nvarchar)) c5, (CAST('19000103' AS nvarchar) - CAST('19000103' AS SMALLDATETIME)) c6
GO
