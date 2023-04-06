CREATE LOGIN sysusers_dep_vu_prepare_login1 WITH PASSWORD = '123'
GO

CREATE USER sysusers_dep_vu_prepare_user1 FOR LOGIN sysusers_dep_vu_prepare_login1
GO

CREATE LOGIN sysusers_dep_vu_prepare_login2 WITH PASSWORD = '123'
GO

CREATE USER sysusers_dep_vu_prepare_user2 FOR LOGIN sysusers_dep_vu_prepare_login2
GO

CREATE VIEW sysusers_dep_vu_prepare_view
AS
SELECT name, roles, islogin, hasdbaccess, isntname, isntgroup, isntuser, issqluser, isaliased, issqlrole, isapprole
FROM sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%'
ORDER BY name
GO

CREATE PROC sysusers_dep_vu_prepare_proc
AS
SELECT name, roles, islogin, hasdbaccess, isntname, isntgroup, isntuser, issqluser, isaliased, issqlrole, isapprole
FROM sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%'
ORDER BY name
GO

CREATE FUNCTION sysusers_dep_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.sysusers WHERE name LIKE '%sysusers_dep_vu_prepare_%')
END
GO