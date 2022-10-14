-- tsql
-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

-- Throw an error when member doesn't exist
Exec sp_droprolemember 'sp_addrolemember_r1', 'sp_addrolemember_r3';
GO
