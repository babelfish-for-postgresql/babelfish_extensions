create table babel4264(name1 varchar(42), flag1 bit)
go

select * from babel4264 where flag1 = CAST('true' as VARCHAR(20))
go

select * from babel4264 where CAST('true' as VARCHAR(20)) = flag1
go

drop table babel4264
go

create table babel4264(date1 date)
go

select * from babel4264 where date1 = '1955-12-13 12:43:10'
go

drop table babel4264
go