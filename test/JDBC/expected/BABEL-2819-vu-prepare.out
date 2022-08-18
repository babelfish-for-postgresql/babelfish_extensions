create view BABEL_2819_vu_prepare_v1 as (select datepart(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datepart(y, cast('2016-11-14' as datetime)) as y);
go

create view BABEL_2819_vu_prepare_v2 as (select datename(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datename(y, cast('2016-11-14' as datetime)) as y);
go

create procedure  BABEL_2819_vu_prepare_p1 as (select datepart(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datepart(y, cast('2016-11-14' as datetime)) as y);
go

create procedure  BABEL_2819_vu_prepare_p2 as (select datename(dayofyear, cast('2016-11-14' as datetime)) as dayofyear, datename(y, cast('2016-11-14' as datetime)) as y);
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
