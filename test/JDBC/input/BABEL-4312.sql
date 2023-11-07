CREATE TABLE babel_4312_tbl (a INT, b VARCHAR(10))
go

INSERT INTO babel_4312_tbl VALUES (1, 'abc'), (2, 'def'), (3, 'ghi'), (4, 'jkl'),
								  (5, 'mno'), (6, 'pqr'), (7, 'stu'), (8, 'xyz'),
								  (NULL, NULL)
go

-- Default/ASC index (ASC NULLS FIRST)
CREATE INDEX babel_4312_idx1 ON babel_4312_tbl (a)
go
CREATE INDEX babel_4312_idx2 ON babel_4312_tbl (b ASC)
go

SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b DESC
go

-- Check query plans, all aggregations should be optimized
-- into LIMIT + index scan.
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a ASC
go

SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go

DROP INDEX babel_4312_idx1 ON babel_4312_tbl
go
DROP INDEX babel_4312_idx2 ON babel_4312_tbl
go

-- DESC index (DESC NULLS LAST)
CREATE INDEX babel_4312_idx1 ON babel_4312_tbl (a DESC)
go
CREATE INDEX babel_4312_idx2 ON babel_4312_tbl (b DESC)
go

SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b DESC
go

-- Check query plans, all aggregations should be optimized
-- into LIMIT + index scan.
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_4312_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_4312_tbl WHERE a > 5 ORDER BY a ASC
go

SELECT TOP 1 b FROM babel_4312_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_4312_tbl WHERE b > 'sss' ORDER BY b
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go

DROP TABLE babel_4312_tbl
go
