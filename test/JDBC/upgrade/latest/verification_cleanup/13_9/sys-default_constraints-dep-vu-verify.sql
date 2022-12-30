-- sla 15000
EXEC sys_default_constraints_dep_vu_prepare_p1
GO

SELECT * FROM sys_default_constraints_dep_vu_prepare_f1()
GO

SELECT * FROM sys_default_constraints_dep_vu_prepare_v1
GO
