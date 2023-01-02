-- sla 400000
SELECT * FROM sys_all_parameters_dep_vu_prepare_upgrade_view
GO

EXEC sys_all_parameters_dep_vu_prepare_upgrade_proc
GO

SELECT sys_all_parameters_dep_vu_prepare_upgrade_func()
GO
