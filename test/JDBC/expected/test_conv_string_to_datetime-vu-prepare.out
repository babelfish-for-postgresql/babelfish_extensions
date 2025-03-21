CREATE VIEW test_conv_string_to_datetime_v1 as (SELECT CONVERT(datetime, '2017-08-25 13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p1 as (SELECT CONVERT(datetime, '2017-08-25 13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_datetime_f1()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, '2017-08-25 13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_datetime_v2 as (SELECT CONVERT(datetime, '13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p2 as (SELECT CONVERT(datetime, '13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_datetime_f2()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, '13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_datetime_v3 as (SELECT CONVERT(datetime, '1753-01-01 0:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p3 as (SELECT CONVERT(datetime, '1753-01-01 0:01:59'));
GO
CREATE FUNCTION test_conv_string_to_datetime_f3()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, '1753-01-01 0:01:59'));
END
GO

CREATE VIEW test_conv_string_to_datetime_v4 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS TEXT)));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p4 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS TEXT)));
GO
CREATE FUNCTION test_conv_string_to_datetime_f4()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS TEXT)));
END
GO

CREATE VIEW test_conv_string_to_datetime_v5 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p5 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_datetime_f5()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_datetime_v6 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p6 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_datetime_f6()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_datetime_v7 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p7 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_datetime_f7()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_datetime_v8 as (SELECT CONVERT(datetime, CAST('2017' AS INTEGER)));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p8 as (SELECT CONVERT(datetime, CAST('2017' AS INTEGER)));
GO
CREATE FUNCTION test_conv_string_to_datetime_f8()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017' AS INTEGER)));
END
GO

CREATE VIEW test_conv_string_to_datetime_v9 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS VARCHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_datetime_p9 as (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS VARCHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_datetime_f9()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, CAST('2017-08-25 13:01:59' AS VARCHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_datetime_v10 as (SELECT CONVERT(datetime, '20'));
GO

CREATE VIEW test_conv_string_to_datetime_v11 as (SELECT CONVERT(datetime, CAST('20' AS INTEGER)));
GO
