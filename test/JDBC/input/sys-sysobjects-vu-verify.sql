USE master;
GO

SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table'
GO

SELECT * FROM sys_sysobjects_vu_prepare_view
GO

EXEC sys_sysobjects_vu_prepare_proc
GO

SELECT dbo.sys_sysobjects_vu_prepare_func()
GO