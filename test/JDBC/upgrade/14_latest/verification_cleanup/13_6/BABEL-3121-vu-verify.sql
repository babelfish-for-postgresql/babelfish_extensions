USE db_babel_3121;
go

select * from babel_3121_t;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

select * from babel_3121_t2;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t2' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

select * from babel_3121_t3;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t3' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

select * from babel_3121_t4;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t4' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

select * from babel_3121_t5;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t5' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

select * from babel_3121_t6;
go

select attname, array_to_string(attoptions,',') attoptions from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_t6' and A.attnum > 0 and attisdropped = 'f' order by attname;
go

USE master;
go

DROP DATABASE db_babel_3121;
go
