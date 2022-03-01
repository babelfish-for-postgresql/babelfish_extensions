-- Test CHECKSUM function works on string input
set quoted_identifier off;
go

-- Null input throws an error, it's not supported.
select CHECKSUM(NULL);
go

select CHECKSUM(1, NULL);
go

-- special case : blank string should return 0.
select CHECKSUM("");
go

select CHECKSUM('');
go

select CHECKSUM(1, 3, '');
go

select CHECKSUM('abcd');
go

select CHECKSUM('abcd', 'efg');
go

select CHECKSUM('abcd', 'efg', 'hi');
go

select CHECKSUM(1, 'efg', 'hi');
go

-- Test CHECKSUM function works on scalar input
select CHECKSUM(123);
go

select CHECKSUM(10.12345);
go

select CHECKSUM(123, 456);
go

select CHECKSUM('123', '456');
go

-- Test CHECKSUM works on table column
create table t1 (a int, b varchar(10));
insert into t1 values (12345, 'abcd');
insert into t1 values (12345, 'abcd');
insert into t1 values (23456, 'bcd');
go

select CHECKSUM(a), CHECKSUM(b) from t1;
go

select CHECKSUM(a, b) from t1;
go

select CHECKSUM(*) from t1;
go

alter table t1 drop column a;
go

select checksum(b) from t1;
go

select checksum(*) from t1;
go

-- Test checksum on table with null input and empty string
create table t2 (a varchar(10), b int);
go

insert into t2 values ('', 1);
go

insert into t2 values (null, 2);
go

insert into t2 values ('empty', 3);
go

select checksum(*) from t2;
go

-- clean up
drop table t1;
go

drop table t2;
go

set quoted_identifier off;
go

create table t1(a int)
go

insert into t1 values(1)
go

select checksum(user_type_id) from sys.columns where object_id=OBJECT_ID('t1')
go

drop table t1;
go

create table dates(a date, b time, c datetimeoffset, d datetime2, e datetime, f smalldatetime)
go

select checksum(*) from dates;
go

drop table dates;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

create table t1(a binary, b bit, c timestamp, d bytea, e sql_variant, f varbinary)
go

select checksum(*) from t1;
go

drop table t1;
go

select distinct checksum(create_date) from sys.objects;
go

select cast(cast(1 as rowversion) as text);
go

select cast(cast(1 as timestamp) as text);
go

select cast(cast(1 as bbf_varbinary) as text);
go

select cast(cast(1 as sql_variant) as text);
go

select cast(cast(1 as varbinary) as text);
go

select cast(cast('12-12-12 12:12:12' AS DATETIME) as text);
go

select cast(cast('12-12-12 12:12:12' AS DATETIME2) as text);
go

select cast(cast('12-12-12 12:12:12' AS DATE) as text);
go

select cast(cast('12-12-12 12:12:12' AS smalldatetime) as text);
go

select cast(cast(NULL as bit) as text);
go

select cast(cast(0xfe as binary) as text);
go

select cast(cast(0xfe as bbf_binary) as text);
go

select cast(cast(0xfe as bytea) as text);
go

select cast(cast('2020-10-05 09:00:00.123456-9:00' AS datetimeoffset) as text);
go

select cast(cast('00:00:00.234' AS time) as text);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

