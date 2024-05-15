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
