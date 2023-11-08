SELECT * FROM babel_index_nulls_order_before_15_5_a_v1
go
SELECT * FROM babel_index_nulls_order_before_15_5_a_v2
go
SELECT * FROM babel_index_nulls_order_before_15_5_a_v3
go
SELECT * FROM babel_index_nulls_order_before_15_5_b_v1
go
SELECT * FROM babel_index_nulls_order_before_15_5_b_v2
go
SELECT * FROM babel_index_nulls_order_before_15_5_b_v3
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v1
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v2
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v3
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v4
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v5
go
SELECT * FROM babel_index_nulls_order_before_15_5_ab_v6
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 OR a IS NULL ORDER BY a
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' OR b IS NULL ORDER BY b
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a
go

-- Using indexes created on old versions, queries cannot be optimized
-- Should see sort step for all following queries
SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'on', false)
go
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a)) 
WHERE a <= 5 OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a))
WHERE a > 5 OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a))
WHERE a > 5 OR a IS NULL ORDER BY a
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b <= 'sss' OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b > 'sss' OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b > 'sss' OR b IS NULL ORDER BY b
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab)) 
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
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
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a)) 
WHERE a <= 5 OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a))
WHERE a > 5 OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_asc_idx_a))
WHERE a > 5 OR a IS NULL ORDER BY a
go

SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b <= 'sss' OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b > 'sss' OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_desc_idx_b))
WHERE b > 'sss' OR b IS NULL ORDER BY b
go

SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab)) 
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WITH (INDEX (babel_index_nulls_order_before_15_5_default_idx_ab))
WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'off', false)
go
SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false)
go
