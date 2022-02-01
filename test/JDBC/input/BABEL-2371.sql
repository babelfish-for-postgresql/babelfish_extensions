-- simple case
create table t_2371(AbCd int, EfGh varchar(10));
GO
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371' and A.attnum > 0 and attisdropped = 'f' order by attname;
GO
select * from t_2371
go

-- alter table add column
alter table t_2371 add IjKl int;
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371' and A.attnum > 0 and attisdropped = 'f' order by attname;
GO
select * from t_2371
go
alter table t_2371 drop column EfGh;
GO
select * from t_2371
go
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371' and A.attnum > 0 and attisdropped = 'f' order by attname;
GO
drop table t_2371
GO

-- identifier longer than 64 characters
create table t_2371_2(A123456789B123456789C123456789D123456789E123456789F123456789G123456789H123456789I123456789J123456789K123456789 int);
GO
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371_2' and A.attname like 'a123456789%';
GO
select * from t_2371_2
go
drop table t_2371_2
GO

-- non-reserved keyword (level is non-reserved keyword in PG)
create table t_2371_3 (LeVeL int);
GO
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371_3' and A.attname like 'level';
GO
select * from t_2371_3
go
drop table t_2371_3
GO

-- delimited identifier
SET QUOTED_IDENTIFIER ON;
GO
create table t_2371_4 ([Abcd] int, "Efgh" int, Ijhl int, [K)@m($[^&] int, "x'AbC""e" int, """""""" int)
GO
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 't_2371_4' and A.attnum > 0 and attisdropped = 'f' order by attname;
GO
select * from t_2371_4
go
drop table t_2371_4
GO

-- CREATE TYPE
CREATE TYPE ty_2371_5 as table ("a""B""c" int);
GO
select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'ty_2371_5' and A.attnum > 0 and attisdropped = 'f' order by attname;
GO
drop type ty_2371_5
GO

SET QUOTED_IDENTIFIER OFF; -- default
GO
