Use constraint_column_usage_vu_prepare_db;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME LIKE 'constraint_column_usage_vu_prepare%' ORDER BY COLUMN_NAME;
go

Use master;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME LIKE 'constraint_column_usage_vu_prepare%' ORDER BY COLUMN_NAME;
go

use constraint_column_usage_vu_prepare_db;
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

drop database constraint_column_usage_vu_prepare_db;
go
