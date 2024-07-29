SELECT * FROM sys.data_spaces
GO

SELECT * FROM sys_data_spaces_vu_prepare_view
GO

EXEC sys_data_spaces_vu_prepare_proc
GO

SELECT dbo.sys_data_spaces_vu_prepare_func()
GO