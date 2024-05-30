CREATE VIEW test_conv_string_to_date_v1 as (SELECT CONVERT(date, '2017-08-25'));
GO
CREATE PROCEDURE test_conv_string_to_date_p1 as (SELECT CONVERT(date, '2017-08-25'));
GO
CREATE FUNCTION test_conv_string_to_date_f1()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, '2017-08-25'));
END
GO

CREATE VIEW test_conv_string_to_date_v2 as (SELECT CONVERT(date, '9999-08-25'));
GO
CREATE PROCEDURE test_conv_string_to_date_p2 as (SELECT CONVERT(date, '9999-08-25'));
GO
CREATE FUNCTION test_conv_string_to_date_f2()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, '9999-08-25'));
END
GO

CREATE VIEW test_conv_string_to_date_v3 as (SELECT CONVERT(date, '13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_date_p3 as (SELECT CONVERT(date, '13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_date_f3()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, '13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_date_v4 as (SELECT CONVERT(date, cast('2017-08-25' as TEXT)));
GO
CREATE PROCEDURE test_conv_string_to_date_p4 as (SELECT CONVERT(date, cast('2017-08-25' as TEXT)));
GO
CREATE FUNCTION test_conv_string_to_date_f4()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2017-08-25' as TEXT)));
END
GO

CREATE VIEW test_conv_string_to_date_v5 as (SELECT CONVERT(date, cast('2017-08-25' as CHAR(10))));
GO
CREATE PROCEDURE test_conv_string_to_date_p5 as (SELECT CONVERT(date, cast('2017-08-25' as CHAR(10))));
GO
CREATE FUNCTION test_conv_string_to_date_f5()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2017-08-25' as CHAR(10))));
END
GO

CREATE VIEW test_conv_string_to_date_v6 as (SELECT CONVERT(date, cast('2017-08-25' as NCHAR(10))));
GO
CREATE PROCEDURE test_conv_string_to_date_p6 as (SELECT CONVERT(date, cast('2017-08-25' as NCHAR(10))));
GO
CREATE FUNCTION test_conv_string_to_date_f6()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2017-08-25' as NCHAR(10))));
END
GO

CREATE VIEW test_conv_string_to_date_v7 as (SELECT CONVERT(date, cast('2017-08-25' as NVARCHAR(10))));
GO
CREATE PROCEDURE test_conv_string_to_date_p7 as (SELECT CONVERT(date, cast('2017-08-25' as NVARCHAR(10))));
GO
CREATE FUNCTION test_conv_string_to_date_f7()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2017-08-25' as NVARCHAR(10))));
END
GO

CREATE VIEW test_conv_string_to_date_v8 as (SELECT CONVERT(date, cast('2002' as INTEGER)));
GO
CREATE PROCEDURE test_conv_string_to_date_p8 as (SELECT CONVERT(date, cast('2002' as INTEGER)));
GO
CREATE FUNCTION test_conv_string_to_date_f8()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2002' as INTEGER)));
END
GO

CREATE VIEW test_conv_string_to_date_v9 as (SELECT CONVERT(date, cast('2017-08-25' as VARCHAR(10))));
GO
CREATE PROCEDURE test_conv_string_to_date_p9 as (SELECT CONVERT(date, cast('2017-08-25' as VARCHAR(10))));
GO
CREATE FUNCTION test_conv_string_to_date_f9()
RETURNS date AS
BEGIN
RETURN (SELECT CONVERT(date, cast('2017-08-25' as VARCHAR(10))));
END
GO

CREATE VIEW test_conv_string_to_date_v10 as (SELECT CONVERT(date, '02-03-2003 11:11:11 +11:11', 130));
GO

CREATE VIEW test_conv_string_to_date_v12 as (SELECT CONVERT(date, CAST('20' as INTEGER)));
GO