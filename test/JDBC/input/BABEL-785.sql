-- Verify correct value of ANSI_NULLS
select sessionproperty('ANSI_NULLS');
go

create table testTbl(fname varchar(10));
insert into testTbl values (null), ('Jenny');
select * from testTbl
go

select * from testTbl where fname=null;
go

select * from testTbl where fname<>null;
go

drop table testTbl;
go

-- Verify correct value of ANSI_PADDING
select sessionproperty('ANSI_PADDING');
go

create table testTbl (
    is_char_null char(10) null,
    is_char_notnull char(10) not null,
    is_varchar_null varchar(10) null,
    is_varchar_notnull varchar(10) not null
);
go

insert into testTbl values
    ('aaa','aaa','aaa','aaa'),
    ('aaa  ','aaa  ','aaa  ','aaa  ');
go

select datalength(is_char_null) as is_char_null_len,
    datalength(is_char_notnull) as is_char_notnull_len,
    datalength(is_varchar_null) as is_varchar_null_len,
    datalength(is_varchar_notnull) as is_varchar_notnull_len
from testTbl;
go

SELECT
    is_char_null+'|' as is_char_null,
    is_char_notnull+'|' as is_char_notnull,
    is_varchar_null+'|' as is_varchar_null,
    is_varchar_notnull+'|' as is_varchar_notnull
from testTbl;
go

drop table testTbl;
go

-- Verify correct value of ANSI_WARNINGS
select sessionproperty('ANSI_WARNINGS');
go

create table testTbl(fname varchar(10));
go

insert into testTbl values (null), ('Jenny Matthews');
go

drop table testTbl;
go

-- Verify correct value of ARITHABORT
select sessionproperty('ARITHABORT');
go

select 25/0;
go

-- Verify correct value of CONCAT_NULL_YIELDS_NULL
select sessionproperty('CONCAT_NULL_YIELDS_NULL');
go

select 'test'+null;
go

select concat('test', null);
go

select concat(null, 'test');
go

-- Verify correct value of NUMERIC_ROUNDABORT
select sessionproperty('NUMERIC_ROUNDABORT');
go

create table testTbl(size int)
go

insert into testTbl values (707072), (1024000);
go

select (100 / SUM((((size) * 8.00) / 1024))) from testTbl as T;
go

drop table testTbl;
go

-- Verify correct value of QUOTED_IDENTIFIER
select sessionproperty('QUOTED_IDENTIFIER');
go

select 'Hello, world!';
go

select "Hello, world!";
go

-- Test invalid property
select sessionproperty('nonexistent_property');
go