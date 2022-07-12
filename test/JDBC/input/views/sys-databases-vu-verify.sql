SELECT name, compatibility_level, collation_name FROM sys_databases_view
GO

EXEC sys_databases_proc
GO

SELECT sys_databases_func()
GO
