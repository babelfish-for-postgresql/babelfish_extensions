USE sysusersdb
GO

-- test view created on sys.sysusers
SELECT * FROM sysusers_dep_vu_prepare_view
GO

-- test procedure created on sys.sysusers
EXEC sysusers_dep_vu_prepare_proc
GO

-- test function created on sys.sysusers
SELECT * FROM sysusers_dep_vu_prepare_func()
GO

-- test sys.sysusers view, hasdbaccess should be 1 for newly created user
SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO

-- sysusers should also exist in schema "dbo"
SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM dbo.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO

-- test [GRANT CONNECT TO], hasdbaccess should be 1
GRANT CONNECT TO guest
GO

SELECT name, hasdbaccess, islogin
FROM sys.sysusers
WHERE name = 'guest'
GO

SELECT name, hasdbaccess, islogin
FROM dbo.sysusers
WHERE name = 'guest'
GO

-- test [REVOKE CONNECT FROM], hasdbaccess should be 0
REVOKE CONNECT FROM guest
GO

SELECT name, hasdbaccess, islogin
FROM sys.sysusers
WHERE name = 'guest'
GO

SELECT name, hasdbaccess, islogin
FROM dbo.sysusers
WHERE name = 'guest'
GO

-- test [REVOKE CONNECT FROM], hasdbaccess should be 0
REVOKE CONNECT FROM sysusers_dep_vu_prepare_user1
GO

SELECT name, hasdbaccess, islogin
FROM sys.sysusers
WHERE name = 'sysusers_dep_vu_prepare_user1'
GO

SELECT name, hasdbaccess, islogin
FROM dbo.sysusers
WHERE name = 'sysusers_dep_vu_prepare_user1'
GO

-- test [GRANT CONNECT TO], hasdbaccess should be 1
GRANT CONNECT TO sysusers_dep_vu_prepare_user1
GO

SELECT name, hasdbaccess, islogin
FROM sys.sysusers
WHERE name = 'sysusers_dep_vu_prepare_user1'
GO

SELECT name, hasdbaccess, islogin
FROM dbo.sysusers
WHERE name = 'sysusers_dep_vu_prepare_user1'
GO

USE master
GO

-- test sys.sysusers view, hasdbaccess should be 1 for newly created user
SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO

SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM dbo.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO

-- Cross-db
SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM sysusersdb.sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO

SELECT name, hasdbaccess, islogin, isntname, issqluser, issqlrole
FROM sysusersdb.dbo.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%' OR name = 'dbo' or name = 'guest'
ORDER BY name
GO