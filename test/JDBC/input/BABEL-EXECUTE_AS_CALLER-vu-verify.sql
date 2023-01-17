-- functions
SELECT babel_execute_as_caller_function_return_table_select()
GO

SELECT babel_execute_as_caller_function_return_int(1)
GO

SELECT babel_execute_as_caller_function_return_bigint()
GO

SELECT babel_execute_as_caller_function_return_int_1(2)
GO

-- procedures
EXEC babel_execute_as_caller_procedure_1
GO

EXEC babel_execute_as_caller_procedure_2 2
GO

-- procedures with more than 1 argument and with-clause
EXEC babel_execute_as_caller_procedure_4 4, 'test'
GO

EXEC babel_execute_as_caller_procedure_5 5, 'test', 0
GO

EXEC babel_execute_as_caller_procedure_6 6, 'test', 0
GO

-- triggers
INSERT INTO babel_execute_as_caller_table values (2);
GO
SELECT * FROM babel_execute_as_caller_table_1;
GO

-- functions with other options
SELECT babel_execute_as_caller_function_return_int_3(3)
GO

SELECT babel_execute_as_caller_function_return_int_4(4)
GO

SELECT babel_execute_as_caller_function_return_int_5(5)
GO

SELECT babel_execute_as_caller_function_return_int_6(6)
GO

SELECT babel_execute_as_caller_function_return_int_7(7, 'test', 5)
GO
