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

drop table tbl2;
go
drop table tbl1;
go
drop table tbl5;
go
drop table tbl3;
go
drop table sc1.tbl4;
go
drop schema sc1;
go

use master
go

drop database db_constraint_column_usage;
go
