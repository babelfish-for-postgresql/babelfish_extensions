CREATE PROCEDURE MyProcedure AS BEGIN     DECLARE @a INT;     SET @a = 1;     SELECT @a AS a; END;
go
create table t1(a int);
go
insert into t1 exec MyProcedure
go
select * from t1
go
insert into t1 exec MyProcedure
go
select * from t1
go
drop table t1
go
drop procedure MyProcedure
go
create procedure p2 as select * from t2
go
create table t1(a int)
go
create table t2(a int)
go
insert into t2(a) values(2)
GO
insert into t1 exec p2
go
select * from t1
go
insert into t1 exec p2
go
select * from t1
go
drop table t1
go
drop table t2
go
drop procedure p2
go
