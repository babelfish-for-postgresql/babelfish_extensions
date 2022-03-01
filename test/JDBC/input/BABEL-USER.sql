CREATE LOGIN test1 WITH PASSWORD = 'abc';
GO

CREATE LOGIN test2 WITH PASSWORD = 'abc';
GO

CREATE LOGIN test3 WITH PASSWORD = 'abc';
GO

CREATE LOGIN test4 WITH PASSWORD = 'abc';
GO

SELECT DB_NAME();
GO

-- Check for default users
CREATE DATABASE db1;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
ORDER BY rolname;
GO

SELECT name, default_schema_name
FROM sys.database_principals
ORDER BY default_schema_name DESC, name;
GO

SELECT rolname, rolcreaterole FROM pg_roles
WHERE rolname LIKE '%dbo'
ORDER BY rolname;
GO

-- Test default create user
CREATE USER test1;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test1';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test1';
GO

SELECT user_name(user_id('test1'));
GO

-- Test create user with login uniqueness in the database
CREATE USER test2 FOR LOGIN test2;
GO

CREATE USER test3 FOR LOGIN test2;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test2';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test2';
GO

-- Test create user with schema option
CREATE USER test3 WITH DEFAULT_SCHEMA = sch3;
GO

CREATE SCHEMA sch3;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test3';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test3';
GO

-- Test create user with invalid login
CREATE USER test4 FOR LOGIN fake_login WITH DEFAULT_SCHEMA = dbo;
GO

-- Test with long name
-- 65 character length name
CREATE USER AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
FOR LOGIN test4;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
GO

-- Test alter user
ALTER USER test1 WITH DEFAULT_SCHEMA = sch3;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test1';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test1';
GO

ALTER USER test1 WITH DEFAULT_SCHEMA = NULL;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'test1';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test1';
GO

ALTER USER test1 WITH NAME = new_test1;
GO

SELECT rolname, login_name, orig_username, database_name, default_schema_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'new_test1';
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'new_test1';
GO

SELECT rolname FROM pg_roles WHERE rolname = 'master_new_test1';
GO

-- Test alter user on predefined database users
ALTER USER dbo WITH DEFAULT_SCHEMA = sch3;
GO

ALTER USER db_owner WITH NAME = new_db_owner;
GO

ALTER USER guest WITH NAME = new_guest;
GO

-- Clean up
DROP USER new_test1;
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test1';
GO

DROP USER IF EXISTS test2;
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test2';
GO

DROP USER test3;
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'test3';
GO

DROP USER AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
GO

SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
GO

DROP SCHEMA sch3;
GO

DROP LOGIN test1;
GO

DROP LOGIN test2;
GO

DROP LOGIN test3;
GO

DROP LOGIN test4;
GO

DROP DATABASE db1;
GO
