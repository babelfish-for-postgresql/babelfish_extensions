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

-- Test modulo operator for fixeddecimal type
-- modulo operator between MONEY/SMALLMONEY and MONEY/SMALLMONEY
-- SMALLMONEY is between -214748.3648 to 214748.3647
-- MONEY is between -922337203685477.5808 to 922337203685477.5807
SELECT CAST(-15.5 AS MONEY) % CAST(24.0 AS MONEY);
GO
SELECT CAST(-273434.2737 AS MONEY) % CAST(283.2245 AS MONEY);
GO
SELECT CAST(-27328391434.2737 AS MONEY) % CAST(283828323.2273 AS MONEY);
GO
SELECT CAST(-27328391434.2737 AS MONEY) % CAST(-283828323.2273 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(283.2245 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(-922337203685477.5808 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(1 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(0.0001 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(-283828323.2273 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(922337203685477.5807 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(283.2245 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(1 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(0.0001 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(-283828323.2273 AS MONEY);
GO
SELECT CAST(0.00 AS MONEY) % CAST(-922337203685477.5808 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(0.00 AS MONEY);
GO

SELECT CAST(-214748.3648 AS SMALLMONEY) % CAST(283.2245 AS SMALLMONEY);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) % CAST(283.2245 AS SMALLMONEY);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) % CAST(0.0001 AS SMALLMONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) % CAST(0.0001 AS SMALLMONEY);
GO

SELECT CAST(-922337203685477.5808 AS MONEY) % CAST(-214748.3648 AS SMALLMONEY);
GO
SELECT CAST(5477.5808 AS MONEY) % CAST(-214748.3648 AS SMALLMONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) % CAST(5477.5808 AS MONEY);
GO

-- modulo operator between MONEY/SMALLMONEY and Integer
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(2833 AS SMALLINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(228325833 AS INT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(293228325827 AS BIGINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(7 AS TINYINT);
GO
SELECT CAST(2833 AS SMALLINT) % CAST(283.2128 AS SMALLMONEY);
GO
SELECT CAST(125833 AS INT) % CAST(-28322.8217 AS SMALLMONEY);
GO
SELECT CAST(-20827 AS BIGINT) % CAST(-98272.1123 AS SMALLMONEY);
GO
SELECT CAST(228325833 AS INT) % CAST(-28322.8217 AS SMALLMONEY);
GO
SELECT CAST(293228325827 AS BIGINT) % CAST(-98272.1123 AS SMALLMONEY);
GO
SELECT CAST(-98272.1123 AS SMALLMONEY) % CAST(7 AS TINYINT);
GO

-- modulo operator between MONEY/SMALLMONEY and DECIMAL
-- use the postgres internal numeric_mod
SELECT CAST(922337203685477.5807 AS MONEY) % CAST(2833.292334 AS NUMERIC(12, 7));
GO
SELECT CAST(289383292919292.238382 AS NUMERIC(30, 5)) % CAST(-922337203685477.5808 AS MONEY);
GO
SELECT CAST(-98272.1123 AS SMALLMONEY) % CAST(7.2 AS NUMERIC(5, 4));
GO
SELECT CAST(289383292919292.238382 AS NUMERIC(30, 5)) % CAST(-98272.1123 AS SMALLMONEY);
GO

CREATE TABLE t1 (a MONEY);
INSERT INTO t1 VALUES (5.5);
GO
SELECT a, a % 1 AS MOD_INT, a % CAST(1 AS MONEY) AS MOD_MONEY, a % CAST(1 AS DECIMAL(10, 5)) AS MOD_DECIMAL FROM t1;
GO
DROP TABLE t1;
GO
