use master
go

create table t1 (a numeric(6,4), b numeric(6,3));
insert into t1 values (4, 16);
insert into t1 values (10.1234, 10.123);
insert into t1 values (1.2, 6);
insert into t1 values (NULL, 101.123);
go

-- test selection of numeric Var
select * from t1;
go

-- test operations on numeric var
select a+b, a-b, a*b, a/b, +a, -a from t1;
go

-- test functions that returns numeric value
select round(a, 2) from t1;
go

select power(a, b) from t1;
go

select sqrt(a) from t1;
go

select abs(a) from t1;
go

-- test overflow error, max precision is 38 for TSQL client.
-- BABEL-2656
select power(10.0, 100);
go

-- test Nullif expression
select nullif(a, b) from t1;
go

-- test Param expr
select (select 1.234);
go

-- test case expr
select a, b,
case when a>5 then a
	 when a<=5 then b
end
	 from t1;
go

-- test Aggref expr
select min(a), max(a), min(b), max(b) from t1;
go

-- test Coalesece expr
-- BABEL-2656
select coalesce(a, b) from t1;
go

-- test Union All
select a from t1 Union All
select b from t1;
go

-- test overflow from multiplication of columns
create table t2 (a numeric(38, 1), b numeric(38, 1))
insert into t1 values (1234567890123456789012345678901234567.1), (1234567890123456789012345678901234567.2)
go

select * from t2
go

select a * b from t2;
go

-- clean up
drop table t1;
drop table t2;
go
