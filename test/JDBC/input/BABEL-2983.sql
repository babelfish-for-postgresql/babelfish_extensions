use master;
go

create table t2983(v varchar(10), nv nvarchar(10), c char(10), nc nchar(10), t text, nt ntext);
go
insert into t2983 values ('abc', 'def', 'ghi', 'jkl', 'mno', 'pqr');
go

select v + v from t2983;
go
select cast(pg_typeof(v + v) as varchar(20)) from t2983;
go

select nv + nv from t2983;
go
select cast(pg_typeof(nv + nv) as varchar(20)) from t2983;
go

select c + c from t2983;
go
select cast(pg_typeof(c + c) as varchar(20)) from t2983;
go

select nc + nc from t2983;
go
select cast(pg_typeof(nc + nc) as varchar(20)) from t2983;
go

select t + t from t2983;
go
select cast(pg_typeof(t + t) as varchar(20)) from t2983;
go

select nt + nt from t2983;
go
select cast(pg_typeof(nt + nt) as varchar(20)) from t2983;
go

-- string literal
select '123' + '456' from t2983;
go
select cast(pg_typeof('123' + '456') as varchar(20)) from t2983;
go

select '123' + v from t2983;
go
select cast(pg_typeof('123' + v) as varchar(20)) from t2983;
go

select v + '123' from t2983;
go
select cast(pg_typeof(v + '123') as varchar(20)) from t2983;
go

select '123' + nv from t2983;
go
select cast(pg_typeof('123' + nv) as varchar(20)) from t2983;
go

select nv + '123' from t2983;
go
select cast(pg_typeof(nv + '123') as varchar(20)) from t2983;
go

-- mixup with nvarchar
select v + nv from t2983;
go
select cast(pg_typeof(v + nv) as varchar(20)) from t2983;
go

select nv + v from t2983;
go
select cast(pg_typeof(nv + v) as varchar(20)) from t2983;
go

select c + nv from t2983;
go
select cast(pg_typeof(c + nv) as varchar(20)) from t2983;
go

select nv + c from t2983;
go
select cast(pg_typeof(nv + c) as varchar(20)) from t2983;
go

select nc + nv from t2983;
go
select cast(pg_typeof(nc + nv) as varchar(20)) from t2983;
go

select nv + nc from t2983;
go
select cast(pg_typeof(nv + nc) as varchar(20)) from t2983;
go

select nc + v from t2983;
go
select cast(pg_typeof(nc + v) as varchar(20)) from t2983;
go

select v + nc from t2983;
go
select cast(pg_typeof(v + nc) as varchar(20)) from t2983;
go

drop table t2983;
go

declare @v varchar(20) = '01-Aug'
select datediff(dd, @v + '-2021', '2022-01-01')
go
