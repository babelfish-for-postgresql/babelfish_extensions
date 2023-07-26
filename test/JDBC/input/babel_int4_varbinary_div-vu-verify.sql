USE master
GO

SELECT * FROM sys_int4_varbinary_vu_prepare_view
GO

EXEC sys_int4_varbinary_vu_prepare_proc
GO

SELECT sys_int4_varbinary_vu_prepare_func()
GO