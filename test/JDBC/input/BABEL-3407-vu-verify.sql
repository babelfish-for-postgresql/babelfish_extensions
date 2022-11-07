-- Display Table Contents
SELECT * FROM babel_3407_table1
GO

SELECT * FROM babel_3407_table2
GO

SELECT * FROM babel_3407_table3
GO

-- FOR JSON PATH clause without nested support
SELECT * FROM babel_3407_view1
GO

SELECT * FROM babel_3407_view2
GO

-- Multiple tables without nested support
SELECT * FROM babel_3407_view3
GO

-- ROOT directive without specifying value
SELECT * FROM babel_3407_view4
GO

-- ROOT directive with specifying ROOT value
SELECT * FROM babel_3407_view5
GO

-- ROOT directive with specifying ROOT value with empty string
SELECT * FROM babel_3407_view6
GO

-- WITHOUT_ARRAY_WRAPPERS directive
SELECT * FROM babel_3407_view7
GO

-- INCLUDE_NULL_VALUES directive
SELECT * FROM babel_3407_view8
GO

-- Multiple Directives
SELECT * FROM babel_3407_view9
GO

SELECT * FROM babel_3407_view10
GO

-- FOR JSON AUTO clause not supported
SELECT * FROM babel_3407_view12
GO


-- Test case with parameters
EXECUTE babel_3407_proc1 @id = 3
GO

EXECUTE babel_3407_proc2 @id = 2
GO

-- Alias/colname is not present
SELECT * FROM babel_3407_view13
GO

-- All null values test
SELECT * FROM babel_3407_view14
GO

-- Test for all parser rules
SELECT * FROM babel_3407_view15
GO

SELECT * FROM babel_3407_view16
GO

SELECT * FROM babel_3407_view17
GO

-- Explicit call to the function
SELECT * FROM explicit_call_view
GO