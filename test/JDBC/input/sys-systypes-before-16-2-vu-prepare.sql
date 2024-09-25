CREATE DATABASE sys_systypes_db;
GO

USE sys_systypes_db
GO


CREATE TYPE sys_systypes_type FROM int;
GO

CREATE view sys_systypes_view1 AS
select name, status, length, variable, allownulls, printfmt, collation from sys.systypes order by name asc;
GO


CREATE view sys_systypes_view2 AS
select name, status, length, variable, allownulls, printfmt, collation from sys.systypes where name = 'sys_systypes_type';
GO


-- variable length
CREATE view sys_systypes_view3 AS
select length, name from sys.systypes where variable = 1 order by name asc;
GO

CREATE TYPE sys_systypes_type2 FROM varchar;
GO

CREATE view sys_systypes_view4 AS
select name, status, length, variable, allownulls, printfmt, collation from sys.systypes where name = 'sys_systypes_type2';
GO