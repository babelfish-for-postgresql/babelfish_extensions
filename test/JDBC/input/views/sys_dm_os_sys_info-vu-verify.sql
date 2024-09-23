SELECT * FROM sys_dm_os_sys_info_test_view
GO

EXEC sys_dm_os_sys_info_test_proc
GO

SELECT dbo.sys_dm_os_sys_info_test_func()
GO
