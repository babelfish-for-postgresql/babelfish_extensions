create table t1(a int);
insert t1 values (1), (1), (3), (null);
GO

create table t2(a int);
insert into t2 select top(3) a from t1 order by 1;
GO

select * from t2 order by 1;
GO

truncate table t1;
truncate table t2;
GO

insert t1 values (1), (1), (1), (1), (2);
GO

insert into t2 select distinct top(2) a from t1 order by 1;
GO

select * from t2 order by 1;
GO

drop table t1;
drop table t2;
GO
