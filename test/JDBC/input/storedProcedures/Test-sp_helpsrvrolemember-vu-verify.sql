EXEC test_sp_helpsrvrolemember_proc
GO

SELECT dbo.test_sp_helpsrvrolemember_func()
GO

SELECT * FROM test_sp_helpsrvrolemember_view
GO

ALTER SERVER ROLE sysadmin ADD MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

SELECT dbo.test_sp_helpsrvrolemember_func()
GO

SELECT * FROM test_sp_helpsrvrolemember_view
GO

ALTER SERVER ROLE sysadmin DROP MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

SELECT dbo.test_sp_helpsrvrolemember_func()
GO

SELECT * FROM test_sp_helpsrvrolemember_view
GO

EXEC sp_helpsrvrolemember 'error'
GO
