CREATE DATABASE db_babel_3234;
go

USE db_babel_3234;
go

create table t1 (a1 decimal DEFAULT '', b1 int);
go
create table t2 (a1 numeric DEFAULT '', b1 int);
go
create table t3 (a1 int DEFAULT '', b1 int);
go

insert into t1 (b1) values (2);
go
insert into t2 (b1) values (2);
go
insert into t3 (b1) values (2);
go

select * from t1;
go
select * from t2;
go
select * from t3;
go
