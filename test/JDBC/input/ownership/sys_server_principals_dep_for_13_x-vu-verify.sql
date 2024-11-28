SELECT * FROM sys_server_principals_dep_for_13_x_vu_prepare_view
GO

EXEC sys_server_principals_dep_for_13_x_vu_prepare_proc
GO

SELECT sys_server_principals_dep_for_13_x_vu_prepare_func()
GO

SELECT name FROM sys.server_principals
WHERE name LIKE 'sys_server_principals_dep_for_13_x_vu_prepare_login%'
ORDER BY name
GO

SELECT name, is_fixed_role FROM sys.server_principals
WHERE name IN ('sysadmin', 'jdbc_user')
ORDER BY name
GO
