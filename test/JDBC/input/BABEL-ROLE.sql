SELECT DB_NAME()
GO

-- Test CREATE ROLE
CREATE ROLE test1
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test1'
GO

SELECT name, type_desc
FROM sys.database_principals
WHERE name = 'test1'
GO

-- Test database principal uniqueness
-- should fail
CREATE ROLE test1
GO

CREATE LOGIN test1 WITH PASSWORD = 'abc';
GO

-- should fail
CREATE USER test1
GO

CREATE LOGIN test2 WITH PASSWORD = 'abc';
GO

CREATE USER test2
GO

-- should fail
CREATE ROLE test2
GO

-- Test database principal uniqueness in a new database
CREATE DATABASE db1
GO

USE db1
GO

SELECT DB_NAME()
GO

CREATE ROLE test1
GO

CREATE ROLE test2
GO

CREATE PROC babel_user_ext AS
BEGIN
	SELECT rolname, type, orig_username, database_name
	FROM sys.babelfish_authid_user_ext
	WHERE orig_username LIKE 'test%'
	ORDER BY rolname, orig_username
END
GO

CREATE PROC babel_db_principal AS
BEGIN
	SELECT name, type_desc
	FROM sys.database_principals
	WHERE name LIKE 'test%'
	ORDER BY name
END
GO

CREATE PROC babel_role_members AS
BEGIN
	SELECT dp1.name AS RoleName, dp1.type AS RoleType,
		   dp2.name AS MemberName, dp2.type AS MemberType
	FROM sys.database_role_members AS drm
	INNER JOIN sys.database_principals AS dp1
	ON drm.role_principal_id = dp1.principal_id
	INNER JOIN sys.database_principals AS dp2
	ON drm.member_principal_id = dp2.principal_id
	ORDER BY dp1.name, dp2.name
END
GO

-- Expect to see roles master_test1, db1_test1, db1_test2
-- and user master_test2
EXEC babel_user_ext
GO

EXEC babel_db_principal
GO

-- Test ALTER ROLE
-- Add role as member
ALTER ROLE test1 ADD MEMBER test2
GO

-- Add user as member
CREATE LOGIN test3 WITH PASSWORD = 'abc'
GO

CREATE USER test3
GO

ALTER ROLE test1 ADD MEMBER test3
GO

CREATE LOGIN test4 WITH PASSWORD = 'abc'
GO

-- Add login as member, should fail
ALTER ROLE test1 ADD MEMBER test4
GO

-- Add itself as member, should fail
ALTER ROLE test1 ADD MEMBER test1
GO

-- Cross member, should fail
ALTER ROLE test2 ADD MEMBER test1
GO

-- Add special principals as member, should fail
ALTER ROLE test1 ADD MEMBER dbo
GO

ALTER ROLE test1 ADD MEMBER db_owner
GO

-- Add/drop member to db_owner, should fail before full support
ALTER ROLE db_owner ADD MEMBER test1
GO

ALTER ROLE db_owner DROP MEMBER test1
GO

CREATE USER test4
GO

ALTER ROLE test2 ADD MEMBER test4
GO

-- Expect to see roles master_test1, db1_test1, db1_test2
-- and users master_test2, db1_test3, db1_test4
EXEC babel_user_ext
GO

EXEC babel_db_principal
GO

EXEC babel_role_members
GO

-- Role renaming
ALTER ROLE test1 WITH NAME = test1_new
GO

EXEC babel_user_ext
GO

EXEC babel_db_principal
GO

EXEC babel_role_members
GO

-- Drop role from member
ALTER ROLE test1_new DROP MEMBER test2
GO

-- Drop user from member
ALTER ROLE test1_new DROP MEMBER test3
GO

-- Expect to see roles master_test1, db1_test1_new, db1_test2
-- and users master_test2, db1_test3
EXEC babel_user_ext
GO

EXEC babel_db_principal
GO

EXEC babel_role_members
GO

-- Test DROP ROLE
DROP USER test3
GO

DROP USER test4
GO

DROP ROLE test2
GO

DROP ROLE test1_new
GO

DROP PROC babel_user_ext
GO

DROP PROC babel_db_principal
GO

DROP PROC babel_role_members
GO

USE master
GO

DROP USER test2
GO

DROP ROLE test1
GO

DROP LOGIN test1
GO

DROP LOGIN test2
GO

DROP LOGIN test3
GO

DROP LOGIN test4
GO

DROP DATABASE db1
GO

-- Check if catalog is cleaned up
SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username LIKE 'test%'
GO

SELECT rolname, type 
FROM sys.babelfish_authid_login_ext
WHERE rolname LIKE 'test%'
GO
