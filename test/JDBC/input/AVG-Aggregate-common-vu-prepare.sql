-- max values causing overflow in avg (BIGINT,INT) 
CREATE TABLE avg_agg_vu_prepare_t1(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO avg_agg_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
INSERT INTO avg_agg_vu_prepare_t1 VALUES (9223372036854775807,2147483647,32767,255)
GO

-- empty table should return NULL
CREATE TABLE avg_agg_vu_prepare_t2(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

-- sanity check 
CREATE TABLE avg_agg_vu_prepare_t3(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO avg_agg_vu_prepare_t3 VALUES(16,8,4,2)
INSERT INTO avg_agg_vu_prepare_t3 VALUES(2,4,8,16)
GO

-- min values causing overflow in avg (BIGINT,INT)
CREATE TABLE avg_agg_vu_prepare_t4(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO avg_agg_vu_prepare_t4 VALUES (-9223372036854775808,-2147483648,-32768,0)
INSERT INTO avg_agg_vu_prepare_t4 VALUES (-9223372036854775808,-2147483648,-32768,0)
GO

-- Test OVER,PARTITION,DISTINCT,ORDER BY clause
CREATE TABLE avg_agg_vu_prepare_t5(
col1int INT, col2int INT, col3bigint BIGINT)
GO

INSERT INTO avg_agg_vu_prepare_t5 VALUES (1,100,1000)
INSERT INTO avg_agg_vu_prepare_t5 VALUES (1,200,2000)
INSERT INTO avg_agg_vu_prepare_t5 VALUES (1,300,3000)
INSERT INTO avg_agg_vu_prepare_t5 VALUES (2,100,1000)
INSERT INTO avg_agg_vu_prepare_t5 VALUES (2,100,1000)
INSERT INTO avg_agg_vu_prepare_t5 VALUES (2,200,2000)
GO

CREATE TABLE avg_agg_vu_prepare_t6 (dept char(1),dt DATE,priceint INT,pricebigint BIGINT)
GO

INSERT INTO avg_agg_vu_prepare_t6 VALUES ('A','2022-01-01',31,1000)
INSERT INTO avg_agg_vu_prepare_t6 VALUES ('A','2022-01-02',35,2000)
INSERT INTO avg_agg_vu_prepare_t6 VALUES ('B','2022-01-03',34,2000)
INSERT INTO avg_agg_vu_prepare_t6 VALUES ('B','2022-01-04',33,3000)
INSERT INTO avg_agg_vu_prepare_t6 VALUES ('B','2022-01-05',32,4000)
GO

CREATE TABLE avg_agg_vu_prepare_t7(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO avg_agg_vu_prepare_t7 VALUES(NULL,8,NULL,2)
INSERT INTO avg_agg_vu_prepare_t7 VALUES(10,NULL,8,NULL)
GO

CREATE TABLE avg_agg_vu_prepare_t8(
avgbigint BIGINT, avgint INT , avgsmallint SMALLINT , avgtinyint TINYINT )
GO

INSERT INTO avg_agg_vu_prepare_t8 VALUES(-10,10,-4,2)
INSERT INTO avg_agg_vu_prepare_t8 VALUES(14,-8,8,0)
INSERT INTO avg_agg_vu_prepare_t8 VALUES(NULL,NULL,NULL,NULL)
GO