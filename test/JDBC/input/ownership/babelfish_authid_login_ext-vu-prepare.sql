CREATE LOGIN babelfish_authid_login_ext_vu_prepare_login1 WITH PASSWORD = '123'
GO

CREATE LOGIN babelfish_authid_login_ext_vu_prepare_login2 WITH PASSWORD = '123'
GO

CREATE VIEW babelfish_authid_login_ext_vu_prepare_view
AS
SELECT rolname, is_disabled, type, default_database_name 
FROM sys.babelfish_authid_login_ext 
WHERE rolname LIKE '%babelfish_authid_login_ext_vu_prepare%'
ORDER BY rolname
GO

CREATE PROC babelfish_authid_login_ext_vu_prepare_proc
AS
SELECT rolname, is_disabled, type, default_database_name 
FROM sys.babelfish_authid_login_ext
WHERE rolname LIKE '%babelfish_authid_login_ext_vu_prepare%'
ORDER BY rolname
GO

CREATE FUNCTION babelfish_authid_login_ext_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_authid_login_ext WHERE rolname LIKE '%babelfish_authid_login_ext_vu_prepare%')
END
GO
