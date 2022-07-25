CREATE PROC test_role_proc_babel_user_ext_master AS
BEGIN 
	SELECT rolname, type, orig_username, database_name
	FROM sys.babelfish_authid_user_ext
	WHERE orig_username LIKE 'test_role%'
	ORDER BY rolname, orig_username
END
GO

CREATE PROC test_role_proc_babel_db_principal_master AS
BEGIN
	SELECT name, type_desc
	FROM sys.database_principals
	WHERE name LIKE 'test_role%'
	ORDER BY name
END
GO

CREATE LOGIN test_role_login1 WITH PASSWORD = 'abc'
GO

CREATE LOGIN test_role_login2 WITH PASSWORD = 'abc'
GO

CREATE LOGIN test_role_login3 WITH PASSWORD = 'abc'
GO

CREATE DATABASE test_role_db
GO

USE test_role_db
GO

CREATE PROC test_role_proc_babel_user_ext AS
BEGIN 
	SELECT rolname, type, orig_username, database_name
	FROM sys.babelfish_authid_user_ext
	WHERE orig_username LIKE 'test_role%'
	ORDER BY rolname, orig_username
END
GO

CREATE PROC test_role_proc_babel_db_principal AS
BEGIN
	SELECT name, type_desc
	FROM sys.database_principals
	WHERE name LIKE 'test_role%'
	ORDER BY name
END
GO

CREATE PROC test_role_proc_babel_role_members AS
BEGIN
	SELECT dp1.name AS RoleName, dp1.type AS RoleType,
		   dp2.name AS MemberName, dp2.type AS MemberType
	FROM sys.database_role_members AS drm
	INNER JOIN sys.database_principals AS dp1
	ON drm.role_principal_id = dp1.principal_id
	INNER JOIN sys.database_principals AS dp2
	ON drm.member_principal_id = dp2.principal_id
	WHERE dp1.name != 'db_owner'
	ORDER BY dp1.name, dp2.name
END
GO
