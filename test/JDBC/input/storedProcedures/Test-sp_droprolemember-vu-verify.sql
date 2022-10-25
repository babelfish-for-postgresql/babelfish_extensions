-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

-- Throw an error when member doesn't exist
Exec sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r3';
GO
