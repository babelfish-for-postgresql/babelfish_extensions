CREATE ROLE sp_helprolemember_role1;
GO

CREATE ROLE sp_helprolemember_role2;
GO

ALTER ROLE sp_helprolemember_role1 ADD MEMBER sp_helprolemember_role2;
GO

EXEC test_sp_helprolemember_proc "sp_helprolemember_role1";
GO

-- case insensitivity check
EXEC test_sp_helprolemember_proc "SP_helprolemember_RoLe1";
GO
