
USE sys_systypes_db
GO

SELECT * FROM sys_systypes_view1
GO

SELECT * FROM sys_systypes_view2
GO

-- variable length
SELECT * FROM sys_systypes_view3
GO


SELECT * FROM sys_systypes_view4
GO

USE master;
GO

-- sys_systypes_type should not be visible here
SELECT count(*) FROM sys.systypes WHERE name = 'sys_systypes_type';
GO

-- systypes should also exist in schema "dbo"
SELECT count(*) FROM dbo.systypes WHERE name = 'sys_systypes_type';
GO

-- Cross-db
SELECT count(*) FROM sys_systypes_db.sys.systypes WHERE name = 'sys_systypes_type';
GO

SELECT count(*) FROM sys_systypes_db.dbo.systypes WHERE name = 'sys_systypes_type';
GO

CREATE TYPE sys_systypes_type FROM int;
GO

SELECT name, status, length, variable, allownulls, printfmt, collation FROM sys.systypes WHERE name = 'sys_systypes_type';
GO

SELECT name, status, length, variable, allownulls, printfmt, collation FROM dbo.systypes WHERE name = 'sys_systypes_type';
GO

-- Cross-db
SELECT name, status, length, variable, allownulls, printfmt, collation FROM sys_systypes_db.sys.systypes WHERE name = 'sys_systypes_type';
GO

SELECT name, status, length, variable, allownulls, printfmt, collation FROM sys_systypes_db.dbo.systypes WHERE name = 'sys_systypes_type';
GO

DROP TYPE sys_systypes_type;
GO


USE sys_systypes_db
GO


DROP TYPE sys_systypes_type
GO

DROP TYPE sys_systypes_type2
GO

DROP VIEW sys_systypes_view4
GO

DROP VIEW sys_systypes_view3
GO

DROP VIEW sys_systypes_view2
GO

DROP VIEW sys_systypes_view1
GO

USE master
GO

DROP DATABASE sys_systypes_db
GO