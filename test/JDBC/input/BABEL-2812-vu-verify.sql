EXEC babel_2812_vu_p1 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p2 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p3 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p4 '17:30:00', '20211212';
GO

SELECT * FROM babel_2812_vu_v1
GO

SELECT * FROM babel_2812_vu_v2
GO

SELECT * FROM babel_2812_vu_v3
GO

SELECT * FROM babel_2812_vu_v4
GO

SELECT * FROM babel_2812_vu_v5
GO

SELECT * FROM babel_2812_vu_v6
GO

SELECT * FROM babel_2812_vu_v7
GO

SELECT * FROM babel_2812_vu_v8
GO

SELECT * FROM babel_2812_vu_v9
GO

SELECT * FROM babel_2812_vu_v10
GO

SELECT * FROM babel_2812_vu_v11
GO

SELECT * FROM babel_2812_vu_v12
GO

SELECT * FROM babel_2812_vu_v13
GO

SELECT * FROM babel_2812_vu_v14
GO

SELECT * FROM babel_2812_vu_v15
GO

SELECT * FROM babel_2812_vu_v16
GO

SELECT * FROM babel_2812_vu_v17
GO

SELECT * FROM babel_2812_vu_v18
GO

SELECT * FROM babel_2812_vu_v19
GO

SELECT * FROM babel_2812_vu_v20
GO

SELECT * FROM babel_2812_vu_v21
GO

SELECT * FROM babel_2812_vu_v22
GO

SELECT * FROM babel_2812_vu_v23
GO

SELECT * FROM babel_2812_vu_v24
GO

SELECT * FROM babel_2812_vu_v25
GO

-- test DATETIME + other date and time data types (should not work)
SELECT (CAST('20211212' AS DATETIME) + CAST('19000103' AS DATE))
GO

SELECT (CAST('20211212' AS DATETIME) + CAST('19000103' AS TEXT))
GO

-- overflow for datetime, should error
SELECT  (CAST('1753-01-01' AS DATETIME) + CAST(2000000000 AS INT))
GO

SELECT  (CAST('1753-01-01' AS DATETIME) + CAST(4000000000 AS BIGINT))
GO

-- Test DATEDIFF() with DATE type for different dateparts
SELECT datediff(year, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(quarter, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(month, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
-- datediff(week) is not 100% the same as SQL Server, needs to be fixed
SELECT datediff(week, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(y, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(day, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(hour, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(minute, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
SELECT datediff(second, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
-- should overflow
SELECT datediff(millisecond, CAST('2015-12-31' as date), cast('2016-12-28' as date));
GO
-- smaller interval for millisecond
SELECT datediff(millisecond, CAST('2016-12-27' as date), cast('2016-12-28' as date));
GO
-- should overflow
SELECT datediff(microsecond, CAST('2016-12-27' as date), cast('2016-12-28' as date));
GO
-- microsecond and nanosecond can only handle diff of 0 for date type
SELECT datediff(microsecond, CAST('2016-12-28' as date), cast('2016-12-28' as date));
GO
SELECT datediff(nanosecond, CAST('2016-12-28' as date), cast('2016-12-28' as date));
GO
