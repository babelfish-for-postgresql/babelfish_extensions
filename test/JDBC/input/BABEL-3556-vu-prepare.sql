-- To test out of range values for fixeddecimal
CREATE TABLE babel_3556_vu_prepare_t1(a fixeddecimal);
GO

CREATE TABLE babel_3556_vu_prepare_t2(a fixeddecimal);
GO

-- decimal
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

INSERT INTO babel_3556_vu_prepare_t1 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_vu_prepare_t1 VALUES(-922337203685478.5808);
GO
-- integral
SELECT CAST(922337203685478 AS fixeddecimal);
GO

SELECT CAST(-922337203685478 AS fixeddecimal);
GO

SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO

INSERT INTO babel_3556_vu_prepare_t1 VALUES(922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t1 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t1 VALUES(1232422322334223423121);
GO


-- To test out of range values for money
CREATE TABLE babel_3556_vu_prepare_t3(a money);
GO

CREATE TABLE babel_3556_vu_prepare_t4(a money);
GO

-- decimal
SELECT CAST($922337203685478.5807 AS money);
GO

SELECT CAST(₧-922337203685478.5808 AS money);
GO

INSERT INTO babel_3556_vu_prepare_t3 VALUES($922337203685478.5807);
GO

INSERT INTO babel_3556_vu_prepare_t3 VALUES(₧-922337203685478.5808);
GO
-- integral
SELECT CAST(₧922337203685478 AS money);
GO

SELECT CAST($-922337203685478 AS money);
GO

SELECT CAST($1232422322334223423121 AS money);
GO

INSERT INTO babel_3556_vu_prepare_t3 VALUES($922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t3 VALUES(₧-922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t3 VALUES(1232422322334223423121);
GO

-- To test out of range values for smallmoney
CREATE TABLE babel_3556_vu_prepare_t5(a smallmoney);
GO

CREATE TABLE babel_3556_vu_prepare_t6(a smallmoney);
GO

-- decimal
SELECT CAST($214748.3648 AS smallmoney);
GO

SELECT CAST(₧-214748.3649 AS smallmoney);
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES($214748.3648);
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES(₧-214748.3649);
GO

-- integer
SELECT CAST($214749 AS smallmoney);
GO

SELECT CAST(₧-214749 AS smallmoney);
GO

SELECT CAST($1232422322334223423121 AS smallmoney);
GO

SELECT CAST(₧-1232422322334223423121 AS smallmoney);
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES($214749);
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES(₧-214749 );
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES($1232422322334223423121);
GO

INSERT INTO babel_3556_vu_prepare_t5 VALUES(₧-1232422322334223423121);
GO

-- cast inside view
CREATE VIEW babel_3556_vu_prepare_v1 AS
    SELECT CAST(CAST(1234 as bigint) as money);
GO

CREATE VIEW babel_3556_vu_prepare_v2 AS
    SELECT CAST(CAST(1234 as bigint) as smallmoney);
GO