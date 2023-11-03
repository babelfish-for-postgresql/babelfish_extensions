USE [DATABASE_1];
GO

-- login_name should be empty and database users should
-- be present after database-level restore.
EXEC [db1_SCHEMA_2].[babel_user_ext];
GO

-- dbo and guest roles should be member of sysadmin
SELECT r.rolname FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles r
        ON (m.roleid = r.oid)
WHERE m.member = (SELECT oid FROM pg_roles WHERE rolname = 'sysadmin')
AND r.rolname LIKE 'database_1%' ORDER BY r.rolname;
GO

SELECT COUNT(*) FROM [Table_1];
GO

SELECT COUNT(*) FROM [DB1_My_Schema].[Table_2];
GO

SELECT COUNT(*) FROM [db1_SCHEMA_2].[DB1 My View];
GO

SELECT * FROM [db1_SCHEMA_2].[Func_2](555);
GO
