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

SELECT * FROM sys_suser_sname_view
GO

EXEC sys_suser_sname_proc
GO

SELECT sys_suser_sname_func()
GO

SELECT * FROM sys_suser_name_view
GO

EXEC sys_suser_name_proc
GO

SELECT sys_suser_name_func()
GO
