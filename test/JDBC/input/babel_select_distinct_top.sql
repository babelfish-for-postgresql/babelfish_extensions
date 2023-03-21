--Check if the extension is installed
Select * from pg_extension WHERE extname = 'babelfish_tsql';
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
create table babel_select_distinct_top (a int);
GO
insert into babel_select_distinct_top values (3), (1), (2), (2), (1);
GO
select * from babel_select_distinct_top;
GO
select distinct a from babel_select_distinct_top order by a;
GO
select distinct top(2) a from babel_select_distinct_top order by a;
GO
select * from (select distinct top(2) a from babel_select_distinct_top order by a) b;
GO
select (select distinct top(1) a from babel_select_distinct_top order by a);
GO
select 'foo' where (select distinct top(1) a from babel_select_distinct_top order by a) = 1;
GO
-- Clean up
drop table babel_select_distinct_top;
GO
