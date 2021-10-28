CREATE TABLE t (k INT, c INT)
CREATE TABLE t2 (k INT, c1 INT, c2 INT)
GO

-- test case 1: @v = column
DECLARE @a INT
SET @a = 0
DECLARE @b INT
SET @b = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c, k = 3 WHERE k = 1
UPDATE t SET k = 4, @b = c WHERE k = 2
SELECT * FROM t ORDER BY k
SELECT @a, @b

DELETE FROM t
GO

-- test case 2: @v = expression
DECLARE @a INT
SET @a = 0
DECLARE @b INT
SET @b = 0
DECLARE @d INT
SET @d = 100
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c + 100, k = 3 WHERE k = 1
UPDATE t SET @b = @d + 100, k = 4 WHERE k = 2
SELECT * FROM t ORDER BY k
SELECT @a, @b

DELETE FROM t
GO

-- test case 3: @v = column = value
DECLARE @a INT
SET @a = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c = 40 WHERE k = 1
SELECT * FROM t ORDER BY k
SELECT @a

DELETE FROM t
GO

-- test case 4: @v = CASE clause / parens
DECLARE @a INT
DECLARE @b INT
SET @a = 0
SET @b = 0
INSERT INTO t2 VALUES (1, 10, 30)
INSERT INTO t2 VALUES (2, 20, 40)
UPDATE t2 SET @a = CASE WHEN c1 = 10 THEN 30 ELSE 40 END, c2 = 50 WHERE k = 1
UPDATE t2 SET @b = (SELECT c1 FROM t2 WHERE k = 2), c2 = 60 WHERE k = 2
SELECT * FROM t2 ORDER BY k
SELECT @a, @b

DELETE FROM t2
GO

-- test case 5: @v = column with no WHERE clause
-- @v will be mapped to the last row of available value
DECLARE @a INT
SET @a = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c, k = 3
SELECT * FROM t ORDER BY k
SELECT @a

DELETE FROM t
GO

-- test case 6: @v1 = column, @v2 = column
DECLARE @a INT
SET @a = 0
DECLARE @b INT
SET @b = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c, @b = c, k = 3 WHERE k = 1
SELECT * FROM t ORDER BY k
SELECT @a, @b

DELETE FROM t
GO

-- test case 7: @v1 = column which is updated at the same time
-- INCORRECT RESULT: since OUTPUT clause is unsupported, we will make use of RETURNING clause
-- which will return the updated value. What we really interested is the pre-update values
-- We will need to update this case after BABEL-588 is fixed.
DECLARE @a INT
SET @a = 0
DECLARE @b INT
SET @b = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c, c = 70 WHERE k = 1
UPDATE t SET c = 80, @b = c WHERE k = 2
SELECT * FROM t ORDER BY k
SELECT @a, @b

DELETE FROM t
GO

-- test case 8: @v1 = column with no table updates
-- UNSUPPORTED
DECLARE @a INT
SET @a = 0
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c WHERE k = 1
SELECT * FROM t ORDER BY k
SELECT @a

DELETE FROM t
GO

-- test case 9: @v1 = column and column = @v2 at the same time
DECLARE @a INT
SET @a = 0
DECLARE @b INT
SET @b = 3
INSERT INTO t VALUES (1, 10)
INSERT INTO t VALUES (2, 20)
UPDATE t SET @a = c, k = @b WHERE k = 1
SELECT * FROM t ORDER BY k
SELECT @a, @b

DELETE FROM t
GO

-- test case 10: @v1 = column with OUTPUT clause
-- this test is disabled as OUTPUT clause is not yet supported: BABEL-588
-- UNSUPPORTED
-- DECLARE @a INT
-- SET @a = 0
-- INSERT INTO t VALUES (1, 10)
-- INSERT INTO t VALUES (2, 20)
-- UPDATE t SET @a = c, k = 3 OUTPUT deleted.* WHERE k = 1
-- SELECT * FROM t ORDER BY k
-- SELECT @a
-- DELETE FROM t
-- GO

-- SELECT SET with CASE statement with correct parser behavior on second '='
DECLARE @a INT
SET @a = 0
INSERT INTO t VALUES (1, 10)
SELECT @a = CASE WHEN c = 10 THEN 1 ELSE 2 END FROM t
SELECT @a

DELETE FROM t
GO


-- SELECT SET with parameters with correct parser behavior on second '='
DECLARE @a INT
SET @a = 0
INSERT INTO t VALUES (1, 10)
SELECT @a = ( SELECT c FROM t WHERE k = 1 )
SELECT @a

DELETE FROM t
GO

-- clean up
DROP TABLE t
DROP TABLE t2
GO