USE master
GO

SELECT * FROM sys.credentials
GO

SELECT * FROM sys_credentials_vu_prepare_view
GO

EXEC sys_credentials_vu_prepare_proc
GO

SELECT sys_credentials_vu_prepare_func()
GO