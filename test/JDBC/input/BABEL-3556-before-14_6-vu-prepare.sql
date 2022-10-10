-- To test out of range values for fixeddecimal
CREATE TABLE babel_3556_before_14_6_vu_prepare_t1(a fixeddecimal);
GO

CREATE TABLE babel_3556_before_14_6_vu_prepare_t2(a fixeddecimal);
GO

-- decimal
CREATE VIEW babel_3556_before_14_6_vu_prepare_v1 AS
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v2 AS
SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t1 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t1 VALUES(-922337203685478.5808);
GO

-- integral
CREATE VIEW babel_3556_before_14_6_vu_prepare_v3 AS
SELECT CAST(922337203685478 AS fixeddecimal);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v4 AS
SELECT CAST(-922337203685478 AS fixeddecimal);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v5 AS
SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t1 VALUES(922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t1 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t1 VALUES(1232422322334223423121);
GO


-- To test out of range values for money
CREATE TABLE babel_3556_before_14_6_vu_prepare_t3(a money);
GO

CREATE TABLE babel_3556_before_14_6_vu_prepare_t4(a money);
GO

-- decimal
CREATE VIEW babel_3556_before_14_6_vu_prepare_v6 AS
SELECT CAST($922337203685478.5807 AS money);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v7 AS
SELECT CAST($-922337203685478.5808 AS money);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t3 VALUES($922337203685478.5807);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t3 VALUES($-922337203685478.5808);
GO
-- integral
CREATE VIEW babel_3556_before_14_6_vu_prepare_v8 AS
SELECT CAST($922337203685478 AS money);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v9 AS
SELECT CAST($-922337203685478 AS money);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v10 AS
SELECT CAST($1232422322334223423121 AS money);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t3 VALUES($922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t3 VALUES($-922337203685478);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t3 VALUES(1232422322334223423121);
GO

-- To test out of range values for smallmoney
CREATE TABLE babel_3556_before_14_6_vu_prepare_t5(a smallmoney);
GO

CREATE TABLE babel_3556_before_14_6_vu_prepare_t6(a smallmoney);
GO

-- decimal
CREATE VIEW babel_3556_before_14_6_vu_prepare_v11 AS
SELECT CAST($214748.3648 AS smallmoney);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v12 AS
SELECT CAST($-214748.3649 AS smallmoney);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($214748.3648);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($-214748.3649);
GO

-- integer
CREATE VIEW babel_3556_before_14_6_vu_prepare_v13 AS
SELECT CAST($214749 AS smallmoney);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v14 AS
SELECT CAST($-214749 AS smallmoney);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v15 AS
SELECT CAST($1232422322334223423121 AS smallmoney);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v16 AS
SELECT CAST($-1232422322334223423121 AS smallmoney);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($214749);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($-214749 );
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($1232422322334223423121);
GO

INSERT INTO babel_3556_before_14_6_vu_prepare_t5 VALUES($-1232422322334223423121);
GO

-- cast inside view
CREATE VIEW babel_3556_before_14_6_vu_prepare_v17 AS
    SELECT CAST(CAST(1234 as bigint) as money);
GO

CREATE VIEW babel_3556_before_14_6_vu_prepare_v18 AS
    SELECT CAST(CAST(1234 as bigint) as smallmoney);
GO



-- procedure

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p1 (@val fixeddecimal) AS
SELECT @val AS val
GO

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p2 (@val money) AS
SELECT @val AS val
GO

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p3 (@val smallmoney) AS
SELECT @val AS val
GO

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p4 (@in bigint, @out fixeddecimal OUTPUT) AS
set @out = @in
GO

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p5 (@in bigint, @out smallmoney OUTPUT) AS
set @out = @in
GO

CREATE PROCEDURE  babel_3556_before_14_6_vu_prepare_p6 (@in bigint, @out money OUTPUT) AS
set @out = @in
GO


-- function
CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f1(@val fixeddecimal) 
RETURNS table AS
RETURN SELECT @val 
GO

CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f2(@val money)  
RETURNS table AS
RETURN
SELECT @val 
GO

CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f3(@val smallmoney) 
RETURNS table  AS
RETURN SELECT @val 
GO

CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f4(@val bigint)
RETURNS fixeddecimal AS
BEGIN
RETURN @val;
END
GO

CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f5(@val bigint)
RETURNS money AS
BEGIN
RETURN @val;
END
GO

CREATE FUNCTION babel_3556_before_14_6_vu_prepare_f6(@val bigint)
RETURNS smallmoney AS
BEGIN
RETURN @val;
END
GO
