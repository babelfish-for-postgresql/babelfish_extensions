SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b DESC
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Using indexes created on old versions, queries cannot be optimized
-- Should see sort step for all following queries
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SELECT set_config('enable_seqscan', 'off', false)
go
SELECT set_config('enable_bitmapscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b DESC
go

SET babelfish_showplan_all OFF
go
SELECT set_config('enable_indexonlyscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go
SELECT set_config('enable_bitmapscan', 'on', false)
go
SELECT set_config('enable_indexonlyscan', 'on', false)
go

-- Recreate indexes
DROP INDEX babel_index_nulls_order_before_15_5_asc_idx_a ON babel_index_nulls_order_before_15_5_tbl
go
DROP INDEX babel_index_nulls_order_before_15_5_desc_idx_b ON babel_index_nulls_order_before_15_5_tbl
go
DROP INDEX babel_index_nulls_order_before_15_5_default_idx_ab ON babel_index_nulls_order_before_15_5_tbl
go

CREATE INDEX babel_index_nulls_order_before_15_5_asc_idx_a ON babel_index_nulls_order_before_15_5_tbl (a ASC)
go
CREATE INDEX babel_index_nulls_order_before_15_5_desc_idx_b ON babel_index_nulls_order_before_15_5_tbl (b DESC)
go
CREATE INDEX babel_index_nulls_order_before_15_5_default_idx_ab ON babel_index_nulls_order_before_15_5_tbl (a, b)
go

-- Check query plans, all aggregations should be optimized
-- into LIMIT + index scan.
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 ORDER BY a
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 ORDER BY a DESC
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' ORDER BY b
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' ORDER BY b DESC
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a = 3 AND b <= 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 AND b = 'xyz' ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go


