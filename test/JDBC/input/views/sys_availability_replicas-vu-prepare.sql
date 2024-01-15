CREATE VIEW sys_availability_replicas_test_view
AS
    SELECT * FROM sys.availability_replicas;
GO

CREATE PROC sys_availability_replicas_test_proc
AS
    SELECT * FROM sys.availability_replicas
GO

CREATE FUNCTION sys_availability_replicas_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.availability_replicas)
END
GO