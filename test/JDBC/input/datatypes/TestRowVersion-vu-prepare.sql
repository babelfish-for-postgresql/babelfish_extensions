EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Create table with rowversion column
create table testrowversion_t1(id int, rv rowversion);
go

-- A table can only have one rowversion column
create table testrowversion_t2(id int, rv1 rowversion, rv2 rowversion);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

-- Insert into a rowversion column is not allowed
insert into testrowversion_t1(id, rv) values(1,2);
go

-- Valid insert
insert into testrowversion_t1(id) values(1);
insert into testrowversion_t1(id) values(2);
go

-- Test view
create view testrowversion_v1 as select id, rv from testrowversion_t1;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test with tvf
create function testrowversion_tvf1(@x int) returns table as return select id, rv from testrowversion_t1;
go

-- function return type can not be rowversion
create function testrowversion_tvf2(@x int) returns rowversion as begin return cast(@x as rowversion) end;
go

-- function parameter types can not be rowversion
create function testrowversion_tvf3(@x int, @y rowversion) returns int as begin return @x end;
go

-- Updating a rowversion column is not allowed
update testrowversion_t1 set rv = 2 where id = 1;
go

-- NULL, NOT-NULL, check constraints are allowed on rowversion column
create table testrowversion_t3(id int, rv rowversion null);
go

create table testrowversion_t4(id int, rv rowversion not null);
go

create table testrowversion_t5(id int, rv rowversion check(rv > 50));
go

-- All other constraints should not be allowed
create table testrowversion_t6(id int, rv rowversion default 50);
go

create table testrowversion_t7(id int, rv rowversion primary key);
go

create table testrowversion_t8(a int primary key);
go

create table testrowversion_t9(id int, [RV] rowversion, foreign key(rv) references t1(a));
go

create table testrowversion_t10(id int, rv rowversion not null unique);
go

create table testrowversion_t11(id int, rv rowversion);
go

-- creating computed column from rowversion column is allowed
create table testrowversion_t12(id int, rv rowversion, rv2 as (rv+2));
go

create table testrowversion_t13([ID] int, [RV] rowversion);
go

-- Test dbts
create table testrowversion_t14(id int, rv rowversion);
go

-- dbts value should not be constant inside a transaction
create table babel_3139_t(c1 int, rv rowversion, dbts_after_insert binary(8));
go

begin tran;
insert into babel_3139_t(c1) values(1);
update babel_3139_t set dbts_after_insert = @@dbts where c1 = 1;

insert into babel_3139_t(c1) values(2);
update babel_3139_t set dbts_after_insert = @@dbts where c1 = 2;

insert into babel_3139_t(c1) values(3);
update babel_3139_t set dbts_after_insert = @@dbts where c1 = 3;
commit;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
