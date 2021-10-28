drop table if exists person;
go
create table person(
    name_vcnn varchar(10) not null primary key,
    name_vcn varchar(10) null
);
go

insert into person values ('smith', 'smith');
go
insert into person values ('jones  ', 'jones  ');
go
insert into person values ('jones ', 'jones  ');
go

select count(*) from person where name_vcnn = 'smith  ';
go
select count(*) from person where name_vcn = 'smith    ';
go
select count(*) from person where name_vcnn = 'jones   ';
go
select count(*) from person where name_vcn = 'jones   ';
go
select count(*) from person where name_vcn = 'jones    ';
go

drop table person;
go

-- Cast from VARCHAR
select
    cast(cast('2021-08-15 ' as varchar(11)) as smalldatetime),
    cast(cast('2021-08-15 ' as varchar(11)) as datetime2),
    cast(cast('2021-08-15 ' as varchar(11)) as datetime)
;
go

select
    cast(cast('decimal ' as varchar(8)) as sql_variant),
    cast(cast('abc ' as varchar(5)) as pg_catalog.varchar),
    cast(cast('abc ' as varchar(5)) as pg_catalog.bpchar(4)),
    cast(cast('<xml></xml> ' as varchar(12)) as xml),
    cast(cast('abc ' as varchar(5)) as text),
    cast(cast('abc ' as varchar(5)) as name),
    cast(cast('abc ' as varchar(5)) as char(1))
;
go

-- Convert from VARCHAR
select
    convert(sql_variant, cast('decimal ' as varchar(8))),
    convert(smalldatetime, cast('2021-08-15 ' as varchar(11))),
    convert(datetime2, cast('2021-08-15 ' as varchar(11)))
;
go

select
    convert(pg_catalog.varchar, cast('abc ' as varchar(5))),
    convert(pg_catalog.bpchar(4), cast('abc ' as varchar(5))),
    convert(xml, cast('<xml></xml> ' as varchar(12))),
    convert(text, cast('abc ' as varchar(5))),
    convert(name, cast('abc ' as varchar(5))),
    convert(char(1), cast('abc ' as varchar(5)))
;
go

-- CAST to VARCHAR
select
    cast(cast('2021-08-15 ' as datetime) as varchar(20)),
    cast(cast('2021-08-15 ' as datetime2) as varchar(20)),
    cast(cast('2021-08-15 ' as smalldatetime) as varchar(20)),
    cast(cast('decimal ' as sql_variant) as varchar(8)),
    cast(FALSE as varchar(6)),
    cast(cast('a' as char(1)) as varchar(3))
;
go

select
    cast(cast('abc ' as name) as varchar(4)),
    cast(cast('128' as cidr) as varchar(13)),
    cast(cast('2001:4f8:3:ba::/64' as inet) as varchar(20)),
    cast(cast('abc ' as text) as varchar(4)),
    cast(cast('<xml></xml> ' as xml) as varchar(12)),
    cast(cast('abc ' as pg_catalog.bpchar(5)) as varchar(4)),
    cast(cast('abc ' as pg_catalog.varchar) as varchar(4))
;
go

-- Convert to VARCHAR
select
    convert(varchar(20), cast('2021-08-15 ' as datetime)),
    convert(varchar(20), cast('2021-08-15 ' as datetime2)),
    convert(varchar(20), cast('2021-08-15 ' as smalldatetime)),
    convert(varchar(8), cast('decimal ' as sql_variant)),
    convert(varchar(6), FALSE),
    convert(varchar(3), cast('a' as pg_catalog.char(1)))
;
go

select
    convert(varchar(4), cast('abc ' as name)),
    convert(varchar(13), cast('128' as cidr)),
    convert(varchar(20), cast('2001:4f8:3:ba::/64' as inet)),
    convert(varchar(4), cast('abc ' as text)),
    convert(varchar(12), cast('<xml></xml> ' as xml)),
    convert(varchar(4), cast('abc ' as pg_catalog.bpchar(5))),
    convert(varchar(4), cast('abc ' as pg_catalog.varchar))
;
go

-- String functions
select
    unicode(cast('a ' as varchar(5))),
    reverse(cast('a ' as varchar(5))),
    quotename(cast('a[] b ' as varchar(6))),
    patindex('a %', cast('a ' as varchar(5))),
    rtrim(cast('a ' as varchar(5)))
;
go

select
    lower(cast('A ' as varchar(5))),
    left(cast('a  ' as varchar(5)), 2),
    charindex(cast('a ' as varchar(5)), 'a  '),
    ascii(cast('a ' as varchar(5))),
    datalength(cast('123 ' as varchar(5))),
    length(cast('123 ' as varchar(5))),
    len(cast('123 ' as varchar(5)))
;
go