-- parallel_query_expected
BEGIN TRAN BABEL4281_T1; 
GO

CREATE TABLE t_babel4281 (a int, b int);
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

select set_config('babelfishpg_tsql.explain_costs', 'off', false);
GO

SET BABELFISH_SHOWPLAN_ALL ON
GO

select a, count(*) from t_babel4281 group by a order by 2; -- should not crash
GO

-- set configurations back
SET BABELFISH_SHOWPLAN_ALL OFF
GO

-- Verify Output
select a, count(*) from t_babel4281 group by a order by 2; -- should not crash
GO

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_costs', 'on', false);
GO

-- Commiting sets parallel_setup_cost, parallel_tuple_cost, min_parallel_table_scan_size back to default
COMMIT TRAN BABEL4281_T1;
GO


DROP TABLE t_babel4281;
GO
