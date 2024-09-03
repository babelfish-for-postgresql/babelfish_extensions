CREATE VIEW sys_dm_os_sys_info_test_view
AS 
    SELECT COUNT(*) FROM sys.dm_os_sys_info
GO

CREATE PROC sys_dm_os_sys_info_test_proc
AS 
    SELECT COUNT(*) FROM sys.dm_os_sys_info
GO

CREATE FUNCTION sys_dm_os_sys_info_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.dm_os_sys_info)
END
GO
