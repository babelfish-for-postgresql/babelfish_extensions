create view BABEL_3358_vu_prepare_v1 as (select datepart(dw, cast('2016-11-14' as datetime)) as dw, datepart(w, cast('2016-11-14' as datetime)) as w);
go

create view BABEL_3358_vu_prepare_v2 as (select datename(dw, cast('2016-11-14' as datetime)) as dw, datename(w, cast('2016-11-14' as datetime)) as w);
go

create view BABEL_3358_vu_prepare_v3 as (select datediff(w, cast('2016-11-14' as datetime), cast('2016-11-14' as datetime) + 17));
go

create view BABEL_3358_vu_prepare_v4 as (select dateadd(w, 1,cast('2016-11-14' as datetime)));
go

create procedure  BABEL_3358_vu_prepare_p1 as (select datepart(dw, cast('2016-11-14' as datetime))as dw, datepart(w, cast('2016-11-14' as datetime)) as w);
go

create procedure  BABEL_3358_vu_prepare_p2 as (select datename(dw, cast('2016-11-14' as datetime)) as dw, datename(w, cast('2016-11-14' as datetime)) as w);
go

create procedure  BABEL_3358_vu_prepare_p3 as (select datediff(w, cast('2016-11-14' as datetime), cast('2016-11-14' as datetime) + 17));
go

create procedure  BABEL_3358_vu_prepare_p4 as (select dateadd(w, 1,cast('2016-11-14' as datetime)));
go

create function BABEL_3358_vu_prepare_f1()
returns datetime as
begin
return (select datepart(w, cast('2016-06-27' as datetime)) as w);
end
go

create function BABEL_3358_vu_prepare_f2()
returns nvarchar(15) as
begin
return (select datename(w, cast('2016-06-27' as datetime)) as w);
end
go

create function BABEL_3358_vu_prepare_f3()
returns datetime as
begin
return (select datediff(w, cast('2016-06-27' as datetime), cast('2016-06-27' as datetime) + 17));
end
go

create function BABEL_3358_vu_prepare_f4()
returns datetime as
begin
return (select dateadd(w, 1,cast('2016-06-27' as datetime)));
end
go
