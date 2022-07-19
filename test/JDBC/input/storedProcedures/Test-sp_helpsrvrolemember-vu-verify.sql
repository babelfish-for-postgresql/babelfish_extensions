EXEC test_sp_helpsrvrolemember_proc
GO

ALTER SERVER ROLE sysadmin ADD MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

ALTER SERVER ROLE sysadmin DROP MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

EXEC sp_helpsrvrolemember 'error'
GO
