SELECT * FROM sys_database_mirroring_vu_prepare_view
GO

EXEC sys_database_mirroring_vu_prepare_proc
GO

SELECT * FROM sys_database_mirroring_vu_prepare_func()
GO

SELECT * FROM sys.database_mirroring WHERE database_id IN (1,2,4);
GO
