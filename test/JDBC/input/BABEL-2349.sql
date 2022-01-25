create table t1(a int, b float, c bigint, d numeric);
go

create index i1_t1 on t1 (a, b);
go

select indid, name from sys.sysindexes where id=OBJECT_ID('t1');
go

-- clean up
drop index i1_t1 on t1
go

drop table t1
go
