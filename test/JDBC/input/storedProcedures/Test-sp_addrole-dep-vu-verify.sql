EXEC test_sp_addrole_proc 'sp_addrole_role1'
GO

SELECT dbo.test_sp_addrole_func('sp_addrole_role2')
GO

SELECT * FROM test_sp_addrole_view
GO

EXEC test_sp_addrole_proc 'sp_addrole_role3'
GO

EXEC test_sp_addrole_proc 'sp_addrole_role1', ''
GO
