SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

USE db_column_domain_usage;
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

use master;
go

drop table tb1;
go

drop type typ1;
go

use db_column_domain_usage;
go

drop table col_test;
go

drop type NTYP;
go

use master;
go

drop database db_column_domain_usage;
go
