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

SET BABELFISH_STATISTICS PROFILE ON
GO

select a, count(*) from t_babel4261 group by a order by 2; -- should not crash
GO


-- set configurations back
SET BABELFISH_STATISTICS PROFILE OFF
GO

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'on', false);
GO

-- Commiting sets parallel_setup_cost, parallel_tuple_cost, min_parallel_table_scan_size back to default
COMMIT TRAN BABEL4261_T1;
GO


DROP TABLE t_babel4261;
GO

