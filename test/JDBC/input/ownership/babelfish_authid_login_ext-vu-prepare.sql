CREATE LOGIN test_babelfish_authid_login_ext_login1 WITH PASSWORD = '123'
GO

CREATE LOGIN test_babelfish_authid_login_ext_login2 WITH PASSWORD = '123'
GO

CREATE VIEW test_babelfish_authid_login_ext_view
AS
SELECT rolname, is_disabled, type, default_database_name FROM sys.babelfish_authid_login_ext 
ORDER BY rolname
GO

CREATE PROC test_babelfish_authid_login_ext_proc
AS
SELECT rolname, is_disabled, type, default_database_name FROM sys.babelfish_authid_login_ext
ORDER BY rolname
GO

CREATE FUNCTION test_babelfish_authid_login_ext_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_authid_login_ext)
END
GO
