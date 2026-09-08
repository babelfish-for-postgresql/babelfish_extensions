EXEC test_sp_droprole_proc 'sp_droprole_role1'
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_droprole output
-- into a table variable directly in the batch instead.
DECLARE @tmp_sp_droprole TABLE(dropRole sys.SYSNAME);
INSERT INTO @tmp_sp_droprole (dropRole) EXEC sp_droprole 'sp_droprole_role2';
SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = 'sp_droprole_role2';
GO

DECLARE @tmp_sp_droprole_dummy TABLE(dropRole sys.SYSNAME);
INSERT INTO @tmp_sp_droprole_dummy (dropRole) EXEC sp_droprole 'sp_droprole_dummy';
SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = 'sp_droprole_dummy';
GO

EXEC test_sp_droprole_proc 'sp_droprole_role3'
GO
