create table t1(a int, b float, c bigint, d numeric);
go

create index i1_t1 on t1 (a, b);
go

select indid, name from sys.sysindexes where id=OBJECT_ID('t1');
go

select count(*) from sys.sysindexes where id=OBJECT_ID('t1');
go

create database db1;
go

use db1;
go

-- should not be visible here
select count(*) from sys.sysindexes where id=OBJECT_ID('t1');
go

use master;
go

-- sysindexes should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT COUNT(*) FROM sys.    SySInDeXes where id=OBJECT_ID('t1');
go

SELECT COUNT(*) FROM dbo.    SySInDeXes where id=OBJECT_ID('t1');
go

-- In case of cross-db, sysindexes should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
-- should not be visible here
SELECT COUNT(*) FROM db1.sys.     SySInDeXes where id=OBJECT_ID('t1');
go

SELECT COUNT(*) FROM db1.dbo.     SySInDeXes where id=OBJECT_ID('t1');
go

-- clean up
drop index i1_t1 on t1
go

drop table t1
go

drop database db1;
go
