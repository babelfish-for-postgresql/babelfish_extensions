CREATE PROC test_sp_addrole_proc @rolename AS sys.SYSNAME, @ownername AS sys.SYSNAME = NULL
AS
BEGIN
    IF @ownername IS NULL
	EXEC sp_addrole @rolename;
    ELSE
	EXEC sp_addrole @rolename, @ownername;
END
GO

CREATE FUNCTION dbo.test_sp_addrole_func(@rolename sys.SYSNAME, @ownername sys.SYSNAME = NULL) RETURNS INT
AS
BEGIN
DECLARE
    @tmp_sp_addrole TABLE(addRole sys.SYSNAME);
    IF @ownername IS NULL
	INSERT INTO @tmp_sp_addrole (addRole) EXEC sp_addrole @rolename;
    ELSE
	INSERT INTO @tmp_sp_addrole (addRole) EXEC sp_addrole @rolename, @ownername;
    RETURN (SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = @rolename);
END
GO

CREATE VIEW test_sp_addrole_view AS
SELECT dbo.test_sp_addrole_func('sp_addrole_dummy') AS Description
GO
