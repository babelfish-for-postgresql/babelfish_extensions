USE test_role_db
GO

DROP PROC test_role_proc_babel_user_ext
GO

DROP PROC test_role_proc_babel_db_principal
GO

DROP PROC test_role_proc_babel_role_members
GO


USE master
GO

DROP LOGIN test_role_role1
GO

-- Check if catalog is cleaned up
EXEC test_role_proc_babel_user_ext_master
GO

EXEC test_role_proc_babel_db_principal_master
GO

DROP PROC test_role_proc_babel_user_ext_master
GO

DROP PROC test_role_proc_babel_db_principal_master
GO

DROP DATABASE test_role_db
GO
