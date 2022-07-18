SELECT name, compatibility_level, collation_name FROM sys_databases_view_vu_prepare
GO

EXEC sys_databases_proc_vu_prepare
GO

SELECT sys_databases_func_vu_prepare()
GO
