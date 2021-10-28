create table cctab (a int, b as a*10, c int)
go
insert cctab values (1,2)
go
select * from cctab
go

-- Expect Error
insert into cctab values (1,2,3)
go

create table cctab2 (a int identity, b as a+10, c int)
go
insert cctab2 values (1)
go
select * from cctab2
go

create table cctab3 (a int, c int, b as a*10)
go
insert cctab3 values (1,2)
go
select * from cctab3
go

create table cctab4 (a int, c int, b as a*10, d as c*20)
go
insert cctab4 values (1,2)
go
select * from cctab4
go

DROP TABLE cctab, cctab2, cctab3, cctab4
go
