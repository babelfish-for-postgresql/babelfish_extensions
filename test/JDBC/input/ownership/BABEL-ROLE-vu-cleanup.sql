USE babel_role_vu_prepare_db
GO

DROP PROC babel_role_vu_prepare_user_ext
GO

DROP PROC babel_role_vu_prepare_db_principal
GO

DROP PROC babel_role_vu_prepare_role_members
GO


USE master
GO

DROP LOGIN babel_role_vu_prepare_login1
GO

DROP LOGIN babel_role_vu_prepare_login2
GO

DROP LOGIN babel_role_vu_prepare_login3
GO

-- Check if catalog is cleaned up
EXEC babel_role_vu_prepare_user_ext_master
GO

EXEC babel_role_vu_prepare_db_principal_master
GO

DROP PROC babel_role_vu_prepare_user_ext_master
GO

DROP PROC babel_role_vu_prepare_db_principal_master
GO

DROP DATABASE babel_role_vu_prepare_db
GO
