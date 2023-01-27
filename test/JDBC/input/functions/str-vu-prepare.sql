CREATE VIEW str_vu_prepare_v1 AS (
    SELECT 
        STR(1234.56, 8, 2) AS res1,
        STR(1234.56, 4, 0) AS res2,
        STR(-1234.56, 20, 10) AS res3,
        STR(1234.567, 10, 2) AS res4
    );
GO

-- test different number of input agruments, default lenghth = 10 and default decimal = 0
CREATE VIEW str_vu_prepare_v2 AS (
    SELECT 
        STR(1234.56) AS res1,
        STR(1234.56, 6) AS res2,
        STR(1234.56, 6, 1) AS res3
    );
GO

-- null inputs
-- no input arguments, throw error
CREATE VIEW str_vu_prepare_v3 AS (SELECT STR());
GO

-- only third argument could be null, otherwise return null
CREATE VIEW str_vu_prepare_v4 AS (
    SELECT 
        STR(NULL) AS res1,
        STR(NULL, NULL) AS res2,
        STR(NULL, NULL, NULL) AS res3,
        STR(1234.56, NULL) AS res4,
        STR(NULL, 6) AS res5,
        STR(1234.56, NULL, NULL) AS res6,
        STR(NULL, 6, NULL) AS res7,
        STR(NULL, NULL, 2) AS res8,
        STR(1234.56, 6, NULL) AS res9,
        STR(1234.56, NULL, 2) AS res10,
        STR(NULL, 6, 2) AS res11
    );
GO

-- test with all datatypes that could implicitly converted to numeric
CREATE VIEW str_vu_prepare_v5 AS (
    SELECT 
        STR(CAST(123.45 AS INT), 5, 1) AS res1,
        STR(CAST(123.45 AS FLOAT), 5, 1) AS res2,
        STR(CAST(123.45 AS REAL), 5, 1) AS res3,
        STR(CAST(123.45 AS BIGINT), 5, 1) AS res4,
        STR(CAST(123.45 AS SMALLINT), 5, 1) AS res5,
        STR(CAST(123.45 AS TINYINT), 5, 1) AS res6,
        STR(CAST('$123.45' AS MONEY), 5, 1) AS res7,
        STR(CAST('$123.45' AS SMALLMONEY),5, 1) AS res8,
        STR(CAST(123.45 AS DECIMAL), 5, 1) AS res9,
        STR(CAST(123.45 AS NUMERIC), 5, 1) AS res10,
        STR(CAST('123.45' AS CHAR), 5, 1) AS res11,
        STR(CAST('123.45' AS VARCHAR), 5, 1) AS res12,
        STR(CAST('123.45' AS NCHAR), 5, 1) AS res13,
        STR(CAST('123.45' AS NVARCHAR), 5, 1) AS res14
    );
GO

-- test with all datatypes that could implicitly converted to int
CREATE VIEW str_vu_prepare_v6 AS (
    SELECT 
        STR(1234.56, CAST(8 AS INT), CAST(3 AS INT)) AS res1,
        STR(1234.56, CAST(8 AS FLOAT), CAST(3 AS FLOAT)) AS res2,
        STR(1234.56, CAST(8 AS REAL), CAST(3 AS REAL)) AS res3,
        STR(1234.56, CAST(8 AS BIGINT), CAST(3 AS BIGINT)) AS res4,
        STR(1234.56, CAST(8 AS SMALLINT), CAST(3 AS SMALLINT)) AS res5,
        STR(1234.56, CAST(8 AS TINYINT), CAST(3 AS TINYINT)) AS res6,
        STR(1234.56, CAST('$8' AS MONEY), CAST('$3' AS MONEY)) AS res7,
        STR(1234.56, CAST('$8' AS SMALLMONEY), CAST('$3' AS SMALLMONEY)) AS res8,
        STR(1234.56, CAST(8 AS DECIMAL), CAST(3 AS DECIMAL)) AS res9,
        STR(1234.56, CAST(8 AS NUMERIC), CAST(3 AS NUMERIC)) AS res10,
        STR(1234.56, CAST('8' AS CHAR), CAST('3' AS CHAR)) AS res11,
        STR(1234.56, CAST('8' AS VARCHAR), CAST('3' AS VARCHAR)) AS res12,
        STR(1234.56, CAST('8' AS NCHAR), CAST('3' AS NCHAR)) AS res13,
        STR(1234.56, CAST('8' AS NVARCHAR), CAST('3' AS NVARCHAR)) AS res14
    );
GO


-- returns null on negative second or third input argument
CREATE VIEW str_vu_prepare_v7 AS (
    SELECT 
        STR(1234.56, -10) AS res1,
        STR(1234.56, -10, 3) AS res2,
        STR(1234.56, 10, -3) AS res3,
        STR(1234.56, -10, -3) AS res4
    );
GO

-- returns null when float_exp is NaN or Infinity
CREATE VIEW str_vu_prepare_v8 AS (
    SELECT 
        STR('NaN', 5, 3) AS res1,
        STR('nan', 5, 3) AS res2,
        STR('NAN', 5, 3) AS res3,
        STR('Infinity', 5, 3) AS res4,
        STR('Inf', 5, 3) AS res5,
        STR('INFINITY', 5, 3) AS res6,
        STR('INF', 5, 3) AS res7,
        STR('infinity', 5, 3) AS res8,
        STR('inf', 5, 3) AS res9,
        STR('-Infinity', 5, 3) AS res10,
        STR('-Inf', 5, 3) AS res11,
        STR('-INFINITY', 5, 3) AS res12,
        STR('-INF', 5, 3) AS res13,
        STR('-infinity', 5, 3) AS res14,
        STR('-inf', 5, 3) AS res15
    );
GO

-- returns null when length > 8000, due to row size limit
CREATE VIEW str_vu_prepare_v9 AS (
    SELECT 
        STR(1234.56, 8000) AS res1,
        STR(1234.56, 8001) AS res2
    );
GO

-- throws error when float_exp input has precision > 38
CREATE VIEW str_vu_prepare_v10 AS (
    SELECT 
        STR(12345678901234567890.1234567890123456789, 40, 20)
    );
GO

-- throws error when length input exceed input of int32
CREATE VIEW str_vu_prepare_v11 AS (
    SELECT 
        STR(1234.56, 2147483648, 20)
    );
GO

-- throws error when decimal input exceed input of int32
CREATE VIEW str_vu_prepare_v12 AS (
    SELECT 
        STR(1234.56, 40, 2147483648)
    );
GO

-- won't over flow
CREATE VIEW str_vu_prepare_v13 AS (
    SELECT 
        STR(12345678901234567890.123456789012345678, 2147483647, 2147483647)
    );
GO

-- integer length of input expression exceeds the specified length, returns ** for the specified length
-- negative sign is also count as one digit in integer part
CREATE VIEW str_vu_prepare_v14 AS (
    SELECT 
        STR(1234, 3) AS res1,
        STR(123456.78, 5, 3) AS res2,
        STR(-123456, 6, 1) AS res3
    );
GO

-- when input decimal greater than length - integer digits, go with length's constraint
CREATE VIEW str_vu_prepare_v15 AS (
    SELECT 
        STR(1234, 5, 6) AS res1,
        STR(123456.78, 6, 3) AS res2,
        STR(-123456.789, 7, 3) AS res3,
        STR(1234.567, 12, 20) AS res4
    );
GO

-- actual max precision 17, round to 17th digit and pad rest of significant digits with zeros
--
-- SQL Server's STR() function returns flacky results when it rounds the integer part.
-- SELECT  STR(123456789012345670, 20); returns '  123456789012345660', which brings down the 17th digit by 1.
-- SELECT  STR(123456789012345671, 20); and SELECT  STR(123456789012345672, 20); returns the same result as above.
-- Starting from 123456789012345673 to 123456789012345679,
-- SELECT  STR(12345678901234567X, 20); returns '  123456789012345680', the last digit get rounded up
--
-- When integer has 19 digits,
-- SELECT  STR(1234567890123456100, 20); returns ' 1234567890123456000', 17th digit 1 got rounded down
-- SELECT  STR(1234567890123456200, 20); returns ' 1234567890123456300', 17th digit 2 got rounded up
-- SELECT  STR(1234567890123456380, 20); returns ' 1234567890123456300' but SELECT  STR(1234567890123456390, 20); returns ' 1234567890123456500'
--
-- When integer has 20 digits,
-- SELECT  STR(12345678901234562000, 20); returns '12345678901234561000', 17th digit 2 got rounded down
-- SELECT  STR(12345678901234562050, 20); returns '12345678901234563000', 17th digit 2 got rounded up
-- SELECT  STR(12345678901234567890, 20); returns '12345678901234567000', 17th digit didn't get rounded up
-- SELECT  STR(12345678901234569999, 20); returns '12345678901234569000', 17th digit didn't get rounded up
-- 
-- This is hard to recreate so here we return with the correct rounding result.
CREATE VIEW str_vu_prepare_v16 AS (
    SELECT 
        STR(1234567890123456789012345.67, 26, 1) AS res1,
        STR(123456789012345670, 20) AS res2,
        STR(123456789012345679, 20) AS res3,
        STR(1234567890123456100, 20) AS res4,
        STR(12345678901234562050, 20) AS res5,
        STR(12345678901234569999, 20) AS res6,
        STR(-1234567890.12345678901234567, 30, 16) AS res7
    );
GO

-- max scale is 16, add num of preceding spaces when decimal is more than 16
CREATE VIEW str_vu_prepare_v17 AS (
    SELECT 
        STR(1234.1234567890123456789012, 30, 20) AS res1,
        STR(1234.123, 25, 20) AS res2
    );
GO

-- decimal point and negative sign count as one digit
CREATE VIEW str_vu_prepare_v18 AS (
    SELECT 
        STR(1234567890.5, 9, 1) AS res1,
        STR(1234567890.5, 10, 1) AS res2,
        STR(1234567890.5, 11, 1) AS res3,
        STR(1234567890.5, 12, 1) AS res4,
        STR(-1234567890.5, 10, 1) AS res5,
        STR(-1234567890.5, 11, 1) AS res6,
        STR(-1234567890.5, 12, 1) AS res7,
        STR(-1234567890.5, 13, 1) AS res8
    );
GO

-- when there's one extra digit from carried over, go with the length and decimal constraint before rounding
CREATE VIEW str_vu_prepare_v19 AS (
    SELECT 
        STR(9999.995, 8, 2) AS res1,
        STR(999.99, 3, 1) AS res2,
        STR(9999.998, 7, 2) AS res3
    );
GO

CREATE PROCEDURE str_vu_prepare_p1 AS 
BEGIN
    SELECT 
        STR(1234.56, 8, 2) AS res1,
        STR(1234.56, 4, 0) AS res2,
        STR(-1234.56, 20, 10) AS res3,
        STR(1234.567, 10, 2) AS res4;
END
GO

CREATE PROCEDURE str_vu_prepare_p2 AS 
BEGIN
    SELECT 
        STR(1234.56) AS res1,
        STR(1234.56, 6) AS res2,
        STR(1234.56, 6, 1) AS res3;
END
GO

CREATE PROCEDURE str_vu_prepare_p3 AS 
BEGIN
    SELECT STR();
END
GO

CREATE PROCEDURE str_vu_prepare_p4 AS 
BEGIN
    SELECT 
        STR(NULL) AS res1,
        STR(NULL, NULL) AS res2,
        STR(NULL, NULL, NULL) AS res3,
        STR(1234.56, NULL) AS res4,
        STR(NULL, 6) AS res5,
        STR(1234.56, NULL, NULL) AS res6,
        STR(NULL, 6, NULL) AS res7,
        STR(NULL, NULL, 2) AS res8,
        STR(1234.56, 6, NULL) AS res9,
        STR(1234.56, NULL, 2) AS res10,
        STR(NULL, 6, 2) AS res11;
END
GO

-- test with all datatypes that could implicitly converted to numeric
CREATE PROCEDURE str_vu_prepare_p5 
    @x1 INT = 123.45,
    @x2 FLOAT = 123.45,
    @x3 REAL = 123.45,
    @x4 BIGINT = 123.45,
    @x5 SMALLINT = 123.45,
    @x6 TINYINT = 123.45,
    @x7 MONEY = '$123.45',
    @x8 SMALLMONEY = '$123.45',
    @x9 DECIMAL = 123.45,
    @x10 NUMERIC = 123.45,
    @x11 CHAR = '123.45',
    @x12 VARCHAR = '123.45',
    @x13 NCHAR = '123.45',
    @x14 NVARCHAR = '123.45'
AS
BEGIN
    SELECT 
        STR(@x1, 5, 1) AS res1,
        STR(@x2, 5, 1) AS res2,
        STR(@x3, 5, 1) AS res3,
        STR(@x4, 5, 1) AS res4,
        STR(@x5, 5, 1) AS res5,
        STR(@x6, 5, 1) AS res6,
        STR(@x7, 5, 1) AS res7,
        STR(@x8,5, 1) AS res8,
        STR(@x9, 5, 1) AS res9,
        STR(@x10, 5, 1) AS res10,
        STR(@x11, 5, 1) AS res11,
        STR(@x12, 5, 1) AS res12,
        STR(@x13, 5, 1) AS res13,
        STR(@x14, 5, 1) AS res14
END
GO

-- test with all datatypes that could implicitly converted to int
CREATE PROCEDURE str_vu_prepare_p6 
    @x1 INT = 8, @y1 INT = 3,
    @x2 FLOAT = 8, @y2 FLOAT = 3,
    @x3 REAL = 8, @y3 REAL = 3,
    @x4 BIGINT = 8, @y4 BIGINT = 3,
    @x5 SMALLINT = 8, @y5 SMALLINT = 3,
    @x6 TINYINT = 8, @y6 TINYINT = 3,
    @x7 MONEY = '$8', @y7 MONEY = '$3',
    @x8 SMALLMONEY = '$8', @y8 SMALLMONEY = '$3',
    @x9 DECIMAL = 8, @y9 DECIMAL = 3,
    @x10 NUMERIC = 8, @y10 NUMERIC = 3,
    @x11 CHAR = '8', @y11 CHAR = '3',
    @x12 VARCHAR = '8', @y12 VARCHAR = '3',
    @x13 NCHAR = '8', @y13 NCHAR = '3',
    @x14 NVARCHAR = '8', @y14 NVARCHAR = '3'
AS 
BEGIN
    SELECT 
        STR(1234.56, @x1, @y1) AS res1,
        STR(1234.56, @x2, @y2) AS res2,
        STR(1234.56, @x3, @y3) AS res3,
        STR(1234.56, @x4, @y4) AS res4,
        STR(1234.56, @x5, @y5) AS res5,
        STR(1234.56, @x6, @y6) AS res6,
        STR(1234.56, @x7, @y7) AS res7,
        STR(1234.56, @x8, @y8) AS res8,
        STR(1234.56, @x9, @y9) AS res9,
        STR(1234.56, @x10, @y10) AS res10,
        STR(1234.56, @x11, @y11) AS res11,
        STR(1234.56, @x12, @y12) AS res12,
        STR(1234.56, @x13, @y13) AS res13,
        STR(1234.56, @x14, @y14) AS res14;
END
GO

CREATE PROCEDURE str_vu_prepare_p7 AS 
BEGIN
    SELECT 
        STR(1234.56, -10) AS res1,
        STR(1234.56, -10, 3) AS res2,
        STR(1234.56, 10, -3) AS res3,
        STR(1234.56, -10, -3) AS res4;
END
GO

CREATE PROCEDURE str_vu_prepare_p8 AS
BEGIN
    SELECT 
        STR('NaN', 5, 3) AS res1,
        STR('nan', 5, 3) AS res2,
        STR('NAN', 5, 3) AS res3,
        STR('Infinity', 5, 3) AS res4,
        STR('Inf', 5, 3) AS res5,
        STR('INFINITY', 5, 3) AS res6,
        STR('INF', 5, 3) AS res7,
        STR('infinity', 5, 3) AS res8,
        STR('inf', 5, 3) AS res9,
        STR('-Infinity', 5, 3) AS res10,
        STR('-Inf', 5, 3) AS res11,
        STR('-INFINITY', 5, 3) AS res12,
        STR('-INF', 5, 3) AS res13,
        STR('-infinity', 5, 3) AS res14,
        STR('-inf', 5, 3) AS res15;
END
GO

CREATE PROCEDURE str_vu_prepare_p9 AS 
BEGIN
    SELECT 
        STR(1234.56, 8000) AS res1,
        STR(1234.56, 8001) AS res2;
END
GO

CREATE PROCEDURE str_vu_prepare_p10 AS 
BEGIN
    SELECT 
        STR(12345678901234567890.1234567890123456789, 40, 20);
END
GO

-- throws error when length input exceed input of int32
CREATE PROCEDURE str_vu_prepare_p11 AS 
BEGIN
    SELECT 
        STR(1234.56, 2147483648, 20);
END
GO

-- throws error when decimal input exceed input of int32
CREATE PROCEDURE str_vu_prepare_p12 AS 
BEGIN
    SELECT 
        STR(1234.56, 40, 2147483648);
END
GO

-- won't overfow
CREATE PROCEDURE str_vu_prepare_p13 AS 
BEGIN
    SELECT 
        STR(12345678901234567890.123456789012345678, 2147483647, 2147483647);
END
GO

-- integer length of input expression exceeds the specified length, returns ** for the specified length
-- negative sign is also count as one digit in integer part
CREATE PROCEDURE str_vu_prepare_p14 AS 
BEGIN
    SELECT 
        STR(1234, 3) AS res1,
        STR(123456.78, 5, 3) AS res2,
        STR(-123456, 6, 1) AS res3;
END
GO

-- when input decimal greater than length - integer digits, go with length's constraint
CREATE PROCEDURE str_vu_prepare_p15 AS 
BEGIN
    SELECT 
        STR(1234, 5, 6) AS res1,
        STR(123456.78, 6, 3) AS res2,
        STR(-123456.789, 7, 3) AS res3,
        STR(1234.567, 12, 20) AS res4;
END
GO

-- actual max precision 17, round to 17th digit and pad rest of significant digits with zeros
CREATE PROCEDURE str_vu_prepare_p16 AS 
BEGIN
    SELECT 
        STR(1234567890123456789012345.67, 26, 1) AS res1,
        STR(123456789012345670, 20) AS res2,
        STR(123456789012345679, 20) AS res3,
        STR(1234567890123456100, 20) AS res4,
        STR(12345678901234562050, 20) AS res5,
        STR(12345678901234569999, 20) AS res6,
        STR(-1234567890.12345678901234567, 30, 16) AS res;
END
GO

-- max scale is 16, add num of preceding spaces when decimal is more than 16
CREATE PROCEDURE str_vu_prepare_p17 AS 
BEGIN
    SELECT 
        STR(1234.1234567890123456789012, 30, 20) AS res1,
        STR(1234.123, 25, 20) AS res2
END
GO

-- decimal point and negative sign count as one digit
CREATE PROCEDURE str_vu_prepare_p18 AS 
BEGIN
    SELECT 
        STR(1234567890.5, 9, 1) AS res1,
        STR(1234567890.5, 10, 1) AS res2,
        STR(1234567890.5, 11, 1) AS res3,
        STR(1234567890.5, 12, 1) AS res4,
        STR(-1234567890.5, 10, 1) AS res5,
        STR(-1234567890.5, 11, 1) AS res6,
        STR(-1234567890.5, 12, 1) AS res7,
        STR(-1234567890.5, 13, 1) AS res8;
END
GO

-- when there's one extra digit from carried over, go with the length and decimal constraint before rounding
CREATE PROCEDURE str_vu_prepare_p19 AS 
BEGIN
    SELECT 
        STR(9999.995, 8, 2) AS res1,
        STR(999.99, 3, 1) AS res2,
        STR(9999.998, 7, 2) AS res3;
END
GO
