create table t_405_insert1(x int);
create table t_405_insert2(x int);
insert into t_405_insert1 values(1);
insert into t_405_insert1 select * from t_405_insert1;
insert into t_405_insert1 select * from t_405_insert1;
go

create trigger tr1 on t_405_insert2 instead of insert
as
begin
select * from t_405_insert1;
end
go

create trigger tr2 on t_405_insert2 instead of insert
as
begin
select * from t_405_insert1;
end
go

insert into t_405_insert2 values(2);
go

select * from t_405_insert2;
go

drop trigger tr1;
go

create trigger tr1 on t_405_insert2 instead of insert
as
begin
end
go

insert into t_405_insert2 values(2);
select * from t_405_insert2;
go

drop trigger tr1;
go

insert into t_405_insert2 values(2);
select * from t_405_insert2;
go

drop table t_405_insert1;
drop table t_405_insert2;
go

create table t_405_delete1(x int);
create table t_405_delete2(x int);
insert into t_405_delete1 values(1);
insert into t_405_delete1 select * from t_405_delete1;
insert into t_405_delete1 select * from t_405_delete1;
insert into t_405_delete2 values(2);
go

create trigger tr1 on t_405_delete2 instead of delete
as
begin
select * from t_405_delete1;
end
go

create trigger tr2 on t_405_delete2 instead of insert
as
begin
select '1';
end
go

delete from t_405_delete2 where 1=1;
go

select * from t_405_delete2;
go

drop trigger tr1;
go

create trigger tr1 on t_405_delete2 instead of delete
as
begin
end
go

delete from t_405_delete2;
select * from t_405_delete2;
go

drop trigger tr1;
go

insert into t_405_delete2 values(2);
select * from t_405_delete2;
go

drop table t_405_delete1;
drop table t_405_delete2;
go

create table t_405_update1(x int);
create table t_405_update2(x int);
insert into t_405_update1 values(1);
insert into t_405_update1 select * from t_405_update1;
insert into t_405_update1 select * from t_405_update1;
insert into t_405_update2 values(1);
go

create trigger tr1 on t_405_update2 instead of update
as
begin
select * from t_405_update1;
end
go

create trigger tr2 on t_405_update2 instead of update
as
begin
select 'hello';
end
go

update t_405_update2 set x = 2 where x=1;
go
  
select * from t_405_update2;
go
  
drop trigger tr1;
go
  
create trigger tr1 on t_405_update2 instead of update
as
begin
end
go
  
update t_405_update2 set x = 3 where 1 = 1;
select * from t_405_update2;
go
  
drop trigger tr1;
go

update t_405_update2 set x=2 where x=1;
select * from t_405_update2;
go

drop table t_405_update1;
drop table t_405_update2;
go

create table t_405_insert1(x int);
create table t_405_insert2(x int);
insert into t_405_insert1 values(1);
insert into t_405_insert1 select * from t_405_insert1;
insert into t_405_insert1 select * from t_405_insert1;
go

create trigger tr1 on t_405_insert2 instead of insert
as
begin
select * from t_405_insert1
end;
go

create trigger after_trig on t_405_insert2 after insert
as
begin
select 'hello'
end;
go

insert into t_405_insert2 values(3);
go

drop trigger tr1;
go

insert into t_405_insert2 values(3);
go

select * from t_405_insert2;
go

drop trigger after_trig;

insert into t_405_insert2 values(3);
go

select * from t_405_insert2;
go

drop table t_405_insert1;
drop table t_405_insert2;
go

