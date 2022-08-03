CREATE LOGIN babelfish_authid_user_ext_vu_prepare_login1 WITH PASSWORD = '123'
GO

CREATE USER babelfish_authid_user_ext_vu_prepare_user1 FOR LOGIN babelfish_authid_user_ext_vu_prepare_login1
GO

CREATE LOGIN babelfish_authid_user_ext_vu_prepare_login2 WITH PASSWORD = '123'
GO

CREATE USER babelfish_authid_user_ext_vu_prepare_user2 FOR LOGIN babelfish_authid_user_ext_vu_prepare_login2
GO

CREATE VIEW babelfish_authid_user_ext_vu_prepare_view
AS
SELECT rolname, login_name, type, orig_username, database_name, default_schema_name 
FROM sys.babelfish_authid_user_ext
WHERE rolname LIKE '%babelfish_authid_user_ext_vu_prepare_%'
ORDER BY rolname
GO

CREATE PROC babelfish_authid_user_ext_vu_prepare_proc
AS
SELECT rolname, login_name, type, orig_username, database_name, default_schema_name 
FROM sys.babelfish_authid_user_ext
WHERE rolname LIKE '%babelfish_authid_user_ext_vu_prepare_%'
ORDER BY rolname
GO

CREATE FUNCTION babelfish_authid_user_ext_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_authid_user_ext WHERE rolname LIKE '%babelfish_authid_user_ext_vu_prepare_%')
END
GO
