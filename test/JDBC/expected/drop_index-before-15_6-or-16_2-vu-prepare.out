use master
go
create table dbo.t1_drop_index(a int)
go
create index ix1 on dbo.t1_drop_index(a)
go

create procedure p1_drop_index 
as
	drop index dbo.t1_drop_index.ix1
	drop index if exists dbo.t1_drop_index.ix1	
go

create table dbo.t2_drop_index(a int)
go
create index ix1 on dbo.t2_drop_index(a)
go

create procedure p2_drop_index 
as
	drop index ix1 on dbo.t2_drop_index
	drop index if exists ix1 on dbo.t2_drop_index	
go



