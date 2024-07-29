CREATE VIEW sys_partition_schemes_test_view
AS
    SELECT * FROM sys.partition_schemes;
GO

CREATE PROC sys_partition_schemes_test_proc
AS
    SELECT * FROM sys.partition_schemes
GO

CREATE FUNCTION sys_partition_schemes_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.partition_schemes)
END
GO
