USE master
GO

SELECT * FROM sys.database_permissions
GO

SELECT * FROM sys_database_permissions_vu_prepare_view
GO

EXEC sys_database_permissions_vu_prepare_proc
GO

SELECT sys_database_permissions_vu_prepare_func()
GO