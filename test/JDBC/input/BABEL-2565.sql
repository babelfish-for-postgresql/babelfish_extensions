-- actual table with correlation name - should work
create table tv_t (a int)
insert into tv_t values(1)
UPDATE t SET a = 100 FROM tv_t AS t
select * from tv_t
drop table tv_t
go

-- table variable with correlation name - should work
declare @tv as table (a int)
insert into @tv values(1)
UPDATE t SET a = 100 FROM @tv AS t
select * from @tv
go

-- table variable without correlation name - should work
declare @tv as table (a int)
insert into @tv values(1)
UPDATE @tv SET a = 100
select * from @tv
go

-- WHERE clause that references the alias in FROM clause
create table tv_t (a int)
insert into tv_t values(10)
update t SET a = 100 FROM tv_t AS t where t.a = 10
select * from tv_t
drop table tv_t
go

-- same as above but UPDATE target is actual table, not correlation name
create table tv_t (a int)
insert into tv_t values(10)
update tv_t SET a = 100 FROM tv_t AS t where t.a = 10
select * from tv_t
drop table tv_t
go

-- test OUTPUT INTO
create table tv_t (a int)
insert into tv_t values(10)
create table tv_t1 (a int)
update t set a = 100 output inserted.a into tv_t1 from tv_t t where t.a = 10
select * from tv_t
select * from tv_t1
drop table tv_t
drop table tv_t1
go

-- test OUTPUT
create table tv_t (a int)
insert into tv_t values(10)
update t set a = 100 output deleted.a, inserted.a from tv_t t where t.a > 1
select * from tv_t
drop table tv_t
go

-- test collision with schema name
create table tv_t (a int)
insert into tv_t values(10)
update test_schema.test_table1 set a = 100 from tv_t as test_table1
go
drop table tv_t
go

-- test DELETE
create table tv_t (a int)
insert into tv_t values(10)
delete t from tv_t as t where t.a = 10
select * from tv_t
drop table tv_t
go

-- test DELETE with OUTPUT INTO
create table tv_t (a int)
insert into tv_t values(10)
create table tv_t1 (a int)
delete t output deleted.a into tv_t1 from tv_t t where t.a = 10
select * from tv_t
select * from tv_t1
drop table tv_t
drop table tv_t1
go

-- test DELETE with OUTPUT
create table tv_t (a int)
insert into tv_t values(10)
delete t output deleted.a from tv_t t where t.a > 1
select * from tv_t
drop table tv_t
go
