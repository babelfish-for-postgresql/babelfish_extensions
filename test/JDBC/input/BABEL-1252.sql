use master;
go

create table dttest (d datetime)
go
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) - 100)
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) - (-100))
insert dttest values(100 - cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values((-100) - cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) + 100)
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) + (-100))
insert dttest values(100 + cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values((-100) + cast('10/10/2000 12:34:56.789' as datetime))
go

insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) - 1.5)
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) - (-1.5))
insert dttest values(2.3 - cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values((-2.3) - cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) + .11)
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) + (-.11))
insert dttest values(8.55 + cast('10/10/2000 12:34:56.789' as datetime))
insert dttest values((-9.76) + cast('10/10/2000 12:34:56.789' as datetime))
go

-- should error, out of range
insert dttest values(10000000 + cast('10/10/2000 12:34:56.789' as datetime))
go
insert dttest values(cast('10/10/2000 12:34:56.789' as datetime) - 10000000)
go

select * from dttest
go


create table dttest2 (d smalldatetime)
go
insert dttest2 values(1000 - cast('1/10/1900 12:34:56.789' as smalldatetime))
insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) + 100)
insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) - 10)
insert dttest2 values(100 + cast('10/10/2000 12:34:56.789' as smalldatetime))
go

insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) + 1.5)
insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) - (1.5))
insert dttest2 values(20.3 - cast('1/2/1900 12:34:56.789' as smalldatetime))
insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) + .11)
insert dttest2 values(8.55 + cast('10/10/2000 12:34:56.789' as smalldatetime))
go

-- should error, out of range
insert dttest2 values(100000 + cast('10/10/2000 12:34:56.789' as smalldatetime))
go
insert dttest2 values((-100000)+ cast('10/10/2000 12:34:56.789' as smalldatetime))
go
insert dttest2 values(cast('10/10/2000 12:34:56.789' as smalldatetime) - 10000000)
go

select * from dttest2
go


drop table dttest
drop table dttest2
go