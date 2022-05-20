create table test_tsql_const(
	c_int int primary key,
	c_bit sys.bit check(c_bit <> cast(1 as sys.bit)),
	check(c_int < 10),
	c_smallint smallint check(c_smallint < cast(cast(CAST('20' AS smallint) as sql_variant) as smallint)),
	c_binary binary(8) check(c_binary > cast(0xfe as binary(8))),
);
go

create table test_tsql_cast(
	c_float float check(c_float < cast(133.230182309832423 as float) and c_float < cast(133.230182309832423 as float(7))),
	c_real real check(c_real < cast(133.230182309832423 as real)),
	c_decimal decimal check(c_decimal < cast(cast($133.23 as money) as decimal) and c_decimal < cast(133.230182309832423 as decimal(5,3))),
	c_numeric numeric check(c_numeric < cast(133.230182309832423 as numeric) and c_numeric < cast(133.230182309832423 as numeric(5,3))),
);
go

create table test_tsql_collate(
	c_varchar varchar check(c_varchar <> cast('sflkjasdlkfjf' as varchar(12)) COLLATE bbf_unicode_cp1_ci_as),
	c_char char check(c_char <> cast('sflkjasdlkfjf' as char(7)) COLLATE bbf_unicode_cp1_ci_as),
	c_nchar nchar check(cast(c_nchar as nchar(7)) <> cast('sflkjasdlkfjf' as nchar(7)) COLLATE bbf_unicode_cp1_ci_as),
);
go

create table test_null(a int, b int, check(a IS NOT NULL), CONSTRAINT constraint1 check (a>10));
go

alter table test_null add constraint constraint2 check(a<=20 and b>a);
go

create table test_date(
	c_datetime datetime check(c_datetime < CAST('20060830' AS datetime)),
);
go

select tsql_get_constraintdef(oid) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='test_null');
go

select tsql_get_constraintdef(oid) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='test_tsql_const');
go

select tsql_get_constraintdef(oid) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='test_tsql_collate');
go

select tsql_get_constraintdef(oid) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='test_tsql_cast');
go

select tsql_get_constraintdef(oid) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='test_date');
go

drop table test_tsql_const
drop table test_null
drop table test_tsql_collate
drop table test_tsql_cast
drop table test_date
go


