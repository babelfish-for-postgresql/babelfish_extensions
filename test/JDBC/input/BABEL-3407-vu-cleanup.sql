-- Display Table Contents
DROP TABLE babel_3407_table1
GO

DROP TABLE babel_3407_table2
GO

DROP TABLE babel_3407_table3
GO

-- FOR JSON PATH clause without nested support
DROP VIEW babel_3407_view1
GO

DROP VIEW babel_3407_view2
GO

-- Multiple tables without nested support
DROP VIEW babel_3407_view3
GO

-- ROOT directive without specifying value
DROP VIEW babel_3407_view4
GO

-- ROOT directive with specifying ROOT value
DROP VIEW babel_3407_view5
GO

-- ROOT directive with specifying ROOT value with empty string
DROP VIEW babel_3407_view6
GO

-- WITHOUT_ARRAY_WRAPPERS directive
DROP VIEW babel_3407_view7
GO

-- INCLUDE_NULL_VALUES directive
DROP VIEW babel_3407_view8
GO

-- Multiple Directives
DROP VIEW babel_3407_view9
GO

DROP VIEW babel_3407_view10
GO

-- FOR JSON AUTO clause not supported
DROP VIEW babel_3407_view12
GO


-- Test case with parameters
DROP PROCEDURE babel_3407_proc1
GO

DROP PROCEDURE babel_3407_proc2
GO

-- Alias/colname is not present
DROP VIEW babel_3407_view13
GO

-- All null values test
DROP VIEW babel_3407_view14
GO

-- Test for all parser rules
DROP VIEW babel_3407_view15
GO

DROP VIEW babel_3407_view16
GO

DROP VIEW babel_3407_view17
GO

-- Explicit call to the function
DROP VIEW explicit_call_view
GO