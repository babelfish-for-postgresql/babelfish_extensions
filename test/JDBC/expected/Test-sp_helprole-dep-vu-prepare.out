CREATE PROC test_sp_helprole_proc @rolename AS sys.SYSNAME = NULL
AS
BEGIN
	DECLARE @tmp_sp_helprole TABLE(RoleName sys.SYSNAME, RoleId integer, IsAppRole integer);
	INSERT INTO @tmp_sp_helprole (RoleName, RoleId, IsAppRole) EXEC sp_helprole @rolename;
	SELECT RoleName, (CASE WHEN RoleId IS NULL THEN 0 ELSE 1 END), IsAppRole FROM @tmp_sp_helprole;
END
GO
