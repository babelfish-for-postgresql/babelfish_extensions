USE master
GO

CREATE VIEW sys_database_permissions_vu_prepare_view AS
SELECT * FROM sys.database_permissions
GO

CREATE PROC sys_database_permissions_vu_prepare_proc AS
SELECT * FROM sys.database_permissions
GO

CREATE FUNCTION sys_database_permissions_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.database_permissions WHERE state='A')
END
GO