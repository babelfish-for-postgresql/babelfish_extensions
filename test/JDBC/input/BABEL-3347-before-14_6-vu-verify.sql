-- table variable
SELECT * FROM babel_3347_before_14_6_vu1
GO

-- null constant
SELECT * FROM babel_3347_before_14_6_vu2
GO

-- function that returns null
SELECT * FROM babel_3347_before_14_6_vu3
GO

-- table for substring start index
SELECT * FROM babel_3347_before_14_6_vu4
GO

-- table for substring end index
SELECT * FROM babel_3347_before_14_6_vu5
GO

-- cast
SELECT * FROM babel_3347_before_14_6_vu6
GO

-- null constant function qualified with 'sys'
SELECT * FROM babel_3347_vu7
GO

-- variables
DECLARE @babel_3347_before_14_6_vu7_var NVARCHAR(MAX) = NULL
SELECT SUBSTRING(@babel_3347_before_14_6_vu7_var, 2,3)
GO

-- ensure null literal aborts batch statements
CREATE table babel_3347_before_14_6_vu_tbl (a INT)
SELECT substring(null, 2,3)
PRINT 'this should not print'
GO

SELECT * FROM babel_3347_before_14_6_vu_tbl
GO
