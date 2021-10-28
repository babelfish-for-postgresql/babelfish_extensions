create table t (a int, b int)
go

insert t values(1,1)
insert t values(2,2)
insert t values(3,3)
insert t values(4,4)
insert t values(5,5)
go

select * from t
go

update t set b = b*-1 where b > 0
go

select * from t
go

update top(2) t set b = b*-1 where b < 0
go

select count(*) from t where b > 0
go

delete top(2) from t where b < 0
go

select count(*) from t
go

declare @a int
set @a = 1
delete top (@a) from t
go

select count(*) from t
go

-- test TOP clause in UPDATE together with JOIN
create table t1 (a int, b int)
go

insert t1 values(1,1)
insert t1 values(2,2)
insert t1 values(3,3)
insert t1 values(4,4)
insert t1 values(5,5)
go

create table t2 (a int, b int)
go

insert t2 values(1,-1)
insert t2 values(2,2)
insert t2 values(3,3)
insert t2 values(400,4)
insert t2 values(500,5)
go

update top(2) t1 set a = a*-1 from t1 alias1 inner join t2 alias2 on alias1.a = alias2.a
go

select count(*) from t1 where a < 0
go

-- test TOP clause in DELETE together with JOIN
create table t3 (a int, b int)
go

insert t3 values(1,1)
insert t3 values(2,2)
insert t3 values(-3,-3)
go

create table t4 (a int, b int)
go

insert t4 values(1,-1)
insert t4 values(2,2)
insert t4 values(3,3)
insert t4 values(400,4)
insert t4 values(500,5)
go

delete top(1) t3 from t3 alias3 inner join t4 alias4 on alias3.b = alias4.b
go

select count(*) from t3
go

-- test error message on TOP n PERCENT
-- TOP 100 PERCENT should be supported
update top (100) percent t3 set b = 100
go

select count(*) from t3 where b = 100
go

delete top (100) percent from t3
go

select count(*) from t3
go

-- other percentage should report unsupported error
update top (10) percent t4 set b = 100
go

delete top (10) percent from t4
go

drop table t
go

drop table t1
go

drop table t2
go

drop table t3
go

drop table t4
go
