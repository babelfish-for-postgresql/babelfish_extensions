use alter_func_db
go

select alter_func_mvu_f1(10);
go

select alter_func_mvu_f4();
go

select Id from alter_func_mvu_f5();
go

use alter_proc_db
go

exec alter_proc_p1 @dateParam = '2020-01-01'
go

exec alter_proc_p3;
go

use alter_func_db
go

alter function alter_func_mvu_f4() returns TABLE as return (select * from alter_func_users)
go
