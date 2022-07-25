SELECT DB_NAME()
GO

-- Test CREATE ROLE
CREATE ROLE test_role_role1
GO

EXEC test_role_proc_babel_user_ext_master
GO

EXEC test_role_proc_babel_db_principal_master
GO

-- Test database principal uniqueness
-- should fail, duplicate role name
CREATE ROLE test_role_role1
GO

-- Can create a login with same name
CREATE LOGIN test_role_role1 WITH PASSWORD = 'abc';
GO

-- should fail, cannot create a user with same name in same db
CREATE USER test_role_role1
GO

-- should fail, already have a user with this name in same db
CREATE ROLE test_role_user1
GO

-- Test database principal uniqueness in a new database
USE test_role_db
GO

SELECT DB_NAME()
GO

-- It's ok to use duplicate role name in a different db
CREATE ROLE test_role_role1
GO

CREATE ROLE test_role_role2
GO

EXEC test_role_proc_babel_user_ext
GO

EXEC test_role_proc_babel_db_principal
GO

-- Test ALTER ROLE
-- Add role as member
ALTER ROLE test_role_role1 ADD MEMBER test_role_role2
GO

-- Add user as member
CREATE LOGIN test_role_login2 WITH PASSWORD = 'abc'
GO

CREATE USER test_role_user2 FOR LOGIN test_role_login2
GO

ALTER ROLE test_role_role1 ADD MEMBER test_role_user2
GO

CREATE LOGIN test_role_login3 WITH PASSWORD = 'abc'
GO

-- Add login as member, should fail
ALTER ROLE test_role_role1 ADD MEMBER test_role_login3
GO

-- Add itself as member, should fail
ALTER ROLE test_role_role1 ADD MEMBER test_role_role1
GO

-- Cross member, should fail
ALTER ROLE test_role_role2 ADD MEMBER test_role_role1
GO

-- Add special principals as member, should fail
ALTER ROLE test_role_role1 ADD MEMBER dbo
GO

ALTER ROLE test_role_role1 ADD MEMBER db_owner
GO

-- Add/drop member to db_owner, should fail before full support
ALTER ROLE db_owner ADD MEMBER test_role_role1
GO

ALTER ROLE db_owner DROP MEMBER test_role_role1
GO

CREATE USER test_role_user3 FOR LOGIN test_role_login3
GO

ALTER ROLE test_role_role2 ADD MEMBER test_role_user3
GO

EXEC test_role_proc_babel_user_ext
GO

EXEC test_role_proc_babel_db_principal
GO

EXEC test_role_proc_babel_role_members
GO

-- Role renaming
ALTER ROLE test_role_role1 WITH NAME = test_role_role1_new
GO

EXEC test_role_proc_babel_user_ext
GO

EXEC test_role_proc_babel_db_principal
GO

EXEC test_role_proc_babel_role_members
GO

-- Drop role from member
ALTER ROLE test_role_role1_new DROP MEMBER test_role_role2
GO

-- Drop user from member
ALTER ROLE test_role_role1_new DROP MEMBER test_role_user2
GO

EXEC test_role_proc_babel_user_ext
GO

EXEC test_role_proc_babel_db_principal
GO

EXEC test_role_proc_babel_role_members
GO

ALTER ROLE test_role_role2 DROP MEMBER test_role_user3
GO

-- Test DROP ROLE
DROP USER test_role_user2
GO

DROP USER test_role_user3
GO

DROP ROLE test_role_role1_new
GO

DROP ROLE test_role_role2
GO

USE master
GO

DROP USER test_role_user1
GO

DROP ROLE test_role_role1
GO

DROP LOGIN test_role_login1
GO

DROP LOGIN test_role_login2
GO

DROP LOGIN test_role_login3
GO
