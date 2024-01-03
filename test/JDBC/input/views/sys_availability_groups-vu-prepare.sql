CREATE VIEW sys_availability_groups_test_view
AS
    SELECT * FROM sys.availability_groups;
GO

CREATE PROC sys_availability_groups_test_proc
AS
    SELECT * FROM sys.availability_groups
GO

CREATE FUNCTION sys_availability_groups_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.availability_groups)
END
GO