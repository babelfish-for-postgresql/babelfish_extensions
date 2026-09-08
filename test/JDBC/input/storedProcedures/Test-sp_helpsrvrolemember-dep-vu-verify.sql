EXEC test_sp_helpsrvrolemember_proc
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_helpsrvrolemember
-- output into a table variable directly in the batch instead.
DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER test_sp_helpsrvrolemember_login
GO

EXEC test_sp_helpsrvrolemember_proc 'sysadmin'
GO

DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85));
INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember;
GO

EXEC sp_helpsrvrolemember 'error'
GO
