-- parallel_query_expected
-- Test to check if initialisation of Parallel Worker crash when babelfishpg_tsql.enable_pg_hint is set
/*
 * Set the enable_pg_hint, try to create parallel worker
 */

exec sp_babelfish_configure 'enable_pg_hint', 'on', 'server'
go

select COUNT( babel_4294_t3.val), babel_4294_t2.val from babel_4294_t1
inner join babel_4294_t2 on babel_4294_t1.id = babel_4294_t2.babel_4294_t1_id
inner join babel_4294_t3 on babel_4294_t1.id = babel_4294_t3.babel_4294_t1_id
GROUP BY babel_4294_t2.val
UNION ALL
select COUNT( babel_4294_t3.val), babel_4294_t2.val from babel_4294_t1
inner join babel_4294_t2 on babel_4294_t1.id = babel_4294_t2.babel_4294_t1_id
inner join babel_4294_t3 on babel_4294_t1.id = babel_4294_t3.babel_4294_t1_id
GROUP BY babel_4294_t2.val
go

-- Used force parallel mode to create a parallel worker
select set_config('force_parallel_mode', '1', false)
go

-- to check if parallel worker generated for following query, will crash or not
select * from babel_4294_t4
go

select set_config('force_parallel_mode', '0', false)
go

exec sp_babelfish_configure 'enable_pg_hint', 'off', 'server'
go