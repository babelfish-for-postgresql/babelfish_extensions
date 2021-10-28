-- Test valid maximum/minimum values for smallmoney
SELECT CAST($214748.3647 AS smallmoney);
GO

SELECT CAST(-214748.3648 AS smallmoney);
GO

SELECT CAST('214748.3647' AS smallmoney);
GO

SELECT CAST('-214748.3648' AS smallmoney);
GO

-- Test valid maximum/minimum values for money
SELECT CAST($922337203685477.5807 AS money);
GO

SELECT CAST(-922337203685477.5808 AS money);
GO

SELECT CAST('922337203685477.5807' AS money);
GO

SELECT CAST('-922337203685477.5808' AS money);
GO

-- Test out of range value for smallmoney
SELECT CAST($214748.3648 AS smallmoney);
GO

SELECT CAST(-214748.3649 AS smallmoney);
GO

SELECT CAST('214748.3648' AS smallmoney);
GO

SELECT CAST('-214748.3649' AS smallmoney);
GO

-- Test out of range values for money
SELECT CAST($922337203685477.5808 AS money);
GO

SELECT CAST(-922337203685477.5809 AS money);
GO

SELECT CAST('922337203685477.5808' AS money);
GO

SELECT CAST('-922337203685477.5809' AS money);
GO

-- Test table insert of max/min/out of range values
CREATE TABLE t1 (a smallmoney, b money)
GO

-- Insert valid values
INSERT INTO t1 VALUES ($214748.3647, 0), (-214748.3648, 0), (0, 922337203685477.5807), (0, -922337203685477.5808)
GO

-- Insert invalid values
INSERT INTO t1 VALUES ($214748.3648, 0)
GO

INSERT INTO t1 VALUES (-214748.3649, 0)
GO

INSERT INTO t1 VALUES (0, 922337203685477.5808)
GO

INSERT INTO t1 VALUES (0, -922337203685477.5809)
GO

-- Clean up
DROP TABLE t1;
GO
