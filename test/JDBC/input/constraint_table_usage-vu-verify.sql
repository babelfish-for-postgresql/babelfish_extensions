use constraint_table_usage_prepare_db;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

drop table constraint_table_usage_prepare_tb4;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

drop table constraint_table_usage_prepare_tb3;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

drop table constraint_table_usage_prepare_tb2;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

drop table constraint_table_usage_prepare_tb1;
go

use master;
go

drop database constraint_table_usage_prepare_db;
go