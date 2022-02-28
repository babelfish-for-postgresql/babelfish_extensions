use master;
go

create table t3006_i(i int, bi bigint, si smallint, ti tinyint);
insert into t3006_i values (1, 1, 1, 1), (2, 2, 2, 2), (3, 3, 3, 3);
go

select min(i), min(bi), min(si), min(ti) from t3006_i;
go

select max(i), max(bi), max(si), max(ti) from t3006_i;
go

select cast(pg_typeof(m) as varchar(20)) i from (select min(i) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) bi from (select min(bi) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) si from (select min(si) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) ti from (select min(ti) as m from t3006_i) tt
go

select cast(pg_typeof(m) as varchar(20)) i from (select max(i) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) bi from (select max(bi) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) si from (select max(si) as m from t3006_i) tt
select cast(pg_typeof(m) as varchar(20)) ti from (select max(ti) as m from t3006_i) tt
go

create table t3006_f(r real, f float);
insert into t3006_f values (1.1, 1.1), (2.2, 2.2), (3.3, 3.3);
go

select min(r), min(f) from t3006_f;
go

select max(r), max(f) from t3006_f;
go

select cast(pg_typeof(m) as varchar(20)) r from (select min(r) as m from t3006_f) tt
select cast(pg_typeof(m) as varchar(20)) f from (select min(f) as m from t3006_f) tt
go

select cast(pg_typeof(m) as varchar(20)) r from (select max(r) as m from t3006_f) tt
select cast(pg_typeof(m) as varchar(20)) f from (select max(f) as m from t3006_f) tt
go

create table t3006_m(m money, sm smallmoney, d decimal(10,2));
insert into t3006_m values (1.1, 1.1, 1.1), (2.2, 2.2, 2.2), (3.3, 3.3, 3.3);
go

select min(m), min(sm), min(d) from t3006_m;
go

select max(m), max(sm), max(d) from t3006_m;
go

select cast(pg_typeof(m) as varchar(20)) m from (select min(m) as m from t3006_m) tt
select cast(pg_typeof(m) as varchar(20)) sm from (select min(sm) as m from t3006_m) tt
select cast(pg_typeof(m) as varchar(20)) d from (select min(d) as m from t3006_m) tt
go

select cast(pg_typeof(m) as varchar(20)) m from (select max(m) as m from t3006_m) tt
select cast(pg_typeof(m) as varchar(20)) sm from (select max(sm) as m from t3006_m) tt
select cast(pg_typeof(m) as varchar(20)) d from (select max(d) as m from t3006_m) tt
go

create table t3006_b(b bit);
insert into t3006_b values (1), (2);
go

select min(b) from t3006_b;
go
select max(b) from t3006_b;
go
select sum(b) from t3006_b;
go
select avg(b) from t3006_b;
go

drop table t3006_i;
drop table t3006_f;
drop table t3006_m;
drop table t3006_b;
go
