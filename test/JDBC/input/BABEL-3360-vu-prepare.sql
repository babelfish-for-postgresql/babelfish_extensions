create view BABEL_3360_vu_prepare_v1 as (select dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go

create view BABEL_3360_vu_prepare_v2 as (select dateadd(microsecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go

create view BABEL_3360_vu_prepare_v3 as (select dateadd(millisecond, 56, null));
go

create view BABEL_3360_vu_prepare_v4 as (select dateadd(microsecond, 56, null));
go

create procedure  BABEL_3360_vu_prepare_p1 as (select dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go

create procedure  BABEL_3360_vu_prepare_p2 as (select dateadd(microsecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go

create procedure  BABEL_3360_vu_prepare_p3 as (select dateadd(millisecond, 56, null));
go

create procedure  BABEL_3360_vu_prepare_p4 as (select dateadd(microsecond, 56, null));
go

create function BABEL_3360_vu_prepare_f1()
returns datetime2 as
begin
return (select * from dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
end
go

create function BABEL_3360_vu_prepare_f2()
returns datetime2 as
begin
return (select * from dateadd(microsecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
end
go

create function BABEL_3360_vu_prepare_f3()
returns datetime as
begin
return (select * from dateadd(millisecond, 56, null));
end
go

create function BABEL_3360_vu_prepare_f4()
returns datetime as
begin
return (select * from dateadd(microsecond, 56, null));
end
go
