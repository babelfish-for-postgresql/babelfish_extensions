USE master;
go

select * from babel_3121_vu_prepare_t;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t2;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t2' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t3;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t3' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t4;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t4' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t5;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t5' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t6;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t6' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

select * from babel_3121_vu_prepare_t7;
go

select attname, string_agg(opt, ',') attoptions from (select A.attname, unnest(A.attoptions) opt from pg_class C, pg_attribute A where C.oid = A.attrelid and C.relname like 'babel_3121_vu_prepare_t7' and A.attnum > 0 and attisdropped = 'f') t where opt not like 'pg_attver=%' group by attname order by attname;
go

drop table babel_3121_vu_prepare_t7;
drop table babel_3121_vu_prepare_t6;
drop table babel_3121_vu_prepare_t5;
drop table babel_3121_vu_prepare_t4;
drop table babel_3121_vu_prepare_t3;
drop table babel_3121_vu_prepare_t2;
drop table babel_3121_vu_prepare_t;
go
