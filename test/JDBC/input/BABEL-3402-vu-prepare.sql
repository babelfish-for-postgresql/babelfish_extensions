use master
go

SELECT suser_sid(-10)
go

DROP VIEW IF EXISTS babel_3402_vu_prepare_v1
go
CREATE VIEW babel_3402_vu_prepare_v1 AS SELECT suser_sid(-10)
go
select * from babel_3402_vu_prepare_v1;
go

drop function if exists babel_3402_vu_prepare_f1(int);
go
CREATE FUNCTION babel_3402_vu_prepare_f1(@a int)
RETURNS VARBINARY(85)
AS
BEGIN
    return suser_sid(@a);
END;
GO
select babel_3402_vu_prepare_f1(-10);
go

drop procedure if exists babel_3402_vu_prepare_p1;
go
CREATE PROCEDURE babel_3402_vu_prepare_p1 @a int
AS
SELECT suser_sid(@a)
GO
exec babel_3402_vu_prepare_p1 -10;
go
