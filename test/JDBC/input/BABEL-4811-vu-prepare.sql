create function babel_4811_vu_prepare_f1(@number int)
returns int 
BEGIN
    RETURN DATALENGTH(SPACE(@number))
END
GO

create procedure babel_4811_vu_prepare_p1 (@number AS INT)
AS
BEGIN
SELECT DATALENGTH(SPACE(@number))
END;
GO

create view babel_4811_vu_prepare_v1 AS
SELECT DATALENGTH(SPACE(10))
GO


create view babel_4811_vu_prepare_v2 AS
SELECT DATALENGTH(SPACE(0))
GO

create view babel_4811_vu_prepare_v3 AS
SELECT DATALENGTH(SPACE(-10))
GO