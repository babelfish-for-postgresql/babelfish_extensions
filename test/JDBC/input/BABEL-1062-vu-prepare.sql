create view BABEL_1062_vu_prepare_v1 as (select datepart(mi, cast('2016-11-14 12:43:10' as datetime)));
go

create view BABEL_1062_vu_prepare_v2 as (select datename(mi, cast('2016-11-14 12:43:10' as datetime)));
go

create view BABEL_1062_vu_prepare_v3 as (select datediff(mi,cast('1956-06-27 12:43:10' as datetime),cast('1956-11-14 12:44:10' as datetime)));
go

create view BABEL_1062_vu_prepare_v4 as (select dateadd(mi, 149, cast('2016-11-14 12:43:10' as datetime)));
go

create procedure  BABEL_1062_vu_prepare_p1 as (select datepart(mi, cast('2016-11-14 12:43:10' as datetime)));
go

create procedure  BABEL_1062_vu_prepare_p2 as (select datename(mi, cast('2016-11-14 12:43:10' as datetime)));
go

create procedure  BABEL_1062_vu_prepare_p3 as (select datediff(mi,cast('1956-06-27 12:43:10' as datetime),cast('1956-11-14 12:44:10' as datetime)));
go

create procedure  BABEL_1062_vu_prepare_p4 as (select dateadd(mi, 149, cast('2016-11-14 12:43:10' as datetime)));
go

create function BABEL_1062_vu_prepare_f1()
returns datetime as
begin
return (select datepart(mi, cast('2016-06-27 12:43:10' as datetime)));
end
go

create function BABEL_1062_vu_prepare_f2()
returns nvarchar(15) as
begin
return (select datename(mi, cast('2016-06-27 12:43:10' as datetime)));
end
go
create function BABEL_1062_vu_prepare_f3()
returns int as
begin
return (select datediff(mi,cast('1956-06-27 12:43:10' as datetime),cast('1956-11-14 12:44:10' as datetime)));
end
go

create function BABEL_1062_vu_prepare_f4()
returns datetime as
begin
return (select dateadd(mi, 149, cast('2016-11-14 12:43:10' as datetime)));
end
go
