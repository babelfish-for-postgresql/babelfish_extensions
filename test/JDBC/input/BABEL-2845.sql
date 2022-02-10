create table babel_2845_t1(a int, check (a > 5));
go

create table babel_2845_t2(a int, b int);
go

insert into babel_2845_t2 values (1, 2);
GO

create trigger babel_2845_trig on babel_2845_t1 
for insert
as
	update babel_2845_t2 set a = 2 where b = 2
GO

begin tran
GO

insert into babel_2845_t1 values (6)
GO

save transaction tran1
GO

insert into babel_2845_t1 values (7)
GO

rollback transaction tran1
GO

commit
GO

select * from babel_2845_t1;
GO

begin tran
GO

insert into babel_2845_t1 values (7)
GO

save transaction tran1
GO

-- error which should rollback the whole tran
insert into babel_2845_t1 values (1)
GO

if (@@trancount > 0) rollback tran;
GO

select * from babel_2845_t1;
GO

drop trigger babel_2845_trig
GO

drop table babel_2845_t1
go

drop table babel_2845_t2
GO
