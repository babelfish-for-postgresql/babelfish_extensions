-- note: the default typmod for varchar should be 1
CREATE FUNCTION babel_1000_test1 (@arg1 varchar)
RETURNS TABLE AS RETURN
(SELECT @arg1 as a)
GO
SELECT * FROM babel_1000_test1('babel_1000_varchar')
GO

CREATE FUNCTION babel_1000_test2 (@arg1 varchar(10), @arg2 varchar(20))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

SELECT * FROM babel_1000_test2('babel_1000_varchar', 'babel_1000_varchar2')
GO
SELECT * FROM babel_1000_test2('babel_1000', 'abcdefghijklmnopqrstuvwxyz')
GO

CREATE FUNCTION babel_1000_test3 (@arg1 nvarchar(10), @arg2 nvarchar(20))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

SELECT * FROM babel_1000_test3('babel_1000_varchar', 'babel_1000_varchar3')
GO
SELECT * FROM babel_1000_test3('12345678910', 'babel_1000_varchar3')
GO

-- numeric default typmod is (18,0)
CREATE FUNCTION babel_1000_test4 (@arg1 nvarchar(10), @arg2 numeric)
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

SELECT * FROM babel_1000_test4('babel_1000_test4', 123.456)
GO
SELECT * FROM babel_1000_test4('babel_1000_test4', 123.567)
GO
SELECT * FROM babel_1000_test4('test4', 123456789012345678)
GO
-- precision 19, expect error
SELECT * FROM babel_1000_test4('test4-2', 1234567890123456789)
GO

CREATE FUNCTION babel_1000_test5 (@arg1 nvarchar(30), @arg2 numeric(6,3))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

SELECT * FROM babel_1000_test5('babel_1000_test5', 123.4567)
GO
SELECT * FROM babel_1000_test5('babel_1000_test5', 567.89)
GO
-- expect overflow error
SELECT * FROM babel_1000_test5('babel_1000_test5', 5567.89)
GO

CREATE FUNCTION babel_1000_test6 (@arg1 datetimeoffset(2), @arg2 datetime2(4))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

SELECT * FROM babel_1000_test6(CAST('2030-05-06 13:59:29.123456 -8:00' AS datetimeoffset),
                                CAST('1234-12-31 23:59:59.999999' AS datetime2))
GO
SELECT * FROM babel_1000_test6(CAST('2030-05-06 13:59:29.124456 +8:00' AS datetimeoffset(4)),
                                CAST('9999-12-31 23:59:59.999999' AS datetime2(5)))
GO

CREATE PROCEDURE babel_1000_test7 (@val datetimeoffset(2)) AS
BEGIN
    DECLARE @DF datetimeoffset = @val
    SELECT @DF
END
GO

EXEC babel_1000_test7 '2030-05-06 13:59:29.123456 -8:00'
GO

-- test return types
CREATE FUNCTION babel_1000_test8(@arg1 numeric)
RETURNS numeric(6,2) AS
BEGIN
 RETURN @arg1 + 1.055
END
GO

SELECT * FROM babel_1000_test8(1)
GO
SELECT * FROM babel_1000_test8(12.345678)
GO
-- overflow, expect error
SELECT * FROM babel_1000_test8(123456.345678)
GO

CREATE FUNCTION babel_1000_test9(@arg1 varchar)
RETURNS varchar(5) AS
BEGIN
 RETURN @arg1
END
GO

SELECT * FROM babel_1000_test9('babel_1000_test9')
GO
SELECT * FROM babel_1000_test9('abcdefghijkl')
GO

CREATE PROCEDURE babel_1000_test10 (@val varchar(2)) AS
BEGIN
    DECLARE @DF varchar = @val
    SELECT @DF
END
GO

EXEC babel_1000_test10 '2030-05-06 13:59:29.123456 -8:00'
GO

CREATE PROCEDURE babel_1000_test10_2 (@val varchar(2)) AS
BEGIN
    DECLARE @DF varchar(100) = @val
    SELECT @DF
END
GO

EXEC babel_1000_test10_2 '2030-05-06 13:59:29.123456 -8:00'
GO


CREATE FUNCTION babel_1000_test11 (@var varchar(10))
RETURNS varchar(4)
AS
BEGIN
    return @var
END
GO

SELECT babel_1000_test11('abcdefghijkl')
GO

CREATE FUNCTION babel_1000_test12 (@var varbinary(10))
RETURNS varbinary(2)
AS
BEGIN
    return @var
END
GO

SELECT babel_1000_test12(0x0123456789)
GO


DROP FUNCTION babel_1000_test1
GO
DROP FUNCTION babel_1000_test2
GO
DROP FUNCTION babel_1000_test3
GO
DROP FUNCTION babel_1000_test4
GO
DROP FUNCTION babel_1000_test5
GO
DROP FUNCTION babel_1000_test6
GO
DROP PROCEDURE babel_1000_test7
GO
DROP FUNCTION babel_1000_test8
GO
DROP FUNCTION babel_1000_test9
GO
DROP PROCEDURE babel_1000_test10
GO
DROP PROCEDURE babel_1000_test10_2
GO
DROP FUNCTION babel_1000_test11
GO
DROP FUNCTION babel_1000_test12
GO
