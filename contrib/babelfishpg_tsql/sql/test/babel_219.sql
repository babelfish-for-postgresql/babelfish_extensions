-- This test should be run without installing the babelfishpg_tsql extension
-- BABEL-219 test a domain named varchar in schema other than sys
-- is not affected by the fix of BABEL-219
create domain public.varchar as pg_catalog.varchar(2) check (char_length(value) < 1);
select cast('a' as public.varchar); -- throw error
select cast('' as public.varchar);
select cast('a' as varchar); -- pg_catalog.varchar should work

show search_path;
-- Explicitly add pg_catalog to tail of search_path,
-- to force varchar default to public.varchar
select set_config('search_path', current_setting('search_path') || ', pg_catalog', false);
-- Set tsql dialet so the fix for BABEL-219 can kick in
SET babelfishpg_tsql.sql_dialect = 'tsql';
select cast('a' as varchar); -- varchar default to public.varchar. should fail exactly the same way as explicitly specifying public.varchar
select cast('' as varchar); -- varchar default to public.varchar. should pass
create table t1(col varchar);
insert into t1 (col) select 'a'; -- fail
insert into t1 (col) select ''; -- pass
select * from t1;
-- verify behavior of public.varchar is unchanged in tsql dialect
select cast('a' as public.varchar); -- fail
select cast('' as public.varchar); -- pass
create table t2(col public.varchar);
insert into t1 (col) select 'a'; -- fail
insert into t1 (col) select ''; -- pass
select * from t1;

-- Clean up
drop table t1;
drop table t2;
set babelfishpg_tsql.sql_dialect = 'postgres';
-- Reset search_path
set search_path to "$user", public;
show search_path;
