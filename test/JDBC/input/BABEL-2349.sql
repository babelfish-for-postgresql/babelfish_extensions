create table t1(a int, b float, c bigint, d numeric);
go

create index i1_t1 on t1 (a, b);
go

select name from sys.sysindexes where id=OBJECT_ID('t1');
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

-- clean up
drop index i1_t1 on t1
go

drop table t1
go

drop database db1;
go
