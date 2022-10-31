-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO

-- Throw an error is role/member is empty
EXEC sp_droprolemember '', '';
GO

EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist', '';
GO

EXEC sp_droprolemember '', 'sp_droprolemember_role_doesnot_exist';
GO

-- Throw an error if member does not exist
EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_role_doesnot_exist';
GO

-- Throw an error if role does not exist or user is passed as role
EXEC sp_droprolemember 'sp_droprolemember_role_doesnot_exist', 'sp_droprolemember_r1';
GO

EXEC sp_droprolemember 'sp_droprolemember_user', 'sp_droprolemember_r1';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO
