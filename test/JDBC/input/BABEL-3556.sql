-- Test valid maximum/minimum/zero values for fixeddecimal

-- without qoute
-- decimal
SELECT CAST(922337203685477.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685477.5808 AS fixeddecimal);
GO

SELECT CAST(0 AS fixeddecimal);
GO

-- integral
SELECT CAST(922337203685477 AS fixeddecimal);
GO

SELECT CAST(-922337203685477 AS fixeddecimal);
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

-- Negative test
-- Test out of range value for fixeddecimal

-- without qoute
-- decimal
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

-- integral
SELECT CAST(922337203685478 AS fixeddecimal);
GO

SELECT CAST(-922337203685478 AS fixeddecimal);
GO

SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO


-- inside qoute
-- decimal
SELECT CAST(922337203685478.5807 AS fixeddecimal);
GO

SELECT CAST(-922337203685478.5808 AS fixeddecimal);
GO

-- integral
SELECT CAST(922337203685478 AS fixeddecimal);
GO

SELECT CAST(-922337203685478 AS fixeddecimal);
GO

SELECT CAST(1232422322334223423121 AS fixeddecimal);
GO

-- Test valid maximum/minimum/zero values for money

-- without qoute
-- decimal
SELECT CAST($922337203685477.5807 AS money);
GO

SELECT CAST(₧-922337203685477.5808 AS money);
GO

SELECT CAST($0 AS money);
GO

-- integral
SELECT CAST($922337203685477 AS money);
GO

SELECT CAST(₧-922337203685477 AS money);
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

-- integer
SELECT CAST($922337203685478 AS money);
GO

SELECT CAST(₧-922337203685478 AS money);
GO

SELECT CAST($1232422322334223423121 AS money);
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

-- without qoute
-- decimal
SELECT CAST($214748.3647 AS smallmoney);
GO

SELECT CAST(₧-214748.3648 AS smallmoney);
GO

SELECT CAST($0 AS smallmoney);
GO

-- integer
SELECT CAST($214748 AS smallmoney);
GO

SELECT CAST(₧-214748 AS smallmoney);
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

-- integer
SELECT CAST($214749 AS smallmoney);
GO

SELECT CAST(₧-214749 AS smallmoney);
GO

SELECT CAST($1232422322334223423121 AS smallmoney);
GO

SELECT CAST(₧-1232422322334223423121 AS smallmoney);
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