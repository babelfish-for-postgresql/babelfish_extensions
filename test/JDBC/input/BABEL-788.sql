
drop table if exists babel_788_int;
GO

create table babel_788_int(a int null, b int not null);
GO

insert babel_788_int values (1, 10);
insert babel_788_int values (3, 7);
insert babel_788_int values (null, 8);
GO

select * from babel_788_int order by a;
GO
select * from babel_788_int order by a asc;
GO
select * from babel_788_int order by a desc;
GO

select * from babel_788_int order by b;
GO
select * from babel_788_int order by b asc;
GO
select * from babel_788_int order by b desc;
GO

select * from babel_788_int order by a + b;
GO
select * from babel_788_int order by a + b asc;
GO
select * from babel_788_int order by a + b desc;
GO

select * from (select top(2) a from babel_788_int order by 1) s;
GO

drop table if exists babel_788_select_into;
GO
select top(2) a into babel_788_select_into from babel_788_int order by 1;
GO
select * from babel_788_select_into;
GO

drop table if exists babel_788_subquery_select_into;
GO
select * into babel_788_subquery_select_into from (select top(2) a from babel_788_int order by 1) s;
GO
select * from babel_788_subquery_select_into;
GO

drop table if exists babel_788_int;
GO
drop table if exists babel_788_select_into;
GO
drop table if exists babel_788_subquery_select_into;
GO

drop table if exists babel_788_varchar;
GO

create table babel_788_varchar(a varchar(2) null, b varchar(2) not null);
GO

insert babel_788_varchar values ('1', '10');
insert babel_788_varchar values ('3', '7');
insert babel_788_varchar values ('', ' ');
insert babel_788_varchar values (null, '8');
GO

select * from babel_788_varchar order by a;
GO
select * from babel_788_varchar order by a asc;
GO
select * from babel_788_varchar order by a desc;
GO

select * from babel_788_varchar order by b;
GO
select * from babel_788_varchar order by b asc;
GO
select * from babel_788_varchar order by b desc;
GO

select * from babel_788_varchar order by a + b;
GO
select * from babel_788_varchar order by a + b asc;
GO
select * from babel_788_varchar order by a + b desc;
GO
drop table if exists babel_788_varchar;
GO
