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


