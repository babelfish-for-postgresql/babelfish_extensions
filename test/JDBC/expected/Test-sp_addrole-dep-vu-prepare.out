CREATE PROC test_sp_addrole_proc @rolename AS sys.SYSNAME
AS
BEGIN
	EXEC sp_addrole @rolename;
END
GO


CREATE FUNCTION dbo.test_sp_addrole_func(@rolename sys.SYSNAME) RETURNS INT
AS
BEGIN
DECLARE
    @tmp_sp_addrole TABLE(addRole sys.SYSNAME);
	INSERT INTO @tmp_sp_addrole (addRole) EXEC sp_addrole @rolename;
    RETURN (SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = @rolename);
END
GO


CREATE VIEW test_sp_addrole_view AS
SELECT dbo.test_sp_addrole_func('sp_addrole_dummy') AS Description
GO
