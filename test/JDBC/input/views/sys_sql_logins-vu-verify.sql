USE master
GO

SELECT * FROM sys.sql_logins
GO

SELECT * FROM sys_sql_logins_vu_prepare_view
GO

EXEC sys_sql_logins_vu_prepare_proc
GO

SELECT sys_sql_logins_vu_prepare_func()
GO