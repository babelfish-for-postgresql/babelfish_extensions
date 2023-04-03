create table t1(a int, b float, c bigint, d numeric);
go

create index i1_t1 on t1 (a, b);
go

select indid, name from sys.sysindexes where id=OBJECT_ID('t1');
go

select indid, name from dbo.sysindexes where id=OBJECT_ID('t1');
go

select count(*) from sys.sysindexes where id=OBJECT_ID('t1');
go

select count(*) from dbo.sysindexes where id=OBJECT_ID('t1');
go

create database db1;
go

use db1;
go

-- should not be visible here
select count(*) from sys.sysindexes where id=OBJECT_ID('t1');
go

select count(*) from dbo.sysindexes where id=OBJECT_ID('t1');
go

use master;
go

-- sysindexes should also exist in dbo schema
SELECT COUNT(*) FROM sys.SySInDeXes where id=OBJECT_ID('t1');
go

SELECT COUNT(*) FROM dbo.SySInDeXes where id=OBJECT_ID('t1');
go

-- In case of cross-db, sysindexes should also exist in dbo schema
-- should not be visible here
SELECT count(*) FROM db1.sys.SySInDeXes where id=OBJECT_ID('t1');
go

SELECT count(*) FROM db1.dbo.SySInDeXes where id=OBJECT_ID('t1');
go

-- clean up
drop index i1_t1 on t1
go

drop table t1
go

drop database db1;
go
