use master;
go

create table t3004(dto datetimeoffset, dt2 datetime2, dt datetime, sdt smalldatetime, d date, t time);
go

insert into t3004 values ('2021-05-01 11:11:11.111', '2021-05-01 11:11:11.111', '2021-05-01 11:11:11.111', '2021-05-01 11:11:11.111', '2021-05-01', '11:11:11.111');
insert into t3004 values ('2021-05-02 22:22:22.222', '2021-05-02 22:22:22.222', '2021-05-02 22:22:22.222', '2021-05-02 22:22:22.222', '2021-05-02', '22:22:22.222');
insert into t3004 values ('2021-05-03 23:33:33.333', '2021-05-03 23:33:33.333', '2021-05-03 23:33:33.333', '2021-05-03 23:33:33.333', '2021-05-03', '23:33:33.333');
go

select min(dto), min(dt2), min(dt), min(sdt), min(d), min(t) from t3004;
go

select max(dto), max(dt2), max(dt), max(sdt), max(d), max(t) from t3004;
go

select cast(pg_typeof(m) as varchar(20)) dto from (select min(dto) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) dt2 from (select min(dt2) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) dt from (select min(dt) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) sdt from (select min(sdt) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) d from (select min(d) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) t from (select min(t) as m from t3004) tt
go

select cast(pg_typeof(m) as varchar(20)) dto from (select max(dto) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) dt2 from (select max(dt2) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) dt from (select max(dt) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) sdt from (select max(sdt) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) d from (select max(d) as m from t3004) tt
select cast(pg_typeof(m) as varchar(20)) t from (select max(t) as m from t3004) tt
go

drop table t3004;
go
