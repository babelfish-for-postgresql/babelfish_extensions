-- -- Numeric
select cast('3-2-4 14:30' as datetime2)
go

select cast('3-12-4 14:30' as datetime2)
go

select cast('3-12-24 14:30' as datetime2)
go

select cast('3-12-2024 14:30' as datetime2)
go

select cast('3     -        12 -           2024 14:30' as datetime2)
go

select cast('3.2.4 14:30' as datetime2)
go

select cast('3.12.4 14:30' as datetime2)
go

select cast('3.12.24 14:30' as datetime2)
go

select cast('3.12.2024 14:30' as datetime2)
go

select cast('3     .        12 .           2024 14:30' as datetime2)
go

select cast('3/2/4 14:30' as datetime2)
go

select cast('3/12/4 14:30' as datetime2)
go

select cast('3/12/24 14:30' as datetime2)
go

select cast('3/12/2024 14:30' as datetime2)
go

select cast('3     /        12 /           2024 14:30' as datetime2)
go

select cast('04-02-03 14:30' as datetime2)
go

-- invalid syntax
select cast('3#12#2024' as datetime2)
go

select cast('3/12.2024' as datetime2)
go

-- Alphabetical
select cast('Apr 12,2000 14:30' as datetime2)
go

select cast('Apr 12 2000 14:30' as datetime2)
go

select cast('Apr 1 2000 14:30' as datetime2)
go

select cast('Apr 1,2000 14:30' as datetime2)
go

select cast('Apr 2000 14:30' as datetime2)
go

select cast('Apr 16, 2000 14:30' as datetime2)
go

select cast('Apr 1, 2000 14:30' as datetime2)
go

select cast('April 16, 2000 14:30' as datetime2)
go

select cast('April 16  2000 14:30' as datetime2)
go

select cast('Apr 16, 24 14:30' as datetime2)
go

select cast('Apr 16,4 14:30' as datetime2)
go

select cast('Apr 1,4 14:30' as datetime2)
go

select cast('Apr 16    24 14:30' as datetime2)
go

select cast('Apr 16 4 14:30' as datetime2)
go

select cast('April 16 14:30' as datetime2)
go

select cast('Apr 2024 14:30' as datetime2)
go

select cast('Apr 2024 22 14:30' as datetime2)
go

select cast('Apr 2024 2 14:30' as datetime2)
go

select cast('24 Apr, 2024 14:30' as datetime2)
go

select cast('3 Apr, 2024 14:30' as datetime2)
go

select cast('Apr, 2024 14:30' as datetime2)
go

select cast('Apr 2024 14:30' as datetime2)
go

select cast('3 Apr 2024 14:30' as datetime2)
go

select cast('3Apr2024 14:30' as datetime2)
go

select cast('3Apr24 14:30' as datetime2)
go

select cast('Apr24 14:30' as datetime2)
go

select cast('Apr,24 14:30' as datetime2)
go

select cast('24 Apr 14:30' as datetime2)
go

select cast('12 24 Apr 14:30' as datetime2)
go

select cast('12 2024 Apr 14:30' as datetime2)
go

select cast('2024 Apr 14:30' as datetime2)
go

select cast('2024 12 Apr 14:30' as datetime2)
go

select cast('2024 9 Apr 14:30' as datetime2)
go

select cast('2024 Apr 12 14:30' as datetime2)
go

select cast('12, Apr, 2024 14:30' as datetime2)
go

select cast('12 Apr, 2024 14:30' as datetime2)
go

select cast('12, Apr 2024 14:30' as datetime2)
go

select cast('2024, Apr, 12 14:30' as datetime2)
go

select cast('2024 Apr, 12 14:30' as datetime2)
go

select cast('2024, Apr 12 14:30' as datetime2)
go

select cast('Apr, 12, 2024 14:30' as datetime2)
go

select cast('Apr 12, 2024 14:30' as datetime2)
go

select cast('Apr, 12 2024 14:30' as datetime2)
go

select cast('Apr, 2024, 12 14:30' as datetime2)
go

select cast('Apr 2024, 12 14:30' as datetime2)
go

select cast('Apr, 2024 12 14:30' as datetime2)
go

select cast('12, 2024, Apr 14:30' as datetime2)
go

select cast('12 2024, Apr 14:30' as datetime2)
go

select cast('12, 2024 Apr 14:30' as datetime2)
go

select cast('2024, 12, Apr 14:30' as datetime2)
go

select cast('2024 12, Apr 14:30' as datetime2)
go

select cast('2024, 12 Apr 14:30' as datetime2)
go

-- ISO 8601	
select cast('2023-11-27' as datetime2)
go

SELECT cast('2022-10-30T03:00:00' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00.123' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00.123-12:12' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00.123+12:12' as datetime2)
GO

SELECT cast('2022-10-30T03:00' as datetime2)
GO

SELECT cast('2022-10 -30T03: 00:00' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00.12345' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00:123' as datetime2)
GO

SELECT cast('2022-10-30T03:00:00:12345' as datetime2)
GO

-- Unseparated
select cast('20240129' as datetime2)
go

select cast('20241329' as datetime2)
go

select cast('240129' as datetime2)
go

select cast('241329' as datetime2)
go

select cast('2001' as datetime2)
go

select cast('0001' as datetime2)
go

select cast('20240129 03:00:00' as datetime2)
go

select cast('20241329 03:00:00' as datetime2)
go

select cast('240129 03:00' as datetime2)
go

select cast('241329 03:00' as datetime2)
go

select cast('2001 03:00:00.123' as datetime2)
go

select cast('0001 03:00:00.421' as datetime2)
go

-- -- invalid syntax
select cast('0' as datetime2)
go

select cast('1' as datetime2)
go

select cast('11' as datetime2)
go

select cast('111' as datetime2)
go

select cast('11111' as datetime2)
go

select cast('1111111' as datetime2)
go

-- should return default datetime2
select cast('16:23:51' as datetime2)
go

select cast('4:12:12:123' as datetime2)
go

select cast('4:12:12:1234' as datetime2)
go

select cast('4:12:12.1234' as datetime2)
go

-- rounding of datetime2
select cast('01/01/98 23:59:59.12345679' as datetime2)
go

select cast('01/01/98 23:59:59.12345678' as datetime2)
go

select cast('01/01/98 23:59:59.12345677' as datetime2)
go

select cast('01/01/98 23:59:59.12345676' as datetime2)
go

select cast('01/01/98 23:59:59.12345675' as datetime2)
go

select cast('01/01/98 23:59:59.12345674' as datetime2)
go

select cast('01/01/98 23:59:59.12345673' as datetime2)
go

select cast('01/01/98 23:59:59.12345672' as datetime2)
go

select cast('01/01/98 23:59:59.12345671' as datetime2)
go

select cast('01/01/98 23:59:59.12345670' as datetime2)
go

-- -- out of bound values
SELECT cast('2022-10-00 23:59:59.990' as datetime2)
GO

SELECT cast('0000-10-01 23:59:59.990' as datetime2)
GO

SELECT cast('2023-00-01 23:59:59.990' as datetime2)
GO

SELECT cast('0000-00-00 23:59:59.990' as datetime2)
GO

--- misc
SELECT cast('02001-04-22 16:23:51' as datetime2)
GO

SELECT cast('1900-05-06 13:59:29.050 -8:00' as datetime2)
GO

SELECT cast('2011-08-15 14:30.00 -8:00' as datetime2)
GO

SELECT cast('16 apr 2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000' as datetime)
go

select * from babel_4328_datetime2_v1
go

exec babel_4328_datetime2_p1
go

select babel_4328_datetime2_f1()
go

select * from babel_4328_datetime2_v2
go

exec babel_4328_datetime2_p2
go

select babel_4328_datetime2_f2()
go

select * from babel_4328_datetime2_v3
go

exec babel_4328_datetime2_p3
go

select babel_4328_datetime2_f3()
go

select * from babel_4328_datetime2_v4
go

exec babel_4328_datetime2_p4
go

select babel_4328_datetime2_f4()
go

select * from babel_4328_datetime2_v5
go

exec babel_4328_datetime2_p5
go

select babel_4328_datetime2_f5()
go

select * from babel_4328_datetime2_v6
go

exec babel_4328_datetime2_p6
go

select babel_4328_datetime2_f6()
go

