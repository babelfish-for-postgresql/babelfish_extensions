EXEC test_sp_helpsrvrolemember_proc
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

SELECT * FROM test_sp_helpsrvrolemember_func()
GO
