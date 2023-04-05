drop table if exists t1;
GO

create table t1(a int);
GO

insert t1 values (1);
insert t1 values (3);
insert t1 values (null);
GO

create view orderby_vu_view as with t1cte AS (
select top(3) a from t1 order by 1
)
select * from t1cte; 
GO

