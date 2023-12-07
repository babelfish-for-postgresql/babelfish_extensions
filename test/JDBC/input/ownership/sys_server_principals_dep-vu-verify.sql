SELECT * FROM sys_server_principals_dep_vu_prepare_view
GO

EXEC sys_server_principals_dep_vu_prepare_proc
GO

SELECT sys_server_principals_dep_vu_prepare_func()
GO

SELECT name FROM sys.server_principals
WHERE name LIKE 'sys_server_principals_dep_vu_prepare_login%'
ORDER BY name
GO

-- Test case-semantics for column type
SELECT COUNT(*) FROM sys.server_principals WHERE type='R';
GO
SELECT COUNT(*) FROM sys.server_principals WHERE type='r';
GO
