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
