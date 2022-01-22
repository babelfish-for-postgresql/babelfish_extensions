USE master;
go

drop table if exists [babel_'2451];
go
create table [babel_'2451] (a int, b varchar(max), c nvarchar(max));
go
insert into [babel_'2451] values (1, 'DDD','dede');
go
drop table if exists [babel_'2451];
go