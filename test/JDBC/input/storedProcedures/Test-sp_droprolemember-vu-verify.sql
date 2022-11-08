-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

CREATE LOGIN sp_droprolemember_login WITH PASSWORD = '123';
GO

CREATE USER sp_droprolemember_user FOR LOGIN sp_droprolemember_login;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_user
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_user;
GO

-- Throw error if no argument or more than 1 argument are passed to sp_droprolemember procedure
EXEC sp_droprolemember;
GO

EXEC sp_droprolemember NULL;
GO

EXEC sp_droprolemember '';
GO

EXEC sp_droprolemember '','','';
GO

-- Throw an error is role/member is empty
EXEC sp_droprolemember '', '';
GO

EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist', '';
GO

EXEC sp_droprolemember '', 'sp_droprolemember_role_doesnot_exist';
GO

EXEC sp_droprolemember NULL, NULL;
GO

EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist', NULL;
GO

EXEC sp_droprolemember NULL, 'sp_droprolemember_role_doesnot_exist';
GO

-- Throw an error if member does not exist
EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_role_doesnot_exist';
GO

-- Throw an error if role does not exist or user/login is passed as role
EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist', 'sp_droprolemember_r1';
GO

EXEC sp_droprolemember 'sp_droprolemember_user', 'sp_droprolemember_r1';
GO

EXEC sp_droprolemember 'sp_droprolemember_login', 'sp_droprolemember_r1';
GO

EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist_1', 'sp_droprolemember_role_doesnot_exist_2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_user';
GO

-- Test whether sp_droprolemember_user is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_user')
GO

-- case insensitivity check
-- role 'sp_droprolemember_r1', 'sp_droprolemember_r2' exists in DB
EXEC sp_droprolemember 'SP_DROPROLEMEMBER_R1', 'sp_droprolemember_r2';
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'SP_DROPROLEMEMBER_R2';
GO

-- procedure does not remove leading spaces but removes trailing whitespaces if exists in rolename/membername
EXEC sp_droprolemember ' sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

EXEC sp_droprolemember 'sp_droprolemember_r1 ', 'sp_droprolemember_r2';
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', ' sp_droprolemember_r2';
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2 ';
GO
