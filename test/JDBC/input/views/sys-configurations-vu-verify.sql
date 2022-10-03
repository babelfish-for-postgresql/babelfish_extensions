USE master;
GO

SELECT * FROM sys_configurations_vu_prepare_v1
GO

EXEC sys_configurations_vu_prepare_p1
GO

SELECT * FROM sys_configurations_vu_prepare_f1()
GO

SELECT * FROM sys_configurations_vu_prepare_v2
GO

EXEC sys_configurations_vu_prepare_p2
GO

SELECT * FROM sys_configurations_vu_prepare_f2()
GO

SELECT * FROM sys_configurations_vu_prepare_v3
GO

EXEC sys_configurations_vu_prepare_p3
GO

SELECT * FROM sys_configurations_vu_prepare_f3()
GO
