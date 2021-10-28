-- When ANSI_NULLS is ON, the conditions exp = NULL, exp <> NULL and exp != NULL are never true:
CREATE TABLE t_nulls1 (c1 CHAR(1), c2 INT);
INSERT INTO t_nulls1 VALUES ('A', 1);
INSERT INTO t_nulls1 VALUES ('B', NULL);
GO

-- Expect 0 rows
SELECT c1 FROM t_nulls1 WHERE c2 = NULL;
GO

-- Expect 0 rows 
SELECT c1 FROM t_nulls1 WHERE c2 <> NULL;
GO

SELECT c1 FROM t_nulls1 WHERE c2 != NULL;
GO

-- Only IS NULL and IS NOT NULL can be used. Result: A
SELECT c1 FROM t_nulls1 WHERE c2 IS NOT NULL;
GO

SET ANSI_NULLS OFF
GO

-- Expect A 
SELECT c1 FROM t_nulls1 WHERE c2 <> NULL;
GO

SELECT c1 FROM t_nulls1 WHERE c2 != NULL;
GO
 
-- Expect B
SELECT c1 FROM t_nulls1 WHERE c2 = NULL;
GO

-- IS NULL and IS NOT NULL still can be used when ANSI_NULLS is OFF
SELECT c1 FROM t_nulls1 WHERE c2 IS NOT NULL;
GO

-- RESET ANSI_NULLS AND test behavior is back to normal
SET ANSI_NULLS ON

-- Expect 0 rows
SELECT c1 FROM t_nulls1 WHERE c2 = NULL;
GO

-- Expect 0 rows 
SELECT c1 FROM t_nulls1 WHERE c2 <> NULL;
GO

SELECT c1 FROM t_nulls1 WHERE c2 != NULL;
GO

-- Clean up
DROP TABLE t_nulls1;
GO
