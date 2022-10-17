create table t_2390(a int);
insert into t_2390 values (1), (2);
GO

-- query hint option should be ignored
DECLARE @a int
DECLARE c_byname CURSOR STATIC LOCAL FOR select a from t_2390 order by a option (maxdop 1)
open c_byname
fetch c_byname into @a
select @a
close c_byname
GO

-- table hint shoudl be ignored
DECLARE @a int
DECLARE c_byname CURSOR STATIC LOCAL FOR select a from t_2390 with (TABLOCK) order by a
open c_byname
fetch c_byname into @a
select @a
close c_byname
GO

drop table t_2390;
GO
