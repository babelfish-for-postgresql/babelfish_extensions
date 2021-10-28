SELECT set_config('extra_float_digits', '0', 'false')
go

-- test money operators return type money
create table t1(a money, b smallmoney);
insert into t1 values (1.1234, 2.1234);
insert into t1 values (2.5678, 3.5678);
insert into t1 values (4.9012, 5.9012);
go

select * from t1 order by a;
go

-- test implicit casting for money
create table t2(a money, b smallmoney);
insert into t2 values (CAST( '1.1234' AS CHAR(10)), CAST( '2.1234' AS CHAR(10)));
insert into t2 values (CAST( '$2.56789' AS VARCHAR), CAST( '$3.56789' AS VARCHAR));
insert into t2 values (CAST( '¥4.91' AS TEXT), CAST( '¥5.91' AS TEXT));
insert into t2 values (CAST( '0006.' AS TEXT), CAST( '0000' AS TEXT));
go

select * from t2 order by a;
go

select sum(a), sum(b) from t1;
go

select cast(pg_typeof(sum(a)) AS VARCHAR(10)), cast(pg_typeof(sum(b)) AS VARCHAR(10)) from t1;
go

select avg(a), avg(b) from t1;
go

select cast(pg_typeof(avg(a)) AS VARCHAR(10)), cast(pg_typeof(avg(b)) AS VARCHAR(10)) from t1;
go

select a+b from t1 order by a;
go

select cast(pg_typeof(a+b) AS VARCHAR(10)) from t1 order by a;
go

select b-a from t1 order by a;
go

select cast(pg_typeof(b-a) AS VARCHAR(10)) from t1 order by a;
go

select a*b from t1 order by a;
go

select cast(pg_typeof(a*b) AS VARCHAR(10)) from t1 order by a;
go

select a/b from t1 order by a;
go

select cast(pg_typeof(a/b) AS VARCHAR(10)) from t1 order by a;
go

drop table t1, t2;

-- BABEL-598 Money type as procedure parameter should work without explicit cast
create table employees(pers_id int, fname nvarchar(20), lname nvarchar(30), sal money);
go

create procedure p_employee_select
as
begin
	select * from employees
end;
go

create procedure p_employee_insert
@pers_id int, @fname nvarchar(20), @lname nvarchar(30), @sal money
as
begin
	insert into employees values (@pers_id, @fname, @lname, @sal)
end;
go

-- test const 123.1234 and 200 are valid MONEY inputs for the procedure without explicit cast
execute p_employee_insert @pers_id=1, @fname='John', @lname='Johnson', @sal=123.1234;
execute p_employee_insert @pers_id=1, @fname='Adam', @lname='Smith', @sal=200;
go

execute p_employee_select;
go

drop procedure p_employee_select;
drop procedure p_employee_insert;
drop table employees;
go

-- BABEL-920
-- Test operations(e.g. +,-,*,/) between fixeddecimal(money/smallmoney) and int8(bigint)
select CAST(2.56 as bigint) + CAST(3.60 as money);
go
select CAST(3.60 as money) + CAST(2.56 as bigint);
go
select CAST(2.56 as bigint) - CAST(3.60 as money);
go
select CAST(3.60 as money) - CAST(2.56 as bigint);
go
select CAST(2.56 as bigint) * CAST(3.60 as money);
go
select CAST(3.60 as money) * CAST(2.56 as bigint);
go
select CAST(2.56 as bigint) / CAST(3.60 as money);
go
select CAST(3.60 as money) / CAST(2.56 as bigint);
go

select CAST(2.56 as bigint) + CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) + CAST(2.56 as bigint);
go
select CAST(2.56 as bigint) - CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) - CAST(2.56 as bigint);
go
select CAST(2.56 as bigint) * CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) * CAST(2.56 as bigint);
go
-- select CAST(2.56 as bigint) / CAST(3.60 as smallmoney); -> see BABEL-977
-- go
select CAST(3.60 as smallmoney) / CAST(2.56 as bigint);
go

-- Test operations(e.g. +,-,*,/) between fixeddecimal(money/smallmoney) and int4(int)
select CAST(2.56 as int) + CAST(3.60 as money);
go
select CAST(3.60 as money) + CAST(2.56 as int);
go
select CAST(2.56 as int) - CAST(3.60 as money);
go
select CAST(3.60 as money) - CAST(2.56 as int);
go
select CAST(2.56 as int) * CAST(3.60 as money);
go
select CAST(3.60 as money) * CAST(2.56 as int);
go
select CAST(2.56 as int) / CAST(3.60 as money);
go
select CAST(3.60 as money) / CAST(2.56 as int);
go

select CAST(2.56 as int) + CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) + CAST(2.56 as int);
go
select CAST(2.56 as int) - CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) - CAST(2.56 as int);
go
select CAST(2.56 as int) * CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) * CAST(2.56 as int);
go
-- select CAST(2.56 as int) / CAST(3.60 as smallmoney); -> see BABEL-977
-- go
select CAST(3.60 as smallmoney) / CAST(2.56 as int);
go

-- Test operations(e.g. +,-,*,/) between fixeddecimal(money/smallmoney) and int2(smallint)
select CAST(2.56 as smallint) + CAST(3.60 as money);
go
select CAST(3.60 as money) + CAST(2.56 as smallint);
go
select CAST(2.56 as smallint) - CAST(3.60 as money);
go
select CAST(3.60 as money) - CAST(2.56 as smallint);
go
select CAST(2.56 as smallint) * CAST(3.60 as money);
go
select CAST(3.60 as money) * CAST(2.56 as smallint);
go
select CAST(2.56 as smallint) / CAST(3.60 as money);
go
select CAST(3.60 as money) / CAST(2.56 as smallint);
go

select CAST(2.56 as smallint) + CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) + CAST(2.56 as smallint);
go
select CAST(2.56 as smallint) - CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) - CAST(2.56 as smallint);
go
select CAST(2.56 as smallint) * CAST(3.60 as smallmoney);
go
select CAST(3.60 as smallmoney) * CAST(2.56 as smallint);
go
-- select CAST(2.56 as smallint) / CAST(3.60 as smallmoney); -> see BABEL-977
-- go
select CAST(3.60 as smallmoney) / CAST(2.56 as smallint);
go
