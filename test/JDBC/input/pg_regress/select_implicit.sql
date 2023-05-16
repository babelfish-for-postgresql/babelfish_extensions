--
-- SELECT_IMPLICIT
-- Test cases for queries with ordering terms missing from the target list.
-- This used to be called "junkfilter.sql".
-- The parser uses the term "resjunk" to handle these cases.
-- - thomas 1998-07-09
--

-- load test data
CREATE TABLE test_missing_target (a int, b int, c char(8), d char);
GO
INSERT INTO test_missing_target VALUES (0, 1, 'XXXX', 'A');
GO
INSERT INTO test_missing_target VALUES (1, 2, 'ABAB', 'b');
GO
INSERT INTO test_missing_target VALUES (2, 2, 'ABAB', 'c');
GO
INSERT INTO test_missing_target VALUES (3, 3, 'BBBB', 'D');
GO
INSERT INTO test_missing_target VALUES (4, 3, 'BBBB', 'e');
GO
INSERT INTO test_missing_target VALUES (5, 3, 'bbbb', 'F');
GO
INSERT INTO test_missing_target VALUES (6, 4, 'cccc', 'g');
GO
INSERT INTO test_missing_target VALUES (7, 4, 'cccc', 'h');
GO
INSERT INTO test_missing_target VALUES (8, 4, 'CCCC', 'I');
GO
INSERT INTO test_missing_target VALUES (9, 4, 'CCCC', 'j');
GO


--   w/ existing GROUP BY target
SELECT c, count(*) FROM test_missing_target GROUP BY test_missing_target.c ORDER BY c;
GO

--   w/o existing GROUP BY target using a relation name in GROUP BY clause
SELECT count(*) FROM test_missing_target GROUP BY test_missing_target.c ORDER BY c;
GO

--   w/o existing GROUP BY target and w/o existing a different ORDER BY target
--   failure expected
SELECT count(*) FROM test_missing_target GROUP BY a ORDER BY b;
GO

--   w/o existing GROUP BY target and w/o existing same ORDER BY target
SELECT count(*) FROM test_missing_target GROUP BY b ORDER BY b;
GO

--   w/ existing GROUP BY target using a relation name in target
SELECT test_missing_target.b, count(*)
  FROM test_missing_target GROUP BY b ORDER BY b;
GO

--   w/o existing GROUP BY target
SELECT c FROM test_missing_target ORDER BY a;
GO

--   w/o existing ORDER BY target
SELECT count(*) FROM test_missing_target GROUP BY b ORDER BY b desc;
GO

--   group using reference number
SELECT count(*) FROM test_missing_target ORDER BY 1 desc;
GO

--   order using reference number
SELECT c, count(*) FROM test_missing_target GROUP BY 1 ORDER BY 1;
GO

--   group using reference number out of range
--   failure expected
SELECT c, count(*) FROM test_missing_target GROUP BY 3;
GO

--   group w/o existing GROUP BY and ORDER BY target under ambiguous condition
--   failure expected
SELECT count(*) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY b ORDER BY b;
GO

--   order w/ target under ambiguous condition
--   failure NOT expected
SELECT a, a FROM test_missing_target
	ORDER BY a;
GO

--   order expression w/ target under ambiguous condition
--   failure NOT expected
SELECT a/2, a/2 FROM test_missing_target
	ORDER BY a/2;
GO

--   group expression w/ target under ambiguous condition
--   failure NOT expected
SELECT a/2, a/2 FROM test_missing_target
	GROUP BY a/2 ORDER BY a/2;
GO

--   group w/ existing GROUP BY target under ambiguous condition
SELECT x.b, count(*) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b ORDER BY x.b;
GO

--   group w/o existing GROUP BY target under ambiguous condition
SELECT count(*) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b ORDER BY x.b;
GO

--   group w/o existing GROUP BY target under ambiguous condition
--   into a table
SELECT count(*) INTO test_missing_target2
FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b ORDER BY x.b;
GO
SELECT * FROM test_missing_target2;
GO


--  Functions and expressions

--   w/ existing GROUP BY target
SELECT a%2, count(b) FROM test_missing_target
GROUP BY test_missing_target.a%2
ORDER BY test_missing_target.a%2;
GO

--   w/o existing GROUP BY target using a relation name in GROUP BY clause
SELECT count(c) FROM test_missing_target
GROUP BY lower(test_missing_target.c)
ORDER BY lower(test_missing_target.c);
GO

--   w/o existing GROUP BY target and w/o existing a different ORDER BY target
--   failure expected
SELECT count(a) FROM test_missing_target GROUP BY a ORDER BY b;
GO

--   w/o existing GROUP BY target and w/o existing same ORDER BY target
SELECT count(b) FROM test_missing_target GROUP BY b/2 ORDER BY b/2;
GO

--   w/ existing GROUP BY target using a relation name in target
SELECT lower(test_missing_target.c), count(c)
  FROM test_missing_target GROUP BY lower(c) ORDER BY lower(c);
GO

--   w/o existing GROUP BY target
SELECT a FROM test_missing_target ORDER BY upper(d);
GO

--   w/o existing ORDER BY target
SELECT count(b) FROM test_missing_target
	GROUP BY (b + 1) / 2 ORDER BY (b + 1) / 2 desc;
GO

--   group w/o existing GROUP BY and ORDER BY target under ambiguous condition
--   failure expected
SELECT count(x.a) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY b/2 ORDER BY b/2;
GO

--   group w/ existing GROUP BY target under ambiguous condition
SELECT x.b/2, count(x.b) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b/2 ORDER BY x.b/2;
GO

--   group w/o existing GROUP BY target under ambiguous condition
--   failure expected due to ambiguous b in count(b)
SELECT count(b) FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b/2;
GO

--   group w/o existing GROUP BY target under ambiguous condition
--   into a table
SELECT count(x.b) INTO test_missing_target3
FROM test_missing_target x, test_missing_target y
	WHERE x.a = y.a
	GROUP BY x.b/2 ORDER BY x.b/2
SELECT * FROM test_missing_target3;
GO

--   Cleanup
DROP TABLE test_missing_target;
GO
DROP TABLE test_missing_target2;
GO
DROP TABLE test_missing_target3;
GO
