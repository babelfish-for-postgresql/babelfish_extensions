USE babel_3190_vu_prepare_db;
go

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('babel_3190_vu_prepare_t1') order by name;
GO

drop table babel_3190_vu_prepare_t1;
GO

select * from v1;
go
drop view v1;
go

USE master;
go

DROP DATABASE babel_3190_vu_prepare_db;
go
