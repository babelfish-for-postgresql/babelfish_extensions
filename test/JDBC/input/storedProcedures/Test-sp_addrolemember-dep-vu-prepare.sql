CREATE PROC test_sp_addrolemember_proc @rolename AS sys.SYSNAME, @membername AS sys.SYSNAME
AS
BEGIN
	EXEC sp_addrolemember @rolename, @membername;
END
GO


CREATE FUNCTION dbo.test_sp_addrolemember_func(@rolename sys.SYSNAME, @membername sys.SYSNAME) RETURNS INT
AS
BEGIN
DECLARE
    @tmp_sp_addrolemember TABLE(rolename sys.SYSNAME, membername sys.SYSNAME);
	INSERT INTO @tmp_sp_addrolemember (rolename, membername) EXEC sp_addrolemember @rolename, @membername;
    RETURN (SELECT IS_ROLEMEMBER(@rolename, @membername));
END
GO


CREATE VIEW test_sp_addrolemember_view AS
SELECT dbo.test_sp_addrolemember_func('sp_addrolemember_role1','sp_addrolemember_dummy') AS Description
GO


CREATE ROLE sp_addrolemember_role1
GO

CREATE ROLE sp_addrolemember_role2
GO

CREATE ROLE sp_addrolemember_role3
GO

CREATE ROLE sp_addrolemember_role4
GO

CREATE ROLE sp_addrolemember_dummy
GO
