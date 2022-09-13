SELECT name, compatibility_level, collation_name FROM sys_databases_vu_prepare_view
GO

EXEC sys_databases_vu_prepare_proc
GO

SELECT sys_databases_vu_prepare_func()
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.databases');
GO

SELECT name FROM sys.databases where name = 'sys_databases_vu_prepare_db';
GO
