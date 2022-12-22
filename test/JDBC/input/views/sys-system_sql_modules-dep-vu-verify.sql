-- sla 70000
USE sys_system_sql_modules_dep_vu_prepare_db1
GO

EXEC sys_system_sql_modules_dep_vu_prepare_p1
GO

SELECT * FROM sys_system_sql_modules_dep_vu_prepare_f1()
GO

SELECT * FROM sys_system_sql_modules_dep_vu_prepare_v1
GO

USE master
GO
