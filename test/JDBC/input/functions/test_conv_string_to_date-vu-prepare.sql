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