CREATE PROC test_sp_helprolemember_proc @rolename AS sys.SYSNAME = NULL
AS
BEGIN
	DECLARE @tmp_sp_helprolemember TABLE(RoleName sys.SYSNAME, MemberName sys.SYSNAME, MemberSID sys.VARBINARY(85) );
	INSERT INTO @tmp_sp_helprolemember (RoleName, MemberName, MemberSID ) EXEC sp_helprolemember @rolename;
	SELECT RoleName, MemberName , (CASE WHEN MemberSID IS NULL THEN 0 ELSE 1 END) FROM @tmp_sp_helprolemember;
END
GO
