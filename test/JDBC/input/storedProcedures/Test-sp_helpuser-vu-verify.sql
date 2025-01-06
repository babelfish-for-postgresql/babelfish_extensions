select * from sys.babelfish_authid_user_ext
GO

SELECT r.rolname AS role_name FROM pg_auth_members m JOIN pg_roles r ON m.roleid = r.oid JOIN pg_roles u ON m.member = u.oid WHERE u.rolname IN ('test_sp_helpuser_vu_prepare_db_dbo', 'master_dbo') ORDER BY r.rolname;
GO

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

