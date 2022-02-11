create table t1(c1 int)
GO

insert into t1 values(1)
GO

alter table t1 add c2 char
GO

select * from t1;
GO

insert into t1 values(1, 'a')
GO

select * from t1;
GO

drop table t1;
GO

create table t1(c1 int)
GO

insert into t1 values(1)
GO

alter table t1 add c2 varchar
GO

select * from t1;
GO

insert into t1 values(1, 'a')
GO

select * from t1;
GO

drop table t1;
GO

create table t2 (a varchar(1))
GO

insert into t2 values ('D')
GO

alter table t2 alter column a char
GO

select * from t2;
GO

drop table t2;
GO

create table t2 (a varchar(2))
GO

insert into t2 values ('De')
GO

insert into t2 values ('D')
GO

alter table t2 alter column a char
GO

select * from t2;
GO

alter table t2 alter column a char(2)
GO

select * from t2;
GO

insert into t2 values ('A')
GO

select * from t2;
GO

drop table t2;
GO