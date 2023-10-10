SELECT * FROM DATETRUNC_vu_prepare_v1
GO

SELECT * FROM DATETRUNC_vu_prepare_v2
GO

SELECT * FROM DATETRUNC_vu_prepare_v3
GO

SELECT * FROM DATETRUNC_vu_prepare_v4
GO

SELECT * FROM DATETRUNC_vu_prepare_v5
GO

SELECT * FROM DATETRUNC_vu_prepare_v6
GO

SELECT * FROM DATETRUNC_vu_prepare_v7
GO

SELECT * FROM DATETRUNC_vu_prepare_v8
GO

SELECT * FROM DATETRUNC_vu_prepare_v9
GO

SELECT * FROM DATETRUNC_vu_prepare_v10
GO

SELECT * FROM DATETRUNC_vu_prepare_v11
GO

EXEC BABEL_3953_vu_prepare_p1
GO

EXEC BABEL_3953_vu_prepare_p2
GO

EXEC BABEL_3953_vu_prepare_p3
GO

EXEC BABEL_3953_vu_prepare_p4
GO

EXEC BABEL_3953_vu_prepare_p5
GO

EXEC BABEL_3953_vu_prepare_p6
GO

SELECT BABEL_3953_vu_prepare_f1()
GO

SELECT BABEL_3953_vu_prepare_f2()
GO

SELECT BABEL_3953_vu_prepare_f3()
GO

select datetrunc(null, CAST('2020-01-01' as date)) as dt1
GO
select datetrunc(null, null) as dt1
GO
select datetrunc(null, 'NULL') as dt1
GO
select datetrunc('NULL', null) as dt1
GO
select datetrunc('NULL', 'NULL') as dt1
GO
select datetrunc('year',CAST('2020-01-01' as date))
go
select datetrunc(year, null) as dt3
GO
select datetrunc(years, null) as dt4
GO
select datetrunc(nanosecond ,null) as dt5
GO
SELECT datetrunc(nanosecond, 2020)
GO
select datetrunc(invalid_datepart, 2020)
GO
select datetrunc(hour, 2020.0)
GO

-- postgres support 6 digits of fractional time-scale so the bbf output will differ
-- in the last fractional second digit from t-sql. bbf- 2021-12-08 11:30:15.1234570
-- tsql- 2021-12-08 11:30:15.1234560
DECLARE @d datetime2 = '2021-12-08 11:30:15.1234567';
SELECT 'Microsecond', DATETRUNC(microsecond, @d);
Go

DECLARE @test_date date;
SET @test_date = '1998-09-12';
SELECT datetrunc(week, @test_date);
GO

DECLARE @test_date datetime;
SET @test_date = '2010-09-12 12:23:12.564';
SELECT datetrunc(week, @test_date);
GO

DECLARE @test_date datetime2;
SET @test_date = '2010-09-12 12:23:12.56443';
SELECT datetrunc(week, @test_date);
GO

DECLARE @test_date smalldatetime;
SET @test_date = '2010-09-12 12:23:12';
SELECT datetrunc(week, @test_date);
GO

DECLARE @test_date datetimeoffset;
SET @test_date = '2010-09-12 12:23:12.56443 +10:12';
SELECT datetrunc(week, @test_date);
GO

DECLARE @test_date time;
SET @test_date = '12:23:12.56443';
SELECT datetrunc(hour, @test_date);
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a datetime)
insert into dtrunc (a) values(datetrunc(day, CAST('2020-01-09 12:32:23.23' as datetime)))
Select * from dtrunc
Select datetrunc(week, a) from dtrunc
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a date)
insert into dtrunc (a) values(datetrunc(day, CAST('2020-01-09' as date)))
Select * from dtrunc
Select datetrunc(week, a) from dtrunc
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a datetime2)
insert into dtrunc (a) values(datetrunc(day, '2020-01-09 12:32:23.23'))
Select * from dtrunc
Select datetrunc(day, a) from dtrunc
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a datetimeoffset)
insert into dtrunc (a) values(datetrunc(day, CAST('2020-01-09 12:32:23.23 -10:23' as datetimeoffset)))
Select * from dtrunc
Select datetrunc(month, a) from dtrunc
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a smalldatetime)
insert into dtrunc (a) values(datetrunc(day, CAST('2020-01-09 12:32:23' as smalldatetime)))
Select * from dtrunc
Select datetrunc(hour, a) from dtrunc
GO

DROP TABLE IF EXISTS dtrunc
GO
Create table dtrunc(a time)
insert into dtrunc (a) values(datetrunc(minute, CAST('12:32:23.23' as time)))
Select * from dtrunc
Select datetrunc(second, a) from dtrunc
GO

SET DATEFIRST 1
SELECT DATETRUNC(ISO_WEEK, CAST('2020-09-13 21:32:32.23' as datetime2)) 
SELECT DATETRUNC(WEEK, CAST('2020-09-13 21:32:32.23' as datetime2))
GO

SET DATEFIRST 1
SELECT DATETRUNC(ISO_WEEK, CAST('2020-08-12 21:32:32.23' as datetime2)) 
SELECT DATETRUNC(WEEK, CAST('2020-08-12 21:32:32.23' as datetime2))
GO

SET DATEFIRST 2 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12 21:32:32.23' as datetime)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12 21:32:32.23' as datetime))
GO

SET DATEFIRST 3 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12' as date)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12' as date))
GO

SET DATEFIRST 4 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12 12:22:32' as smalldatetime)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12 21:23:23' as smalldatetime))
GO

SET DATEFIRST 5 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12 12:22:32' as datetime2)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12 21:23:23' as datetime2))
GO

SET DATEFIRST 6 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12 12:22:32 +12:32' as datetimeoffset)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12 21:23:23 -09:43' as datetimeoffset))
GO

SET DATEFIRST 7 
SELECT DATETRUNC(ISO_WEEK, CAST('2020-01-12 12:22:32 +12:32' as datetimeoffset)) 
SELECT DATETRUNC(WEEK, CAST('2020-01-12 21:23:23 -09:43' as datetimeoffset))
GO
