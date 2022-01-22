use master;
go

-- basic operations
create table t1813 (a int, b int, collation int not null);
go
insert into t1813 (a, collation) values (1, 2);
go
select a, b, collation from t1813;
go
select a, b, t1813.collation from t1813;
go
alter table t1813 add binary binary; -- column "binary" whose type is binary
go
insert into t1813(collation,binary) values (3, 0x04);
go
create unique index i1813 on t1813(collation);
go
insert into t1813(collation,binary) values (4, 0x05);
insert into t1813(collation,binary) values (4, 0x05);
go
select abs(-collation)*2 c, binary from t1813;
go
update t1813 set collation = 5 output deleted.collation where collation = 2;
go
delete from t1813 output collation where collation = 4;
go
select collation from t1813 order by collation;
go
select [collation] from t1813 order by collation;
go
select t1813.[collation] from t1813 order by collation;
go
select COLLATION from t1813 order by COLLATION;
go
select CoLlAtIoN from t1813 order by CoLlAtIoN;
go
drop table t1813;
go

-- test all keywords
create table t1813_binary(binary int);
go
drop table t1813_binary;
go

create table t1813_collation(collation int);
go
drop table t1813_collation;
go

create table t1813_concurrently(concurrently int);
go
drop table t1813_concurrently;
go

create table t1813_current_schema(current_schema int);
go
drop table t1813_current_schema;
go

create table t1813_freeze(freeze int);
go
drop table t1813_freeze;
go

create table t1813_ilike(ilike int);
go
drop table t1813_ilike;
go

create table t1813_isnull(isnull int);
go
drop table t1813_isnull;
go

create table t1813_natural(natural int);
go
drop table t1813_natural;
go

create table t1813_notnull(notnull int);
go
drop table t1813_notnull;
go

create table t1813_overlaps(overlaps int);
go
drop table t1813_overlaps;
go

create table t1813_similar(similar int);
go
drop table t1813_similar;
go
