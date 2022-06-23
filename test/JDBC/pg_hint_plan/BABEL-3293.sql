drop table if exists babel_3293_t1
go

drop table if exists babel_3293_t2
go

create table babel_3293_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3293_t1_b1 on babel_3293_t1(b1)
go

create table babel_3293_t2(a2 int PRIMARY KEY, b2 int)
go

create index index_babel_3293_t2_b2 on babel_3293_t2(b2)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

/*
 * Run a SELECT query joining two tables without any join hints to ensure that un-hinted queries still work.
 * This also ensures that when the SELECT query is not hinted it produces a different plan(hash join)
 * than the other join plans that we're hinting in the queries below. This verifies that the next set of tests are actually valid.
 */
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

/*
 * Give the hints in the queries to follow a specified join plan.
 * The query plan should now use the specified join plan instead of hash join it uses in the un-hinted test above.
 */
select * from babel_3293_t1 inner merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 left outer loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 -- Join query with just table hints
go

-- Join hints through option clause
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(hash join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(merge join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(loop join)
go

-- Queries with both table hints and join hints
select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) inner loop join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) right outer merge join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(loop join, table hint(babel_3293_t1, index(index_babel_3293_t1_b1)), table hint(babel_3293_t2, index(index_babel_3293_t2_b2)))
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3293_t1
go

drop table babel_3293_t2
go


-- Test all queries by specifying a database and schema name
use tempdb
go

drop table if exists babel_3293_schema.t1
go

drop table if exists babel_3293_t2
go

drop schema if exists babel_3293_schema
go

create schema babel_3293_schema
go

create table babel_3293_schema.t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3293_schema_t1_b1 on babel_3293_schema.t1(b1)
go

create table babel_3293_t2(a2 int PRIMARY KEY, b2 int)
go

create index index_babel_3293_t2_b2 on babel_3293_t2(b2)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

select * from tempdb.babel_3293_schema.t1 inner merge join tempdb.dbo.babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from tempdb.babel_3293_schema.t1 with(index(index_babel_3293_schema_t1_b1)) join babel_3293_t2 (index(index_babel_3293_t2_b2)) on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1 -- Join query with just table hints
go

select * from tempdb.babel_3293_schema.t1 join babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(merge join, table hint(tempdb.babel_3293_schema.t1, index(index_babel_3293_schema_t1_b1)), table hint(tempdb.dbo.babel_3293_t2, index(index_babel_3293_t2_b2)))
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3293_schema.t1 
go

drop table babel_3293_t2
go

drop schema babel_3293_schema
go
