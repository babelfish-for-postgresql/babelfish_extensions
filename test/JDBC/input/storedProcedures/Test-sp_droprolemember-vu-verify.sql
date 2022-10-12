-- tsql
-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

EXEC sp_droprolemember 'sp_droprolemember_r1', 'sp_droprolemember_r2';
GO

-- Test whether sp_droprolemember_r2 is rolemember of sp_droprolemember_r1
SELECT IS_ROLEMEMBER('sp_droprolemember_r1', 'sp_droprolemember_r2')
GO

-- Test whether sp_droprolemember_u1 is rolemember of sp_droprolemember_r2
SELECT IS_ROLEMEMBER('sp_droprolemember_r2', 'sp_droprolemember_u1')
GO

EXEC sp_droprolemember 'sp_droprolemember_r2', 'sp_droprolemember_u1';
GO

-- Test whether sp_droprolemember_u1 is rolemember of sp_droprolemember_r2
SELECT IS_ROLEMEMBER('sp_droprolemember_r2', 'sp_droprolemember_u1')
GO
