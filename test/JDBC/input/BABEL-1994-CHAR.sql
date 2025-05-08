drop table if exists pad;
go

create table pad(
    c5nn char(5) not null,
    c5n character(5) null
);
go

insert into pad values('ab ', 'ab ');
create index pad_c5nn_idx on pad(c5nn);
go

select
    concat('[', c5nn, ']') as c5nn_concat,
    '[' + c5nn +']' as c5nn_to_text_concat,
    concat('[', cast(c5nn as varchar), ']') as c5nn_to_varchar_concat,
    concat('[', c5n, ']') as c5n_concat,
    '[' + c5n + ']' as c5n_to_text_concat,
    concat('[', cast(c5n as varchar), ']') as c5n_to_varchar_concat,
    pg_catalog.concat('[', cast(c5n as pg_catalog.name), ']') as c5n_to_name_concat
from pad;
go

drop table pad;
go

-- default length of CHAR should be 1. Otherwise, it will crash on the below select statement.
drop table if exists t1;
go

CREATE TABLE t1 (c1 CHAR);
INSERT INTO t1 VALUES ('A');
GO

SELECT c1 from t1;
go

drop table t1;
go

-- In case of CAST, the default length of CHAR should be 30.
select datalength(cast('123 ' as char));
go

-- Cast from sys.BPCHAR
select
    cast(cast('2021-08-15 ' as char(11)) as sys.smalldatetime),
    cast(cast('2021-08-15 ' as char(11)) as sys.datetime2),
    cast(cast('2021-08-15 ' as char(11)) as sys.datetime)
;
go

select
    cast(cast('decimal ' as char(8)) as sys.sql_variant),
    cast(cast('abc ' as char(5)) as pg_catalog.varchar),
    cast(cast('abc ' as char(5)) as pg_catalog.bpchar(4)),
    cast(cast('<xml></xml> ' as char(12)) as pg_catalog.xml),
    cast(cast('abc ' as char(5)) as pg_catalog.text),
    cast(cast('abc ' as char(5)) as pg_catalog.name),
    cast(cast('abc ' as char(5)) as pg_catalog.char(1))
;
go

-- Convert from sys.BPCHAR
select
    convert(sys.sql_variant, cast('decimal ' as char(8))),
    convert(sys.smalldatetime, cast('2021-08-15 ' as char(11))),
    convert(sys.datetime2, cast('2021-08-15 ' as char(11)))
;
go

select
    convert(pg_catalog.varchar, cast('abc ' as char(5))),
    convert(pg_catalog.bpchar(4), cast('abc ' as char(5))),
    convert(pg_catalog.xml, cast('<xml></xml> ' as char(12))),
    convert(pg_catalog.text, cast('abc ' as char(5))),
    convert(pg_catalog.name, cast('abc ' as char(5))),
    convert(pg_catalog.char(1), cast('abc ' as char(5)))
;
go

-- CAST to sys.BPCHAR
select
    cast(cast('2021-08-15 ' as sys.datetime) as char(20)),
    cast(cast('2021-08-15 ' as sys.datetime2) as char(20)),
    cast(cast('2021-08-15 ' as sys.smalldatetime) as char(20)),
    cast(cast('decimal ' as sys.sql_variant) as char(8)),
    cast(cast('a' as pg_catalog.char(1)) as char(3))
;
go

select
    cast(cast('abc ' as pg_catalog.name) as char(4)),
    cast(cast('128' as pg_catalog.cidr) as char(13)),
    cast(cast('2001:4f8:3:ba::/64' as pg_catalog.inet) as char(20)),
    cast(cast('abc ' as pg_catalog.text) as char(4)),
    cast(cast('<xml></xml> ' as pg_catalog.xml) as char(12)),
    cast(cast('abc ' as pg_catalog.bpchar(5)) as char(4)),
    cast(cast('abc ' as pg_catalog.varchar) as char(4))
;
go

-- Convert to sys.BPCHAR
select
    convert(char(20), cast('2021-08-15 ' as sys.datetime)),
    convert(char(20), cast('2021-08-15 ' as sys.datetime2)),
    convert(char(20), cast('2021-08-15 ' as sys.smalldatetime)),
    convert(char(8), cast('decimal ' as sys.sql_variant)),
    convert(char(3), cast('a' as pg_catalog.char(1)))
;
go

select
    convert(char(4), cast('abc ' as pg_catalog.name)),
    convert(char(13), cast('128' as pg_catalog.cidr)),
    convert(char(20), cast('2001:4f8:3:ba::/64' as pg_catalog.inet)),
    convert(char(4), cast('abc ' as pg_catalog.text)),
    convert(char(12), cast('<xml></xml> ' as pg_catalog.xml)),
    convert(char(4), cast('abc ' as pg_catalog.bpchar(5))),
    convert(char(4), cast('abc ' as pg_catalog.varchar))
;
go

-- String functions
select
    unicode(cast('a ' as char(5))),
    reverse(cast('a ' as char(5))),
    quotename(cast('a[] b ' as char(6))),
    patindex('a %', cast('a ' as char(5))),
    rtrim(cast('a ' as char(5)))
;
go

select
    lower(cast('A ' as char(5))),
    left(cast('a  ' as char(5)), 2),
    charindex(cast('a ' as char(5)), 'a  '),
    ascii(cast('a ' as char(5))),
    datalength(cast('123 ' as char(5))),
    length(cast('123 ' as char(5))),
    len(cast('123 ' as char(5)))
;
go
