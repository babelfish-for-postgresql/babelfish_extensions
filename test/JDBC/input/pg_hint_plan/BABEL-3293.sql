drop table if exists babel_3293_t1
go

drop table if exists babel_3293_t2
go

drop table if exists babel_3293_t3
go

create table babel_3293_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3293_t1_b1 on babel_3293_t1(b1)
go

create table babel_3293_t2(a2 int PRIMARY KEY, b2 int)
go

create index index_babel_3293_t2_b2 on babel_3293_t2(b2)
go

create table babel_3293_t3(a3 int PRIMARY KEY, b3 int)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

select set_config('babelfishpg_tsql.enable_pg_hint', 'on', false);
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

select * from babel_3293_t1 t1 inner merge join babel_3293_t2 t2 on t1.a1 = t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 left outer loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from BABEL_3293_t1 LeFt ouTer LOOP join Babel_3293_T2 on BABEL_3293_t1.a1 = BABEL_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 -- Join query with just table hints
go

-- Queries with multiple joins
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1 left outer merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t1.a1 = babel_3293_t3.a3
go

select * from babel_3293_t1 left outer merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3  where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 inner merge join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1 left outer loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 inner loop join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1 left outer merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 inner loop join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1 t1 left outer merge join babel_3293_t2 t2 on t1.a1 = t2.a2 inner loop join babel_3293_t3 t3 on t2.a2 = t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

select * from babel_3293_t1, babel_3293_t2 inner merge join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where babel_3293_t1.a1=babel_3293_t3.a3
go

select * from babel_3293_t1 t1, babel_3293_t2 t2 inner merge join babel_3293_t3 t3 on t2.a2 = t3.a3 where t1.a1 = t3.a3
go

select * from babel_3293_t1 t1, babel_3293_t2 t2 inner hash join babel_3293_t3 t3 on t2.a2 = t3.a3
go

select * from BABEL_3293_t1 t1 left outer MERGE join BaBeL_3293_T2 t2 on t1.a1 = t2.a2 InNeR LOOP JOIN bABEL_3293_t3 t3 on t2.a2 = t3.a3 where b1 = 1 and b2 = 1 and b3 = 1
go

-- Join hints through option clause
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(hash join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(merge join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(loop join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1 option(merge join)
go

select * from babeL_3293_T1 join BABEL_3293_T2 on babeL_3293_T1.a1 = BABEL_3293_T2.a2 join babEl_3293_t3 on babel_3293_T2.a2 = BABEL_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1 option(merge join)
go

-- Conflicting join hints
select * from babel_3293_t1 inner hash join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 option(merge join)
go

select * from babel_3293_t1 inner hash join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 option(hash join)
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 option(merge join, loop join)
go

select * from babel_3293_t1 inner loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1 option(merge join)
go

select * from babel_3293_t1 inner loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 inner merge join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1 option(merge join)
go

select * from babel_3293_t1 inner loop join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 inner merge join babel_3293_t3 on babel_3293_t2.a2 = babel_3293_t3.a3 where b1 = 1 and b2 = 1 and b3 = 1 option(merge join, loop join)
go

-- Queries with both table hints and join hints
select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) inner loop join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 with(index(index_babel_3293_t1_b1)) right outer merge join babel_3293_t2 (index(index_babel_3293_t2_b2)) on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(loop join, table hint(babel_3293_t1, index(index_babel_3293_t1_b1)), table hint(babel_3293_t2, index(index_babel_3293_t2_b2)))
go

-- Join hints on nested subqueries are not supported
select * from (select distinct a1 as a1 from babel_3293_t1) s1 inner merge join babel_3293_t2 on s1.a1 = babel_3293_t2.a2
go

select * from (select babel_3293_t1.* from babel_3293_t1 inner merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2) s1 inner join (select babel_3293_t1.* from babel_3293_t1 inner hash join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2) s2 on s1.a1 = s2.a1
go

-- Test FORCE ORDER hints
/**
 * Run a SELECT query with multiple joins such that the join order indicated by the query syntax is not preserved during query optimization.
 * This ensures that when the FORCE ORDER query hint is given in the test below, the join order is preserved.
 * If the join order was to be preserved even without the hint, the next test would not prove that the FORCE ORDER hint is working.
 */
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t1.b1 = babel_3293_t3.b3
go

/*
 * Run the above SELECT query and give the FORCE ORDER query hint to make sure that the join order is preserved
 */
select * from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 join babel_3293_t3 on babel_3293_t1.b1 = babel_3293_t3.b3 option(force order)
go

-- UPDATE and DELETE queries with join hints needs to be revisited later. pg_hint_plan is currently not following the given join hints 
-- Test UPDATE queries with and without hints
update babel_3293_t1 set a1 = 1 from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

update babel_3293_t1 set a1 = 1 from babel_3293_t1 inner merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

update babel_3293_t1 set a1 = 1 from babel_3293_t1 with(index(index_babel_3293_t1_b1)) full outer merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

-- Test DELETE queries with and without hints
delete babel_3293_t1 from babel_3293_t1 join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

delete babel_3293_t1 from babel_3293_t1 inner merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

delete babel_3293_t1 from babel_3293_t1 with(index(index_babel_3293_t1_b1)) left outer merge join babel_3293_t2 on babel_3293_t1.a1 = babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3293_t1
go

drop table babel_3293_t2
go

drop table babel_3293_t3
go

-- Test all queries by specifying a database and schema name
use tempdb
go

drop table if exists babel_3293_schema.t1
go

drop table if exists babel_3293_t2
go

drop table if exists babel_3293_t3
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

create table babel_3293_t3(a3 int PRIMARY KEY, b3 int)
go

set babelfish_showplan_all on
go

select * from tempdb.babel_3293_schema.t1 inner merge join tempdb.dbo.babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1
go

select * from tempdb.babel_3293_schema.t1 with(index(index_babel_3293_schema_t1_b1)) join tempdb.dbo.babel_3293_t2 (index(index_babel_3293_t2_b2)) on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1 -- Join query with just table hints
go

select * from tempdb.babel_3293_schema.t1 join tempdb.dbo.babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 where b1 = 1 and b2 = 1 option(merge join, table hint(tempdb.babel_3293_schema.t1, index(index_babel_3293_schema_t1_b1)), table hint(tempdb.dbo.babel_3293_t2, index(index_babel_3293_t2_b2)))
go

select * from tempdb.babel_3293_schema.t1 join tempdb.dbo.babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 join tempdb.dbo.babel_3293_t3 on tempdb.babel_3293_schema.t1.b1 = tempdb.dbo.babel_3293_t3.b3 option(force order)
go

select * from tempdb.babel_3293_schema.t1 inner loop join tempdb.dbo.babel_3293_t2 on tempdb.babel_3293_schema.t1.a1 = tempdb.dbo.babel_3293_t2.a2 left outer merge join tempdb.dbo.babel_3293_t3 on tempdb.babel_3293_schema.t1.b1 = tempdb.dbo.babel_3293_t3.b3
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3293_schema.t1 
go

drop table babel_3293_t2
go

drop table babel_3293_t3
go

drop schema babel_3293_schema
go
