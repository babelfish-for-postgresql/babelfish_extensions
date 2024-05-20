create table babel_4815(
    a datetime,
    b datetimeoffset,
    c datetime2,
    d smalldatetime,
    e date,
    f TEXT,
    g BIT,
    h REAL
)
go

create view babel_4815_1 as select datediff(dd, a, cast(b as datetime)) from babel_4815;
GO

create view babel_4815_2 as select datediff(dd, b, cast(c as datetimeoffset)) from babel_4815;
GO

create view babel_4815_3 as select datediff(dd, c, cast(a as datetime2)) from babel_4815;
GO

create view babel_4815_4 as select datediff(dd, d, cast(e as smalldatetime)) from babel_4815;
GO

create view babel_4815_5 as select datediff(dd, e, cast(a as date)) from babel_4815;
GO

create view babel_4815_11 as select dateadd(day, -5, a ) from babel_4815;
GO

create view babel_4815_12 as select dateadd(day, -5, b ) from babel_4815;
go

create view babel_4815_13 as select dateadd(day, -5, c ) from babel_4815;
go

create view babel_4815_14 as select dateadd(day, -5, d ) from babel_4815;
go

create view babel_4815_15 as select dateadd(day, -5, e ) from babel_4815;
go

create view babel_4815_16 as select dateadd(day, -5, f ) from babel_4815;
GO

create view babel_4815_17 as select dateadd(day, -5, g ) from babel_4815;
go

create view babel_4815_18 as select dateadd(day, -5, h ) from babel_4815;
go

create view babel_4815_19 as select * from babel_4815 where dateadd(day, -5, a ) > a;
go

create view babel_4815_20 as select * from babel_4815 where dateadd(day, -5, b ) > a;
go

create view babel_4815_21 as select * from babel_4815 where dateadd(day, -5, c ) > a;
go

create view babel_4815_22 as select * from babel_4815 where dateadd(day, -5, d ) > a;
go

create view babel_4815_23 as select * from babel_4815 where dateadd(day, -5, e ) > a;
go

create view babel_4815_24 as select * from babel_4815 where dateadd(day, -5, f ) > a;
GO

create view babel_4815_27 as select * FROM babel_4815 where datediff(dd, a, cast(b as datetime)) > 5;
GO

create view babel_4815_28 as select * FROM babel_4815 where datediff(dd, b, cast(c as datetimeoffset)) > 5;
GO

create view babel_4815_30 as select * FROM babel_4815 where datediff(dd, d, cast(e as smalldatetime)) > 5;
GO

create view babel_4815_31 as select * FROM babel_4815 where datediff(dd, e, cast(a as date)) > 5;
GO
