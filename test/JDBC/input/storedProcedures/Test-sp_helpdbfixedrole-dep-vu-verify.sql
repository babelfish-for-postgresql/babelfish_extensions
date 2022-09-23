EXEC test_sp_helpdbfixedrole_proc
GO

EXEC test_sp_helpdbfixedrole_proc 'db_owner'
GO

SELECT dbo.test_sp_helpdbfixedrole_func()
GO

SELECT * FROM test_sp_helpdbfixedrole_view
GO

EXEC test_sp_helpdbfixedrole_proc 'DB_securityadmin'
GO

EXEC test_sp_helpdbfixedrole_proc 'error'
GO
