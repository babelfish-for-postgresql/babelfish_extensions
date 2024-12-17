CREATE LOGIN sys_server_principals_dep_for_13_x_vu_prepare_login1 WITH PASSWORD = '123'
GO

CREATE LOGIN sys_server_principals_dep_for_13_x_vu_prepare_login2 WITH PASSWORD = '123'
GO

CREATE VIEW sys_server_principals_dep_for_13_x_vu_prepare_view
AS
SELECT name, type, type_desc, is_disabled, default_database_name, default_language_name, is_fixed_role
FROM sys.server_principals 
WHERE name LIKE '%sys_server_principals_dep_for_13_x_vu_prepare%'
ORDER BY name
GO

CREATE PROC sys_server_principals_dep_for_13_x_vu_prepare_proc
AS
SELECT name, type, type_desc, is_disabled, default_database_name, default_language_name, is_fixed_role
FROM sys.server_principals 
WHERE name LIKE '%sys_server_principals_dep_for_13_x_vu_prepare%'
ORDER BY name
GO

CREATE FUNCTION sys_server_principals_dep_for_13_x_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.server_principals WHERE name LIKE '%sys_server_principals_dep_for_13_x_vu_prepare%')
END
GO

SELECT name, is_fixed_role FROM sys.server_principals
WHERE name IN ('sysadmin', 'jdbc_user')
ORDER BY name
GO
