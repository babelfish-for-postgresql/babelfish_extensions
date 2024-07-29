CREATE VIEW sys_partition_functions_test_view
AS
    SELECT * FROM sys.partition_functions;
GO

CREATE PROC sys_partition_functions_test_proc
AS
    SELECT * FROM sys.partition_functions
GO

CREATE FUNCTION sys_partition_functions_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.partition_functions)
END
GO
