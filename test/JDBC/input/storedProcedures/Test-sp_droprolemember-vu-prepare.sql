-- tsql
CREATE ROLE sp_droprolemember_r1;
GO

CREATE ROLE sp_droprolemember_r2;
GO

-- sp_droprolemember_r1 -> sp_droprolemember_r2
ALTER ROLE sp_droprolemember_r1 ADD MEMBER sp_droprolemember_r2;
GO
