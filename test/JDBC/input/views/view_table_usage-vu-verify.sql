select * from information_schema.view_table_usage where view_name like 'view_table_usage_v%' order by view_name;
go

create view view_table_usage_v1 as select * from view_table_usage_tb1;
go

select * from information_schema.view_table_usage where view_name like 'view_table_usage_v%' order by view_name;
go

create procedure view_table_usag_proc as select * from information_schema.view_table_usage where view_name like 'view_table_usage_v%' order by view_name;
go

create function view_table_usag_func() returns table as return(select * from information_schema.view_table_usage where view_name like 'view_table_usage_v%' order by view_name);
go

select * from information_schema.view_table_usage where view_name like 'view_table_usage_v%' order by view_name;
go

drop function view_table_usag_func

drop procedure view_table_usag_proc

drop view view_table_usage_v1
go

drop table view_table_usage_tb1
go