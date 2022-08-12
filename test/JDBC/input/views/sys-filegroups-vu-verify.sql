USE master
GO

SELECT * FROM sys.filegroups
GO

SELECT * FROM sys_filegroups_vu_prepare_view
GO

EXEC sys_filegroups_vu_prepare_proc
GO

SELECT dbo.sys_filegroups_vu_prepare_func()
GO
