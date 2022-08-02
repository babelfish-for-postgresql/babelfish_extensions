-- resolve to schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1 - gives 1 as an output
select schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f1()
go

-- resolve to dbo.schema_resolution_func_vu_prepare_t1 - gives 0 as an output
select dbo.schema_resolution_func_vu_prepare_f1()
go

-- test sys function 
select schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f2()
go

-- resolve to schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1 - gives 1 as an output
exec schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1;
go

-- cross-db procedure call with a function
use schema_resolution_func_vu_prepare_d1;
go

exec master.schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1;
go

use master;
go

--resolves to schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1 - gives 1 as an output
select schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f4();
go

drop table schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1;
go

-- resolve to dbo.schema_resolution_func_vu_prepare_t1 - gives 0 as an output
exec schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1;
go

drop function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f2()
go

drop table dbo.schema_resolution_func_vu_prepare_t1;
go

-- fails because dbo.schema_resolution_func_vu_prepare_t1 doesn't exist
exec schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1;
go

drop function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f1()
go

drop function dbo.schema_resolution_func_vu_prepare_f1()
go

drop function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f4();
drop view dbo.schema_resolution_func_vu_prepare_v1;
drop function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f3();
drop table schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_t1;
drop proc schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1
go

drop schema schema_resolution_func_vu_prepare_s1;
drop schema schema_resolution_func_vu_prepare_s2;
drop database schema_resolution_func_vu_prepare_d1;
go

