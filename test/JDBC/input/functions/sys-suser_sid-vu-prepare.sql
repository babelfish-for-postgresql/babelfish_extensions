CREATE VIEW sys_suser_sid_view_vu_prepare AS
SELECT suser_sid(CAST('-1' AS sys.sysname))
GO

CREATE PROC sys_suser_sid_proc_vu_prepare AS
SELECT suser_sid(CAST('-1' AS sys.sysname))
GO

CREATE FUNCTION sys_suser_sid_func_vu_prepare()
RETURNS SYS.VARBINARY(85)
AS
BEGIN
    RETURN suser_sid(CAST('-1' AS sys.sysname))
END
GO

CREATE VIEW sys_suser_id_view_vu_prepare AS
SELECT suser_id(-1)
GO

CREATE PROC sys_suser_id_proc_vu_prepare AS
SELECT suser_id(-1)
GO

CREATE FUNCTION sys_suser_id_func_vu_prepare()
RETURNS SYS.VARBINARY(85)
AS
BEGIN
    RETURN suser_id(-1)
END
GO
