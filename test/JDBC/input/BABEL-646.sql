create table t1 ( a int )
GO

create procedure my_proc as
PRINT 'OK'
GO

create procedure test_proc1 as
execute my_proc
execute [my_proc]
GO

create procedure test_proc2 as
execute my_proc
execute [my_proc]
GO

create procedure test_proc3 as
execute my_proc
execute [my_proc]
select 123
GO

create procedure test_proc4 as
execute my_proc
execute [my_proc]
insert into t1 values (1)
GO

create procedure test_proc5 as
execute my_proc
execute [my_proc]
update t1 set a = 2
GO

EXEC test_proc1;
GO

EXEC test_proc2;
GO

EXEC test_proc3;
GO

EXEC test_proc4;
GO

select * from t1;
GO

EXEC test_proc5;
GO

select * from t1;
GO

drop procedure test_proc1
GO

drop procedure test_proc2
GO

drop procedure test_proc3
GO

drop procedure test_proc4
GO

drop procedure test_proc5
GO

drop procedure my_proc
GO

drop table t1
GO

