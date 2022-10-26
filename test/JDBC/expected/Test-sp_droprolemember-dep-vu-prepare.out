CREATE PROC test_sp_droprolemember_proc @rolename AS sys.SYSNAME, @membername AS sys.SYSNAME
AS
BEGIN
	EXEC sp_droprolemember @rolename, @membername;
END
GO


CREATE FUNCTION dbo.test_sp_droprolemember_func(@rolename sys.SYSNAME, @membername sys.SYSNAME) RETURNS INT
AS
BEGIN
DECLARE
    @tmp_sp_droprolemember TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
	INSERT INTO @tmp_sp_droprolemember (rolename, membername) EXEC sp_droprolemember @rolename, @membername;
    RETURN (SELECT IS_ROLEMEMBER(@rolename, @membername));
END
GO


CREATE VIEW test_sp_droprolemember_view AS
SELECT dbo.test_sp_droprolemember_func('sp_droprolemember_role1','sp_droprolemember_dummy') AS Description
GO


CREATE ROLE sp_droprolemember_role1
GO

CREATE ROLE sp_droprolemember_role2
GO

CREATE ROLE sp_droprolemember_role3
GO

CREATE ROLE sp_droprolemember_role4
GO

CREATE ROLE sp_droprolemember_dummy
GO

ALTER ROLE sp_droprolemember_role1 ADD MEMBER sp_droprolemember_role2
GO

ALTER ROLE sp_droprolemember_role1 ADD MEMBER sp_droprolemember_role3
GO

ALTER ROLE sp_droprolemember_role1 ADD MEMBER sp_droprolemember_role4
GO

ALTER ROLE sp_droprolemember_role1 ADD MEMBER sp_droprolemember_dummy
GO
