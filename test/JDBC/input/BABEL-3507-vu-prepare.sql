-- max values causing overflow in avg (BIGINT,INT) 
CREATE TABLE babel_3507_vu_prepare_t1(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
INSERT INTO babel_3507_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
GO

-- empty table should return NULL
CREATE TABLE babel_3507_vu_prepare_t2(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

-- sanity check 
CREATE TABLE babel_3507_vu_prepare_t3(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t3 VALUES(16,8,4,2)
INSERT INTO babel_3507_vu_prepare_t3 VALUES(2,4,8,16)
GO

CREATE TABLE babel_3507_vu_prepare_t4(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t4 VALUES(1,1,1,1)
GO

-- Dependant Functions
CREATE FUNCTION babel_3507_vu_prepare_f1()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    SELECT @ans= AVG(avgint) FROM babel_3507_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3507_vu_prepare_f2()
RETURNS BIGINT AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= AVG(avgbigint) FROM babel_3507_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3507_vu_prepare_f3()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    SELECT @ans= AVG(avgsmallint) FROM babel_3507_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3507_vu_prepare_f4()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    SELECT @ans= AVG(avgtinyint) FROM babel_3507_vu_prepare_t4
    RETURN @ans
END
GO

-- Dependant Procedures
CREATE PROCEDURE babel_3507_vu_prepare_p1
AS
SELECT AVG(avgbigint)as avg_bigint,AVG(avgint)as avg_int,AVG(avgsmallint) as avg_smallint ,AVG(avgtinyint) as avg_tinyint FROM babel_3507_vu_prepare_t4
GO

-- min values causing overflow in avg (BIGINT,INT)
CREATE TABLE babel_3507_vu_prepare_t5(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t5 VALUES (-9223372036854775808,-2147483648,-32768,0)
INSERT INTO babel_3507_vu_prepare_t5 VALUES (-9223372036854775808,-2147483648,-32768,0)
GO

-- Test OVER,PARTITION,DISTINCT,ORDER BY clause
CREATE TABLE babel_3507_vu_prepare_t6(
col1int INT, col2int INT, col3bigint BIGINT)
GO

INSERT INTO babel_3507_vu_prepare_t6 VALUES (1,100,1000)
INSERT INTO babel_3507_vu_prepare_t6 VALUES (1,200,2000)
INSERT INTO babel_3507_vu_prepare_t6 VALUES (1,300,3000)
INSERT INTO babel_3507_vu_prepare_t6 VALUES (2,100,1000)
INSERT INTO babel_3507_vu_prepare_t6 VALUES (2,100,1000)
INSERT INTO babel_3507_vu_prepare_t6 VALUES (2,200,2000)
GO

CREATE TABLE babel_3507_vu_prepare_t7 (dept char(1),dt DATE,priceint INT,pricebigint BIGINT)
GO

INSERT INTO babel_3507_vu_prepare_t7 VALUES ('A','2022-01-01',31,1000)
INSERT INTO babel_3507_vu_prepare_t7 VALUES ('A','2022-01-02',35,2000)
INSERT INTO babel_3507_vu_prepare_t7 VALUES ('B','2022-01-03',34,2000)
INSERT INTO babel_3507_vu_prepare_t7 VALUES ('B','2022-01-04',33,3000)
INSERT INTO babel_3507_vu_prepare_t7 VALUES ('B','2022-01-05',32,4000)
GO

CREATE VIEW babel_3507_vu_prepare_v1 as SELECT 
cast(pg_typeof( AVG( avgbigint ) ) as varchar(48) )  as avg_bigint , 
cast(pg_typeof( AVG( avgint ) ) as varchar(48) )  as avg_int , 
cast(pg_typeof( AVG( avgsmallint ) ) as varchar(48) )  as avg_smallint ,
cast(pg_typeof( AVG( avgtinyint ) ) as varchar(48) )  as avg_tinyint 
FROM babel_3507_vu_prepare_t3
GO

CREATE TABLE babel_3507_vu_prepare_t8(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t8 VALUES(NULL,8,NULL,2)
INSERT INTO babel_3507_vu_prepare_t8 VALUES(10,NULL,8,NULL)
GO

CREATE TABLE babel_3507_vu_prepare_t9(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO babel_3507_vu_prepare_t9 VALUES(-10,10,-4,2)
INSERT INTO babel_3507_vu_prepare_t9 VALUES(14,-8,8,0)
INSERT INTO babel_3507_vu_prepare_t9 VALUES(NULL,NULL,NULL,NULL)
GO