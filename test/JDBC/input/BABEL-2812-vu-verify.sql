EXEC babel_2812_vu_p1 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p2 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p3 '17:30:00', '20211212';
GO

EXEC babel_2812_vu_p4 '17:30:00', '20211212';
GO

-- SELECT * FROM babel_2812_vu_v1
-- GO

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

-- test DATETIME + other date and time data types (should not work)
SELECT (CAST('20211212' AS DATETIME) + CAST('19000103' AS DATE))
GO
