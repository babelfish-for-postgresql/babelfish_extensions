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
SELECT * FROM babel_2812_vu_v26
GO
SELECT * FROM babel_2812_vu_v27
GO

-- overflow for datetime, should error
SELECT * FROM babel_2812_vu_v28
GO
SELECT * FROM babel_2812_vu_v29
GO

-- Test DATEDIFF() with DATE type for different dateparts
SELECT * FROM babel_2812_vu_v30
GO
SELECT * FROM babel_2812_vu_v31
GO
SELECT * FROM babel_2812_vu_v32
GO
-- datediff(week) is not 100% the same as SQL Server, needs to be fixed - should return 52
SELECT * FROM babel_2812_vu_v33
GO
SELECT * FROM babel_2812_vu_v34
GO
SELECT * FROM babel_2812_vu_v35
GO
SELECT * FROM babel_2812_vu_v36
GO
SELECT * FROM babel_2812_vu_v37
GO
SELECT * FROM babel_2812_vu_v38
GO
-- should overflow
SELECT * FROM babel_2812_vu_v39
GO
-- smaller interval for millisecond
SELECT * FROM babel_2812_vu_v40
GO
-- should overflow
SELECT * FROM babel_2812_vu_v41
GO
-- microsecond and nanosecond can only handle diff of 0 for date type
SELECT * FROM babel_2812_vu_v42
GO
SELECT * FROM babel_2812_vu_v43
GO
