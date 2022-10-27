CREATE VIEW BABEL_3614_vu_prepare_v1 as (SELECT TRY_CONVERT(DATETIME2(5), '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p1 as (SELECT TRY_CONVERT(DATETIME2(5), '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f1()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(5), '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v2 as (SELECT TRY_CONVERT(DATETIME2(3), '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p2 as (SELECT TRY_CONVERT(DATETIME2(3), '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f2()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(3), '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v3 as (SELECT TRY_CONVERT(DATETIME2(1), '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p3 as (SELECT TRY_CONVERT(DATETIME2(1), '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f3()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(1), '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v4 as (SELECT TRY_CONVERT(DATETIME2(7), '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p4 as (SELECT TRY_CONVERT(DATETIME2(7), '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f4()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(7), '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v5 as (SELECT TRY_CONVERT(DATETIME2(80), '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p5 as (SELECT TRY_CONVERT(DATETIME2(80), '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f5()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(80), '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v6 as (SELECT TRY_CONVERT(DATETIME2, '2017-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p6 as (SELECT TRY_CONVERT(DATETIME2, '2017-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f6()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, '2017-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v7 as (SELECT TRY_CONVERT(DATETIME2, CAST(5.0 AS decimal)));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p7 as (SELECT TRY_CONVERT(DATETIME2, CAST(5.0 AS decimal)));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f7()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, CAST(5.0 AS decimal)));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v8 as (SELECT TRY_CONVERT(DATETIME2, CAST('2017-08-25' AS DATE)));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p8 as (SELECT TRY_CONVERT(DATETIME2, CAST('2017-08-25' AS DATE)));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f8()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, CAST('2017-08-25' AS DATE)));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v9 as (SELECT sys.datetime2scale(CAST('2017-08-25 13:01:10.1234567' AS DATETIME2(5)), 2));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p9 as (SELECT sys.datetime2scale(CAST('2017-08-25 13:01:10.1234567' AS DATETIME2(5)), 2));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f9()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT sys.datetime2scale(CAST('2017-08-25 13:01:10.1234567' AS DATETIME2(5)), 2));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v10 as (SELECT sys.babelfish_try_conv_to_datetime2(CAST(5.0 AS decimal)));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p10 as (SELECT sys.babelfish_try_conv_to_datetime2(CAST(5.0 AS decimal)));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f10()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT sys.babelfish_try_conv_to_datetime2(CAST(5.0 AS decimal)));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v11 as (SELECT TRY_CONVERT(DATETIME2, '0001-01-01'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p11 as (SELECT TRY_CONVERT(DATETIME2, '0001-01-01'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f11()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, '0001-01-01'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v12 as (SELECT TRY_CONVERT(DATETIME2, '1600-08-25 13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p12 as (SELECT TRY_CONVERT(DATETIME2, '1600-08-25 13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f12()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, '1600-08-25 13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v13 as (SELECT TRY_CONVERT(DATETIME2, '13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p13 as (SELECT TRY_CONVERT(DATETIME2, '13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f13()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2, '13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v14 as (SELECT TRY_CONVERT(DATETIME2(2), '13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p14 as (SELECT TRY_CONVERT(DATETIME2(2), '13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f14()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(2), '13:01:10.1234567'));
END
GO

CREATE VIEW BABEL_3614_vu_prepare_v15 as (SELECT TRY_CONVERT(DATETIME2(0), '13:01:10.1234567'));
GO
CREATE PROCEDURE BABEL_3614_vu_prepare_p15 as (SELECT TRY_CONVERT(DATETIME2(0), '13:01:10.1234567'));
GO
CREATE FUNCTION BABEL_3614_vu_prepare_f15()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT TRY_CONVERT(DATETIME2(0), '13:01:10.1234567'));
END
GO