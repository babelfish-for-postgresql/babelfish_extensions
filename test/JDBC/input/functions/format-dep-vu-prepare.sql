CREATE TABLE format_dep_date_testing(d DATE);
INSERT INTO format_dep_date_testing VALUES('1753-1-1');
INSERT INTO format_dep_date_testing VALUES('9999-12-31');
INSERT INTO format_dep_date_testing VALUES('1992-05-23');
GO

create table format_dep_datetime_testing ( dt DATETIME );
INSERT INTO format_dep_datetime_testing VALUES('1753-1-1 00:00:00.000');
INSERT INTO format_dep_datetime_testing VALUES('9999-12-31 23:59:59.456');
INSERT INTO format_dep_datetime_testing VALUES('1992-05-23 23:40:30.000');
INSERT INTO format_dep_datetime_testing VALUES('1999-12-31 23:59:59.123');
INSERT INTO format_dep_datetime_testing VALUES('23:40:29.456');
INSERT INTO format_dep_datetime_testing VALUES('23:40:30.000');
INSERT INTO format_dep_datetime_testing VALUES('2020-03-14');
GO

create table format_dep_datetime2_testing ( dt2 DATETIME2 );
INSERT INTO format_dep_datetime2_testing VALUES('0001-1-1 00:00:00');
INSERT INTO format_dep_datetime2_testing VALUES('9999-12-31 23:59:59');
INSERT INTO format_dep_datetime2_testing VALUES('1992-05-23 23:40:29');
INSERT INTO format_dep_datetime2_testing VALUES('1992-05-23 23:40:30');
INSERT INTO format_dep_datetime2_testing VALUES('1999-12-31 23:59:59');
INSERT INTO format_dep_datetime2_testing VALUES('1999-12-31 23:59:59');
INSERT INTO format_dep_datetime2_testing VALUES('23:40:29.236');
INSERT INTO format_dep_datetime2_testing VALUES('23:40:30.000');
INSERT INTO format_dep_datetime2_testing VALUES('2020-03-14');
GO

create table format_dep_time_testing ( ti TIME );
INSERT INTO format_dep_time_testing VALUES('00:00:00.12345');
INSERT INTO format_dep_time_testing VALUES('3:53:59');
INSERT INTO format_dep_time_testing VALUES('15:5:45.0000');
INSERT INTO format_dep_time_testing VALUES('23:59:59.12345');
GO

CREATE TABLE format_dep_tinyint_testing(ti TINYINT);
INSERT INTO format_dep_tinyint_testing VALUES(0);
INSERT INTO format_dep_tinyint_testing VALUES(31);
INSERT INTO format_dep_tinyint_testing VALUES(255);
GO

CREATE TABLE format_dep_smallint_testing(si SMALLINT);
INSERT INTO format_dep_smallint_testing VALUES(-2456);
INSERT INTO format_dep_smallint_testing VALUES(-62);
INSERT INTO format_dep_smallint_testing VALUES(282);
INSERT INTO format_dep_smallint_testing VALUES(2456);
GO

CREATE TABLE format_dep_int_testing(it INT);
INSERT INTO format_dep_int_testing VALUES(-2147483);
INSERT INTO format_dep_int_testing VALUES(-586);
INSERT INTO format_dep_int_testing VALUES(7869);
INSERT INTO format_dep_int_testing VALUES(2147483);
GO

CREATE TABLE format_dep_bigint_testing(bi BIGINT);
INSERT INTO format_dep_bigint_testing VALUES(-9223372036854);
INSERT INTO format_dep_bigint_testing VALUES(-352);
INSERT INTO format_dep_bigint_testing VALUES(2822);
INSERT INTO format_dep_bigint_testing VALUES(9223372036854);
GO

CREATE TABLE format_dep_real_testing(rt REAL);
INSERT INTO format_dep_real_testing VALUES(-3.40E+38);
INSERT INTO format_dep_real_testing VALUES(-3.312346E+38);
INSERT INTO format_dep_real_testing VALUES(-3.312341234E+38);
INSERT INTO format_dep_real_testing VALUES(-22.1234);
INSERT INTO format_dep_real_testing VALUES(22.1234);
INSERT INTO format_dep_real_testing VALUES(22.12341234);
INSERT INTO format_dep_real_testing VALUES(3.312346E+38);
INSERT INTO format_dep_real_testing VALUES(3.4E+38);
GO

CREATE TABLE format_dep_float_testing(ft FLOAT);
GO
INSERT INTO format_dep_float_testing VALUES(-1.79E+308);
GO
INSERT INTO format_dep_float_testing VALUES(-3.4E+38);
GO
INSERT INTO format_dep_float_testing VALUES(35.3675);
GO
INSERT INTO format_dep_float_testing VALUES(3.4E+38);
GO
INSERT INTO format_dep_float_testing VALUES(1.79E+308);
GO

CREATE TABLE format_dep_smallmoney_testing(sm MONEY);
GO
INSERT INTO format_dep_smallmoney_testing VALUES(-214478.3648);
GO
INSERT INTO format_dep_smallmoney_testing VALUES(435627.1435);
GO
INSERT INTO format_dep_smallmoney_testing VALUES(-435627.1435);
GO
INSERT INTO format_dep_smallmoney_testing VALUES(214478.3647);
GO

CREATE TABLE format_dep_money_testing(mt MONEY);
GO
INSERT INTO format_dep_money_testing VALUES(-92233720.5808);
GO
INSERT INTO format_dep_money_testing VALUES(-214478.3648);
GO
INSERT INTO format_dep_money_testing VALUES(435627.1435);
GO
INSERT INTO format_dep_money_testing VALUES(214478.3647);
GO
INSERT INTO format_dep_money_testing VALUES(92233720.5807);
GO

CREATE TABLE format_dep_real_testing2(rt REAL);
GO
INSERT INTO format_dep_real_testing2 VALUES(-3.4E+1);
GO
INSERT INTO format_dep_real_testing2 VALUES(-34);
GO
INSERT INTO format_dep_real_testing2 VALUES(-3.312346789E+38);
GO
INSERT INTO format_dep_real_testing2 VALUES(22.1234565656565E+3);
GO
INSERT INTO format_dep_real_testing2 VALUES(22.1234123412341234);
GO
INSERT INTO format_dep_real_testing2 VALUES(3.312346E+38);
GO
INSERT INTO format_dep_real_testing2 VALUES(3.40E+38);
GO

CREATE TABLE format_dep_float_testing2(ft FLOAT);
GO
INSERT INTO format_dep_float_testing2 VALUES(-3.312346789123456789E+38);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.3123489656565789);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.3123489656565);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.31234896565651);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.312348965656512);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.3123489656565123);
GO
INSERT INTO format_dep_float_testing2 VALUES(33123489656565123.34);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.312348965656512345);
GO
INSERT INTO format_dep_float_testing2 VALUES(3.3123489656565123456);
GO
INSERT INTO format_dep_float_testing2 VALUES(351234567891025621.1);
GO

CREATE TABLE format_dep_decimal_testing(dt DECIMAL(15, 5));
GO
INSERT INTO format_dep_decimal_testing VALUES(-8999999999.09909);
GO
INSERT INTO format_dep_decimal_testing VALUES(-352);
GO
INSERT INTO format_dep_decimal_testing VALUES(5478);
GO
INSERT INTO format_dep_decimal_testing VALUES(8999999999.99999);
GO

create table format_dep_smalldatetime_testing ( sdt smalldatetime );
GO
INSERT INTO format_dep_smalldatetime_testing VALUES('1990-05-23 23:40:29');
GO
INSERT INTO format_dep_smalldatetime_testing VALUES('2022-12-31 23:59:59');
GO
INSERT INTO format_dep_smalldatetime_testing VALUES('2079-06-06 22:59:59');
GO

CREATE TABLE format_dep_numeric_testing(nt NUMERIC(15, 4));
GO
INSERT INTO format_dep_numeric_testing VALUES(-8999999999.0990);
GO
INSERT INTO format_dep_numeric_testing VALUES(-352);
GO
INSERT INTO format_dep_numeric_testing VALUES(5478);
GO
INSERT INTO format_dep_numeric_testing VALUES(8999999999.9999);
GO

-- date
CREATE VIEW format_dep_view_date AS
select FORMAT(d, 'F','en-us') from format_dep_date_testing;
GO

CREATE PROC format_dep_proc_date AS
select FORMAT(d, 'D','en-us') from format_dep_date_testing;
GO

CREATE FUNCTION format_dep_func_date()
RETURNS date
AS
BEGIN
RETURN (select TOP 1 FORMAT(d, 'G','en-us') from format_dep_date_testing);
END
GO

-- datetime
CREATE VIEW format_dep_view_datetime AS
select FORMAT(dt, 'd','en-us') from format_dep_datetime_testing;
GO

CREATE PROC format_dep_proc_datetime AS
select FORMAT(dt, 'D','en-us') from format_dep_datetime_testing;
GO

CREATE FUNCTION format_dep_func_datetime()
RETURNS datetime
AS
BEGIN
RETURN (select TOP 1 FORMAT(dt, 'f','en-us') from format_dep_datetime_testing);
END
GO

-- datetime2
CREATE VIEW format_dep_view_datetime2 AS
select FORMAT(dt2, 'F','en-us') from format_dep_datetime2_testing;
GO

CREATE PROC format_dep_proc_datetime2 AS
select FORMAT(dt2, 'D','en-us') from format_dep_datetime2_testing;
GO

CREATE FUNCTION format_dep_func_datetime2()
RETURNS datetime2
AS
BEGIN
RETURN (select TOP 1 FORMAT(dt2, 'G','en-us') from format_dep_datetime2_testing);
END
GO

-- smalldatetime
CREATE VIEW format_dep_view_smalldatetime AS
select FORMAT(sdt, 'F','en-us') from format_dep_smalldatetime_testing;
GO

CREATE PROC format_dep_proc_smalldatetime AS
select FORMAT(sdt, 'f','en-us') from format_dep_smalldatetime_testing;
GO

CREATE FUNCTION format_dep_func_smalldatetime()
RETURNS smalldatetime
AS
BEGIN
RETURN (select TOP 1 FORMAT(sdt, 'D','en-us') from format_dep_smalldatetime_testing);
END
GO

-- time
CREATE VIEW format_dep_view_time AS
select FORMAT(ti, 'f','en-us') from format_dep_time_testing;
GO

CREATE VIEW format_datetime_dep_view_time AS
select format_datetime(ti, 'd','en-us', 'time') from format_dep_time_testing;
GO

CREATE VIEW format_datetime_dep_view_time2 AS
select format_datetime(ti, 'c','en-us', 'time') from format_dep_time_testing;
GO

CREATE PROC format_dep_proc_time AS
select FORMAT(ti, 'D','en-us') from format_dep_time_testing;
GO

CREATE FUNCTION format_dep_func_time()
RETURNS time
AS
BEGIN
RETURN (select TOP 1 FORMAT(ti, 'c','en-us') from format_dep_time_testing);
END
GO

-- tinyint
CREATE VIEW format_dep_view_tinyint AS
SELECT FORMAT(ti, 'C0', 'en-us') from format_dep_tinyint_testing;
GO

CREATE PROC format_dep_proc_tinyint AS
SELECT FORMAT(ti, 'C', 'en-us') from format_dep_tinyint_testing;
GO

-- smallint
CREATE VIEW format_dep_view_smallint AS
SELECT FORMAT(si, 'C6', 'en-us') from format_dep_smallint_testing;
GO

CREATE PROC format_dep_proc_smallint AS
SELECT FORMAT(si, 'C', 'aa-DJ') from format_dep_smallint_testing;
GO

-- int
CREATE VIEW format_dep_view_int AS
SELECT FORMAT(it, 'C6', 'en-us') from format_dep_int_testing;
GO

CREATE VIEW format_numeric_dep_view_int AS
SELECT format_numeric(it, 'C6', 'en-us', 'integer') from format_dep_int_testing;
GO

CREATE PROC format_dep_proc_int AS
SELECT FORMAT(it, 'C', 'en-us') from format_dep_int_testing;
GO

-- bigint
CREATE VIEW format_dep_view_bigint AS
SELECT FORMAT(bi, 'C6', 'en-us') from format_dep_bigint_testing;
GO

CREATE PROC format_dep_proc_bigint AS
SELECT FORMAT(bi, 'C', 'en-us') from format_dep_bigint_testing;
GO

-- decimal
CREATE VIEW format_dep_view_decimal AS
SELECT FORMAT(dt, 'C6', 'en-us') from format_dep_decimal_testing;
GO

CREATE PROC format_dep_proc_decimal AS
SELECT FORMAT(dt, 'C', 'en-us') from format_dep_decimal_testing;
GO

-- numeric
CREATE VIEW format_dep_view_numeric AS
SELECT FORMAT(nt, 'C6', 'en-us') from format_dep_numeric_testing;
GO

CREATE PROC format_dep_proc_numeric AS
SELECT FORMAT(nt, 'C', 'en-us') from format_dep_numeric_testing;
GO

-- real
CREATE VIEW format_dep_view_real AS
SELECT FORMAT(rt, 'C9', 'en-us') from format_dep_real_testing;
GO

CREATE PROC format_dep_proc_real AS
SELECT FORMAT(rt, 'C', 'en-us') from format_dep_real_testing;
GO

-- float
CREATE VIEW format_dep_view_float AS
SELECT FORMAT(ft, 'C9', 'en-us') from format_dep_float_testing;
GO

CREATE PROC format_dep_proc_float AS
SELECT FORMAT(ft, 'C', 'en-us') from format_dep_float_testing;
GO

-- smallmoney
CREATE VIEW format_dep_view_smallmoney AS
SELECT FORMAT(sm, 'C9', 'en-us') from format_dep_smallmoney_testing;
GO

CREATE PROC format_dep_proc_smallmoney AS
SELECT FORMAT(sm, 'C', 'en-us') from format_dep_smallmoney_testing;
GO

-- money
CREATE VIEW format_dep_view_money AS
SELECT FORMAT(mt, 'C9', 'en-us') from format_dep_money_testing;
GO

CREATE PROC format_dep_proc_money AS
SELECT FORMAT(mt, 'C', 'en-us') from format_dep_money_testing;
GO

-- real
CREATE VIEW format_dep_view_real2 AS
SELECT FORMAT(rt, 'C9', 'en-us') from format_dep_real_testing2;
GO

CREATE PROC format_dep_proc_real2 AS
SELECT FORMAT(rt, 'C', 'en-us') from format_dep_real_testing2;
GO

-- float
CREATE VIEW format_dep_view_float2 AS
SELECT FORMAT(ft, 'C9', 'en-us') from format_dep_float_testing2;
GO

CREATE PROC format_dep_proc_float2 AS
SELECT FORMAT(ft, 'C', 'en-us') from format_dep_float_testing2;
GO
