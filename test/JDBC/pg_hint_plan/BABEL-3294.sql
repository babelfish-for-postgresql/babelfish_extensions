drop table if exists babel_3294_t1
go

create table babel_3294_t1(a1 int)
go

alter table babel_3294_t1 set (parallel_workers = 16)
go

-- Encourage use of parallel plans
select set_config('force_parallel_mode', '1', false)
go

select set_config('parallel_setup_cost', '0', false)
go

select set_config('parallel_tuple_cost', '0', false)
go

select set_config('babelfishpg_tsql.enable_hint_mapping', 'on', false)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

/*
 * Run a SELECT query without any hints to ensure that un-hinted queries still work
 * It uses 2 workers as it is the deault value for the GUC max_parallel_workers_per_gather
 */
select * from babel_3294_t1 t1 where a1 = 1
go

/*
 * The MAXDOP hint should be handled specially the hint value is 0
 * This is because in T-SQL, setting MAXDOP to 0 allows SQL Server to use all the available processors up to 64 processors
 * However, if we set the GUC max_parallel_workers_per_gather to 0, it disables parallelism in P-SQL
 * Thus, we need to set the GUC value to 64 instead. The planner however will use 16 workers as we only have 16 workers available
 */
select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 0)
go

/*
 * Run SELECT queries and give the MAXDOP hint with different values to verify the hint is actually getting mapped
 */
select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 1)
go

select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 2)
go

select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 4)
go

select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 8)
go

select * from babel_3294_t1 t1 where a1 = 1 option(maxdop 16)
go

set babelfish_showplan_all off
go

-- cleanup
select set_config('babelfishpg_tsql.explain_costs', 'on', false)
go

select set_config('force_parallel_mode', '0', false)
go

select set_config('babelfishpg_tsql.enable_hint_mapping', 'off', false)
go

drop table babel_3294_t1
go
