CREATE LOGIN database_principals_dep_vu_prepare_login1 WITH PASSWORD = '123'
GO

CREATE USER database_principals_dep_vu_prepare_user1 FOR LOGIN database_principals_dep_vu_prepare_login1
GO

CREATE LOGIN database_principals_dep_vu_prepare_login2 WITH PASSWORD = '123'
GO

CREATE USER database_principals_dep_vu_prepare_user2 FOR LOGIN database_principals_dep_vu_prepare_login2
GO

CREATE VIEW database_principals_dep_vu_prepare_view
AS
SELECT name, type, type_desc, default_schema_name, is_fixed_role, authentication_type, default_language_name, allow_encrypted_value_modifications
FROM sys.database_principals
WHERE name LIKE '%database_principals_dep_vu_prepare_%'
ORDER BY name
GO

CREATE PROC database_principals_dep_vu_prepare_proc
AS
SELECT name, type, type_desc, default_schema_name, is_fixed_role, authentication_type, default_language_name, allow_encrypted_value_modifications
FROM sys.database_principals
WHERE name LIKE '%database_principals_dep_vu_prepare_%'
ORDER BY name
GO

CREATE FUNCTION database_principals_dep_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.database_principals WHERE name LIKE '%database_principals_dep_vu_prepare_%')
END
GO

