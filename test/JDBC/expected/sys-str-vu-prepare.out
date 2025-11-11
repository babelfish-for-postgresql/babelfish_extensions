CREATE VIEW sys_str_vu_prepare_v1 as (SELECT STR(123.355, 10, 2));
GO

CREATE VIEW sys_str_vu_prepare_v2 as (SELECT STR(123.355, 10));
GO

CREATE VIEW sys_str_vu_prepare_v3 as (SELECT STR(123.355));
GO

CREATE PROCEDURE  sys_str_vu_prepare_p1 as (SELECT STR(123.355, 10, 2));
GO
 
CREATE PROCEDURE  sys_str_vu_prepare_p2 as (SELECT STR(123.355, 10));
GO

CREATE PROCEDURE  sys_str_vu_prepare_p3 as (SELECT STR(123.355));
GO

CREATE FUNCTION sys_str_vu_prepare_f1()
RETURNS VARCHAR AS
BEGIN
RETURN (SELECT STR(123.355, 10, 2));
END
GO
 
CREATE FUNCTION sys_str_vu_prepare_f2()
RETURNS VARCHAR as
begin
RETURN (SELECT STR(123.355, 10));
END
GO

CREATE FUNCTION sys_str_vu_prepare_f3()
RETURNS VARCHAR as
begin
RETURN (SELECT STR(123.355));
END
GO
