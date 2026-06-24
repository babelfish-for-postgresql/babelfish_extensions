CREATE PROC test_sp_droprolemember_proc @rolename AS sys.SYSNAME, @membername AS sys.SYSNAME
AS
BEGIN
	EXEC sp_droprolemember @rolename, @membername;
END
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
