select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema;
go

create view key_column_usage_vu_verify_view as select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema;
go

create procedure key_column_usage_vu_verify_proc as select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema;
go

create function key_column_usage_vu_verify_func() returns table as return(select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema);
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema;
go

drop function key_column_usage_vu_verify_func;
go

drop procedure key_column_usage_vu_verify_proc;
go

drop view key_column_usage_vu_verify_view;
go

drop table key_column_usage_vu_prepare_tb5;
go

drop table key_column_usage_vu_prepare_tb4;
go

drop table key_column_usage_vu_prepare_tb3;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%' order by table_name,constraint_name,table_schema;
go

drop table key_column_usage_vu_prepare_tb2;
go

drop table key_column_usage_vu_prepare_tb1;
go

