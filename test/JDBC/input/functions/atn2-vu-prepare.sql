CREATE VIEW atn2_vu_prepare_v1 AS (
    SELECT 
        ATN2(2, 3) AS res1,
        ATN2(2.5, 3.5) AS res2,
        ATN2('2.5', '3.5') AS res3
    );
GO

-- test with all datatypes that could implicity converted to float
CREATE VIEW atn2_vu_prepare_v2 AS (
    SELECT 
        ATN2(CAST(2 AS INT), CAST(3 AS INT)) AS res1,
        ATN2(CAST(2.5 AS FLOAT), CAST(3.5 AS FLOAT)) AS res2,
        ATN2(CAST(2.5 AS REAL), CAST(3.5 AS REAL)) AS res3,
        ATN2(CAST(2.5 AS BIGINT), CAST(3.5 AS BIGINT)) AS res4,
        ATN2(CAST(2.5 AS SMALLINT), CAST(3.5 AS SMALLINT)) AS res5,
        ATN2(CAST(2.5 AS TINYINT), CAST(3.5 AS TINYINT)) AS res6,
        ATN2(CAST('$2.5' AS MONEY), CAST('$3.5' AS MONEY)) AS res7,
        ATN2(CAST('$2.5' AS SMALLMONEY), CAST('$3.5' AS SMALLMONEY)) AS res8,
        ATN2(CAST(2.5 AS DECIMAL), CAST(3.5 AS DECIMAL)) AS res9,
        ATN2(CAST(2.5 AS NUMERIC), CAST(3.5 AS NUMERIC)) AS res10,
        ATN2(CAST('2.5' AS CHAR), CAST('3.5' AS CHAR)) AS res11,
        ATN2(CAST('2.5' AS VARCHAR), CAST('3.5' AS VARCHAR)) AS res12,
        ATN2(CAST('2.5' AS NCHAR), CAST('3.5' AS NCHAR)) AS res13,
        ATN2(CAST('2.5' AS NVARCHAR), CAST('3.5' AS NVARCHAR)) AS res14
    );
GO

-- returns NULL when input is NULL
CREATE VIEW atn2_vu_prepare_v3 AS (
    SELECT 
        ATN2(NULL, 1) AS res1,
        ATN2(1, NULL) AS res2,
        ATN2(NULL, NULL) AS res3
    );
GO

-- expect float overflow error
CREATE VIEW atn2_vu_prepare_v4 AS (SELECT ATN2(1.79E+309, 1));
GO

-- won't over flow
CREATE VIEW atn2_vu_prepare_v5 AS (SELECT ATN2(1.79E+308, 1));
GO


-- test in procedures
CREATE PROCEDURE atn2_vu_prepare_p1 AS 
BEGIN
    SELECT ATN2(2, 3);
    SELECT ATN2(2.5, 3.5);
    SELECT ATN2('2.5', '3.5');
END
GO

-- test with all datatypes that could implicity converted to float
-- CREATE PROCEDURE atn2_vu_prepare_p2 AS (SELECT ATN2(CAST(2 AS INT), CAST(3 AS INT)));
-- GO

CREATE PROCEDURE atn2_vu_prepare_p2
    @x1 INT = 2, @y1 INT = 3,
    @x2 FLOAT = 2.5, @y2 FLOAT = 3.5,
    @x3 REAL = 2.5, @y3 REAL = 3.5,
    @x4 BIGINT = 2.5, @y4 BIGINT = 3.5,
    @x5 SMALLINT = 2.5, @y5 SMALLINT = 3.5,
    @x6 TINYINT = 2.5, @y6 TINYINT = 3.5,
    @x7 MONEY = '$2.5', @y7 MONEY = '$3.5',
    @x8 SMALLMONEY = '$2.5', @y8 SMALLMONEY = '$3.5',
    @x9 DECIMAL = 2.5, @y9 DECIMAL = 3.5,
    @x10 NUMERIC = 2.5, @y10 NUMERIC = 3.5,
    @x11 CHAR = '2.5', @y11 CHAR = '3.5',
    @x12 VARCHAR = '2.5', @y12 VARCHAR = '3.5',
    @x13 NCHAR = '2.5', @y13 NCHAR = '3.5',
    @x14 NVARCHAR = '2.5', @y14 NVARCHAR = '3.5'
AS
BEGIN
    SELECT ATN2(@x1, @y1);
    SELECT ATN2(@x12, @y2);
    SELECT ATN2(@x3, @y3);
    SELECT ATN2(@x4, @y4);
    SELECT ATN2(@x5, @y5);
    SELECT ATN2(@x6, @y6);
    SELECT ATN2(@x7, @y7);
    SELECT ATN2(@x8, @y8);
    SELECT ATN2(@x9, @y9);
    SELECT ATN2(@x10, @y10);
    SELECT ATN2(@x11, @y11);
    SELECT ATN2(@x12, @y12);
    SELECT ATN2(@x13, @y13);
    SELECT ATN2(@x14, @y14);
END
GO

-- returns NULL when input is NULL
CREATE PROCEDURE atn2_vu_prepare_p3 AS (SELECT ATN2(NULL, 1));
GO

CREATE PROCEDURE atn2_vu_prepare_p4 AS (SELECT ATN2(1, NULL));
GO

CREATE PROCEDURE atn2_vu_prepare_p5 AS (SELECT ATN2(NULL, NULL));
GO

-- expect float overflow
CREATE PROCEDURE atn2_vu_prepare_p6 AS (SELECT ATN2(1.79E+309, 1));
GO

-- won't over flow
CREATE PROCEDURE atn2_vu_prepare_p7 AS (SELECT ATN2(1.79E+308, 1));
GO
