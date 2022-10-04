
-- Custom date formats
DECLARE @curr_date date;
SET @curr_date = '12/01/1999';
SELECT FORMAT(@curr_date, 'dd/yy/MM', 'dz-BT');
GO

DECLARE @curr_date2 date;
SET @curr_date2 = '11/5/9999';
SELECT FORMAT(@curr_date2, 'ddd, MMMM, yyyy', 'en-US');
GO

DECLARE @curr_date3 date;
SET @curr_date3 = '5/12/9999';
SELECT FORMAT(@curr_date3, 'dddd, MMMMM, yyyy', 'en-US');
GO

DECLARE @curr_date4 date;
SET @curr_date4 = '12/08/2022';
SELECT FORMAT(@curr_date4, 'dd, MM, y yy yyy yyyy yyyyy, ffffff  gg h hh H HH m mm s ss t tt',  'en-US');
GO

DECLARE @curr_date5 date;
SET @curr_date5 = '7/5/2021';
SELECT FORMAT(@curr_date5, 'abc "dd abc" \dddd/MMM/yyyyy, hh:mm:ss, dd,MM,yy d/MMMMMM/y f   ff  fff  ffff  fffff  ffffff  fffffff  h:m:s','en-US');
GO

-- Custom datetime formats
DECLARE @curr_datetime datetime;
SET @curr_datetime = '1753-01-01 00:00:00.123';
SELECT FORMAT(@curr_datetime, 'dd/yy/MM', 'dz-BT');
GO

DECLARE @curr_datetime2 datetime;
SET @curr_datetime2 = '9999-12-31 23:59:55.456';
SELECT FORMAT(@curr_datetime2, 'ddd, MMMM, yyyy', 'en-US');
GO

DECLARE @curr_datetime3 datetime;
SET @curr_datetime3 = '5/12/2022';
SELECT FORMAT(@curr_datetime3, 'dddd, MMMMM, yyyy', 'en-US');
GO

DECLARE @curr_datetime4 datetime;
SET @curr_datetime4 = '1753-01-01 00:00:00.456';
SELECT FORMAT(@curr_datetime4, 'dd, MM, y yy yyy yyyy yyyyy, ffffff  gg h hh H HH m mm s ss t tt',  'en-US');
GO

DECLARE @curr_datetime5 datetime;
SET @curr_datetime5 = '9999-12-31 23:59:55.987';
SELECT FORMAT(@curr_datetime5, 'abc "dd abc" \dddd/MMM/yyyyy, hh:mm:ss, dd,MM,yy d/MMMMMM/y f   ff  fff  ffff  fffff  ffffff  fffffff  h:m:s','en-US');
GO

-- Custom datetime2 formats
DECLARE @curr_datetime_2 datetime2;
SET @curr_datetime_2 = '0001-01-01 00:00:00.123';
SELECT FORMAT(@curr_datetime_2, 'dd/yy/MM', 'dz-BT');
GO

DECLARE @curr_datetime2_2 datetime2;
SET @curr_datetime2_2 = '9999-12-31 23:59:55.1234567';
SELECT FORMAT(@curr_datetime2_2, 'ddd, MMMM, yyyy', 'en-US');
GO

DECLARE @curr_datetime3_2 datetime2;
SET @curr_datetime3_2 = '5/12/2022';
SELECT FORMAT(@curr_datetime3_2, 'dddd, MMMMM, yyyy', 'en-US');
GO

DECLARE @curr_datetime4_2 datetime2;
SET @curr_datetime4_2 = '0001-01-01 00:00:00.123';
SELECT FORMAT(@curr_datetime4_2, 'dd, MM, y yy yyy yyyy yyyyy, ffffff  gg h hh H HH m mm s ss t tt y',  'en-US');
GO

DECLARE @curr_datetime5_2 datetime2;
SET @curr_datetime5_2 = '9999-12-31 23:59:55.1234567';
SELECT FORMAT(@curr_datetime5_2, 'abc "dd abc" \dddd/MMM/yyyyy, hh:mm:ss, dd,MM,yy d/MMMMMM/y f   ff  fff  ffff  fffff  ffffff  fffffff  h:m:s','en-US');
GO

-- Custom smalldatetime formats
DECLARE @curr_sdt smalldatetime;
SET @curr_sdt = '1753-01-01 1:11:31';
SELECT FORMAT(@curr_sdt, 'dd/yy/MM', 'dz-BT');
GO

DECLARE @curr_sdt2 smalldatetime;
SET @curr_sdt2 = '2079-06-04 23:59:55';
SELECT FORMAT(@curr_sdt2, 'ddd, MMMM, yyyy', 'en-US');
GO

DECLARE @curr_sdt3 smalldatetime;
SET @curr_sdt3 = '5/12/2022';
SELECT FORMAT(@curr_sdt3, 'dddd, MMMMM, yyyy', 'en-US');
GO

DECLARE @curr_sdt4 smalldatetime;
SET @curr_sdt4 = '1753-01-01 20:3:54';
SELECT FORMAT(@curr_sdt4, 'dd, MM, y yy yyy yyyy yyyyy, ffffff  gg h hh H HH m mm s ss t tt',  'en-US');
GO

DECLARE @curr_sdt5 smalldatetime;
SET @curr_sdt5 = '2079-06-04 23:59:55';
SELECT FORMAT(@curr_sdt5, 'abc "dd abc" \dddd/MMM/yyyyy, hh:mm:ss, dd,MM,yy d/MMMMMM/y f   ff  fff  ffff  fffff  ffffff  fffffff  h:m:s','en-US');
GO


-- Time custom formats

SELECT FORMAT(cast('07:35' as time), N'hh.mm');  
GO
SELECT FORMAT(cast('07:35' as time), N'hh:mm');  
GO

SELECT FORMAT(cast('07:35' as time), N'hh\.mm');  
GO
SELECT FORMAT(cast('07:35' as time), N'hh\:mm');  
GO

select FORMAT(CAST('2018-01-01 01:00' AS datetime2), N'hh:mm tt');
GO
select FORMAT(CAST('2018-01-01 01:00' AS datetime2), N'hh:mm t')  ;
GO

select FORMAT(CAST('2018-01-01 14:00' AS datetime2), N'hh:mm tt') ;
GO
select FORMAT(CAST('2018-01-01 14:00' AS datetime2), N'hh:mm t') ;
GO

select FORMAT(CAST('2018-01-01 14:00' AS datetime2), N'HH:mm') ;
GO
