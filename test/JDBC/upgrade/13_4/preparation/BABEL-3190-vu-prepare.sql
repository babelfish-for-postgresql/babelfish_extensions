CREATE DATABASE babel_3190_vu_prepare_db;
go

USE babel_3190_vu_prepare_db;
go

CREATE TABLE babel_3190_vu_prepare_t1(c1 datetime2(0)
                , c2 datetime2(7)
                , c3 datetimeoffset(0)
                , c4 datetimeoffset(7)
                , c5 time(0)
                , c6 time(7))

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('babel_3190_vu_prepare_t1') order by name;
GO

CREATE VIEW v1 as SELECT CAST('12-04-1999' as datetime2);
go
select * from v1;
go
