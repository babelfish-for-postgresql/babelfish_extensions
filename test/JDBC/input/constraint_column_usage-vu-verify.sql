Use db_constraint_column_usage;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

Use master;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

use db_constraint_column_usage;
go

drop table constraint_column_usage_tbl2;
go
drop table constraint_column_usage_tbl1;
go
drop table constraint_column_usage_tbl5;
go
drop table constraint_column_usage_tbl3;
go
drop table constraint_column_usage_sc1.constraint_column_usage_tbl4;
go
drop schema constraint_column_usage_sc1;
go

use master
go

drop database db_constraint_column_usage;
go
