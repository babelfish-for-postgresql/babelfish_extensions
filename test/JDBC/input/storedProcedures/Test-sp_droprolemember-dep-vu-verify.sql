EXEC test_sp_droprolemember_proc 'sp_droprolemember_role1', 'sp_droprolemember_role2'
GO

SELECT dbo.test_sp_droprolemember_func('sp_droprolemember_role1', 'sp_droprolemember_role3')
GO

SELECT * FROM test_sp_droprolemember_view
GO

EXEC test_sp_droprolemember_proc 'sp_droprolemember_role1', 'sp_droprolemember_role4'
GO
