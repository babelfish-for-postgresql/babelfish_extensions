CREATE DATABASE sys_systypes_db;
GO

USE sys_systypes_db
GO

select name, status, length, variable, allownulls, printfmt, collation from sys.systypes order by name asc;
GO

CREATE TYPE sys_systypes_type FROM int;
GO

select name, status, length, variable, allownulls, printfmt, collation from sys.systypes where name = 'sys_systypes_type';
GO


-- variable length

select length, name from sys.systypes where variable = 1 order by name asc;
GO

CREATE TYPE sys_systypes_type2 FROM varchar;
GO

select name, status, length, variable, allownulls, printfmt, collation from sys.systypes where name = 'sys_systypes_type2';
GO

USE master;
GO

-- sys_systypes_type should not be visible here
SELECT count(*) FROM sys.systypes WHERE name = 'sys_systypes_type';
GO

CREATE TYPE sys_systypes_type FROM int;
GO


SELECT name, status, length, variable, allownulls, printfmt, collation FROM sys.systypes WHERE name = 'sys_systypes_type';
GO


DROP TYPE sys_systypes_type;
GO

USE sys_systypes_db
GO


DROP TYPE sys_systypes_type
GO

DROP TYPE sys_systypes_type2
GO


USE master
GO

DROP DATABASE sys_systypes_db
GO