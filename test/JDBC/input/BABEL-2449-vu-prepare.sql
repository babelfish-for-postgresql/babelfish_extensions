CREATE VIEW BABEL_2449_vu_prepare_v1 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3));
GO

--Input has NULL, output should be NULL
CREATE VIEW BABEL_2449_vu_prepare_v2 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, NULL, 30, 00, 500, 12, 30, 3));
GO

--Input hour offset if negative, should raise error
CREATE VIEW BABEL_2449_vu_prepare_v3 as (SELECT DATETIMEOFFSETFROMPARTS(2021, 05, 10, 23, 35, 29, 500, -12, 30, 4));
GO

--Input hour offset is not between -14 and 14, should raise error
CREATE VIEW BABEL_2449_vu_prepare_v4 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 15, 00, 3));
GO

CREATE VIEW BABEL_2449_vu_prepare_v5 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 50, 12, 00, 5));
GO

--Input minute is not between 0 and 59, should raise error
CREATE VIEW BABEL_2449_vu_prepare_v6 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, 3));
GO

--Input precision null, should raise error
CREATE VIEW BABEL_2449_vu_prepare_v7 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, NULL));
GO

CREATE VIEW BABEL_2449_vu_prepare_v8 as (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, 3));
GO

CREATE VIEW BABEL_2449_vu_prepare_v9 as (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, NULL));
GO

CREATE VIEW BABEL_2449_vu_prepare_v10 as (SELECT DATETIMEOFFSETFROMPARTS('2011', '8', '15', '14', '30', '00', '500', '12', '30', '3'));
GO

CREATE VIEW BABEL_2449_vu_prepare_v11 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3.2));
GO

CREATE VIEW BABEL_2449_vu_prepare_v12 as (SELECT DATETIMEOFFSETFROMPARTS(2011.9, 8.9, 15.9, 14.9, 30.9, 00, 500.9, 12.9, 30.9, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p1 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p2 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, NULL, 30, 00, 500, 12, 30, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p3 as (SELECT DATETIMEOFFSETFROMPARTS(2021, 05, 10, 23, 35, 29, 500, -12, 30, 4));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p4 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 15, 00, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p5 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 50, 12, 00, 5));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p6 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p7 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p8 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, NULL));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p9 as (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, 3));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p10 as (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, NULL));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p11 as (SELECT DATETIMEOFFSETFROMPARTS('2011', '8', '15', '14', '30', '00', '500', '12', '30', '3'));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p12 as (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3.2));
GO

CREATE PROCEDURE  BABEL_2449_vu_prepare_p13 as (SELECT DATETIMEOFFSETFROMPARTS(2011.9, 8.9, 15.9, 14.9, 30.9, 00, 500.9, 12.9, 30.9, 3));
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f1()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f2()
RETURNS DATETIMEOFFSET as
begin
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, NULL, 30, 00, 500, 12, 30, 3));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f3()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2021, 05, 10, 23, 35, 29, 500, -12, 30, 4));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f4()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 15, 00, 3));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f5()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 50, 12, 00, 5));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f6()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, 3));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f7()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f8()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 61, 500, 12, 00, NULL));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f9()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, 3));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f10()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS('2011', 8, 15, 14, '30', 00, 500, 12, 30, NULL));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f11()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS('2011', '8', '15', '14', '30', '00', '500', '12', '30', '3'));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f12()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011, 8, 15, 14, 30, 00, 500, 12, 30, 3.2));
END
GO

CREATE FUNCTION BABEL_2449_vu_prepare_f13()
RETURNS DATETIMEOFFSET AS
BEGIN
RETURN (SELECT DATETIMEOFFSETFROMPARTS(2011.9, 8.9, 15.9, 14.9, 30.9, 00, 500.9, 12.9, 30.9, 3));
END
GO
