-- DIFFERENT CASES TO CHECK DATATYPES
-- Exact Numerics
SELECT * FROM forjson_vu_view1
GO

SELECT * FROM forjson_vu_view2
GO

SELECT * FROM forjson_vu_view3
GO

SELECT * FROM forjson_vu_view4
GO

-- Approximate numerics
SELECT * FROM forjson_vu_view5
GO

-- Date and time
SELECT * FROM forjson_vu_view6
GO

SELECT * FROM forjson_vu_view7
GO

SELECT * FROM forjson_vu_view8
GO

SELECT * FROM forjson_vu_view9
GO

SELECT * FROM forjson_vu_view10
GO

-- Character strings
SELECT * FROM forjson_vu_view11
GO

-- Unicode character strings
SELECT * FROM forjson_vu_view12
GO

-- Binary strings
SELECT * FROM forjson_vu_view13
GO

SELECT * FROM forjson_vu_view14
GO

-- Return null string
-- should return 0 rows after BABEL-3690 is fixed
SELECT * FROM forjson_vu_view15
GO

-- Rowversion and timestamp
SELECT * FROM forjson_vu_view16
GO

SELECT * FROM forjson_vu_view17
GO