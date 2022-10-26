-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

CREATE ROLE sp_droprolemember_r3;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r3
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r3;
GO

-- Throw an error if passed rolename or membername contains \ or between whitespaces
Exec sp_droprolemember 'sp_droprolemember_ r1', 'sp_droprolemember_r2';
GO

Exec sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_\r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

-- Check whether sp_droprolemember_r3 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r3')
GO

-- Executes even if rolename or membername contains leading and trailing whitespaces
Exec sp_droprolemember '    sp_droprolemember_r1   ', '    sp_droprolemember_r3    ';
GO

-- Check whether sp_droprolemember_r3 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r3')
GO

-- Throw an error when member doesn't exist
Exec sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r4';
GO
