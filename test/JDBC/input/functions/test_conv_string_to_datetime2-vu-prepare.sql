CREATE VIEW test_conv_string_to_datetime2_v1 as (SELECT CONVERT(datetime2(1), CAST('2017-08-25 13:01:59' AS datetime)));
GO
CREATE PROCEDURE test_conv_string_to_datetime2_p1 as (SELECT CONVERT(datetime2(1), CAST('2017-08-25 13:01:59' AS datetime)));
GO
CREATE FUNCTION test_conv_string_to_datetime2_f1()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT CONVERT(datetime2(1), CAST('2017-08-25 13:01:59' AS datetime)));
END
GO

CREATE VIEW test_conv_string_to_datetime2_v2 as (SELECT CONVERT(datetime2, '2017-08-25 13:01:59.1234567'));
GO
CREATE PROCEDURE test_conv_string_to_datetime2_p2 as (SELECT CONVERT(datetime2, '2017-08-25 13:01:59.1234567'));
GO
CREATE FUNCTION test_conv_string_to_datetime2_f2()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT CONVERT(datetime2, '2017-08-25 13:01:59.1234567'));
END
GO

CREATE PROCEDURE test_conv_string_to_datetime2_p2_2 as (SELECT CONVERT(datetime2(10), '2017-08-25 13:01:59.1234567'));
GO
CREATE FUNCTION test_conv_string_to_datetime2_f2_2()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT CONVERT(datetime2(10), '2017-08-25 13:01:59.1234567'));
END
GO


CREATE VIEW test_conv_string_to_datetime2_v3 as (SELECT CONVERT(datetime2(5), '2017-08-25 13:01:59.1234567'));
GO
CREATE PROCEDURE test_conv_string_to_datetime2_p3 as (SELECT CONVERT(datetime2(5), '2017-08-25 13:01:59.1234567'));
GO
CREATE FUNCTION test_conv_string_to_datetime2_f3()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT CONVERT(datetime2(5), '2017-08-25 13:01:59.1234567'));
END
GO
