EXEC test_sp_addrolemember_proc 'sp_addrolemember_role1', 'sp_addrolemember_role2'
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_addrolemember
-- output into a table variable directly in the batch instead.
DECLARE @tmp_sp_addrolemember TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
INSERT INTO @tmp_sp_addrolemember (rolename, membername) EXEC sp_addrolemember 'sp_addrolemember_role1', 'sp_addrolemember_role3';
SELECT IS_ROLEMEMBER('sp_addrolemember_role1', 'sp_addrolemember_role3');
GO

DECLARE @tmp_sp_addrolemember_dummy TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
INSERT INTO @tmp_sp_addrolemember_dummy (rolename, membername) EXEC sp_addrolemember 'sp_addrolemember_role1', 'sp_addrolemember_dummy';
SELECT IS_ROLEMEMBER('sp_addrolemember_role1', 'sp_addrolemember_dummy');
GO

EXEC test_sp_addrolemember_proc 'sp_addrolemember_role1', 'sp_addrolemember_role4'
GO
