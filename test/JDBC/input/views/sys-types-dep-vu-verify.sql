USE sys_types_dep_vu_prepare_db1
GO

EXEC sys_types_dep_vu_prepare_p1
GO

SELECT * FROM sys_types_dep_vu_prepare_f1()
GO

SELECT * FROM sys_types_dep_vu_prepare_v1
GO
