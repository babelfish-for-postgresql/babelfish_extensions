-- [BABEL-2769] Nullable DATETIME column does not store NULL

USE db_babel_2769;
go

SELECT * FROM Smalldatetime2769;
go
DROP TABLE Smalldatetime2769;
go

SELECT * FROM Datetime2769;
go
DROP TABLE Datetime2769;
go

SELECT * FROM Datetime2_2769;
go
DROP TABLE Datetime2_2769;
go

SELECT * FROM Datetimeoffset2769;
go
DROP TABLE Datetimeoffset2769;
go

select * from #srtestnull_t1;
go
drop table #srtestnull_t1;
go

select * from #srtestnull_t2;
go
drop table #srtestnull_t2;
go

select * from #srtestnull_t3;
go
drop table #srtestnull_t3;
go

select * from #srtestnull_t4;
go
drop table #srtestnull_t4;
go

USE master;
go

DROP DATABASE db_babel_2769;
go
