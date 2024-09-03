CREATE VIEW sys_dm_os_sys_info_test_view
AS 
    SELECT COUNT(*) FROM sys.dm_os_sys_info 
    WHERE ms_ticks IS NOT NULL 
    AND sqlserver_start_time_ms_ticks IS NOT NULL
    AND sqlserver_start_time IS NOT NULL
GO

CREATE PROC sys_dm_os_sys_info_test_proc
AS 
    SELECT COUNT(*) FROM sys.dm_os_sys_info 
    WHERE ms_ticks IS NOT NULL 
    AND sqlserver_start_time_ms_ticks IS NOT NULL
    AND sqlserver_start_time IS NOT NULL
GO

CREATE FUNCTION sys_dm_os_sys_info_test_func()
RETURNS INT
AS
BEGIN
    RETURN 
        (SELECT COUNT(*) FROM sys.dm_os_sys_info 
        WHERE ms_ticks IS NOT NULL 
        AND sqlserver_start_time_ms_ticks IS NOT NULL
        AND sqlserver_start_time IS NOT NULL)
END
GO
