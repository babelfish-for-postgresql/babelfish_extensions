EXEC test_sp_droprolemember_proc 'sp_droprolemember_role1', 'sp_droprolemember_role2'
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_droprolemember
-- output into a table variable directly in the batch instead.
DECLARE @tmp_sp_droprolemember TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
INSERT INTO @tmp_sp_droprolemember (rolename, membername) EXEC sp_droprolemember 'sp_droprolemember_role1', 'sp_droprolemember_role3';
SELECT IS_ROLEMEMBER('sp_droprolemember_role1', 'sp_droprolemember_role3');
GO

DECLARE @tmp_sp_droprolemember_dummy TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
INSERT INTO @tmp_sp_droprolemember_dummy (rolename, membername) EXEC sp_droprolemember 'sp_droprolemember_role1', 'sp_droprolemember_dummy';
SELECT IS_ROLEMEMBER('sp_droprolemember_role1', 'sp_droprolemember_dummy');
GO

EXEC test_sp_droprolemember_proc 'sp_droprolemember_role1', 'sp_droprolemember_role4'
GO
