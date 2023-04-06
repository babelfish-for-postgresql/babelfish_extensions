drop table if exists t2;
GO

create table t2(a int);
GO

insert t2 values (1);
insert t2 values (3);
insert t2 values (null);
GO

create view orderby_vu_view_1 as with t1cte AS (
select top(3) a from t2 order by 1
)
select * from t1cte; 
GO

create view orderby_vu_view_2 as 
select top(3) a from t2 order by 1; 
GO

create view orderby_vu_view_3 as
select * from (select top(3) a from t2 order by 1) as b;
GO
