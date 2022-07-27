DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID())
SELECT SYS.SUSER_SNAME(@id)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jdbc_user'))
SELECT SYS.SUSER_SNAME(@id)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jDbC_uSeR'))
SELECT SYS.SUSER_SNAME(@id)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jdbc_user  '))
SELECT SYS.SUSER_SNAME(@id)
GO

SELECT SYS.SUSER_SID(' jdbc_user')
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jdbc_user', 0))
SELECT SYS.SUSER_SNAME(@id)
GO

DECLARE @id SYS.VARBINARY(85)
SET @id = (SELECT SYS.SUSER_SID('jdbc_user', NULL))
SELECT SYS.SUSER_SNAME(@id)
GO

SELECT SYS.SUSER_SID('non_existent_user')
GO

SELECT SYS.SUSER_SID(NULL)
GO

SELECT SYS.SUSER_SID(NULL, NULL)
GO

SELECT SYS.SUSER_SID(NULL, 0)
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
