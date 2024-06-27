create view babel_4328_datetime_v1 as select cast('2020' as datetime)
go
create procedure babel_4328_datetime_p1 as select cast('2020' as datetime)
go
create function babel_4328_datetime_f1()
returns datetime as
begin
return (select cast('2020' as datetime));
end
go

create view babel_4328_datetime_v2 as select cast('04-02-03' as datetime)
go
create procedure babel_4328_datetime_p2 as select cast('04-02-03' as datetime)
go
create function babel_4328_datetime_f2()
returns datetime as
begin
return (select cast('04-02-03' as datetime));
end
go

create view babel_4328_datetime_v3 as select cast('240129' as datetime)
go
create procedure babel_4328_datetime_p3 as select cast('240129' as datetime)
go
create function babel_4328_datetime_f3()
returns datetime as
begin
return (select cast('240129' as datetime));
end
go

create view babel_4328_datetime_v4 as select cast('3     .        12 .           2024' as datetime)
go
create procedure babel_4328_datetime_p4 as select cast('3     .        12 .           2024' as datetime)
go
create function babel_4328_datetime_f4()
returns datetime as
begin
return (select cast('3     .        12 .           2024' as datetime));
end
go

create view babel_4328_datetime_v5 as select cast('April 16, 2000' as datetime)
go
create procedure babel_4328_datetime_p5 as select cast('April 16, 2000' as datetime)
go
create function babel_4328_datetime_f5()
returns datetime as
begin
return (select cast('April 16, 2000' as datetime));
end
go

create view babel_4328_datetime_v6 as select cast('2022-10-30T03:00:00.123' as datetime)
go
create procedure babel_4328_datetime_p6 as select cast('2022-10-30T03:00:00.123' as datetime)
go
create function babel_4328_datetime_f6()
returns datetime as
begin
return (select cast('2022-10-30T03:00:00.123' as datetime));
end
go
