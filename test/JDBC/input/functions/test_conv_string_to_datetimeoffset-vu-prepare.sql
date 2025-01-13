CREATE VIEW test_conv_string_to_datetimeoffset_v1 as (SELECT CONVERT(datetimeoffset, '2017-08-25 13:01:59 +12:15'));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p1 as (SELECT CONVERT(datetimeoffset, '2017-08-25 13:01:59 +12:15'));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f1()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, '2017-08-25 13:01:59 +12:15'));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v2 as (SELECT CONVERT(datetimeoffset, '13:01:59 +12:15'));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p2 as (SELECT CONVERT(datetimeoffset, '13:01:59 +12:15'));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f2()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, '13:01:59 +12:15'));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v3 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS TEXT)));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p3 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS TEXT)));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f3()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS TEXT)));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v4 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS CHAR(30))));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p4 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS CHAR(30))));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f4()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS CHAR(30))));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v5 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NCHAR(30))));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p5 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NCHAR(30))));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f5()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NCHAR(30))));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v6 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NVARCHAR(30))));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p6 as (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NVARCHAR(30))));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f6()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, CAST('2017-08-25 13:01:59 +12:15' AS NVARCHAR(30))));
END
GO

CREATE VIEW test_conv_string_to_datetimeoffset_v7 as (SELECT CONVERT(datetimeoffset, CAST('2017' AS INTEGER)));
GO
CREATE PROCEDURE test_conv_string_to_datetimeoffset_p7 as (SELECT CONVERT(datetimeoffset, CAST('2017' AS INTEGER)));
GO
CREATE FUNCTION test_conv_string_to_datetimeoffset_f7()
RETURNS datetimeoffset AS
BEGIN
RETURN (SELECT CONVERT(datetimeoffset, CAST('2017' AS INTEGER)));
END
GO
