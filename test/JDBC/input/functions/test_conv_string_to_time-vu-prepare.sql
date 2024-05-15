CREATE VIEW test_conv_string_to_time_v1 as (SELECT CONVERT(time, '13:01:59'));
GO
CREATE PROCEDURE test_conv_string_to_time_p1 as (SELECT CONVERT(time, '13:01:59'));
GO
CREATE FUNCTION test_conv_string_to_time_f1()
RETURNS time AS
BEGIN
RETURN (SELECT CONVERT(time, '13:01:59'));
END
GO

CREATE VIEW test_conv_string_to_time_v2 as (SELECT CONVERT(time, '00:00:00'));
GO
CREATE PROCEDURE test_conv_string_to_time_p2 as (SELECT CONVERT(time, '00:00:00'));
GO
CREATE FUNCTION test_conv_string_to_time_f2()
RETURNS time AS
BEGIN
RETURN (SELECT CONVERT(time, '00:00:00'));
END
GO

CREATE VIEW test_conv_string_to_time_v3 as (SELECT CONVERT(time, '1:1:1'));
GO
CREATE PROCEDURE test_conv_string_to_time_p3 as (SELECT CONVERT(time, '1:1:1'));
GO
CREATE FUNCTION test_conv_string_to_time_f3()
RETURNS time AS
BEGIN
RETURN (SELECT CONVERT(time, '1:1:1'));
END
GO