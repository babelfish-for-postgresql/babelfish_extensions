USE db_sys_configurations;
GO

SELECT * FROM sys_configurations_view
GO

EXEC sys_configurations_proc
GO

SELECT * FROM sys_configurations_func()
GO

SELECT * FROM sys_syscurconfigs_view
GO

EXEC sys_syscurconfigs_proc
GO

SELECT * FROM sys_syscurconfigs_func()
GO

SELECT * FROM sys_sysconfigures_view
GO

EXEC sys_sysconfigures_proc
GO

SELECT * FROM sys_sysconfigures_func()
GO

DROP VIEW sys_configurations_view
GO

DROP PROC sys_configurations_proc
GO

DROP FUNCTION sys_configurations_func
GO

DROP VIEW sys_sysconfigures_view
GO

DROP PROC sys_sysconfigures_proc
GO

DROP FUNCTION sys_sysconfigures_func
GO

DROP VIEW sys_syscurconfigs_view
GO

DROP PROC sys_syscurconfigs_proc
GO

DROP FUNCTION sys_syscurconfigs_func
GO

USE master
GO

DROP DATABASE db_sys_configurations
GO