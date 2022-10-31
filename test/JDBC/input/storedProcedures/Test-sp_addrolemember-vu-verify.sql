-- tsql
CREATE ROLE sp_addrolemember_r1;
GO

CREATE ROLE sp_addrolemember_r2;
GO

CREATE ROLE sp_addrolemember_r3;
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

Exec sp_addrolemember 'sp_addrolemember_role_doesnot_exist', 'sp_addrolemember_r1';
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
