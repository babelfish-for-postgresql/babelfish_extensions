-- DATE
-- -- Numeric: [m]m<seperator>[d]d<seperator>([y]y|yyyy)
select cast('3-2-4' as datetime)
go

select cast('3-12-4' as datetime)
go

select cast('3-12-24' as datetime)
go

select cast('3-12-2024' as datetime)
go

select cast('3     -        12 -           2024' as datetime)
go

select cast('3.2.4' as datetime)
go

select cast('3.12.4' as datetime)
go

select cast('3.12.24' as datetime)
go

select cast('3.12.2024' as datetime)
go

select cast('3     .        12 .           2024' as datetime)
go

select cast('3/2/4' as datetime)
go

select cast('3/12/4' as datetime)
go

select cast('3/12/24' as datetime)
go

select cast('3/12/2024' as datetime)
go

select cast('3     /        12 /           2024' as datetime)
go

select cast('04-02-03' as datetime)
go

-- invalid syntax
select cast('3#12#2024' as datetime)
go

select cast('3/12.2024' as datetime)
go

-- Alphabetical
select cast('Apr 12,2000' as datetime)
go

select cast('Apr 12 2000' as datetime)
go

select cast('Apr 1 2000' as datetime)
go

select cast('Apr 1,2000' as datetime)
go

select cast('Apr 2000' as datetime)
go

select cast('Apr 16, 2000' as datetime)
go

select cast('Apr 1, 2000' as datetime)
go

select cast('April 16, 2000' as datetime)
go

select cast('April 16  2000' as datetime)
go

select cast('Apr 16, 24' as datetime)
go

select cast('Apr 16,4' as datetime)
go

select cast('Apr 1,4' as datetime)
go

select cast('Apr 16    24' as datetime)
go

select cast('Apr 16 4' as datetime)
go

select cast('April 16' as datetime)
go

select cast('Apr 2024' as datetime)
go

select cast('Apr 2024 22' as datetime)
go

select cast('Apr 2024 2' as datetime)
go

select cast('24 Apr, 2024' as datetime)
go

select cast('3 Apr, 2024' as datetime)
go

select cast('Apr, 2024' as datetime)
go

select cast('Apr 2024' as datetime)
go

select cast('3 Apr 2024' as datetime)
go

select cast('3Apr2024' as datetime)
go

select cast('3Apr24' as datetime)
go

select cast('Apr24' as datetime)
go

select cast('Apr,24' as datetime)
go

select cast('24 Apr' as datetime)
go

select cast('12 24 Apr' as datetime)
go

select cast('12 2024 Apr' as datetime)
go

select cast('2024 Apr' as datetime)
go

select cast('2024 12 Apr' as datetime)
go

select cast('2024 9 Apr' as datetime)
go

select cast('2024 Apr 12' as datetime)
go

-- ISO 8601	
select cast('2023-11-27' as datetime)
go

select cast('2023-2-29' as datetime)
go

select cast('2022-10-30T03:00:00.123' as datetime)
go

select cast('2022-10-30T03:00:00.123-11:11' as datetime)
go

-- Unseparated
select cast('20240129' as datetime)
go

select cast('20241329' as datetime)
go

select cast('240129' as datetime)
go

select cast('241329' as datetime)
go

select cast('2001' as datetime)
go

select cast('0001' as datetime)
go

-- -- invalid syntax
select cast('0' as datetime)
go

select cast('1' as datetime)
go

select cast('11' as datetime)
go

select cast('111' as datetime)
go

select cast('11111' as datetime)
go

select cast('1111111' as datetime)
go

-- W3C XML format
select cast('2000-04-22-05:12' as datetime)
go

select cast('2000-04-22+05:12' as datetime)
go

select cast('2000-04-22-14:00' as datetime)
go

select cast('2000-04-22+14:00' as datetime)
go

select cast('2000-04-22-14:10' as datetime)
go

select cast('2000-04-22+14:10' as datetime)
go

select cast('2000-04-22Z' as datetime)
go

-- should return default date
select cast('16:23:51' as datetime)
go

select cast('4:12:12:123' as datetime)
go

select cast('4:12:12:1234' as datetime)
go

select cast('4:12:12.1234' as datetime)
go

-- out of bound values
SELECT cast('2022-10-00' as datetime)
GO

SELECT cast('0000-10-01' as datetime)
GO

SELECT cast('2023-00-01' as datetime)
GO

SELECT cast('0000-00-00' as datetime)
GO

-- -- misc
SELECT cast('2022-10-29 20:01:00.000' as datetime)
GO

SELECT cast('2020' as datetime)
GO

SELECT cast('2000-04-22 16:23:51.7668c0' as datetime)
GO

SELECT cast('2000-04-22 16:23:51.7668c0' as datetime)
GO

SELECT cast('2001-04-022 16:23:51.766890 +12:00' as datetime)
GO

SELECT cast('02001-04-22 16:23:51.766890 +12:00' as datetime) 
GO 

SELECT cast(' 2001- 04 - 22 16: 23: 51. 766890 +12:00' as datetime)
GO

SELECT cast('02001-04-22 16:23:51' as datetime)
GO

SELECT cast('1900-05-06 13:59:29.050 -8:00' as datetime)
GO

SELECT cast('2011-08-15 14:30.00' as datetime)
GO

SELECT cast('2011-08-15 14:30.00' as datetime)
GO

SELECT cast('2022-10-29 20:01:00.000' as datetime)
GO

SELECT cast('2020' as datetime)
GO

SELECT cast('2022-10-30T03:00:00' as datetime)
GO

exec babel_4328_datetime_p1
go

select babel_4328_datetime_f1()
go

select * from babel_4328_datetime_v2
go

exec babel_4328_datetime_p2
go

select babel_4328_datetime_f2()
go

select * from babel_4328_datetime_v3
go

exec babel_4328_datetime_p3
go

select babel_4328_datetime_f3()
go

exec babel_4328_datetime_p4
go

select babel_4328_datetime_f4()
go

select * from babel_4328_datetime_v5
go

exec babel_4328_datetime_p5
go

select babel_4328_datetime_f5()
go

select * from babel_4328_datetime_v6
go

exec babel_4328_datetime_p6
go

select babel_4328_datetime_f6()
go
