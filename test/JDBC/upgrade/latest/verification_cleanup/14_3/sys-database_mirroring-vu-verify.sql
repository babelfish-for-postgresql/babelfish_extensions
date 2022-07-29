SELECT * FROM sys_database_mirroring_view_vu_prepare
GO

EXEC sys_database_mirroring_proc_vu_prepare
GO

SELECT * FROM sys_database_mirroring_func_vu_prepare()
GO

SELECT * FROM sys.database_mirroring WHERE database_id IN (1,2,4);
GO
