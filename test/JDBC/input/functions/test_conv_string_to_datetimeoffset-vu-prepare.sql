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