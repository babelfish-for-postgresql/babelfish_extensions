DROP SCHEMA babel_user_vu_prepare_sch
GO

DROP PROC babel_user_vu_prepare_user_ext_proc
GO

DROP PROC babel_user_vu_prepare_db_principal_proc
GO

DROP LOGIN babel_user_vu_prepare_test1
GO

DROP LOGIN babel_user_vu_prepare_test2
GO

DROP LOGIN babel_user_vu_prepare_test3
GO

DROP LOGIN babel_user_vu_prepare_test4
GO

DROP LOGIN babel_user_vu_prepare_test5
GO

DROP LOGIN babel_user_vu_prepare_test6
GO

DROP LOGIN babel_user_vu_prepare_long_login_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
GO

USE babel_5890_db
GO

DROP PROC babel_role_vu_prepare_role_mapping
GO

DROP USER babel_5890_role_vu_prepare_r2;
GO

USE master
GO

DROP LOGIN babel_5890_role_vu_prepare_r1;
GO

DROP LOGIN babel_5890_role_vu_prepare_r2;
GO

DROP DATABASE babel_5890_db
GO
