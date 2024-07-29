SELECT * FROM sys_partition_functions_test_view
GO

EXEC sys_partition_functions_test_proc
GO

SELECT * FROM sys_partition_functions_test_func()
GO