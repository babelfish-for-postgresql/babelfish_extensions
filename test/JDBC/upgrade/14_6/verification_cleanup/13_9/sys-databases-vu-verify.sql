SELECT name, compatibility_level, collation_name FROM sys_databases_view_vu_prepare
GO

EXEC sys_databases_proc_vu_prepare
GO

SELECT sys_databases_func_vu_prepare()
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.databases');
GO

SELECT name FROM sys.databases where name = 'db_sys_databases_vu_prepare';
GO
