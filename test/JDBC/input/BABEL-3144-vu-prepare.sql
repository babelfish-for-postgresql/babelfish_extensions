-- max values causing overflow in sum (BIGINT,INT) 
CREATE TABLE babel_3144_vu_prepare_t1(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO babel_3144_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
INSERT INTO babel_3144_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
GO

-- empty table
CREATE TABLE babel_3144_vu_prepare_t2(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

CREATE TABLE babel_3144_vu_prepare_t3(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO babel_3144_vu_prepare_t3 VALUES(16,8,4,2)
INSERT INTO babel_3144_vu_prepare_t3 VALUES(2,4,8,16)
GO

CREATE TABLE babel_3144_vu_prepare_t4(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO babel_3144_vu_prepare_t4 VALUES(1,1,1,1)
GO


CREATE FUNCTION babel_3144_vu_prepare_f1()
RETURNS BIGINT AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= SUM(sumint) FROM babel_3144_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3144_vu_prepare_f2()
RETURNS NUMERIC AS
BEGIN
    DECLARE @ans NUMERIC
    SELECT @ans= SUM(sumbigint) FROM babel_3144_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3144_vu_prepare_f3()
RETURNS BIGINT AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= SUM(sumsmallint) FROM babel_3144_vu_prepare_t4
    RETURN @ans
END
GO

CREATE FUNCTION babel_3144_vu_prepare_f4()
RETURNS BIGINT AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= SUM(sumtinyint) FROM babel_3144_vu_prepare_t4
    RETURN @ans
END
GO


CREATE PROCEDURE babel_3144_vu_prepare_p1
AS
SELECT SUM(sumint)as sum_int,SUM(sumsmallint) as sum_smallint ,SUM(sumtinyint) as sum_tinyint FROM babel_3144_vu_prepare_t4
GO

-- min values causing overflow in sum (BIGINT,INT)
CREATE TABLE babel_3144_vu_prepare_t5(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO babel_3144_vu_prepare_t5 VALUES (-9223372036854775808,-2147483648,-32768,0)
INSERT INTO babel_3144_vu_prepare_t5 VALUES (-9223372036854775808,-2147483648,-32768,0)
GO

CREATE TABLE babel_3144_vu_prepare_t6(
col1int INT, col2int INT, col3bigint BIGINT)
GO

INSERT INTO babel_3144_vu_prepare_t6 VALUES (1,100,1000)
INSERT INTO babel_3144_vu_prepare_t6 VALUES (1,200,2000)
INSERT INTO babel_3144_vu_prepare_t6 VALUES (1,300,3000)
INSERT INTO babel_3144_vu_prepare_t6 VALUES (2,100,1000)
INSERT INTO babel_3144_vu_prepare_t6 VALUES (2,100,1000)
INSERT INTO babel_3144_vu_prepare_t6 VALUES (2,200,2000)
GO

CREATE TABLE babel_3144_vu_prepare_t7 (dept char(1),dt DATE,priceint INT,pricebigint BIGINT)
GO

INSERT INTO babel_3144_vu_prepare_t7 VALUES ('A','2022-01-01',31,1000)
INSERT INTO babel_3144_vu_prepare_t7 VALUES ('A','2022-01-02',35,2000)
INSERT INTO babel_3144_vu_prepare_t7 VALUES ('B','2022-01-03',34,2000)
INSERT INTO babel_3144_vu_prepare_t7 VALUES ('B','2022-01-04',33,3000)
INSERT INTO babel_3144_vu_prepare_t7 VALUES ('B','2022-01-05',32,4000)
GO