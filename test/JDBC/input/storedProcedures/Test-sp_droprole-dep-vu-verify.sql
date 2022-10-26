EXEC test_sp_droprole_proc 'sp_droprole_role1'
GO

SELECT dbo.test_sp_droprole_func('sp_droprole_role2')
GO

SELECT * FROM test_sp_droprole_view
GO

EXEC test_sp_droprole_proc 'sp_droprole_role3'
GO
