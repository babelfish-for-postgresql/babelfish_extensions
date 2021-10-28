-- Test numeric in cast function
select cast(1.123 as numeric(38, 10));
go
select cast(1.123 as numeric(39, 10));
go

-- Test decimal in cast function
select cast(1.123 as decimal(38, 10));
go
select cast(1.123 as decimal(39, 10));
go

-- Test dec in cast function
select cast(1.123 as dec(38, 10));
go
select cast(1.123 as dec(39, 10));
go

-- Test numeric in create table
create table t1 (col numeric(38,37));
drop table t1;
go

create table t1 (col numeric(39, 37));
go

-- Test decimal in create table
create table t1 (col decimal(38,37));
drop table t1;
go

create table t1 (col decimal(39, 37));
go

-- Test dec in create table
create table t1 (col decimal(38,37));
drop table t1;
go

create table t1 (col decimal(39, 37));
go

-- Test default precision and scale is set to 18, 0
create table t1 (col numeric);
insert into t1 values (1.2);
insert into t1 values (123456789012345678);
select * from t1;
go
insert into t1 values (1234567890123456789);
select * from t1;
go

drop table t1;
go

-- Test default scale is set to 0 if only precision is specified
create table t1 (col numeric(4));
insert into t1 values (1.2);
select * from t1;
go

drop table t1;
go