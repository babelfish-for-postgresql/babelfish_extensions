USE master
GO

SELECT * FROM sys.hash_indexes
GO

SELECT * FROM sys_hash_indexes_vu_prepare_view
GO

EXEC sys_hash_indexes_vu_prepare_proc
GO

SELECT dbo.sys_hash_indexes_vu_prepare_func()
GO
