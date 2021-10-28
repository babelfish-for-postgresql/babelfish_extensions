create type tableType as table (i int, j int);
go

-- ROLLBACK should get unsupported error message
create proc p1 as
begin
	declare @tv tableType;
	begin tran insert @tv values (1,2);
	rollback;
	select * from @tv
end
go
exec p1
go

-- ROLLBACK should get unsupported error message
declare @t table (a int)
begin tran
insert into @t values(1)
select @@rowcount as rows_inserted
rollback
select count(*) from @t
print 'after select'
go

declare @tv1 tableType;
begin transaction
insert @tv1 values (1,2), (2,1);
select * from @tv1;
go

-- ROLLBACK here is fine because @tv1 is out of scope
rollback
select * from @tv1;
go

-- ROLLBACK should get unsupported error message
declare @tv2 tableType;
begin transaction
insert @tv2 values (3,4), (4,3);
select * from @tv2;
rollback
select * from @tv2;
go

-- cleanup
drop type tableType;
go
drop proc p1;
go
