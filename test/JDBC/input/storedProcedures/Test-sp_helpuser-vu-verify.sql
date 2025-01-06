-- verify
EXEC Test_sp_helpuser_vu_prepare_check_helpuser 'dbo';
GO

USE Test_sp_helpuser_vu_prepare_db;
GO

EXEC Test_sp_helpuser_vu_prepare_check_helpuser;
GO

EXEC Test_sp_helpuser_vu_prepare_check_helpuser 'dbo';
GO

-- cleanup
DROP PROCEDURE Test_sp_helpuser_vu_prepare_check_helpuser
GO

USE master;
GO

DROP DATABASE Test_sp_helpuser_vu_prepare_db;
GO

DROP PROCEDURE Test_sp_helpuser_vu_prepare_check_helpuser
GO

