create view BABEL_2819_vu_prepare_v1 as (select datepart(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datepart(y, cast('2016-11-14' as datetime)) as y);
go

create view BABEL_2819_vu_prepare_v2 as (select datename(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datename(y, cast('2016-11-14' as datetime)) as y);
go

create view BABEL_2819_vu_prepare_v3 as (select datediff(y,cast('1956-06-27' as datetime),cast('1956-11-14' as datetime)));
go

create view BABEL_2819_vu_prepare_v4 as (select dateadd(y, 149, cast('2016-11-14' as datetime)));
go

create procedure  BABEL_2819_vu_prepare_p1 as (select datepart(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datepart(y, cast('2016-11-14' as datetime)) as y);
go

create procedure  BABEL_2819_vu_prepare_p2 as (select datename(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datename(y, cast('2016-11-14' as datetime)) as y);
go

create procedure  BABEL_2819_vu_prepare_p3 as (select datediff(y,cast('1956-06-27' as datetime),cast('1956-11-14' as datetime)));
go

create procedure  BABEL_2819_vu_prepare_p4 as (select dateadd(y, 149, cast('2016-11-14' as datetime)));
go

create function BABEL_2819_vu_prepare_f1()
returns datetime as
begin
return (select datepart(y, cast('2016-06-27' as datetime)) as y);
end
go

create function BABEL_2819_vu_prepare_f2()
returns nvarchar(15) as
begin
return (select datename(y, cast('2016-06-27' as datetime)) as y);
end
go
create function BABEL_2819_vu_prepare_f3()
returns int as
begin
return (select datediff(y,cast('1956-06-27' as datetime),cast('1956-11-14' as datetime)));
end
go

create function BABEL_2819_vu_prepare_f4()
returns datetime as
begin
return (select dateadd(y, 149, cast('2016-11-14' as datetime)));
end
go
