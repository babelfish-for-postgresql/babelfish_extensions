-- test LIKE to ILIKE transformation
create table like_tesing1 (c1 varchar(20), c2 char(20), c3 nvarchar(20))
GO
insert into like_tesing1 values ('JONES','JONES','JONES')
GO
insert into like_tesing1 values ('JoneS','JoneS','JoneS')
GO
insert into like_tesing1 values ('jOnes','jOnes','jOnes')
GO
insert into like_tesing1 values ('abcD','AbcD','ABCd')
GO
insert into like_tesing1 values ('äbĆD','äḃcD','äƀCd')
GO
-- test that like is case-insenstive
select c1 from like_tesing1 where c1 LIKE 'jones'
GO
select c1 from like_tesing1 where c1 LIKE 'Jon%'
GO
select c1 from like_tesing1 where c1 LIKE 'jone_'
GO
select c1 from like_tesing1 where c1 LIKE '_one_'
GO
-- test that like is accent-senstive for CI_AS collation
select c1 from like_tesing1 where c1 LIKE 'ab%'
GO
select c1 from like_tesing1 where c1 LIKE 'äb%'
GO
select c1 from like_tesing1 where c1 LIKE 'äḃĆ_'
GO
-- test not like
select c1 from like_tesing1 where c1 NOT LIKE 'jones'
GO
select c1 from like_tesing1 where c1 NOT LIKE 'jone%'
GO
-- wild card literals are transformed to equal
select c1 from like_tesing1 where c1 LIKE '\%ones'
GO
select c1 from like_tesing1 where c1 LIKE '\_ones'
GO
-- test combining with other string functions
select c1 from like_tesing1 where c1 LIKE lower('_ones')
GO
select c1 from like_tesing1 where c1 LIKE upper('_ones')
GO
select c1 from like_tesing1 where c1 LIKE concat('_on','_s')
GO
select c1 from like_tesing1 where c1 LIKE concat('a','%d')
GO
select c1 from like_tesing1 where c1 NOT LIKE lower('%s')
GO
-- test sub-queries
Select count(*) from like_tesing1 where c1 LIKE (select c1 from like_tesing1 where c1 LIKE 'AbcD')
GO
Select count(*) from like_tesing1 where c2 NOT LIKE (select c2 from like_tesing1 where c2 NOT LIKE 'jo%' AND c2 NOT LIKE 'ä%')
GO
Select count(*) from like_tesing1 where c3 LIKE (select c3 from like_tesing1 where c3 NOT LIKE'jo%' AND c3 NOT LIKE 'ä%')
GO
with p1 as (select c1 from like_tesing1 where c1 LIKE '__Ć_'),
p2 as (select c3 from like_tesing1 where c3 LIKE 'äƀ__')
select * from p1 union all select * from p2
GO
-- test case expression
select c1,(case when c1 LIKE 'j%' then 1 when c1 NOT LIKE 'j%' then 2 end) from like_tesing1
GO
-- test that LIKE transformation is only applied for SQL_LATIN1_GENERAL_CI_AS column
create table like_tesing2(c1 varchar(20) COLLATE SQL_Latin1_General_CP1_CS_AS)
GO
insert into like_tesing2 values ('JONES')
GO
insert into like_tesing2 values ('JoneS')
GO
insert into like_tesing2 values ('abcD')
GO
insert into like_tesing2 values ('äbĆD')
GO
select * from like_tesing2 where c1 LIKE 'jo%'
GO
select * from like_tesing2 where c1 NOT LIKE 'j%'
GO
select * from like_tesing2 where c1 LIKE 'AB%'
GO
-- test eplicitly specify collation as CI_AS, like transformation is also applied.
SELECT CASE WHEN 'JONES' like 'jo%' THEN 1 ELSE 0 END
GO
SELECT CASE WHEN 'JONES' COLLATE SQL_Latin1_General_CP1_CI_AS like 'jo%' THEN 1 ELSE 0 END
GO
-- test when pattern is NULL
SELECT CASE WHEN 'JONES' like '' THEN 1 ELSE 0 END
GO
SELECT * from like_tesing1 where c1 like ''
GO

drop table like_tesing1
GO
drop table like_tesing2
GO
