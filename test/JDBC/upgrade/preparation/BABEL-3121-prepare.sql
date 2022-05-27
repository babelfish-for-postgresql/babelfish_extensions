CREATE DATABASE db_babel_3121;
go

USE db_babel_3121;
go

create table babel_3121_t(id int, [BALA_#] varchar(40));
insert into babel_3121_t values (1, 'success');
go

select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t' and A.attnum > 0 and attisdropped = 'f' order by attname;
go
