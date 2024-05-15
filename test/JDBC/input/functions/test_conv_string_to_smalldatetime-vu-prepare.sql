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