BEGIN TRAN BABEL4261_T1; 
GO

CREATE TABLE t_babel4261 (a int, b int);
GO

-- The third parameter is true to set config back to default after transaction is committed
select set_config('parallel_setup_cost', 0, true);
select set_config('parallel_tuple_cost', 0, true);
select set_config('min_parallel_table_scan_size', 0, true);
GO


-- show explicitly this is a parallel query plan
select set_config('babelfishpg_tsql.explain_timing', 'off', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'off', false);
GO

SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false);
GO

SET BABELFISH_SHOWPLAN_ALL ON
GO

select a, count(*) from t_babel4261 group by a order by 2; -- should not crash
GO

-- set configurations back
SET BABELFISH_SHOWPLAN_ALL OFF
GO

select a, count(*) from t_babel4261 group by a order by 2; -- should not crash
GO

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false);
GO

-- Commiting sets parallel_setup_cost, parallel_tuple_cost, min_parallel_table_scan_size back to default
COMMIT TRAN BABEL4261_T1;
GO


DROP TABLE t_babel4261;
GO



CREATE TABLE t2_babel4261 (a money);
GO

BEGIN TRAN BABEL4261_T2; 
GO

ALTER TABLE t2_babel4261 SET (parallel_workers = 16);  -- note: this is PG syntax, not T-SQL
GO

-- The third parameter is true to set config back to default after transaction is committed
SELECT set_config('force_parallel_mode', '1', true)
SELECT set_config('parallel_setup_cost', '0', true)
SELECT set_config('parallel_tuple_cost', '0', true)
GO

--- INSERT SOME data into t2_babel4261
INSERT t2_babel4261 SELECT 0.4245*10000
INSERT t2_babel4261 SELECT 0.5234*10000
INSERT t2_babel4261 SELECT 0.1113*10000
INSERT t2_babel4261 SELECT 0.6732*10000
INSERT t2_babel4261 SELECT 0.3467*10000
INSERT t2_babel4261 SELECT 0.5213*10000
INSERT t2_babel4261 SELECT 0.9893*10000
INSERT t2_babel4261 SELECT 0.6034*10000
INSERT t2_babel4261 SELECT 0.3334*10000
INSERT t2_babel4261 SELECT 0.8888*10000
GO

SELECT sum(a) FROM t2_babel4261
SELECT sum(a) FROM t2_babel4261   -- should not crash
GO

-- Commiting sets force_parallel_mode, parallel_setup_cost, parallel_tuple_cost back to default
COMMIT TRAN BABEL4261_T2;
GO

DROP TABLE t2_babel4261;
GO

