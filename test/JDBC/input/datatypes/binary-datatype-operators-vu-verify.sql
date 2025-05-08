-- inside view
SELECT * FROM binary_datatype_operators_less_than_view
GO

SELECT * FROM binary_datatype_operators_less_than_equal_view
GO

SELECT * FROM binary_datatype_operators_greater_than_view
GO

SELECT * FROM binary_datatype_operators_greater_than_equal_view
GO

SELECT * FROM binary_datatype_operators_equal_view
GO

SELECT * FROM binary_datatype_operators_not_equal_view
GO

-- inside procedure
EXEC binary_datatype_operators_less_than_proc
GO

EXEC binary_datatype_operators_less_than_equal_proc
GO

EXEC binary_datatype_operators_greater_than_proc
GO

EXEC binary_datatype_operators_greater_than_equal_proc
GO

EXEC binary_datatype_operators_equal_proc
GO

EXEC binary_datatype_operators_not_equal_proc
GO

-- inside function
SELECT * FROM binary_datatype_operators_less_than_func()
GO

SELECT * FROM binary_datatype_operators_less_than_equal_func()
GO

SELECT * FROM binary_datatype_operators_greater_than_func()
GO

SELECT * FROM binary_datatype_operators_greater_than_equal_func()
GO

SELECT * FROM binary_datatype_operators_equal_func()
GO

SELECT * FROM binary_datatype_operators_not_equal_func()
GO