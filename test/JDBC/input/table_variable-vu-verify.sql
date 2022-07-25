--babel-1149
select * from tv_itvf_1(5);
GO

select * from tv_mstvf_1(10);
GO

select tv_func_1(1);
GO

exec tv_proc_1
GO

--babel-2647
SELECT * from dbo.tv_mstvf_2();
go

--babel-2903
use master;
go

select * from tv_t1;
go

set BABELFISH_SHOWPLAN_ALL ON;
go

declare @a int = 5, @b int = 5;
declare @c int;
execute tv_outer_proc @a, @b;
select @a, @b;
go

set BABELFISH_SHOWPLAN_ALL Off;
go

select * from tv_t1;
go

--babel-3101
select * from tv_my_splitstring('this,is,split')
GO

--babel-3088
use tv_db
go

exec tv_proc_2 1;
go

use master
go

--babel-2034
SELECT count(*) FROM tv_CalculateEasDateTime();
GO

select * from tv_mstvf_3(1);
GO

--babel-2676
-- should return both rows
select * from tv_mstvf_conditional(0)
go

-- should only return the first row
select * from tv_mstvf_conditional(1)
go


