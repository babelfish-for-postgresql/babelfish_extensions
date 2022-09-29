-- To test out of range values for fixeddecimal
SELECT * FROM babel_3556_vu_prepare_t1;
GO

-- decimal
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

INSERT INTO babel_3556_vu_prepare_t2 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_vu_prepare_t2 VALUES(-922337203685478.5808);
GO
-- integral
SELECT CAST(922337203685478 AS fixeddecimal);
GO

SELECT CAST(-922337203685478 AS fixeddecimal);
GO

SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO

INSERT INTO babel_3556_vu_prepare_t2 VALUES(922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t2 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t2 VALUES(1232422322334223423121);
GO

SELECT * FROM babel_3556_vu_prepare_t1;
GO

-- To test out of range values for money
SELECT * FROM babel_3556_vu_prepare_t3;
GO

-- decimal
SELECT CAST(922337203685478.5807 AS money);
GO

SELECT CAST(-922337203685478.5808 AS money);
GO

INSERT INTO babel_3556_vu_prepare_t4 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_vu_prepare_t4 VALUES(-922337203685478.5808);
GO
-- integral
SELECT CAST(922337203685478 AS money);
GO

SELECT CAST(-922337203685478 AS money);
GO

SELECT CAST(1232422322334223423121 AS money);
GO

INSERT INTO babel_3556_vu_prepare_t4 VALUES(922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t4 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t4 VALUES(1232422322334223423121);
GO

SELECT * FROM babel_3556_vu_prepare_t4;
GO

-- To test out of range values for smallmoney
SELECT * FROM babel_3556_vu_prepare_t5;
GO

-- decimal
SELECT CAST($214748.3648 AS smallmoney);
GO

SELECT CAST(₧-214748.3649 AS smallmoney);
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES($214748.3648);
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES(₧-214748.3649);
GO

-- integer
SELECT CAST($214749 AS smallmoney);
GO

SELECT CAST(₧-214749 AS smallmoney);
GO

SELECT CAST($922337203685478 AS smallmoney);
GO

SELECT CAST(₧-1232422322334223423121 AS smallmoney);
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES($214749);
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES(₧-214749 );
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES($922337203685478);
GO

INSERT INTO babel_3556_vu_prepare_t6 VALUES(₧-1232422322334223423121);
GO

SELECT * FROM babel_3556_vu_prepare_t6;
GO

-- cast inside view
SELECT * FROM babel_3556_vu_prepare_v1;
GO

SELECT * FROM babel_3556_vu_prepare_v2;
GO

DROP VIEW babel_3556_vu_prepare_v1;
GO

DROP VIEW babel_3556_vu_prepare_v2;
GO

DROP TABLE babel_3556_vu_prepare_t1;
GO

DROP TABLE babel_3556_vu_prepare_t2;
GO

DROP TABLE babel_3556_vu_prepare_t3;
GO

DROP TABLE babel_3556_vu_prepare_t4;
GO

DROP TABLE babel_3556_vu_prepare_t5;
GO

DROP TABLE babel_3556_vu_prepare_t6;
GO