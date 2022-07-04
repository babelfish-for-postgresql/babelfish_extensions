-- [BABEL-3306] Support for empty input string handling in datetime, smalldatetime, datetime2, datetimeoffset datatypes

create table #srtestnull_t1 (a varchar(2), dt smalldatetime null);
go
insert into #srtestnull_t1 values ('A', '');
go
select * from #srtestnull_t1;
go
drop table #srtestnull_t1;
go

create table #srtestnull_t2 (a varchar(2), dt datetime null);
go
insert into #srtestnull_t2 values ('A', '');
go
select * from #srtestnull_t2;
go
drop table #srtestnull_t2;
go

create table #srtestnull_t3 (a varchar(2), dt datetime2(4) null);
go
insert into #srtestnull_t3 values ('A', '');
go
select * from #srtestnull_t3;
go
drop table #srtestnull_t3;
go

create table #srtestnull_t4 (a varchar(2), dt datetimeoffset(6) null);
go
insert into #srtestnull_t4 values ('A', '');
go
select * from #srtestnull_t4;
go
drop table #srtestnull_t4;
go

select cast('' as datetime);
go

select cast('' as smalldatetime);
go

select cast('' as datetime2(4));
go

select cast('' as datetimeoffset(6));
go
