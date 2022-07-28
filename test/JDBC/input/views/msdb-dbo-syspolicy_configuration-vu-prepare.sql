USE master
GO

CREATE VIEW msdb_dbo_syspolicy_configuration_vu_prepare_view AS
SELECT * FROM msdb.dbo.syspolicy_configuration
GO

CREATE PROC msdb_dbo_syspolicy_configuration_vu_prepare_proc AS
SELECT * FROM msdb.dbo.syspolicy_configuration
GO

CREATE FUNCTION dbo.msdb_dbo_syspolicy_configuration_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM msdb.dbo.syspolicy_configuration)
END
GO
