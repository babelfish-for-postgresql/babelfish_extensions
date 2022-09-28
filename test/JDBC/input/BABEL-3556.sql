-- Test valid maximum/minimum/zero values for fixeddecimal
-- to check implicit typecast
CREATE TABLE babel_3556_t1(a fixeddecimal);
GO
-- without qoute
-- decimal
SELECT CAST(922337203685477.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685477.5808 AS fixeddecimal);
GO

SELECT CAST(0 AS fixeddecimal);
GO

INSERT INTO babel_3556_t1 VALUES(922337203685477.5807);
GO

INSERT INTO babel_3556_t1 VALUES(-922337203685477.5808);
GO
-- integral
SELECT CAST(922337203685477 AS fixeddecimal);
GO

SELECT CAST(-922337203685477 AS fixeddecimal);
GO

INSERT INTO babel_3556_t1 VALUES(922337203685477);
GO

INSERT INTO babel_3556_t1 VALUES(-922337203685477);
GO
-- inside qoute
-- decimal
SELECT CAST('922337203685477.5807' AS fixeddecimal);
GO

SELECT CAST('-922337203685477.5808' AS fixeddecimal);
GO

SELECT CAST('0' AS fixeddecimal);
GO


-- integral
SELECT CAST('922337203685477' AS fixeddecimal);
GO

SELECT CAST('-922337203685477' AS fixeddecimal);
GO

-- check if implicit typecast is working
SELECT * FROM babel_3556_t1;
GO

-- Negative test
-- Test out of range value for fixeddecimal

-- without qoute
-- decimal
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

INSERT INTO babel_3556_t1 VALUES(922337203685478.5807);
GO

INSERT INTO babel_3556_t1 VALUES(-922337203685478.5808);
GO
-- integral
SELECT CAST(922337203685478 AS fixeddecimal);
GO

SELECT CAST(-922337203685478 AS fixeddecimal);
GO

SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO

INSERT INTO babel_3556_t1 VALUES(922337203685478);
GO

INSERT INTO babel_3556_t1 VALUES(-922337203685478);
GO

INSERT INTO babel_3556_t1 VALUES(1232422322334223423121);
GO
-- inside qoute
-- decimal
SELECT CAST('922337203685478.5807' AS fixeddecimal);
GO

SELECT CAST('-922337203685478.5808' AS fixeddecimal);
GO

-- integral
SELECT CAST('922337203685478' AS fixeddecimal);
GO

SELECT CAST('-922337203685478' AS fixeddecimal);
GO

SELECT CAST('1232422322334223423121' AS fixeddecimal);
GO

-- check if implicit typecast is working
SELECT * FROM babel_3556_t1;
GO



-- Test valid maximum/minimum/zero values for money
-- to check implicit typecast
CREATE TABLE babel_3556_t2(a money);
GO
-- without qoute
-- decimal
SELECT CAST($922337203685477.5807 AS money);
GO

SELECT CAST(₧-922337203685477.5808 AS money);
GO

SELECT CAST($0 AS money);
GO

INSERT INTO babel_3556_t2 VALUES($922337203685477.5807);
GO

INSERT INTO babel_3556_t2 VALUES(₧-922337203685477.5808);
GO

-- integral
SELECT CAST($922337203685477 AS money);
GO

SELECT CAST(₧-922337203685477 AS money);
GO

INSERT INTO babel_3556_t2 VALUES($922337203685477);
GO

INSERT INTO babel_3556_t2 VALUES(₧-922337203685477);
GO

-- check if implicit typecast is working
SELECT * FROM babel_3556_t2;
GO

-- with qoute
-- decimal
SELECT CAST('$922337203685477.5807' AS money);
GO

SELECT CAST('₧-922337203685477.5808' AS money);
GO

SELECT CAST('$0' AS money);
GO


-- integral
SELECT CAST('$922337203685477' AS money);
GO

SELECT CAST('₧-922337203685477' AS money);
GO




-- Negative test
-- Test out of range value for money

-- without qoute
-- decimal
SELECT CAST($922337203685478.5807 AS money);
GO

SELECT CAST(₧-922337203685478.5808 AS money);
GO


INSERT INTO babel_3556_t2 VALUES($922337203685478.5807);
GO

INSERT INTO babel_3556_t2 VALUES(₧-922337203685478.5808);
GO

-- integer
SELECT CAST($922337203685478 AS money);
GO

SELECT CAST(₧-922337203685478 AS money);
GO

SELECT CAST($1232422322334223423121 AS money);
GO

INSERT INTO babel_3556_t2 VALUES($922337203685478);
GO

INSERT INTO babel_3556_t2 VALUES(₧-922337203685478);
GO

INSERT INTO babel_3556_t2 VALUES($1232422322334223423121);
GO
-- with qoute
-- decimal
SELECT CAST('$922337203685478.5807' AS money);
GO

SELECT CAST('₧-922337203685478.5808' AS money);
GO

-- integer
SELECT CAST('$922337203685478' AS money);
GO

SELECT CAST('₧-922337203685478' AS money);
GO

SELECT CAST('$1232422322334223423121' AS money);
GO

-- Test valid maximum/minimum/zero values for smallmoney
-- to check implicit typecast
CREATE TABLE babel_3556_t3(a smallmoney);
GO
-- without qoute
-- decimal
SELECT CAST($214748.3647 AS smallmoney);
GO

SELECT CAST(₧-214748.3648 AS smallmoney);
GO

SELECT CAST($0 AS smallmoney);
GO

INSERT INTO babel_3556_t3 VALUES($214748.3647);
GO

INSERT INTO babel_3556_t3 VALUES(₧-214748.3648);
GO
-- integer
SELECT CAST($214748 AS smallmoney);
GO

SELECT CAST(₧-214748 AS smallmoney);
GO

INSERT INTO babel_3556_t3 VALUES($214748);
GO

INSERT INTO babel_3556_t3 VALUES(₧-214748 );
GO

-- check if implicit typecast is working
SELECT * FROM babel_3556_t3;
GO

-- inside qoute
-- decimal
SELECT CAST('$214748.3647' AS smallmoney);
GO

SELECT CAST('₧-214748.3648' AS smallmoney);
GO

SELECT CAST('$0' AS smallmoney);
GO

-- integer
SELECT CAST('$214748' AS smallmoney);
GO

SELECT CAST('₧-214748' AS smallmoney);
GO


-- Negative test
-- Test out of range value for smallmoney

-- without qoute
-- decimal
SELECT CAST($214748.3648 AS smallmoney);
GO

SELECT CAST(₧-214748.3649 AS smallmoney);
GO

INSERT INTO babel_3556_t3 VALUES($214748.3648);
GO

INSERT INTO babel_3556_t3 VALUES(₧-214748.3649);
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

INSERT INTO babel_3556_t3 VALUES($214749);
GO

INSERT INTO babel_3556_t3 VALUES(₧-214749 );
GO

INSERT INTO babel_3556_t3 VALUES($922337203685478);
GO

INSERT INTO babel_3556_t3 VALUES(₧-1232422322334223423121);
GO


-- Inside qoute
-- decimal
SELECT CAST('$214748.3648' AS smallmoney);
GO

SELECT CAST('₧-214748.3649' AS smallmoney);
GO

-- integer
SELECT CAST('$214749' AS smallmoney);
GO

SELECT CAST('₧-214749' AS smallmoney);
GO

SELECT CAST('$1232422322334223423121' AS smallmoney);
GO

SELECT CAST('₧-1232422322334223423121' AS smallmoney);
GO


-- Drop tables
DROP TABLE babel_3556_t1;
GO

DROP TABLE babel_3556_t2;
GO

DROP TABLE babel_3556_t3;
GO