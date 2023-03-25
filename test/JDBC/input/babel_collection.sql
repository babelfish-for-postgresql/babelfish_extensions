-- nvarchar is not supported in PG
create table testing1(col nvarchar(60)); -- expect this to fail in the Postgres dialect
GO

CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql" CASCADE;
GO
set babelfishpg_tsql.sql_dialect = "tsql";
GO

-- check the babelfish version
select cast(
    case
        when cast(sys.SERVERPROPERTY('BabelfishVersion') as varchar(20)) LIKE '_._._'
             THEN 'valid'
    else 'invalid'
    end as sys.varchar(20));
GO
-- nvarchar is supported in tsql dialect
create table testing1(col nvarchar(60));
insert into testing1 (col) select N'Muffler';
insert into testing1 (col) select N'Mülle';
insert into testing1 (col) select N'MX Systems';
insert into testing1 (col) select N'Magic';
select * from testing1 order by col;
GO

-- test case insensitive collation
create table testing2 (col varchar(20) collate SQL_Latin1_General_CP1_CI_AS);
GO

insert into testing2 values ('JONES');
insert into testing2 values ('jones');
insert into testing2 values ('Jones');
insert into testing2 values ('JoNes');
insert into testing2 values ('JoNés');
GO

select * from testing2 where col collate BBF_Unicode_General_CS_AS = 'JoNes';
GO
select * from testing2 where col collate BBF_Unicode_General_CI_AS = 'JoNes';
GO
select * from testing2 where col collate BBF_Unicode_General_CI_AI = 'JoNes';
GO
select * from testing2 where col collate BBF_Unicode_General_CS_AI = 'JoNes';
GO

-- test case insensitivity for default collation
create table testing3 (c1 varchar(20), c2 char(20), c3 nvarchar(20));
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing3 values ('JONES','JONES','JONES');
insert into testing3 values ('JoneS','JoneS','JoneS');
insert into testing3 values ('jOnes','jOnes','jOnes');
GO

select c1 from testing3 where c1='jones';
GO
select c2 from testing3 where c2='jones';
GO
select c3 from testing3 where c3='jones';
GO

-- test LIKE to ILIKE transformation
create table testing4 (c1 varchar(20), c2 char(20), c3 nvarchar(20));
create index c1_idx on testing4 (c1);
GO

insert into testing4 values ('JONES','JONES','JONES');
insert into testing4 values ('JoneS','JoneS','JoneS');
insert into testing4 values ('jOnes','jOnes','jOnes');
insert into testing4 values ('abcD','AbcD','ABCd');
insert into testing4 values ('äbĆD','äḃcD','äƀCd');
GO

-- set enable_seqscan doesn't work from the TSQL dialect, so switch
-- dialects, disable sequential scan so we see some index-based plans,
-- then switch back to the TSQL dialect
--
select set_config('enable_seqscan','off','false');
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- test that like is case-insenstive
select c1 from testing4 where c1 LIKE 'jones'; -- this gets converted to '='
GO
explain (costs false) select c1 from testing4 where c1 LIKE 'jones';
GO
select c1 from testing4 where c1 LIKE 'Jon%';
GO
explain (costs false) select c1 from testing4 where c1 LIKE 'Jon%';
GO
select c1 from testing4 where c1 LIKE 'jone_';
GO
explain (costs false) select c1 from testing4 where c1 LIKE 'jone_';
GO
select c1 from testing4 where c1 LIKE '_one_';
GO
explain (costs false) select c1 from testing4 where c1 LIKE '_one_';
GO
select c1 from testing4 where c1 LIKE '%on%s';
GO
explain (costs false) select c1 from testing4 where c1 LIKE '%on%s';
GO
-- test that like is accent-senstive for CI_AS collation
select c1 from testing4 where c1 LIKE 'ab%';
GO
select c1 from testing4 where c1 LIKE 'äb%';
GO
select c1 from testing4 where c1 LIKE 'äḃĆ_';
GO

-- test not like
select c1 from testing4 where c1 NOT LIKE 'jones';
GO
explain (costs false) select c1 from testing4 where c1 NOT LIKE 'jones';
GO
select c1 from testing4 where c1 NOT LIKE 'jone%';
GO
explain (costs false) select c1 from testing4 where c1 NOT LIKE 'jone%';
GO
select c1 from testing4 where c1 NOT LIKE 'ä%';
GO
explain (costs false) select c1 from testing4 where c1 NOT LIKE 'ä%';
GO
-- test escape function and wildcard literal
select c1 from testing4 where c1 LIKE E'\_ones';
GO
explain (costs false) select c1 from testing4 where c1 LIKE E'\_ones';
GO
select c1 from testing4 where c1 LIKE E'\%ones';
GO
explain (costs false) select c1 from testing4 where c1 LIKE E'\%ones';
GO
-- wild card literals are transformed to equal
select c1 from testing4 where c1 LIKE '\%ones';
GO
explain(costs false) select c1 from testing4 where c1 LIKE '\%ones';
GO
select c1 from testing4 where c1 LIKE '\_ones';
GO
explain(costs false) select c1 from testing4 where c1 LIKE '\_ones';
GO
-- test combining with other string functions
select c1 from testing4 where c1 LIKE lower('_ones');
GO
select c1 from testing4 where c1 LIKE upper('_ones');
GO
select c1 from testing4 where c1 LIKE concat('_on','_s');
GO
select c1 from testing4 where c1 LIKE concat('a','%d');
GO
select c1 from testing4 where c1 NOT LIKE lower('%s');
GO
-- test sub-queries
Select * from testing4 where c1 LIKE (select c1 from testing4 where c1 LIKE 'AbcD');
GO
Select * from testing4 where c2 NOT LIKE (select c2 from testing4 where c2 NOT LIKE 'jo%' AND c2 NOT LIKE 'ä%');
GO
Select * from testing4 where c3 LIKE (select c3 from testing4 where c3 NOT LIKE'jo%' AND c3 NOT LIKE 'ä%');
GO
with p1 as (select c1 from testing4 where c1 LIKE '__Ć_'),
p2 as (select c3 from testing4 where c3 LIKE 'äƀ__')
select * from p1 union all select * from p2;
GO
-- test case expression
select c1,(case c1 LIKE 'j%' when true then 1 when false then 2 end) from testing4;
GO
select c2,(case when c2 LIKE '_bc%' then 1 when c2 LIKE 'jon%' then 2 when c3 LIKE 'ä%' then 3 end) from testing4;
GO
-- test that LIKE transformation is applied only for CI_AS column
create table testing5(c1 varchar(20) COLLATE SQL_Latin1_General_CP1_CS_AS);
GO
insert into testing5 values ('JONES');
insert into testing5 values ('JoneS');
insert into testing5 values ('abcD');
insert into testing5 values ('äbĆD');
GO

select * from testing5 where c1 LIKE 'jo%'; -- does not use the transformation
GO
explain(costs false) select * from testing5 where c1 LIKE 'jo%';
GO
select * from testing5 where c1 NOT LIKE 'j%';
GO
select * from testing5 where c1 LIKE 'AB%';
GO

-- test explicitly specify collation as CI_AS, like transformation is also applied.
SELECT 'JONES' like 'jo%';
GO
SELECT 'JONES' COLLATE SQL_Latin1_General_CP1_CI_AS like 'jo%' ;
GO

-- test when pattern is empty string or NULL
SELECT 'JONES' like '';
GO
SELECT 'JONES' like NULL;
GO

SELECT * from testing5 where c1 like '';
GO
explain (costs false) SELECT * from testing5 where c1 like '';
GO
SELECT * from testing5 where c1 like NULL;
GO
explain (costs false) SELECT * from testing5 where c1 like NULL;
GO

SELECT * FROM testing5 where c1 COLLATE French_CI_AS like 'jo%' ;
GO
explain (costs false) SELECT * FROM testing5 where c1 COLLATE French_CI_AS like 'jo%' ;
GO
SELECT * FROM testing5 where c1 COLLATE Chinese_PRC_CI_AS like 'jo%' ;
GO
explain (costs false) SELECT * FROM testing5 where c1 COLLATE Chinese_PRC_CI_AS like 'jo%' ;
GO

-- tsql collations
alter table testing1 alter column col nvarchar(60) collate Arabic_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Chinese_PRC_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Cyrillic_General_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate French_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Korean_Wansung_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Traditional_Spanish_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Modern_Spanish_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate SQL_Latin1_General_CP1_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate SQL_Latin1_General_CP1_CI_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Traditional_Spanish_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Thai_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Turkish_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Ukrainian_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Vietnamese_CS_AS;
GO
alter table testing1 alter column col nvarchar(60) collate Finnish_Swedish_CS_AS;
GO
-- expect different result order from previous select
select * from testing1 order by col;
GO
-- test expression level collate, expect the same result order
select * from testing1 order by col collate Finnish_Swedish_CS_AS;
GO
-- test catalog
select * from sys.fn_helpcollations() order by name;
GO
-- test the TYPE keyword is only required in postgres dialect, but not in tsql dialect
alter table testing1 alter column col varchar(60) collate Finnish_Swedish_CS_AS;
GO
alter table testing1 alter column col TYPE varchar(60) collate Finnish_Swedish_CS_AS;
GO
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
GO
alter table testing1 alter column col varchar(60) collate sys.Finnish_Swedish_CS_AS;
GO
alter table testing1 alter column col TYPE varchar(60) collate sys.Finnish_Swedish_CS_AS;
GO
SELECT set_config('babelfishpg_tsql.sql_dialect', 'tsql', false);
GO
-- test collation list sys table
SELECT collation_name, l1_priority, l2_priority, l3_priority, l4_priority, l5_priority FROM sys.babelfish_collation_list() order by collation_name;
GO
-- clean up
drop table testing1;
GO
drop table testing2;
GO
drop table testing3;
GO
drop table testing4;
GO
drop table testing5;
GO