SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'db_owner');
GO

CREATE DATABASE db1;
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'db_owner');
GO

CREATE LOGIN login1 WITH PASSWORD = '123';
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'login1');
GO

CREATE LOGIN login2 WITH PASSWORD = 'abc';
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'login2');
GO

DROP LOGIN login1;
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'login1');
GO

DROP LOGIN login2;
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'login2');
GO

DROP DATABASE db1;
GO

SELECT COUNT(*) FROM pg_auth_members
WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'guest')
AND "member" = (SELECT oid FROM pg_roles WHERE rolname = 'db_owner');
GO
