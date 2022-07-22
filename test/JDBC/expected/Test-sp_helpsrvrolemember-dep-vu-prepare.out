CREATE PROC test_sp_helpsrvrolemember_proc @rolename AS sys.SYSNAME = NULL
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

CREATE FUNCTION dbo.test_sp_helpsrvrolemember_func() RETURNS INT
AS
BEGIN
	DECLARE @tmp_sp_helpsrvrolemember TABLE(ServerRole sys.SYSNAME,
											MemberName sys.SYSNAME,
											MemberSID sys.VARBINARY(85));
	INSERT INTO @tmp_sp_helpsrvrolemember (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember;
	RETURN (SELECT COUNT(*) FROM @tmp_sp_helpsrvrolemember);
END
GO

CREATE VIEW test_sp_helpsrvrolemember_view AS
SELECT dbo.test_sp_helpsrvrolemember_func() AS num
GO

CREATE LOGIN test_sp_helpsrvrolemember_login WITH PASSWORD='123'
GO
