SELECT name, compatibility_level, collation_name FROM sys_databases_view_dep_vu_prepare
GO
--compatibility level returned will be NULL because View created before Upgrade is not updated.

EXEC sys_databases_proc_dep_vu_prepare
GO

SELECT sys_databases_func_dep_vu_prepare()
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.databases');
GO

SELECT name FROM sys.databases where name = 'db_sys_databases_dep_vu_prepare';
GO
