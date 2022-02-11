create procedure babel_462_proc @a varchar(20) as
begin
exec('create table ' + @a + '(b int) insert into ' + @a + ' values (111)')
end
go

exec babel_462_proc 'babel_462_table'
go


select * from babel_462_table
go

drop table babel_462_table
go

SET apg_tsql_batches ON
go

exec babel_462_proc 'babel_462_table2';
select * from babel_462_table2;
go

create procedure babel_462_proc_int @b int as
begin
declare @c varchar(max);
set @c = cast(@b as varchar(max));
exec('create table babel_462_int (b int) insert into babel_462_int values ('+ @c +')')
end
go

exec babel_462_proc_int  2
go

exec babel_462_proc_int 'unexpected'
go

create procedure babel_462_proc_null as
begin
declare @v varchar(10)
exec(@v)
end
go

create procedure babel_462_semicolon as
begin
exec('select * from babel_462_table2');
end
go

create procedure babel_462_exec_ddl as
begin
exec('create table babel_462_exec_ddl_table(a int)')
end
go

exec babel_462_proc_null
go

exec babel_462_semicolon
go

exec babel_462_exec_ddl
go

select * from babel_462_int
go

select * from babel_462_exec_ddl_table
go

drop table babel_462_table2
go

drop table babel_462_int
go

drop table babel_462_exec_ddl_table
go

drop procedure babel_462_proc
go
drop procedure babel_462_proc_int
go
drop procedure babel_462_proc_null
go
drop procedure babel_462_semicolon
go
drop procedure babel_462_exec_ddl
go
