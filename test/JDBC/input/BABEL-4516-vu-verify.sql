USE [DATABASE_1];
GO

-- database users should be present.
EXEC [db1_SCHEMA_2].[babel_user_ext];
GO

-- dbo and guest roles should be member of sysadmin
SELECT count(*) FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles r ON (m.roleid = r.oid)
        JOIN sys.babelfish_authid_user_ext u ON (r.rolname = u.rolname)
WHERE m.member = (SELECT oid FROM pg_roles WHERE rolname = 'sysadmin')
AND u.database_name = 'database_1'AND (r.rolname like '%dbo' or r.rolname like '%guest');
GO

SELECT COUNT(*) FROM [Table_1];
GO

SELECT COUNT(*) FROM [DB1_My_Schema].[Table_2];
GO

SELECT COUNT(*) FROM [db1_SCHEMA_2].[DB1 My View];
GO

SELECT * FROM [db1_SCHEMA_2].[Func_2](555);
GO
