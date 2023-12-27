SELECT * FROM sys.availability_replicas
GO

SELECT * FROM sys_availability_replicas_test_view
GO

EXEC sys_availability_replicas_test_proc
GO

SELECT sys_availability_replicas_test_func()
GO