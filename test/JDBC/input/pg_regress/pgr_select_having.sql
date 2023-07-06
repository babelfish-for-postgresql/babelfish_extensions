--
-- SELECT_HAVING
--

-- load test data
CREATE TABLE test_having (a int, b int, c char(8), d char);
GO
INSERT INTO test_having VALUES (0, 1, 'XXXX', 'A');
GO
INSERT INTO test_having VALUES (1, 2, 'AAAA', 'b');
GO
INSERT INTO test_having VALUES (2, 2, 'AAAA', 'c');
GO
INSERT INTO test_having VALUES (3, 3, 'BBBB', 'D');
GO
INSERT INTO test_having VALUES (4, 3, 'BBBB', 'e');
GO
INSERT INTO test_having VALUES (5, 3, 'bbbb', 'F');
GO
INSERT INTO test_having VALUES (6, 4, 'cccc', 'g');
GO
INSERT INTO test_having VALUES (7, 4, 'cccc', 'h');
GO
INSERT INTO test_having VALUES (8, 4, 'CCCC', 'I');
GO
INSERT INTO test_having VALUES (9, 4, 'CCCC', 'j');
GO

SELECT b, c FROM test_having
	GROUP BY b, c HAVING count(*) = 1 ORDER BY b, c;
GO

-- HAVING is effectively equivalent to WHERE in this case
SELECT b, c FROM test_having
	GROUP BY b, c HAVING b = 3 ORDER BY b, c;
GO

SELECT lower(c), count(c) FROM test_having
	GROUP BY lower(c) HAVING count(*) > 2 OR min(a) = max(a)
	ORDER BY lower(c);
GO

SELECT c, max(a) FROM test_having
	GROUP BY c HAVING count(*) > 2 OR min(a) = max(a)
	ORDER BY c;
GO

-- test degenerate cases involving HAVING without GROUP BY
-- Per SQL spec, these should generate 0 or 1 row, even without aggregates

SELECT min(a), max(a) FROM test_having HAVING min(a) = max(a);
GO
SELECT min(a), max(a) FROM test_having HAVING min(a) < max(a);
GO

-- errors: ungrouped column references
SELECT a FROM test_having HAVING min(a) < max(a);
GO
SELECT 1 AS one FROM test_having HAVING a > 1;
GO

-- the really degenerate case: need not scan table at all
SELECT 1 AS one FROM test_having HAVING 1 > 2;
GO
SELECT 1 AS one FROM test_having HAVING 1 < 2;
GO

-- and just to prove that we aren't scanning the table:
SELECT 1 AS one FROM test_having WHERE 1/a = 1 HAVING 1 < 2;
GO

DROP TABLE test_having;
GO
