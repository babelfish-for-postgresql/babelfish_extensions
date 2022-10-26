EXEC test_sp_addrolemember_proc 'sp_addrolemember_role1', 'sp_addrolemember_role2'
GO

SELECT dbo.test_sp_addrolemember_func('sp_addrolemember_role1', 'sp_addrolemember_role3')
GO

SELECT * FROM test_sp_addrolemember_view
GO

EXEC test_sp_addrolemember_proc 'sp_addrolemember_role1', 'sp_addrolemember_role4'
GO
