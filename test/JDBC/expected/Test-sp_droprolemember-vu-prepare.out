-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

CREATE LOGIN sp_droprolemember_l1 WITH PASSWORD = '123';
GO

CREATE USER sp_droprolemember_u1 FOR LOGIN sp_droprolemember_l1;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO

-- sp_droprolemember_r2 -> sp_droprolemember_u1
ALTER ROLE sp_droprolemember_r2 ADD MEMBER sp_droprolemember_u1;
GO
