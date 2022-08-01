SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME LIKE 'column_domain_usage_vu_prepare%' ORDER BY COLUMN_NAME;
go

USE db_column_domain_usage_vu_prepare;
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME LIKE 'column_domain_usage_vu_prepare%' ORDER BY COLUMN_NAME;
go

use master;
go

drop table column_domain_usage_vu_prepare_tb1;
go

drop type column_domain_usage_vu_prepare_typ1;
go

use db_column_domain_usage_vu_prepare;
go

drop table column_domain_usage_vu_prepare_col_test;
go

drop type column_domain_usage_vu_prepare_NTYP;
go

use master;
go

drop database db_column_domain_usage_vu_prepare;
go
