REATE PROC test_sp_helpsrvrolemember_proc @rolename AS sys.SYSNAME = NULL
AS
BEGIN
	DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME,
											MemberName sys.SYSNAME,
											MemberSID sys.VARBINARY(85));
	INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember @rolename;
	SELECT ServerRole, MemberName, (CASE WHEN MemberSID IS NULL THEN 0 ELSE 1 END)
	FROM @tmp_sp_helpsrvrolemember;
END
GO

CREATE LOGIN test_sp_helpsrvrolemember_login WITH PASSWORD='123'
GO

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

DROP LOGIN test_sp_helpsrvrolemember_login
GO

DROP PROC test_sp_helpsrvrolemember_proc
GO
