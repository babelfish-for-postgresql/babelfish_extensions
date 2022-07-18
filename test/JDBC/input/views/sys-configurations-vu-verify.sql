USE master;
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
