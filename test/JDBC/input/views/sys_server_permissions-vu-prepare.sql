USE master
GO

CREATE VIEW sys_server_permissions_vu_prepare_view AS
SELECT * FROM sys.server_permissions
GO

CREATE PROC sys_server_permissions_vu_prepare_proc AS
SELECT * FROM sys.server_permissions
GO

CREATE FUNCTION sys_server_permissions_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.server_permissions)
END
GO