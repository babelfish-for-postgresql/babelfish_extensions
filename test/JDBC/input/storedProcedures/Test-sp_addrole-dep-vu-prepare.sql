CREATE PROC test_sp_addrole_proc @rolename AS sys.SYSNAME, @ownername AS sys.SYSNAME = NULL
AS
BEGIN
    IF @ownername IS NULL
	EXEC sp_addrole @rolename;
    ELSE
	EXEC sp_addrole @rolename, @ownername;
END
GO
