drop table if exists babel_3292_t1
go

drop table if exists babel_3292_t2
go

create table babel_3292_t1(a1 int PRIMARY KEY, b1 int, c1 int)
go

create index index_babel_3292_t1_b1 on babel_3292_t1(b1)
go

create index index_babel_3292_t1_c1 on babel_3292_t1(c1)
go

create table babel_3292_t2(a2 int PRIMARY KEY, b2 int, c2 int)
go

create index index_babel_3292_t2_b2 on babel_3292_t2(b2)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

-- Test SELECT queries with and without hints
/*
 * Run a SELECT query without any hints to ensure that un-hinted queries still work.
 * This also ensures that when the SELECT query is not hinted it produces a different plan(bitmap heap scan and bitmap index scan)
 * than the index scan that we're hinting in the query below. This verifies that the next test is actually valid.
 * If the planner was going to choose a sequential scan anyway, the next test wouldn't actually prove that hints were working.
 */
select * from babel_3292_t1 where b1 = 1
go

/*
 * Run SELECT queries and give the hint to follow a index scan using different syntaxes.
 * The query plan should now use a idex scan instead of the bitmap heap and bitmap index scan it uses in the un-hinted test above.
 */
select * from babel_3292_t1 (index(index_babel_3292_t1_b1)) where b1 = 1
go

select * from babel_3292_t1 (index=index_babel_3292_t1_b1) where b1 = 1
go

select * from babel_3292_t1 with(index(index_babel_3292_t1_b1)) where b1 = 1
go

select * from babel_3292_t1 with(index=index_babel_3292_t1_b1) where b1 = 1
go

select * from babel_3292_t1 where b1=1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)))
go

-- Test with multiple index hints
select * from babel_3292_t1 where b1 = 1 and c1 = 1
go

select * from babel_3292_t1 with(index(index_babel_3292_t1_b1), index(index_babel_3292_t1_c1)) where b1 = 1 and c1 = 1
go

select * from babel_3292_t1 where b1 = 1 and c1 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1), index(index_babel_3292_t1_c1)))
go

-- Test with multiple tables
select * from babel_3292_t1, babel_3292_t2 where b1 = 1 and b2 = 1
go

select * from babel_3292_t1 with(index(index_babel_3292_t1_b1)), babel_3292_t2 with(index(index_babel_3292_t2_b2)) where b1 = 1 and b2 = 1
go

select * from babel_3292_t1 with(index=index_babel_3292_t1_b1), babel_3292_t2 with(index=index_babel_3292_t2_b2) where b1 = 1 and b2 = 1
go

select * from babel_3292_t1, babel_3292_t2 where b1 = 1 and b2 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)), table hint(babel_3292_t2, index(index_babel_3292_t2_b2)))
go

-- Test INSERT queries with and without hints
insert into babel_3292_t2 select * from babel_3292_t1 where b1 = 1
go

insert into babel_3292_t2 select * from babel_3292_t1 with(index(index_babel_3292_t1_b1)) where b1 = 1
go

insert into babel_3292_t2 select * from babel_3292_t1 where b1 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)))
go

-- Test UPDATE queries with and without hints
update babel_3292_t1 set a1 = 1 where b1 = 1
go

update babel_3292_t1 with(index(index_babel_3292_t1_b1)) set a1 = 1 where b1 = 1
go

update babel_3292_t1 set a1 = 1 where b1 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)))
go

-- Test DELETE queries with and without hints
delete from babel_3292_t1 where b1 = 1
go

delete from babel_3292_t1 with(index(index_babel_3292_t1_b1)) where b1 = 1
go

delete from babel_3292_t1 where b1 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)))
go

-- Test UNION queries with and without hints
select * from babel_3292_t1 where b1 = 1 UNION select * from babel_3292_t2 where b2 = 1 -- None of the queries have a hint
go

select * from babel_3292_t1 where b1 = 1 UNION select * from babel_3292_t2 with(index=index_babel_3292_t2_b2) where b2 = 1 -- Only one query has a hint
go

select * from babel_3292_t1 where b1 = 1 UNION select * from babel_3292_t2 where b2 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1))) -- Only one query has a hint
go

select * from babel_3292_t1 with(index=index_babel_3292_t1_b1) where b1 = 1 UNION select * from babel_3292_t2 with(index=index_babel_3292_t2_b2) where b2 = 1 -- Both queries have a hint
go

select * from babel_3292_t1 where b1 = 1 UNION select * from babel_3292_t2 where b2 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)), table hint(babel_3292_t2, index(index_babel_3292_t2_b2))) -- Both queries have a hint
go

-- Test CTE queries with and without hints
with babel_3292_t1_cte (a1, b1, c1) as (select * from babel_3292_t1 where b1 = 1) select * from babel_3292_t1_cte where c1 = 1
go

with babel_3292_t1_cte (a1, b1, c1) as (select * from babel_3292_t1 with(index=index_babel_3292_t1_b1) where b1 = 1) select * from babel_3292_t1_cte where c1 = 1
go

with babel_3292_t1_cte (a1, b1, c1) as (select * from babel_3292_t1 where b1 = 1) select * from babel_3292_t1_cte where c1 = 1 option(table hint(babel_3292_t1, index(index_babel_3292_t1_b1)))
go

-- Limitation: Hint given on a CTE is not applied
with babel_3292_t1_cte (a1, b1, c1) as (select * from babel_3292_t1 where b1 = 1) select * from babel_3292_t1_cte with(index=index_babel_3292_t1_c1) where c1 = 1
go

-- Only the hint given on an existing table will be applied
with babel_3292_t1_cte (a1, b1, c1) as (select * from babel_3292_t1 with(index=index_babel_3292_t1_b1) where b1 = 1) select * from babel_3292_t1_cte with(index=index_babel_3292_t1_c1) where c1 = 1
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3292_t1
go

drop table babel_3292_t2
go


-- Test all queries by specifying a database and schema name
use d
go

drop table if exists babel_3292_schema.t1
go

drop table if exists babel_3292_t2
go

drop schema if exists babel_3292_schema
go

create schema babel_3292_schema
go

create table babel_3292_schema.t1(a1 int PRIMARY KEY, b1 int, c1 int)
go

create index index_babel_3292_schema_t1_b1 on babel_3292_schema.t1(b1)
go

create index index_babel_3292_schema_t1_c1 on babel_3292_schema.t1(c1)
go

create table babel_3292_t2(a2 int PRIMARY KEY, b2 int, c2 int)
go

create index index_babel_3292_t2_b2 on babel_3292_t2(b2)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

select * from d.babel_3292_schema.t1 (index(index_babel_3292_schema_t1_b1)) where b1 = 1
go

select * from d.babel_3292_schema.t1 where b1=1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)))
go

select * from d.babel_3292_schema.t1 with(index(index_babel_3292_schema_t1_b1), index(index_babel_3292_schema_t1_c1)) where b1 = 1 and c1 = 1
go

select * from d.babel_3292_schema.t1 where b1 = 1 and c1 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1), index(index_babel_3292_schema_t1_c1)))
go

select * from d.babel_3292_schema.t1 with(index(index_babel_3292_schema_t1_b1)), d.dbo.babel_3292_t2 with(index(index_babel_3292_t2_b2)) where b1 = 1 and b2 = 1
go

select * from d.babel_3292_schema.t1, d.dbo.babel_3292_t2 where b1 = 1 and b2 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)), table hint(d.dbo.babel_3292_t2, index(index_babel_3292_t2_b2)))
go

insert into d.dbo.babel_3292_t2 select * from d.babel_3292_schema.t1 with(index(index_babel_3292_schema_t1_b1)) where b1 = 1
go

insert into d.dbo.babel_3292_t2 select * from d.babel_3292_schema.t1 where b1 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)))
go

update d.babel_3292_schema.t1 with(index(index_babel_3292_schema_t1_b1)) set a1 = 1 where b1 = 1
go

update d.babel_3292_schema.t1 set a1 = 1 where b1 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)))
go

delete from d.babel_3292_schema.t1 with(index(index_babel_3292_schema_t1_b1)) where b1 = 1
go

delete from d.babel_3292_schema.t1 where b1 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)))
go

select * from d.babel_3292_schema.t1 with(index=index_babel_3292_schema_t1_b1) where b1 = 1 UNION select * from d.dbo.babel_3292_t2 with(index=index_babel_3292_t2_b2) where b2 = 1
go

select * from d.babel_3292_schema.t1 where b1 = 1 UNION select * from d.dbo.babel_3292_t2 where b2 = 1 option(table hint(d.babel_3292_schema.t1, index(index_babel_3292_schema_t1_b1)), table hint(d.dbo.babel_3292_t2, index(index_babel_3292_t2_b2))) -- Both queries have a hint
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3292_schema.t1 
go

drop table babel_3292_t2
go

drop schema babel_3292_schema
go
