CREATE VIEW BABEL_3646_vu_prepare_v1 as (SELECT TRY_CAST(CAST('1990-01-01' as xml) as date));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p1 as (SELECT TRY_CAST(CAST('1990-01-01' as xml) as date));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f1()
RETURNS DATE AS
BEGIN
RETURN (SELECT TRY_CAST(CAST('1990-01-01' as xml) as date));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v2 as (SELECT TRY_CAST(TRY_CAST (TRY_CAST('1990-01-01' as xml) as text) as date));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p2 as (SELECT TRY_CAST(TRY_CAST (TRY_CAST('1990-01-01' as xml) as text) as date));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f2()
RETURNS DATE AS
BEGIN
RETURN (SELECT TRY_CAST(TRY_CAST (TRY_CAST('1990-01-01' as xml) as text) as date));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v3 as (select TRY_CAST(CAST (CAST('1990-01-01' as xml) as text) as date));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p3 as (select TRY_CAST(CAST (CAST('1990-01-01' as xml) as text) as date));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f3()
RETURNS DATE AS
BEGIN
RETURN (select TRY_CAST(CAST (CAST('1990-01-01' as xml) as text) as date));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v4 as (select TRY_CAST(TRY_CAST(1 as binary) as float));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p4 as (select TRY_CAST(TRY_CAST(1 as binary) as float));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f4()
RETURNS float AS
BEGIN
RETURN (select TRY_CAST(TRY_CAST(1 as binary) as float));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v5 as (select TRY_CAST(CAST(1 as binary) as real));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p5 as (select TRY_CAST(CAST(1 as binary) as real));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f5()
RETURNS real AS
BEGIN
RETURN (select TRY_CAST(CAST(1 as binary) as real));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v6 as (select TRY_CAST(CAST(1 as numeric) as uniqueidentifier));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p6 as (select TRY_CAST(CAST(1 as numeric) as uniqueidentifier));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f6()
RETURNS uniqueidentifier AS
BEGIN
RETURN (select TRY_CAST(CAST(1 as numeric) as uniqueidentifier));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v7 as (select TRY_CAST(CAST('100' as xml) as image));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p7 as (select TRY_CAST(CAST('100' as xml) as image));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f7()
RETURNS image AS
BEGIN
RETURN (select TRY_CAST(CAST('100' as xml) as image));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v8 as (select TRY_CAST(CAST('100' as xml) as bit));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p8 as (select TRY_CAST(CAST('100' as xml) as bit));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f8()
RETURNS bit AS
BEGIN
RETURN (select TRY_CAST(CAST('100' as xml) as bit));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v9 as (select TRY_CAST(CAST('100' as xml) as money));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p9 as (select TRY_CAST(CAST('100' as xml) as money));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f9()
RETURNS money AS
BEGIN
RETURN (select TRY_CAST(CAST('100' as xml) as money));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v10 as (select TRY_CAST(CAST('100' as int) as money));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p10 as (select TRY_CAST(CAST('100' as int) as money));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f10()
RETURNS money AS
BEGIN
RETURN (select TRY_CAST(CAST('100' as int) as money));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v11 as (select TRY_CAST(CAST('100' as varchar(1)) as text));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p11 as (select TRY_CAST(CAST('100' as varchar(1)) as text));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f11()
RETURNS text AS
BEGIN
RETURN (select TRY_CAST(CAST('100' as varchar(1)) as text));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v12 as (select TRY_CAST(CAST('1990-01-01 10:10:10.12345' as datetime(2)) as datetime));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p12 as (select TRY_CAST(CAST('1990-01-01 10:10:10.12345' as datetime(2)) as datetime));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f12()
RETURNS DATETIME AS
BEGIN
RETURN (select TRY_CAST(CAST('1990-01-01 10:10:10.12345' as datetime(2)) as datetime));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v13 as (select TRY_CAST(CAST('1990-01-01 10:10:10.123' as datetime) as datetime2(1)));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p13 as (select TRY_CAST(CAST('1990-01-01 10:10:10.123' as datetime) as datetime2(1)));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f13()
RETURNS datetime AS
BEGIN
RETURN (select TRY_CAST(CAST('1990-01-01 10:10:10.123' as datetime) as datetime2(1)));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v14 as (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2) as datetime));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p14 as (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2) as datetime));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f14()
RETURNS datetime AS
BEGIN
RETURN (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2) as datetime));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v15 as (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2) as datetime));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p15 as (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2) as datetime));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f15()
RETURNS datetime AS
BEGIN
RETURN (select TRY_CAST(CAST('1990-12-31 23:59:59.999' as datetime2(1)) as datetime));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v16 as (select TRY_CAST(CAST('5' as datetime2(1)) as datetime));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p16 as (select TRY_CAST(CAST('5' as datetime2(1)) as datetime));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f16()
RETURNS datetime AS
BEGIN
RETURN (select TRY_CAST(CAST('5' as datetime2(1)) as datetime));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v17 as (select TRY_CAST(CAST('5' as numeric) as xml));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p17 as (select TRY_CAST(CAST('5' as numeric) as xml));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f17()
RETURNS xml AS
BEGIN
RETURN (select TRY_CAST(CAST('5' as numeric) as xml));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v18 as (select TRY_CAST(TRY_CAST('5' as numeric) as xml));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p18 as (select TRY_CAST(TRY_CAST('5' as numeric) as xml));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f18()
RETURNS xml AS
BEGIN
RETURN (select TRY_CAST(TRY_CAST('5' as numeric) as xml));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v19 as (select TRY_CAST(CAST(NULL as datetime2(1)) as datetime));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p19 as (select TRY_CAST(CAST(NULL as datetime2(1)) as datetime));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f19()
RETURNS datetime AS
BEGIN
RETURN (select TRY_CAST(CAST(NULL as datetime2(1)) as datetime));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v20 as (select TRY_CAST(CAST(5 as smallint) as varchar));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p20 as (select TRY_CAST(CAST(5 as smallint) as varchar));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f20()
RETURNS varchar AS
BEGIN
RETURN (select TRY_CAST(CAST(5 as smallint) as varchar));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v22 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS TIME));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p22 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS TIME));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f22()
RETURNS TIME AS
BEGIN
RETURN (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS TIME));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v24 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS MONEY));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p24 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS MONEY));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f24()
RETURNS MONEY AS
BEGIN
RETURN (SELECT TRY_CAST(CAST('1990-01-01' AS DATE) AS MONEY));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v25 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATETIME) AS XML));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p25 as (SELECT TRY_CAST(CAST('1990-01-01' AS DATETIME) AS XML));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f25()
RETURNS XML AS
BEGIN
RETURN (SELECT TRY_CAST(CAST('1990-01-01' AS DATETIME) AS XML));
END
GO

CREATE VIEW BABEL_3646_vu_prepare_v26 as (SELECT sys.int4binary(1, 1, TRUE));
GO
CREATE PROCEDURE BABEL_3646_vu_prepare_p26 as (SELECT sys.int4binary(1, 1, TRUE));
GO
CREATE FUNCTION BABEL_3646_vu_prepare_f26()
RETURNS BINARY AS
BEGIN
RETURN (SELECT sys.int4binary(1, 1, TRUE));
END
GO
