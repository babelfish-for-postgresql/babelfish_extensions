SELECT SYS.SUSER_SNAME()
GO

SELECT SYS.SUSER_SNAME(0x01)
GO

SELECT SYS.SUSER_SNAME(0x0P)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = CAST(CAST((SELECT oid FROM pg_catalog.pg_roles WHERE rolname = 'jdbc_user') AS INT) AS SYS.VARBINARY(85))
SELECT SYS.SUSER_SNAME(@id)
GO

SELECT SYS.SUSER_SNAME(NULL)
GO

SELECT * FROM sys_suser_sname_view_vu_prepare
GO

EXEC sys_suser_sname_proc_vu_prepare
GO

SELECT sys_suser_sname_func_vu_prepare()
GO

SELECT * FROM sys_suser_name_view_vu_prepare
GO

EXEC sys_suser_name_proc_vu_prepare
GO

SELECT sys_suser_name_func_vu_prepare()
GO
