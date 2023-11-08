SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b DESC
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Using indexes created on old versions, queries cannot be optimized
-- Should see sort step for all following queries
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b DESC
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go

-- Recreate indexes
DROP INDEX babel_index_nulls_order_before_15_4_asc_idx_a ON babel_index_nulls_order_before_15_4_tbl
go
DROP INDEX babel_index_nulls_order_before_15_4_desc_idx_b ON babel_index_nulls_order_before_15_4_tbl
go
DROP INDEX babel_index_nulls_order_before_15_4_default_idx_ab ON babel_index_nulls_order_before_15_4_tbl
go

CREATE INDEX babel_index_nulls_order_before_15_4_asc_idx_a ON babel_index_nulls_order_before_15_4_tbl (a ASC)
go
CREATE INDEX babel_index_nulls_order_before_15_4_desc_idx_b ON babel_index_nulls_order_before_15_4_tbl (b DESC)
go
CREATE INDEX babel_index_nulls_order_before_15_4_default_idx_ab ON babel_index_nulls_order_before_15_4_tbl (a, b)
go

-- Check query plans, all aggregations should be optimized
-- into LIMIT + index scan.
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_4_tbl WHERE b > 'sss' ORDER BY b DESC
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_4_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go


