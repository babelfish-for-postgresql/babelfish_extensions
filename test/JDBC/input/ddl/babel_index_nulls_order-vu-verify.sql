-- Nulls check
SELECT * FROM babel_index_nulls_order_a_v1
go
SELECT * FROM babel_index_nulls_order_a_v2
go
SELECT * FROM babel_index_nulls_order_a_v3
go
SELECT * FROM babel_index_nulls_order_b_v1
go
SELECT * FROM babel_index_nulls_order_b_v2
go
SELECT * FROM babel_index_nulls_order_b_v3
go
SELECT * FROM babel_index_nulls_order_ab_v1
go
SELECT * FROM babel_index_nulls_order_ab_v2
go
SELECT * FROM babel_index_nulls_order_ab_v3
go
SELECT * FROM babel_index_nulls_order_ab_v4
go
SELECT * FROM babel_index_nulls_order_ab_v5
go
SELECT * FROM babel_index_nulls_order_ab_v6
go

-- Check query plans, all aggregations should be optimized
-- into LIMIT + index scan.
SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'on', false)
go
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go
SELECT set_config('enable_seqscan', 'off', false)
go
SELECT set_config('enable_bitmapscan', 'off', false)
go
SET babelfish_showplan_all ON
go

SELECT TOP 1 a FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_asc_idx_a)) WHERE a <= 5 ORDER BY a DESC
go
SELECT TOP 1 a FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_asc_idx_a)) WHERE a > 5 ORDER BY a ASC
go
SELECT TOP 1 a FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_asc_idx_a)) WHERE a > 5 ORDER BY a
go
SELECT TOP 1 b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_desc_idx_b)) WHERE b <= 'sss' ORDER BY b DESC
go
SELECT TOP 1 b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_desc_idx_b)) WHERE b > 'sss' ORDER BY b ASC
go
SELECT TOP 1 b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_desc_idx_b)) WHERE b > 'sss' ORDER BY b
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_default_idx_ab)) WHERE (a = 3 AND b <= 'sss') ORDER BY b DESC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_default_idx_ab)) WHERE (a = 3 AND b <= 'sss') ORDER BY b ASC
go
SELECT TOP 1 a, b FROM babel_index_nulls_order_tbl WITH (INDEX (babel_index_nulls_order_default_idx_ab))  WHERE (a = 3 AND b <= 'sss') ORDER BY b
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'off', false)
go
SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false)
go
SELECT set_config('enable_seqscan', 'on', false)
go
SELECT set_config('enable_bitmapscan', 'on', false)
go
