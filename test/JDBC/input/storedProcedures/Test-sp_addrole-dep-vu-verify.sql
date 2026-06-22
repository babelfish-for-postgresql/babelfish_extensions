EXEC test_sp_addrole_proc 'sp_addrole_role1'
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_addrole output
-- into a table variable directly in the batch instead.
DECLARE @tmp_sp_addrole TABLE(addRole sys.SYSNAME);
INSERT INTO @tmp_sp_addrole (addRole) EXEC sp_addrole 'sp_addrole_role2';
SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = 'sp_addrole_role2';
GO

DECLARE @tmp_sp_addrole_dummy TABLE(addRole sys.SYSNAME);
INSERT INTO @tmp_sp_addrole_dummy (addRole) EXEC sp_addrole 'sp_addrole_dummy';
SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = 'sp_addrole_dummy';
GO

EXEC test_sp_addrole_proc 'sp_addrole_role3'
GO

EXEC test_sp_addrole_proc 'sp_addrole_role1', ''
GO
