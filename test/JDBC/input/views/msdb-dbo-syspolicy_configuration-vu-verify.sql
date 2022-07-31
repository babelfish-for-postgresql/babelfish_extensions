USE master
GO

SELECT * FROM msdb.dbo.syspolicy_configuration
GO

SELECT * FROM msdb_dbo_syspolicy_configuration_vu_prepare_view
GO

EXEC msdb_dbo_syspolicy_configuration_vu_prepare_proc
GO

SELECT dbo.msdb_dbo_syspolicy_configuration_vu_prepare_func()
GO
