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

-- cast BABEL-3599
SELECT * FROM babel_3347_before_14_6_vu6
GO

-- varibles BABEL-3599
DECLARE @babel_3347_before_14_6_vu7_var NVARCHAR(MAX) = NULL
SELECT SUBSTRING(@babel_3347_before_14_6_vu7_var, 2,3)
GO