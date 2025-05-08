CREATE TABLE babel_4811_vu_prepare_t1(number int)
GO
INSERT INTO babel_4811_vu_prepare_t1 VALUES(5)
GO

CREATE TABLE babel_4811_vu_prepare_t2(number int)
GO
INSERT INTO babel_4811_vu_prepare_t2 VALUES(-10)
GO

CREATE TABLE babel_4811_vu_prepare_t3(number int)
GO
INSERT INTO babel_4811_vu_prepare_t3 VALUES(0)
GO

CREATE FUNCTION babel_4811_vu_prepare_f1(@number int)
returns int
BEGIN
    RETURN DATALENGTH(SPACE(@number))
END
GO

CREATE FUNCTION babel_4811_vu_prepare_f2(@number int)
returns varchar(20)
BEGIN
    RETURN '|' + SPACE(@number) + '|'
END
GO

CREATE FUNCTION babel_4811_vu_prepare_f3()
returns table
AS
    RETURN (select '|' + SPACE(number) + '|' as result from babel_4811_vu_prepare_t1)
GO

CREATE PROCEDURE babel_4811_vu_prepare_p1 (@number AS INT)
AS
BEGIN
SELECT DATALENGTH(SPACE(@number))
END;
GO

CREATE PROCEDURE babel_4811_vu_prepare_p2 (@number AS INT)
AS
BEGIN
SELECT '|' + SPACE(@number) + '|' AS result
END;
GO

CREATE VIEW babel_4811_vu_prepare_v1 AS
SELECT DATALENGTH(SPACE(10)) as result
GO


CREATE VIEW babel_4811_vu_prepare_v2 AS
SELECT DATALENGTH(SPACE(0)) as result
GO

CREATE VIEW babel_4811_vu_prepare_v3 AS
SELECT DATALENGTH(SPACE(-10)) as result
GO

CREATE VIEW babel_4811_vu_prepare_v4 AS
    SELECT DATALENGTH(SPACE(number)) as result FROM babel_4811_vu_prepare_t1
GO

CREATE VIEW babel_4811_vu_prepare_v5 AS
    SELECT DATALENGTH(SPACE(number)) as result FROM babel_4811_vu_prepare_t2
GO

CREATE VIEW babel_4811_vu_prepare_v6 AS
    SELECT DATALENGTH(SPACE(number)) as result FROM babel_4811_vu_prepare_t3
GO

CREATE VIEW babel_4811_vu_prepare_v7 AS
SELECT '|' + SPACE(10) + '|' AS result
GO

CREATE VIEW babel_4811_vu_prepare_v8 AS
SELECT '|' + SPACE(0) + '|' AS result
GO

CREATE VIEW babel_4811_vu_prepare_v9 AS
SELECT '|' + SPACE(-10) + '|' AS result
GO
