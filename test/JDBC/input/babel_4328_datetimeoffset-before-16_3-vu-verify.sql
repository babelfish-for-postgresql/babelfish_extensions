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

select * from babel_4328_datetimeoffset_v1
go

exec babel_4328_datetimeoffset_p1
go

select babel_4328_datetimeoffset_f1()
go

select * from babel_4328_datetimeoffset_v2
go

exec babel_4328_datetimeoffset_p2
go

select babel_4328_datetimeoffset_f2()
go

select * from babel_4328_datetimeoffset_v3
go

exec babel_4328_datetimeoffset_p3
go

select babel_4328_datetimeoffset_f3()
go

select * from babel_4328_datetimeoffset_v4
go

exec babel_4328_datetimeoffset_p4
go

select babel_4328_datetimeoffset_f4()
go

select * from babel_4328_datetimeoffset_v5
go

exec babel_4328_datetimeoffset_p5
go

select babel_4328_datetimeoffset_f5()
go

select * from babel_4328_datetimeoffset_v6
go

exec babel_4328_datetimeoffset_p6
go

select babel_4328_datetimeoffset_f6()
go
