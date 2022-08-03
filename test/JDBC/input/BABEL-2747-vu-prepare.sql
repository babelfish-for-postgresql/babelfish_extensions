CREATE PROCEDURE babel_2747_vu_prepare (@arg1 VARCHAR(MAX) OUTPUT)
AS
BEGIN
    print 'body removed'
END;
GO

CREATE PROCEDURE babel_2747__vu_prepare_2 (@arg1 VARCHAR(MAX))
AS
BEGIN
    print 'body removed'
END;
GO

CREATE FUNCTION babel_2747__vu_prepare_3 (@arg1 varchar(5), @arg2 varchar(10))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

CREATE TABLE babel_2747__vu_prepare_t1(c1 int);
GO

CREATE TRIGGER babel_2747__vu_prepare_4 ON babel_2747__vu_prepare_t1
AFTER INSERT
AS
BEGIN
    INSERT INTO babel_2747__vu_prepare_t1(c1) VALUES (1);
END;
GO
