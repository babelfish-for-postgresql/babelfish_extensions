select cast('04/15/1996 14:30' as datetime)
go

select cast('04-15-1996 14:30:20:999' as datetime)
go

select cast('04.15.1996 14:30:20.9' as datetime)
go

select cast('04/1996/15 14:30:20:999' as datetime)
go

select cast('15/04/1996 14:30:20:999' as datetime)
go

select cast('15/1996/04 14:30:20:999' as datetime)
go

select cast('1996/15/04 14:30:20:999' as datetime)
go

select cast('1996/04/15 14:30:20:999' as datetime)
go

select cast('April 15, 1996 14:30:20.9' as datetime)
go

select cast('April 15, 1996 14:30:20.9' as datetime)
go

select cast('April 1996 15 14:30:20.9' as datetime)
go

select cast('15 April, 1996 14:30:20.9' as datetime)
go

select cast('15 April,1996 14:30:20.9' as datetime)
go

select cast('15 1996 april 14:30:20.9' as datetime)
go

select cast('15 1996 april 14:30:20.9' as datetime)
go

select cast('1996 APRIL 15 14:30:20.9' as datetime)
go

select cast('1996 15 APRIL 14:30' as datetime)
go

-- DATETIME
-- -- Numeric
select cast('3-2-4 14:30' as datetime)
go

select cast('3-12-4 14:30' as datetime)
go

select cast('3-12-24 14:30' as datetime)
go

select cast('3-12-2024 14:30' as datetime)
go

-- WRONG
select cast('3     -        12 -           2024 14:30' as datetime)
go

select cast('3.2.4 14:30' as datetime)
go

select cast('3.12.4 14:30' as datetime)
go

select cast('3.12.24 14:30' as datetime)
go

select cast('3.12.2024 14:30' as datetime)
go

-- wrong
select cast('3     .        12 .           2024 14:30' as datetime)
go

select cast('3/2/4 14:30' as datetime)
go

select cast('3/12/4 14:30' as datetime)
go

select cast('3/12/24 14:30' as datetime)
go

select cast('3/12/2024 14:30' as datetime)
go

select cast('3     /        12 /           2024 14:30' as datetime)
go

select cast('04-02-03 14:30' as datetime)
go

-- invalid syntax

-- wrong
select cast('3 12 2024' as datetime)
go

-- wrong
select cast('3#12#2024' as datetime)
go

-- wrong
select cast('3/12.2024' as datetime)
go

-- Alphabetical
select cast('Apr 12,2000 14:30' as datetime)
go

select cast('Apr 12 2000 14:30' as datetime)
go

select cast('Apr 1 2000 14:30' as datetime)
go

select cast('Apr 1,2000 14:30' as datetime)
go

select cast('Apr 2000 14:30' as datetime)
go

select cast('Apr 16, 2000 14:30' as datetime)
go

select cast('Apr 1, 2000 14:30' as datetime)
go

select cast('April 16, 2000 14:30' as datetime)
go

select cast('April 16  2000 14:30' as datetime)
go

select cast('Apr 16, 24 14:30' as datetime)
go

select cast('Apr 16,4 14:30' as datetime)
go

select cast('Apr 1,4 14:30' as datetime)
go

select cast('Apr 16    24 14:30' as datetime)
go

select cast('Apr 16 4 14:30' as datetime)
go

-- wrong
select cast('April 16 14:30' as datetime)
go

-- wrong
select cast('Apr 2024 14:30' as datetime)
go

select cast('Apr 2024 22 14:30' as datetime)
go

select cast('Apr 2024 2 14:30' as datetime)
go

select cast('24 Apr, 2024 14:30' as datetime)
go

select cast('3 Apr, 2024 14:30' as datetime)
go

-- wrong
select cast('Apr, 2024 14:30' as datetime)
go

-- wrong
select cast('Apr 2024 14:30' as datetime)
go

select cast('3 Apr 2024 14:30' as datetime)
go

select cast('3Apr2024 14:30' as datetime)
go

select cast('3Apr24 14:30' as datetime)
go

-- wrong
select cast('Apr24 14:30' as datetime)
go

-- wrong
select cast('Apr,24 14:30' as datetime)
go

-- wrong
select cast('24 Apr 14:30' as datetime)
go

-- wrong
select cast('12 24 Apr 14:30' as datetime)
go

-- wrong
select cast('12 2024 Apr 14:30' as datetime)
go

-- wrong
select cast('2024 Apr 14:30' as datetime)
go

select cast('2024 12 Apr 14:30' as datetime)
go

select cast('2024 9 Apr 14:30' as datetime)
go

select cast('2024 Apr 12 14:30' as datetime)
go

select cast('12, Apr, 2024 14:30' as datetime)
go

select cast('12 Apr, 2024 14:30' as datetime)
go

select cast('12, Apr 2024 14:30' as datetime)
go

-- wrong
select cast('2024, Apr, 12 14:30' as datetime)
go

select cast('2024 Apr, 12 14:30' as datetime)
go

-- wrong
select cast('2024, Apr 12 14:30' as datetime)
go

select cast('Apr, 12, 2024 14:30' as datetime)
go

select cast('Apr 12, 2024 14:30' as datetime)
go

select cast('Apr, 12 2024 14:30' as datetime)
go

-- wrong
select cast('Apr, 2024, 12 14:30' as datetime)
go

-- wrong
select cast('Apr 2024, 12 14:30' as datetime)
go

select cast('Apr, 2024 12 14:30' as datetime)
go

select cast('12, 2024, Apr 14:30' as datetime)
go

select cast('12 2024, Apr 14:30' as datetime)
go

-- wrong
select cast('12, 2024 Apr 14:30' as datetime)
go

-- wrong
select cast('2024, 12, Apr 14:30' as datetime)
go

select cast('2024 12, Apr 14:30' as datetime)
go

-- wrong
select cast('2024, 12 Apr 14:30' as datetime)
go

-- ISO 8601	
select cast('2023-11-27' as datetime)
go

SELECT cast('2022-10-30T03:00:00' as datetime)
GO

SELECT cast('2022-10-30T03:00:00.123' as datetime)
GO

-- wrong
SELECT cast('2022-10-30T03:00:00.123-12:12' as datetime)
GO

-- wrong
SELECT cast('2022-10-30T03:00:00.123+12:12' as datetime)
GO

-- wrong
SELECT cast('2022-10-30T03:00' as datetime)
GO

SELECT cast('2022-10 -30T03: 00:00' as datetime)
GO

SELECT cast('2022-10-30T03:00:00.12345' as datetime)
GO

-- wrong
SELECT cast('2022-10-30T03:00:00:123' as datetime)
GO

SELECT cast('2022-10-30T03:00:00:12345' as datetime)
GO

-- Unseparated
select cast('20240129' as datetime)
go

select cast('20241329' as datetime)
go

select cast('240129' as datetime)
go

select cast('241329' as datetime)
go

-- wrong
select cast('2001' as datetime)
go

select cast('0001' as datetime)
go

select cast('20240129 03:00:00' as datetime)
go

select cast('20241329 03:00:00' as datetime)
go

select cast('240129 03:00' as datetime)
go

select cast('241329 03:00' as datetime)
go

-- wrong
select cast('2001 03:00:00.123' as datetime)
go

-- wrong
select cast('0001 03:00:00.421' as datetime)
go

-- invalid syntax
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

-- should return default datetime
select cast('16:23:51' as datetime)
go

select cast('4:12:12:123' as datetime)
go

select cast('4:12:12:1234' as datetime)
go

select cast('4:12:12.1234' as datetime)
go

-- rounding of datetime
select cast('01/01/98 23:59:59.999' as datetime)
go

select cast('01/01/98 23:59:59.998' as datetime)
go

select cast('01/01/98 23:59:59.997' as datetime)
go

select cast('01/01/98 23:59:59.996' as datetime)
go

select cast('01/01/98 23:59:59.995' as datetime)
go

select cast('01/01/98 23:59:59.994' as datetime)
go

select cast('01/01/98 23:59:59.993' as datetime)
go

select cast('01/01/98 23:59:59.992' as datetime)
go

select cast('01/01/98 23:59:59.991' as datetime)
go

select cast('01/01/98 23:59:59.990' as datetime)
go

-- out of bound values
SELECT cast('2022-10-00 23:59:59.990' as datetime)
GO

SELECT cast('0000-10-01 23:59:59.990' as datetime)
GO

SELECT cast('2023-00-01 23:59:59.990' as datetime)
GO

SELECT cast('0000-00-00 23:59:59.990' as datetime)
GO

SELECT cast('1742-10-01 23:59:59.990' as datetime)
GO

--- misc
-- wrong
SELECT cast('02001-04-22 16:23:51' as datetime)
GO

-- wrong
SELECT cast('1900-05-06 13:59:29.050 -8:00' as datetime)
GO


-- DATETIME2
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
select cast('3 12 2024' as datetime2)
go

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

-- hijri
select cast('20231229', 130)
go

select cast('20231230', 130)
go

select cast('20231129', 130)
go

select cast('20231130', 130)
go

select cast('22 ذو الحجة 1440 1:39:17.090P', 130)
go

select cast('22 ذو الحجة 1440 1:39:17.090P', 130)
go

select cast('22/12/1440 1:39:17.090PM', 131)
go

select cast('22/12/1440 1:39:17.090PM', 131)
go

-- -- hijri leap year
select cast('20241230', 130)
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
SELECT cast(datetime2,'2022-10-00 23:59:59.990' as datetime2)
GO

SELECT cast(datetime2,'0000-10-01 23:59:59.990' as datetime2)
GO

SELECT cast(datetime2,'2023-00-01 23:59:59.990' as datetime2)
GO

SELECT cast(datetime2,'0000-00-00 23:59:59.990' as datetime2)
GO

--- misc
SELECT cast('02001-04-22 16:23:51' as datetime2)
GO

SELECT cast('1900-05-06 13:59:29.050 -8:00' as datetime2)
GO

SELECT cast('2011-08-15 14:30.00 -8:00' as datetime2)
GO

SELECT cast('02001-04-22 16:23:51' as datetime2)
go

-- DATETIMEOFFSET
-- -- Numeric
select cast('3-2-4 14:30 -8:00' as datetimeoffset)
go

select cast('3-12-4 14:30 +8:00' as datetimeoffset)
go

select cast('3-12-24 14:30 -8:00' as datetimeoffset)
go

select cast('3-12-2024 14:30 +8:00' as datetimeoffset)
go

select cast('3     -        12 -           2024 14:30 +8:00' as datetimeoffset)
go

select cast('3.2.4 14:30 -8:00' as datetimeoffset)
go

select cast('3.12.4 14:30 -8:00' as datetimeoffset)
go

select cast('3.12.24 14:30 +8:00' as datetimeoffset)
go

select cast('3.12.2024 14:30 -8:00' as datetimeoffset)
go

select cast('3     .        12 .           2024 14:30 -8:00' as datetimeoffset)
go

select cast('3/2/4 14:30 -8:00' as datetimeoffset)
go

select cast('3/12/4 14:30 +8:00' as datetimeoffset)
go

select cast('3/12/24 14:30 +8:00' as datetimeoffset)
go

select cast('3/12/2024 14:30 -8:00' as datetimeoffset)
go

select cast('3     /        12 /           2024 14:30 -8:00' as datetimeoffset)
go

select cast('04-02-03 14:30 -8:00' as datetimeoffset)
go

-- invalid syntax
select cast('3 12 2024 +8:00' as datetimeoffset)
go

select cast('3#12#2024 -8:00' as datetimeoffset)
go

select cast('3/12.2024 -8:00' as datetimeoffset)
go

-- Alphabetical
select cast('Apr 12,2000 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 12 2000 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 1 2000 14:30 +8:00' as datetimeoffset)
go

select cast('Apr 1,2000 14:30 +8:00' as datetimeoffset)
go

select cast('Apr 2000 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 16, 2000 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 1, 2000 14:30 -8:00' as datetimeoffset)
go

select cast('April 16, 2000 14:30 +8:00' as datetimeoffset)
go

select cast('April 16  2000 14:30Z' as datetimeoffset)
go

select cast('Apr 16, 24 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 16,4 14:30Z' as datetimeoffset)
go

select cast('Apr 1,4 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 16    24 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 16 4 14:30 -8:00' as datetimeoffset)
go

select cast('April 16 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 2024 14:30Z' as datetimeoffset)
go

select cast('Apr 2024 22 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 2024 2 14:30 -8:00' as datetimeoffset)
go

select cast('24 Apr, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('3 Apr, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('Apr, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 2024 14:30 -8:00' as datetimeoffset)
go

select cast('3 Apr 2024 14:30 -8:00' as datetimeoffset)
go

select cast('3Apr2024 14:30 -8:00' as datetimeoffset)
go

select cast('3Apr24 14:30 -8:00' as datetimeoffset)
go

select cast('Apr24 14:30 -8:00' as datetimeoffset)
go

select cast('Apr,24 14:30 -8:00' as datetimeoffset)
go

select cast('24 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('12 24 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('12 2024 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024 12 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024 9 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024 Apr 12 14:30 -8:00' as datetimeoffset)
go

select cast('12, Apr, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('12 Apr, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('12, Apr 2024 14:30 -8:00' as datetimeoffset)
go

select cast('2024, Apr, 12 14:30 -8:00' as datetimeoffset)
go

select cast('2024 Apr, 12 14:30 -8:00' as datetimeoffset)
go

select cast('2024, Apr 12 14:30 -8:00' as datetimeoffset)
go

select cast('Apr, 12, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 12, 2024 14:30 -8:00' as datetimeoffset)
go

select cast('Apr, 12 2024 14:30 -8:00' as datetimeoffset)
go

select cast('Apr, 2024, 12 14:30 -8:00' as datetimeoffset)
go

select cast('Apr 2024, 12 14:30 -8:00' as datetimeoffset)
go

select cast('Apr, 2024 12 14:30 -8:00' as datetimeoffset)
go

select cast('12, 2024, Apr 14:30 -8:00' as datetimeoffset)
go

select cast('12 2024, Apr 14:30 -8:00' as datetimeoffset)
go

select cast('12, 2024 Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024, 12, Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024 12, Apr 14:30 -8:00' as datetimeoffset)
go

select cast('2024, 12 Apr 14:30 -8:00' as datetimeoffset)
go

-- ISO 8601	
select cast('2023-11-27-8:00' as datetimeoffset)
go

SELECT cast('2022-10-30T03:00:00-8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123-8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123-12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123+12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00-8:00' as datetimeoffset)
GO

SELECT cast('2022-10 -30T03: 00:00-8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.12345-8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:123-8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:12345-8:00' as datetimeoffset)
GO

select cast('2023-11-27+8:00' as datetimeoffset)
go

SELECT cast('2022-10-30T03:00:00+8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123+8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123-12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123+12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00+8:00' as datetimeoffset)
GO

SELECT cast('2022-10 -30T03: 00:00+8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.12345+8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:123+8:00' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:12345+8:00' as datetimeoffset)
GO

select cast('2023-11-27Z' as datetimeoffset)
go

SELECT cast('2022-10-30T03:00:00Z' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123Z' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123-12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.123+12:12' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00Z' as datetimeoffset)
GO

SELECT cast('2022-10 -30T03: 00:00Z' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00.12345Z' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:123Z' as datetimeoffset)
GO

SELECT cast('2022-10-30T03:00:00:12345Z' as datetimeoffset)
GO


-- Unseparated
select cast('20240129 +8:00' as datetimeoffset)
go

select cast('20241329 -8:00' as datetimeoffset)
go

select cast('240129 Z' as datetimeoffset)
go

select cast('241329 -8:00' as datetimeoffset)
go

select cast('2001 -8:00' as datetimeoffset)
go

select cast('0001 -8:00' as datetimeoffset)
go

select cast('20240129 03:00:00 -8:00' as datetimeoffset)
go

select cast('20241329 03:00:00 +8:00' as datetimeoffset)
go

select cast('240129 03:00 Z' as datetimeoffset)
go

select cast('241329 03:00 -8:00' as datetimeoffset)
go

select cast('2001 03:00:00.123 -8:00' as datetimeoffset)
go

select cast('0001 03:00:00.421Z' as datetimeoffset)
go

-- -- invalid syntax
select cast('0' as datetimeoffset)
go

select cast('1' as datetimeoffset)
go

select cast('11' as datetimeoffset)
go

select cast('111' as datetimeoffset)
go

select cast('11111' as datetimeoffset)
go

select cast('1111111' as datetimeoffset)
go

-- should return default datetimeoffset
select cast('16:23:51 -8:00' as datetimeoffset)
go

select cast('4:12:12:123 -8:00' as datetimeoffset)
go

select cast('4:12:12:1234 -8:00' as datetimeoffset)
go

select cast('4:12:12.1234 -8:00' as datetimeoffset)
go

-- rounding of datetimeoffset
select cast('01/01/98 23:59:59.12345679 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345678 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345677 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345676 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345675 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345674 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345673 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345672 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345671 -8:00' as datetimeoffset)
go

select cast('01/01/98 23:59:59.12345670 -8:00' as datetimeoffset)
go

-- -- out of bound values
SELECT cast('2022-10-00 23:59:59.990 -8:00' as datetimeoffset)
GO

SELECT cast('0000-10-01 23:59:59.990 -8:00' as datetimeoffset)
GO

-- SELECT cast('2023-00-01 23:59:59.990 -8:00' as datetimeoffset)
-- GO

-- SELECT cast('0000-00-00 23:59:59.990 -8:00' as datetimeoffset)
-- GO

-- SELECT cast('2022-10-21 23:59:59.990 +14:01' as datetimeoffset)
-- GO

-- SELECT cast('2022-10-21 23:59:59.990 -15:00' as datetimeoffset)
-- GO

-- --- misc
-- SELECT cast('02001-04-22 16:23:51 -8:00' as datetimeoffset)
-- GO

-- SELECT cast('1900-05-06 13:59:29.050' as datetimeoffset)
-- GO

-- SELECT cast('2000-04-22 16:23:51.7668c0 -8:00' as datetimeoffset)
-- GO

-- SELECT cast('2001-04-022 16:23:51.766890 +12:00' as datetimeoffset)
-- GO

-- SELECT cast('02001-04-22 16:23:51.766890 +12:00' as datetimeoffset) 
-- GO 

-- SELECT cast(' 2001- 04 - 22 16: 23: 51. 766890 +12:00' as datetimeoffset)
-- GO

-- SELECT cast('2011-08-15 14:30.00' as datetimeoffset)
-- GO
