SELECT CAST('' AS DATETIME2)
go
-- Numeric
select cast('3-2-4 14:30' as datetime2)
go

select cast('3-12-4 14:30' as datetime2)
go

select cast('3-12-24 14:30' as datetime2)
go

select cast('3-12-2024 14:30' as datetime2)
go

SELECT CAST('11-12-2024' AS DATETIME2)
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

SELECT CAST('11.12.2024' AS DATETIME2)
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

SELECT CAST('11/12/2024' AS DATETIME2)
go

select cast('3     /        12 /           2024 14:30' as datetime2)
go

select cast('04-02-03 14:30' as datetime2)
go

SELECT CAST('3-4-2' AS DATETIME2)
go

SELECT CAST('3-4-12' AS DATETIME2)
go

SELECT CAST('3-24-12' AS DATETIME2)
go

SELECT CAST('3-2024-12' AS DATETIME2)
go

SELECT CAST('11-2024-12' AS DATETIME2)
go

SELECT CAST('3 -           2024     -        12' AS DATETIME2)
go

SELECT CAST('3.4.2' AS DATETIME2)
go

SELECT CAST('3.4.12' AS DATETIME2)
go

SELECT CAST('3.24.12' AS DATETIME2)
go

SELECT CAST('3.2024.12' AS DATETIME2)
go

SELECT CAST('11.2024.12' AS DATETIME2)
go

SELECT CAST('3 .           2024     .        12' AS DATETIME2)
go

SELECT CAST('3/4/2' AS DATETIME2)
GO

SELECT CAST('3/4/12' AS DATETIME2)
GO

SELECT CAST('3/24/12' AS DATETIME2)
GO

SELECT CAST('3/2024/12' AS DATETIME2)
GO

SELECT CAST('11/2024/12' AS DATETIME2)
GO

SELECT CAST('3 /           2024     /        12' AS DATETIME2)
GO

-- [d]d<seperator>[m]m<seperator>([y]y|yyyy)
SELECT CAST('2-3-4' AS DATETIME2)
GO

SELECT CAST('12-3-4' AS DATETIME2)
GO

SELECT CAST('12-3-24' AS DATETIME2)
GO

SELECT CAST('12-3-2024' AS DATETIME2)
GO

SELECT CAST('12-11-2024' AS DATETIME2)
GO

SELECT CAST('12 -           3     -        2024' AS DATETIME2)
GO

SELECT CAST('2.3.4' AS DATETIME2)
GO

SELECT CAST('12.3.4' AS DATETIME2)
GO

SELECT CAST('12.3.24' AS DATETIME2)
GO

SELECT CAST('12.3.2024' AS DATETIME2)
GO

SELECT CAST('12.11.2024' AS DATETIME2)
GO

SELECT CAST('12 .           3     .        2024' AS DATETIME2)
GO

SELECT CAST('2/3/4' AS DATETIME2)
GO

SELECT CAST('12/3/4' AS DATETIME2)
GO

SELECT CAST('12/3/24' AS DATETIME2)
GO

SELECT CAST('12/3/2024' AS DATETIME2)
GO

SELECT CAST('12/11/2024' AS DATETIME2)
GO

SELECT CAST('12 /           3     /        2024' AS DATETIME2)
GO

-- [d]d<seperator>([y]y|yyyy)<seperator>[m]m
SELECT CAST('2-4-3' AS DATETIME2)
GO

SELECT CAST('12-4-3' AS DATETIME2)
GO

SELECT CAST('12-24-3' AS DATETIME2)
GO

SELECT CAST('12-2024-3' AS DATETIME2)
GO

SELECT CAST('12-2024-11' AS DATETIME2)
GO

SELECT CAST('12     -        2024 -           3' AS DATETIME2)
GO

SELECT CAST('2.4.3' AS DATETIME2)
GO

SELECT CAST('12.4.3' AS DATETIME2)
GO

SELECT CAST('12.24.3' AS DATETIME2)
GO

SELECT CAST('12.2024.3' AS DATETIME2)
GO

SELECT CAST('12.2024.11' AS DATETIME2)
GO

SELECT CAST('12     .        2024 .           3' AS DATETIME2)
GO

SELECT CAST('2/4/3' AS DATETIME2)
GO

SELECT CAST('12/4/3' AS DATETIME2)
GO

SELECT CAST('12/24/3' AS DATETIME2)
GO

SELECT CAST('12/2024/3' AS DATETIME2)
GO

SELECT CAST('12/2024/11' AS DATETIME2)
GO

SELECT CAST('12     /        2024 /           3' AS DATETIME2)
GO

-- ([y]y|yyyy)<seperator>[m]m<seperator>[d]d
SELECT CAST('4-3-2' AS DATETIME2)
GO

SELECT CAST('4-3-12' AS DATETIME2)
GO

SELECT CAST('24-3-12' AS DATETIME2)
GO
~~START~~

SELECT CAST('2024-3-12' AS DATETIME2)
GO

SELECT CAST('2024-11-12' AS DATETIME2)
GO

SELECT CAST('2024     -        3 -           12' AS DATETIME2)
GO

SELECT CAST('4.3.2' AS DATETIME2)
GO

SELECT CAST('4.3.12' AS DATETIME2)
GO

SELECT CAST('24.3.12' AS DATETIME2)
GO

SELECT CAST('2024.3.12' AS DATETIME2)
GO

SELECT CAST('2024.11.12' AS DATETIME2)
GO

SELECT CAST('2024     .        3 .           12' AS DATETIME2)
GO

SELECT CAST('4/3/2' AS DATETIME2)
GO

SELECT CAST('4/3/12' AS DATETIME2)
GO

SELECT CAST('24/3/12' AS DATETIME2)
GO

SELECT CAST('2024/3/12' AS DATETIME2)
GO

SELECT CAST('2024/11/12' AS DATETIME2)
GO

SELECT CAST('2024     /        3 /           12' AS DATETIME2)
GO

-- Boundary values
SELECT CAST('9999-12-30 23:59:59.99999999' AS DATETIME2)
go

SELECT CAST('9999-12-30 23:59:59.999999999' AS DATETIME2)
go

SELECT CAST('9999-12-31 23:59:59.99999999' AS DATETIME2)
go

SELECT CAST('9999-12-31 23:59:59.999999999' AS DATETIME2)
go

SELECT CAST('2022-10-00' AS DATETIME2)
go

SELECT CAST('0000-10-01' AS DATETIME2)
go

SELECT CAST('2023-00-01' AS DATETIME2)
go

SELECT CAST('0000-00-00' AS DATETIME2)
go

SELECT CAST('1752-01-01' AS DATETIME2)
go

SELECT CAST('1753-01-01' AS DATETIME2)
go

SELECT CAST('1899-01-01' AS DATETIME2)
GO

SELECT CAST('1900-01-01' AS DATETIME2)
GO

SELECT CAST('2079-06-06' AS DATETIME2)
GO

SELECT CAST('2079-06-07' AS DATETIME2)
GO

-- invalid syntax
select cast('3#12#2024' as datetime2)
go

select cast('3/12.2024' as datetime2)
go

-- Alphabetical
select cast('Apr 12,2000 14:30' as datetime2)
go

SELECT CAST('Apr12,2000' AS DATETIME2)
go

SELECT CAST('Apr12 2000' AS DATETIME2)
go

select cast('Apr 12 2000 14:30' as datetime2)
go

select cast('Apr 1 2000 14:30' as datetime2)
go

select cast('Apr 1,2000 14:30' as datetime2)
go

SELECT CAST('Apr1,2000' AS DATETIME2)
go

SELECT CAST('Apr1 2000' AS DATETIME2)
go

SELECT CAST('Apr,2000' AS DATETIME2)
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

SELECT CAST('Apr12,' AS DATETIME2)
go

SELECT CAST('Apr12' AS DATETIME2)
go

SELECT CAST('Apr1,' AS DATETIME2)
go

SELECT CAST('Apr1' AS DATETIME2)
go

SELECT CAST('12 Apr,' AS DATETIME2)
go

SELECT CAST('12 Apr' AS DATETIME2)
go

SELECT CAST('12Apr,' AS DATETIME2)
go

SELECT CAST('12Apr' AS DATETIME2)
go

SELECT CAST('2023-2-29' AS DATETIME2)
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

SELECT CAST('2022-10-22T13:34:12.123456789' AS DATETIME2)
go

SELECT CAST('2022-10-22T13:34:12.12345678' AS DATETIME2)
go

SELECT CAST('2022-10-22T13:34:12.1234567' AS DATETIME2)
go

-- spaces are not allowed between any two tokens for ISO 8601
SELECT CAST('2022-10-22T13 :34:12.123' AS DATETIME2)
go

SELECT CAST('2022-10-22 T 13:34:12.123' AS DATETIME2)
go

SELECT CAST('2022-10-22T13:34:12.123 Z' AS DATETIME2)
go

SELECT CAST('2022-10-22T13:34:12.123 -11:11' AS DATETIME2)
go

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

-- DATETIME2 with typmod
SELECT CAST('01/01/98 23:59:56.501' AS DATETIME2(0))
go

SELECT CAST('01/01/98 23:59:56.500' AS DATETIME2(0))
go

SELECT CAST('01/01/98 23:59:56.499' AS DATETIME2(1))
go

SELECT CAST('01/01/98 23:59:59.123' AS DATETIME2(1))
go

SELECT CAST('01/01/98 23:59:59.123' AS DATETIME2(2))
go

SELECT CAST('01/01/98 23:59:59.123' AS DATETIME2(3))
go



--- misc
SELECT cast('02001-04-22 16:23:51' as datetime2)
GO

SELECT cast('1900-05-06 13:59:29.050 -8:00' as datetime2)
GO

SELECT cast('2011-08-15 14:30.00 -8:00' as datetime2)
GO

SELECT cast('16 apr 2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000' as datetime)
go

DECLARE @TM_ICLO TIME = '17:24:07.1766670'
SELECT CAST(@TM_ICLO AS DATETIME2)
GO

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

