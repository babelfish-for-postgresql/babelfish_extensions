CREATE PROCEDURE babel_2747 (@arg1 VARCHAR(MAX) OUTPUT)
AS
BEGIN
    print 'body removed'
END;
GO

CREATE PROCEDURE babel_2747_2 (@arg1 VARCHAR(MAX))
AS
BEGIN
    print 'body removed'
END;
GO

CREATE FUNCTION babel_2747_3 (@arg1 varchar(5), @arg2 varchar(10))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

CREATE TABLE t1(c1 int);
GO

CREATE TRIGGER babel_2747_4 ON t1
AFTER INSERT
AS
BEGIN
    INSERT INTO t1(c1) VALUES (1);
END;
GO

SELECT type, type_desc from sys.procedures  where name like 'babel_2747%' order by type;
GO

SELECT type, type_desc from sys.all_objects  where name like 'babel_2747%' order by type;
GO

DROP PROCEDURE babel_2747
GO

DROP PROCEDURE babel_2747_2
GO

DROP FUNCTION babel_2747_3
GO

DROP TABLE t1
GO
