USE master
GO

SELECT * FROM sys.server_permissions
GO

SELECT * FROM sys_server_permissions_vu_prepare_view
GO

EXEC sys_server_permissions_vu_prepare_proc
GO

SELECT sys_server_permissions_vu_prepare_func()
GO