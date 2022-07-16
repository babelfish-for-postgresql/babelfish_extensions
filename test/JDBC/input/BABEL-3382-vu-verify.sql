USE master;
GO

SELECT * FROM sys_sysobjects_view
GO

EXEC sys_sysobjects_proc
GO

SELECT dbo.sys_sysobjects_func()
GO