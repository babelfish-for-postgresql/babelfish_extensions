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
