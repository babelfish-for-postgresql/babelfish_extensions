USE master
GO

SELECT * FROM sys.fulltext_indexes
GO

SELECT * FROM sys_fulltext_indexes_vu_prepare_view
GO

EXEC sys_fulltext_indexes_vu_prepare_proc
GO

SELECT dbo.sys_fulltext_indexes_vu_prepare_func()
GO
