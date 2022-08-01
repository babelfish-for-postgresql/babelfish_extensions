CREATE LOGIN test_babelfish_authid_user_ext_login1 WITH PASSWORD = '123'
GO

CREATE USER test_babelfish_authid_user_ext_user1 FOR LOGIN test_babelfish_authid_user_ext_login1
GO

CREATE LOGIN test_babelfish_authid_user_ext_login2 WITH PASSWORD = '123'
GO

CREATE USER test_babelfish_authid_user_ext_user2 FOR LOGIN test_babelfish_authid_user_ext_login2
GO

CREATE VIEW test_babelfish_authid_user_ext_view
AS
SELECT rolname, login_name, type, orig_username, database_name, default_schema_name 
FROM sys.babelfish_authid_user_ext
ORDER BY rolname
GO

CREATE PROC test_babelfish_authid_user_ext_proc
AS
SELECT rolname, login_name, type, orig_username, database_name, default_schema_name 
FROM sys.babelfish_authid_user_ext
ORDER BY rolname
GO

CREATE FUNCTION test_babelfish_authid_user_ext_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_authid_user_ext)
END
GO
