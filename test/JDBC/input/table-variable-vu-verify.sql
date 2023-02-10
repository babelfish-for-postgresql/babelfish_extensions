--babel-1149
select * from table_variable_vu_prepareitvf_1(5);
GO

select * from table_variable_vu_preparemstvf_1(10);
GO

select table_variable_vu_preparefunc_1(1);
GO

exec table_variable_vu_prepareproc_1
GO

--babel-2647
SELECT * from dbo.table_variable_vu_preparemstvf_2();
go

--babel-2903
use master;
go

select * from table_variable_vu_preparet1;
go

set BABELFISH_SHOWPLAN_ALL ON;
go

declare @a int = 5, @b int = 5;
declare @c int;
execute table_variable_vu_prepareouter_proc @a, @b;
select @a, @b;
go

set BABELFISH_SHOWPLAN_ALL Off;
go

select * from table_variable_vu_preparet1;
go

--babel-3101
select * from table_variable_vu_preparemy_splitstring('this,is,split')
GO

--babel-3088
use table_variable_vu_preparedb
go

exec table_variable_vu_prepareproc_2 1;
go

use master
go

--babel-2034
SELECT count(*) FROM table_variable_vu_prepareCalculateEasDateTime();
GO

select * from table_variable_vu_preparemstvf_3(1);
GO

--babel-2676
-- should return both rows
select * from table_variable_vu_preparemstvf_conditional(0)
go

-- should only return the first row
select * from table_variable_vu_preparemstvf_conditional(1)
go

-- BABEL-3967 - table variable in sp_executesql is null error
declare @var1 table_variable_vu_type
insert into @var1 values ('1', 2, 3, 4)
exec sp_executesql N'EXEC table_variable_vu_proc1 @x = @p0', N'@p0 table_variable_vu_type readonly', @p0=@var1
go

declare @tableVar table_variable_vu_type;
insert into @tableVar values('1', 2, 3, 4);
declare @ret int;
select @ret = table_variable_vu_tvp_function(@tableVar);
select @ret 
go
