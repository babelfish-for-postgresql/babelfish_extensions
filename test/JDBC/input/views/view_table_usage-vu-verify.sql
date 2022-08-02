use db_view_table_usage;
go

select * from information_schema.view_table_usage where table_name not like 'sys%';
go

drop view view_table_usage_v1
go

drop table view_table_usage_tb1
go

select * from information_schema.view_table_usage where table_name not like 'sys%';
go

use master;
go

drop database db_view_table_usage;
go