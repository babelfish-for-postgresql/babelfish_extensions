use master;
go

-- basic operations
create table t2725 (a int, b int, offset int not null);
go
insert into t2725 (a, offset) values (1, 2);
go
select a, b, offset from t2725;
go
select a, b, t2725.offset from t2725;
go
alter table t2725 add binary binary; -- column "binary" whose type is binary
go
insert into t2725(offset,binary) values (3, 0x04);
go
create unique index i1813 on t2725(offset);
go
insert into t2725(offset,binary) values (4, 0x05);
insert into t2725(offset,binary) values (4, 0x05);
go
select abs(-offset)*2 c, binary from t2725;
go
update t2725 set offset = 5 output deleted.offset where offset = 2;
go
delete from t2725 output offset where offset = 4;
go
select offset from t2725 order by offset;
go
select [offset] from t2725 order by offset;
go
select t2725.[offset] from t2725 order by offset;
go
select oFfSet from t2725 order by ofFSET;
go
drop table t2725;
go

create table offset(offset int);
go
drop table offset;
go
