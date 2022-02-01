select datename(month, cast('2002-05-23 23:41:29.998' as smalldatetime));
go

select datename(dw, null);
go

select dateadd(year, 2, cast('20060830' AS datetime));
go

select dateadd(yy, 1, null);
go

select datepart(weekday, cast( '2021-12-31' as date));
go

select datepart(dw, null);
go
