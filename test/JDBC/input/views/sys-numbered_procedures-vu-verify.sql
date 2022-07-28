USE master
GO

SELECT * FROM sys_numbered_procedures_vu_prepare_view
GO

EXEC sys_numbered_procedures_vu_prepare_proc
GO

SELECT dbo.sys_numbered_procedures_vu_prepare_func()
GO