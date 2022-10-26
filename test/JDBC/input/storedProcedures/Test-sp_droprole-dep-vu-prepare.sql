CREATE PROC test_sp_droprole_proc @rolename AS sys.SYSNAME
AS
BEGIN
	EXEC sp_droprole @rolename;
END
GO


CREATE FUNCTION dbo.test_sp_droprole_func(@rolename sys.SYSNAME) RETURNS INT
AS
BEGIN
DECLARE
    @tmp_sp_droprole TABLE(dropRole sys.SYSNAME);
	INSERT INTO @tmp_sp_droprole (dropRole) EXEC sp_droprole @rolename;
    RETURN (SELECT count(*) FROM sys.babelfish_authid_user_ext where orig_username = @rolename);
END
GO


CREATE VIEW test_sp_droprole_view AS
SELECT dbo.test_sp_droprole_func('sp_droprole_dummy') AS Description
GO


CREATE ROLE sp_droprole_role1
GO

CREATE ROLE sp_droprole_role2
GO

CREATE ROLE sp_droprole_role3
GO

CREATE ROLE sp_droprole_dummy
GO
