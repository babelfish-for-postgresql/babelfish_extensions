-- tsql
CREATE ROLE sp_addrolemember_r1;
GO

CREATE ROLE sp_addrolemember_r2;
GO

CREATE ROLE sp_addrolemember_r3;
GO

CREATE LOGIN sp_addrolemember_login WITH PASSWORD = '123';
GO

CREATE USER sp_addrolemember_user FOR LOGIN sp_addrolemember_login;
GO

-- Throw error if no argument or more than 2 argument are passed to sp_addrolemember procedure
EXEC sp_addrolemember;
GO

EXEC sp_addrolemember '';
GO

EXEC sp_addrolemember '','','';
GO

-- Throw an error is role/member is empty
EXEC sp_addrolemember '', '';
GO

EXEC sp_addrolemember 'sp_addrolemember_role_doesnot_exist', '';
GO

EXEC sp_addrolemember '', 'sp_addrolemember_role_doesnot_exist';
GO

-- Throw an error when same roles are passed
Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_r1';
GO

-- Throw an error when member doesn't exist
Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_role_doesnot_exist';
GO

-- Throw an error when role doesn't exist or when an user/login is passed
Exec sp_addrolemember 'sp_addrolemember_role_doesnot_exist', 'sp_addrolemember_r1';
GO

Exec sp_addrolemember 'sp_addrolemember_user', 'sp_addrolemember_r1';
GO

Exec sp_addrolemember 'sp_addrolemember_login', 'sp_addrolemember_r1';
GO

-- Check whether sp_addrolemember_r2 is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_r2')
GO

Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_r2';
GO

-- Check whether sp_addrolemember_r2 is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_r2')
GO

-- Throw an error if role is already a member of member
Exec sp_addrolemember 'sp_addrolemember_r2', 'sp_addrolemember_r1';
GO

-- Can add user, role or group as an member for a role
Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_user';
GO

-- Check whether sp_addrolemember_user is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_user')
GO
