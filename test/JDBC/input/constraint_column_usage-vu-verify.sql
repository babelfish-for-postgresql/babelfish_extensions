Use db_constraint_column_usage_vu_prepare;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

Use master;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

use db_constraint_column_usage_vu_prepare;
go

drop table constraint_column_usage_vu_prepare_tbl2;
go
drop table constraint_column_usage_vu_prepare_tbl1;
go
drop table constraint_column_usage_vu_prepare_tbl5;
go
drop table constraint_column_usage_vu_prepare_tbl3;
go
drop table constraint_column_usage_vu_prepare_sc1.constraint_column_usage_vu_prepare_tbl4;
go
drop schema constraint_column_usage_vu_prepare_sc1;
go

use master
go

drop database db_constraint_column_usage_vu_prepare;
go
