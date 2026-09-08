CREATE PROC test_sp_addrolemember_proc @rolename AS sys.SYSNAME, @membername AS sys.SYSNAME
AS
BEGIN
	EXEC sp_addrolemember @rolename, @membername;
END
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
