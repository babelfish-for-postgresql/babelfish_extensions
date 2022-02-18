use master;
go

create table t2964(v varchar(10), nv nvarchar(10), c char(1), nc nchar(1));
insert into t2964 values ('a', 'a', 'a', 'a'), ('b', 'b', 'b', 'b'), ('1', '1', '1', '1');
go

select max(v) maxv, min(v) minv from t2964;
go

select max(nv) maxnv, min(nv) minnv from t2964;
go

select cast(max(c) as varchar(10)), cast(min(c) as varchar(10)) from t2964;
go

select cast(max(nc) as varchar(10)), cast(min(nc) as varchar(10)) from t2964;
go

select cast(pg_typeof(s) as varchar(20)) from (select max(v) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select min(v) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select max(nv) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select min(nv) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select max(c) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select min(c) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select max(nc) s from t2964) tt
go

select cast(pg_typeof(s) as varchar(20)) from (select min(nc) s from t2964) tt
go

drop table t2964;
go
