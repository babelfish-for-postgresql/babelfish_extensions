USE db_babel_3190;
go

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('t1') order by name;
GO

drop table t1;
GO

select * from v1;
go
drop view v1;
go

USE master;
go

DROP DATABASE db_babel_3190;
go
