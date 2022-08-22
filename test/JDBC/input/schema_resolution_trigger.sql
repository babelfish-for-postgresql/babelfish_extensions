create schema s1
go

create table t1(dbo_t1 int)
go

create table s1.t1(s1_t1 int, s1_t2 int)
go

create table mytab(dbo_mytab int)
go

create table s1.mytab(s1_mytab int)
go

create trigger tr1 on dbo.mytab for insert as
select * from t1
go

create trigger tr2 on s1.mytab for insert as
select * from t1
go

insert into dbo.mytab values(1)
go

insert into s1.mytab values(1)
go

drop trigger tr1
go

drop trigger s1.tr2
go

drop table t1
go

drop table s1.t1
go

drop table mytab
go

drop table s1.mytab
go

drop schema s1
go
