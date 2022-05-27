USE db_babel_3121;
go

select * from babel_3121_t;
go

select attname, attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

USE master;
go

DROP DATABASE db_babel_3121;
go
