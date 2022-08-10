use db_view_column_usage;
go

select * from information_schema.view_column_usage where table_name not like 'sys%';
go

drop view view_column_usage_v1
go

drop table view_column_usage_tb1
go

select * from information_schema.view_column_usage where table_name not like 'sys%';
go

use master;
go

drop database db_view_column_usage;
go 