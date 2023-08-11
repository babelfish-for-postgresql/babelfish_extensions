create procedure p3168 as begin
create table #t (id int identity(1,1))
end
go

create procedure p3168_2 as begin
create table #t (id int identity primary key)
create index i on #t(id)
end
go

create procedure p3168_3 as begin
create table #t (id int)
create index i on #t(id)
end
go

create type typ3168 from int
go

create procedure p3168_4 as begin
create table #t(id typ3168 primary key)
create index i on #t(id)
end
go
