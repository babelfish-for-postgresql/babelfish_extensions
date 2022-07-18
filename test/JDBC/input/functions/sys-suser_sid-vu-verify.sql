DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID())
SELECT SYS.SUSER_SNAME(@id)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jdbc_user'))
SELECT SYS.SUSER_SNAME(@id)
GO

SELECT SYS.SUSER_SID('non_existent_user')
GO

SELECT * FROM sys_suser_sid_view_vu_prepare
GO

EXEC sys_suser_sid_proc_vu_prepare
GO

SELECT sys_suser_sid_func_vu_prepare()
GO

SELECT * FROM sys_suser_id_view_vu_prepare
GO

EXEC sys_suser_id_proc_vu_prepare
GO

SELECT sys_suser_id_func_vu_prepare()
GO
