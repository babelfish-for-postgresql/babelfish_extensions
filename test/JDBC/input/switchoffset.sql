Select switchoffset('2001-04-22 ', -120)
GO

Select switchoffset('2001-04-22 ', 120)
GO

Select switchoffset('2001-04-22 17:34:56', 120)
GO

Select switchoffset('2001-04-22 17:34:56.345', 120)
GO

Select switchoffset('2001-04-22 17:34:56.345', 0)
go

Select switchoffset('2001-04-22 17:34:56.345', -0)
go

Select switchoffset('200a-0b-22 17:34:56.345', 1)
GO

Select switchoffset('2001-04-22 17:34:56.345', 0x12)
go

Select switchoffset('2001-04-22 17:34:56.345', 'abcd')
GO

Select switchoffset('2001-04-22 ', '+12:00')
GO

Select switchoffset('2001-04-22 ', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-11:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '+00:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-00:00')
go

Select switchoffset('2001-04-22 10:34:56.345', '-11:00')
go

Select switchoffset('2001-04-22 17:34:56.345', '-101:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-011:00')
GO

Select switchoffset('200a-0b-22 17:34:56.345', '-011:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '+14:01')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-14:01')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-1a:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '14:00')
GO

-- Currently these inputs are giving wrong output due to casting issues .(BABEL-4321) 

Select switchoffset(convert(datetime,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(date,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(datetime2,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(smalldatetime,'2001-04-22'),'-13:00')
GO

--

Select switchoffset('0001-01-00 00:00:00.00', '-10:00')
GO

Select switchoffset('0001-01-01 00:00:00.00', '+13:00')
GO

Select switchoffset('9999-12-31 11:59:59.59', '+12:00')
GO

Select switchoffset('9999-12-31 24:59:59.59', 130)
GO

Select switchoffset('10000-12-31 23:59:59.59', 120)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), 120)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), '+12:00')
GO

DECLARE @test_date datetime;
SET @test_date = '2022-12-11';
Select switchoffset(@test_date,'+12:00');
GO

DECLARE @test_date datetime2;
SET @test_date = '2345-12-31 23:59:59.59';
Select switchoffset(@test_date,-120);
GO

Select switchoffset(DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 6 ), 300)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.998 -8:00' AS datetime2(2)), '+12:00')
Go

Select switchoffset('0',120)
GO

Select switchoffset('0',0x23)
Go

DROP TABLE IF EXISTS tem
GO
Create table tem(a datetimeoffset)
insert into tem (a) values(switchoffset('2000-04-22 12:23:51.766890',120))
Select * from tem
Select switchoffset(a,'+14:00') from tem;
DROP TABLE IF EXISTS tem
GO

Select switchoffset('2030-05-06 13:59:29.998 ' ,'-08:00') + make_interval(1,0,3);
GO

Select switchoffset('2030-05-06 13:59:29.998 ' ,'-08:00') - make_interval(1,0,3);
GO

Select switchoffset('NULL','NULL')
GO

Select switchoffset('NULL',NULL)
GO

Select switchoffset(NULL,NULL)
GO

Select switchoffset(NULL,'NULL')
GO

Select switchoffset(CAST('1900-05-06 13:59:29.998 -8:00' AS datetime2(2)), 0x23)
GO

DECLARE @test_offset text;
SET @test_offset = '-13:00';
Select switchoffset('2345-12-31 23:59:59.59',@test_offset);
GO

DECLARE @test_offset1 float ;
SET @test_offset1 = 23.567;
Select switchoffset('2345-12-31 23:59:59.59',@test_offset1);
GO

DECLARE @test_offset1 decimal ;
SET @test_offset1 = 23.567;
Select switchoffset('2345-12-31 23:59:59.59',@test_offset1);
GO

Select switchoffset(CAST('1900-05-0x12 13:59:29.998 -8:00' AS datetime2(2)), 235.67)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.998 -8:00' AS datetime2(2)), 23647585)
GO

Select switchoffset('2345-12-31 23:59:59.59',23.567);
GO

Select switchoffset('2345-12-31 23:59:59.59',23.467);
GO

Select switchoffset('2345-12-31 23:59:59.59',cast(123 as bit));
GO

Select switchoffset('2345-12-31 23:59:59.59',NULL);
GO

Select switchoffset('2345-12-31 23:59:59.59','NULL');
Go

Select switchoffset(NULL,'+12:00');
GO

Select switchoffset('NULL','+12:00');
GO

Select switchoffset('NULL',234);
GO

Select switchoffset(NULL,234);
GO

Select switchoffset(NULL,'+12:000');
GO

Select switchoffset('NULL','+12:000');
GO

Select switchoffset('NULL',1233456777888);
GO

Select switchoffset(NULL,1233456777888);
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), 840)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), 841)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), -841)
GO

Select switchoffset(CAST('1900-05-06 13:59:29.050 -8:00' AS datetime2(4)), -840)
GO

Select switchoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), 0x23)
GO

Select switchoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), 435.678999)
GO

Select switchoffset(DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3), 43)
GO

Select switchoffset('1900-05-06 13:59:29.998 -8:00', '-12:00')
GO

Select switchoffset('1900-05-06 12:59:29.998 -00:00', '+12:00')
GO

Select switchoffset('1900-05-06 12:59:29.998 -02:00', 234)
GO

Select switchoffset('1900-05-06 12:59:29.998 +10:00', -456)
GO

Select switchoffset('1900-05-06 12:59:29.998 -00:00', 0x12)
GO

Select switchoffset(DATETIMEOFFSETFROMPARTS(1, 1, 1, 4, 30, 00, 500, 12, 30, 3), '+00:43')
GO

Select switchoffset('1-1-1 00:00:00.000 +12:00' , '+12:00')
GO

Select switchoffset('0001-1-1 00:00:00.000 +12:00' , '+12:00')
GO

Select switchoffset('0001-01-01 00:00:00.000 +12:00' , '+12:00')
GO

Select switchoffset('0002-01-01 00:00:00.000 +12:00' , '+12:43')
GO

Select switchoffset('10000-01-01 00:00:00.000 +12:00' , '+12:00')
GO

Select switchoffset('10000-01-01 00:00:00.123 +2:00','+12:00')
GO

Select switchoffset('9999-12-31 23:12:00.123 +00:00','+12:00')
GO

Select switchoffset('9999-12-31 23:12:00.123 +00:00','+12:00')
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00','+12:00')
GO

Select switchoffset('0001-01-01 00:00:00.00 +00:00','+12:00')
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00','+12:00')
GO

Select switchoffset(DATETIMEOFFSETFROMPARTS(1, 1, 1, 4, 30, 00, 500, 12, 30, 3), 743)
GO

Select switchoffset('1-1-1 00:00:00.000 +12:00' , 743)
GO

Select switchoffset('0001-1-1 00:00:00.000 +12:00' , 743)
GO

Select switchoffset('0001-01-01 00:00:00.000 +12:00' , 743)
GO

Select switchoffset('0002-01-01 00:00:00.000 +12:00' , 743)
GO

Select switchoffset('10000-01-01 00:00:00.000 +12:00' , 743)
GO

Select switchoffset('10000-01-01 00:00:00.123 +2:00', 743)
GO

Select switchoffset('9999-12-31 23:12:00.123 +00:00',743)
GO

Select switchoffset('9999-12-31 23:12:00.123 +00:00',743)
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00',743)
GO

Select switchoffset('0001-01-01 00:00:00.00 +00:00',743)
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00',743)
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00',-743)
GO

Select switchoffset('0001-01-01 00:00:01.00 +00:00','-12:00')
GO
