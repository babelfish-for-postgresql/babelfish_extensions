select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create view view_column_usage_v1 as select * from view_column_usage_tb1;
go

create view view_column_usage_v2 as select * from view_column_usage_tb2;
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create procedure view_column_usag_proc as select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create function view_column_usag_func() returns table as return(select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name);
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

drop function view_column_usag_func

drop procedure view_column_usag_proc

drop view view_column_usage_v2
go

drop view view_column_usage_v1
go

drop table view_column_usage_tb2
go

drop table view_column_usage_tb1
go