-- Display Table Contents
SELECT * FROM babel_3407_table1
GO

-- FOR JSON PATH clause
SELECT * FROM babel_3407_view1
GO

-- ROOT directive without specifying value
SELECT * FROM babel_3407_view2
GO

-- ROOT directive with specifying ROOT value
SELECT * FROM babel_3407_view3
GO

-- WITHOUT_ARRAY_WRAPPERS directive
SELECT * FROM babel_3407_view4
GO

-- INCLUDE_NULL_VALUES directive
SELECT * FROM babel_3407_view5
GO

-- Multiple Directives ROOT, INCLUDE_NULL_VALUES
SELECT * FROM babel_3407_view6
GO

-- Multiple Directives WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
SELECT * FROM babel_3407_view7
GO

-- Throws error as ROOT and WITHOUT_ARRAY_WRAPPER cannot be used together
SELECT * FROM babel_3407_view8
GO

-- Test for explicit call to the function
SELECT * FROM explicit_call_view
GO
