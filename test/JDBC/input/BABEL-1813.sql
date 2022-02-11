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

-- several types of object
create table collation(a int);
go
insert into collation values (1), (2);
update collation set a=3 where a=2;
delete from collation where a=1;
select * from collation;
go

drop table collation;
go

create type collation as table (a int);
go
drop type collation;
go

create table t1813(a int);
go
create view collation as select * from t1813;
go
drop view collation;
go

create trigger collation on t1813 after insert as begin print 'trigger invoked' end
go

drop table t1813;
go

create function collation(@a int) returns int as begin return @a+1; end
go
select collation(1);
go
drop function collation
go

-- test all keywords
create table binary(binary int);
go
drop table binary;
go

create table collation(collation int);
go
drop table collation;
go

create table concurrently(concurrently int);
go
drop table concurrently;
go

create table current_schema(current_schema int);
go
drop table current_schema;
go

create table freeze(freeze int);
go
drop table freeze;
go

create table ilike(ilike int);
go
drop table ilike;
go

create table isnull(isnull int);
go
drop table isnull;
go

create table natural(natural int);
go
drop table natural;
go

create table notnull(notnull int);
go
drop table notnull;
go

create table overlaps(overlaps int);
go
drop table overlaps;
go

create table similar(similar int);
go
drop table similar;
go
