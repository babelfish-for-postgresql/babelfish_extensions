CREATE TABLE babel_3144_vu_preppare_t1(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

-- values causing overflow in sum (BIGINT,INT)
INSERT INTO babel_3144_vu_preppare_t1 VALUES (9223372036854775807,2147483647,32767,255)
GO

INSERT INTO babel_3144_vu_preppare_t1 VALUES (9223372036854775807,2147483647,32767,255)
GO

-- empty table
CREATE TABLE babel_3144_vu_preppare_t2(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

CREATE TABLE babel_3144_vu_preppare_t3(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO babel_3144_vu_preppare_t3 VALUES(16,8,4,2)
GO

INSERT INTO babel_3144_vu_preppare_t3 VALUES(2,4,8,16)
GO

CREATE TABLE  babel_3144_vu_preppare_t4(sumbigint BIGINT)
GO

INSERT INTO babel_3144_vu_preppare_t4 VALUES(1)
GO

CREATE VIEW babel_3144_vu_prepare_v1 AS SELECT SUM(sumbigint) FROM babel_3144_vu_preppare_t4
GO