-- To test out of range values for fixeddecimal
SELECT * FROM babel_3556_before_14_6_vu_prepare_t1;
GO

-- decimal
SELECT * FROM babel_3556_before_14_6_vu_prepare_v1;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v2;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t2 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t2 VALUES(-922337203685478.5808);
GO
-- integral
SELECT * FROM babel_3556_before_14_6_vu_prepare_v3;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v4;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v5;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t2 VALUES(922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t2 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t2 VALUES(1232422322334223423121);
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_t1;
GO

-- procedure
DECLARE @in bigint = 922337203685478;
exec babel_3556_before_14_6_vu_prepare_p1 @in;
GO

DECLARE @in bigint = -922337203685478;
exec babel_3556_before_14_6_vu_prepare_p1 @in;
GO

DECLARE @in bigint = 922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p4 @in, @out;
GO

DECLARE @in bigint = -922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p4 @in, @out;
GO

-- function
DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f1(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f1(@in);
GO

DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f4(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f4(@in);
GO

-- To test out of range values for money
SELECT * FROM babel_3556_before_14_6_vu_prepare_t3;
GO

-- decimal
SELECT * FROM babel_3556_before_14_6_vu_prepare_v6;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v7;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t4 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t4 VALUES(-922337203685478.5808);
GO
-- integral
SELECT * FROM babel_3556_before_14_6_vu_prepare_v8;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v9;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v10;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t4 VALUES(922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t4 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t4 VALUES(1232422322334223423121);
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_t4;
GO

-- procedure
DECLARE @in bigint = 922337203685478;
exec babel_3556_before_14_6_vu_prepare_p2 @in;
GO

DECLARE @in bigint = -922337203685478;
exec babel_3556_before_14_6_vu_prepare_p2 @in;
GO

DECLARE @in bigint = 922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p5 @in, @out;
GO

DECLARE @in bigint = -922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p5 @in, @out;
GO

-- function
DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f2(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f2(@in);
GO

DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f5(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f5(@in);
GO


-- To test out of range values for smallmoney
SELECT * FROM babel_3556_before_14_6_vu_prepare_t5;
GO

-- decimal
SELECT * FROM babel_3556_before_14_6_vu_prepare_v11;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v12;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($214748.3648);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($-214748.3649);
GO

-- integer
SELECT * FROM babel_3556_before_14_6_vu_prepare_v13;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v14;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v15;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v16;
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($214749);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($-214749 );
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t6 VALUES($-1232422322334223423121);
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_t6;
GO

-- procedure
DECLARE @in bigint = 922337203685478;
exec babel_3556_before_14_6_vu_prepare_p3 @in;
GO

DECLARE @in bigint = -922337203685478;
exec babel_3556_before_14_6_vu_prepare_p3 @in;
GO

DECLARE @in bigint = 922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p6 @in, @out;
GO

DECLARE @in bigint = -922337203685478;
DECLARE @out fixeddecimal;
exec babel_3556_before_14_6_vu_prepare_p6 @in, @out;
GO

-- function
DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f3(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f3(@in);
GO

DECLARE @in bigint = 922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f6(@in);
GO

DECLARE @in bigint = -922337203685478;
SELECT * FROM babel_3556_before_14_6_vu_prepare_f6(@in);
GO



-- cast inside view
SELECT * FROM babel_3556_before_14_6_vu_prepare_v17;
GO

SELECT * FROM babel_3556_before_14_6_vu_prepare_v18;
GO


-- clear 

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p1;
GO

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p2;
GO

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p3;
GO

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p4;
GO

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p5;
GO

DROP PROCEDURE babel_3556_before_14_6_vu_prepare_p6;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f1;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f2;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f3;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f4;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f5;
GO

DROP FUNCTION babel_3556_before_14_6_vu_prepare_f6;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v1;
GO
DROP VIEW babel_3556_before_14_6_vu_prepare_v2;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v3;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v4;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v5;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v6;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v7;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v8;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v9;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v10;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v11;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v12;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v13;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v14;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v15;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v16;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v17;
GO

DROP VIEW babel_3556_before_14_6_vu_prepare_v18;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t1;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t2;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t3;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t4;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t5;
GO

DROP TABLE babel_3556_before_14_6_vu_prepare_t6;
GO