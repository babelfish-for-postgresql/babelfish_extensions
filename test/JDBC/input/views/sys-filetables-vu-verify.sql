USE master
GO

SELECT * FROM sys.filetables
GO

SELECT * FROM sys_filetables_vu_prepare_view
GO

EXEC sys_filetables_vu_prepare_proc
GO

SELECT dbo.sys_filetables_vu_prepare_func()
GO
