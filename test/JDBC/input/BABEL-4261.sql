CREATE TABLE t_babel4261 (a int, b int);
GO

select set_config('parallel_setup_cost', 0, false);
select set_config('parallel_tuple_cost', 0, false);
select set_config('min_parallel_table_scan_size', 0, false);
GO

select a, count(*) from t_babel4261 group by a order by 2; -- should not crash
GO

DROP TABLE t_babel4261;
GO

