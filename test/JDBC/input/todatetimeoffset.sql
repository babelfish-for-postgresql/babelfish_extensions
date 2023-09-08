Select todatetimeoffset('0000-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('9999-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('-1-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-0a-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('20sb-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-2c 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 1d:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-0a-22 16:2a:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 16:23:5d.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 16:23:51.7668c0','+12:00') -- Wrong output , Need to fix BABEL-4328
GO

Select todatetimeoffset('2000-05-22 16:23:51.766890','+1d:00')
GO

Select todatetimeoffset('2000-04-22 16:23:51.766890','+12:0e')
GO

Select todatetimeoffset('1-04-22 16:23:51.766890','+12:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45.3682170' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '-15:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '+23:00')
GO

Select todatetimeoffset('2000-04-22 1d:23:51.766890',120)
GO

Select todatetimeoffset('2000-04-22 16:2a:51.766890',340)
GO

Select todatetimeoffset('2000-04-22 16:23:5d.766890',841)
GO

Select todatetimeoffset('2000-04-22 16:23:51.7668c0',-342) -- Wrong output , Need to fix BABEL-4328
GO

Select todatetimeoffset('2000-05-22 16:23:51.766890',234)
GO

Select todatetimeoffset('2000-04-22 16:23:51.766890',345)
GO

Select todatetimeoffset('1-04-22 16:23:51.766890',-4556)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45.3682170' as datetime2), -345)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), -234)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08' as datetime2), 4556)
GO

Select todatetimeoffset('0001-01-00 00:00:00.00', '-10:00')
GO

Select todatetimeoffset('0001-01-01 00:00:00.00', '+13:00')
GO

Select todatetimeoffset('9999-12-31 23:59:59.59', '+12:00')
GO

Select todatetimeoffset('9999-12-31 23:59:59.59', '+12:00')
GO

Select todatetimeoffset('10000-12-31 23:59:59.59', '+12:00')
GO

Select todatetimeoffset('9934-11-30 22:52:59.59', '+14:01')
GO

Select todatetimeoffset('9934-11-30 22:52:59.59', '-14:01')
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.998 -8:00' AS datetime2), '+12:00')
GO

DECLARE @test_date datetime;
SET @test_date = '2022-12-11';
Select todatetimeoffset(@test_date,'+12:00');
GO

DECLARE @test_date datetime2;
SET @test_date = '2345-12-31 23:59:59.59';
Select todatetimeoffset(@test_date,-120);
GO

Select todatetimeoffset(DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 6 ), 300)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.998 -8:00' AS datetime2(2)), '+12:00')
Go

Select todatetimeoffset('0',120)
GO

Select todatetimeoffset('0',0x23)
Go

DROP TABLE IF EXISTS tem
GO
Create table tem(a datetimeoffset)
insert into tem (a) values(todatetimeoffset('2000-04-22 12:23:51.766890',120))
Select * from tem
Select todatetimeoffset(a,234) from tem
GO

Select todatetimeoffset('2030-05-06 13:59:29.998 ' ,'-08:00') + make_interval(1,0,3);
GO

Select todatetimeoffset('2030-05-06 13:59:29.998 ' ,'-08:00') - make_interval(1,0,3);
GO

Select todatetimeoffset('2345-12-31 23:59:59.59',NULL);
GO

Select todatetimeoffset('2345-12-31 23:59:59.59','NULL');
Go

Select todatetimeoffset(NULL,'+12:00');
GO

Select todatetimeoffset('NULL','+12:00');
GO

Select todatetimeoffset('NULL',234);
GO

Select todatetimeoffset(NULL,234);
GO

Select todatetimeoffset(NULL,'+12:000');
GO

Select todatetimeoffset('NULL','+12:000');
GO

Select todatetimeoffset('NULL',1233456777888);
GO

Select todatetimeoffset(NULL,1233456777888);
GO

Select todatetimeoffset('NULL','NULL')
GO

Select todatetimeoffset('NULL',NULL)
GO

Select todatetimeoffset(NULL,NULL)
GO

Select todatetimeoffset(NULL,'NULL')
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), 840)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), 841)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), -841)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), -840)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2), 0x23)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2), 234.49)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2), 234.50)
GO

Select todatetimeoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2), 234.56)
GO

Select todatetimeoffset('2001-04-22 ', 120)
GO

Select todatetimeoffset('2001-04-22 ', '+12:30')
GO

Select todatetimeoffset('2001-04-22 17:34:56', -120)
GO

Select todatetimeoffset('2001-04-22 17:34:56', '-13:34')
GO

Select todatetimeoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), 0x23)
GO

Select todatetimeoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), '-09:46')
GO

Select todatetimeoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), 123/2*1.0)
GO

Select todatetimeoffset('0001-01-01 00:00:01.00 +00:00',-743)
GO

Select todatetimeoffset('0001-01-01 00:00:00.00 +00:00',-743)
GO

Select todatetimeoffset('9999-12-31 23:12:00.123 +00:00',743)
GO

Select todatetimeoffset('10000-12-31 23:12:00.123 +00:00',743)
GO

