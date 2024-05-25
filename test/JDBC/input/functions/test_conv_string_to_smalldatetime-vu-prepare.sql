CREATE VIEW test_conv_string_to_smalldatetime_v1 as (SELECT CONVERT(smalldatetime, '2017-08-25 13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p1 as (SELECT CONVERT(smalldatetime, '2017-08-25 13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f1()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, '2017-08-25 13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v2 as (SELECT CONVERT(smalldatetime, '13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p2 as (SELECT CONVERT(smalldatetime, '13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f2()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, '13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v3 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS TEXT)));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p3 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS TEXT)));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f3()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS TEXT)));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v4 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p4 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f4()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS CHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v5 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p5 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f5()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NCHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v6 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p6 as (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f6()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, CAST('2017-08-25 13:01:59' AS NVARCHAR(20))));
END
GO

CREATE VIEW test_conv_string_to_smalldatetime_v7 as (SELECT CONVERT(smalldatetime, CAST('2017' AS INTEGER)));
GO
CREATE PROCEDURE test_conv_string_to_smalldatetime_p7 as (SELECT CONVERT(smalldatetime, CAST('2017' AS INTEGER)));
GO
CREATE FUNCTION test_conv_string_to_smalldatetime_f7()
RETURNS smalldatetime AS
BEGIN
RETURN (SELECT CONVERT(smalldatetime, CAST('2017' AS INTEGER)));
END
GO
