SELECT COUNT(*) FROM sys.dm_os_sys_info
GO

SELECT * FROM sys_dm_os_sys_info_test_view
GO

EXEC sys_dm_os_sys_info_test_proc
GO

SELECT dbo.sys_dm_os_sys_info_test_func()
GO

SELECT
SCHEMA_NAME(seq.schema_id) AS [Schema],
seq.name AS [Name]
FROM
sys.dm_os_sys_info AS seq
ORDER BY
[Schema] ASC,[Name] ASC
GO 
