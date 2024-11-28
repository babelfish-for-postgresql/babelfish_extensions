CREATE LOGIN babel_user_vu_prepare_test1 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_test2 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_test3 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_test4 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_test5 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_test6 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_user_vu_prepare_long_login_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA WITH PASSWORD = 'abc';
GO

CREATE PROC babel_user_vu_prepare_user_ext_proc AS
BEGIN
SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username LIKE 'babel_user_vu_prepare%'
ORDER BY orig_username
END
GO

CREATE PROC babel_user_vu_prepare_db_principal_proc AS
BEGIN
SELECT name, default_schema_name
FROM sys.database_principals
WHERE name LIKE 'babel_user_vu_prepare%'
ORDER BY name
END
GO

CREATE SCHEMA babel_user_vu_prepare_sch
GO
