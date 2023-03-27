-- This test should be run without installing the babelfishpg_tsql extension
-- BABEL-219 test a domain named varchar in schema other than sys
-- is not affected by the fix of BABEL-219
create domain public.varchar as pg_catalog.varchar(2) check (char_length(value) < 1);
GO
select cast('a' as public.varchar); -- throw error
GO
select cast('' as varchar);
GO
select cast('a' as varchar); -- pg_catalog.varchar should work
GO

SELECT @@search_path;
GO
-- Explicitly add pg_catalog to tail of search_path,
-- to force varchar default to public.varchar
select set_config('search_path', current_setting('search_path') + ', pg_catalog', false);
GO
-- Set tsql dialet so the fix for BABEL-219 can kick in
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select cast('a' as varchar); -- varchar default to public.varchar. should fail exactly the same way as explicitly specifying public.varchar
GO
select cast('' as varchar); -- varchar default to public.varchar. should pass
GO
create table t1(col varchar);
insert into t1 (col) select 'a'; -- fail
insert into t1 (col) select ''; -- pass
select * from t1;
GO

-- verify behavior of public.varchar is unchanged in tsql dialect
select cast('a' as public.varchar); -- fail
GO
select cast('' as public.varchar); -- pass
GO
create table t2(col varchar);
GO
insert into t1 (col) select 'a'; -- fail
insert into t1 (col) select ''; -- pass
select * from t1;
GO

-- Clean up
drop table t1;
GO
drop table t2;
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'postgres';
GO
-- Reset search_path
EXEC search_path to "$user", public;
SELECT @@search_path;
GO