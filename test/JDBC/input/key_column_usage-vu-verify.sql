use key_column_usage_vu_prepare_db;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%';
go

drop table key_column_usage_vu_prepare_tb4;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%';
go

drop table key_column_usage_vu_prepare_tb3;
go 

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%';
go

drop table key_column_usage_vu_prepare_tb2;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_vu_prepare_tb%';
go

drop table key_column_usage_vu_prepare_tb1;
go

use master;
go

drop database key_column_usage_vu_prepare_db;
go
