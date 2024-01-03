-- parallel_query_expected
use master;
go

drop table if exists babel_2903_t1;
go
create table babel_2903_t1 (a int, b int);
go
insert into babel_2903_t1 values (1, 1);
go
insert into babel_2903_t1 values (2, 2);
go
select * from babel_2903_t1;
go

drop procedure if exists babel_2903_inner_proc;
go
create procedure babel_2903_inner_proc @b int
as
    set @b = (select top 1 a+b from babel_2903_t1 order by b);
    insert into babel_2903_t1 values (@b, @b);
go

drop procedure if exists babel_2903_outer_proc;
go
create procedure babel_2903_outer_proc @a int, @b int
as
    declare @t table (a int, b int);
    set @a = 3;
    insert into babel_2903_t1 values (@a, @b);
    exec babel_2903_inner_proc @b;
    insert into @t select * from babel_2903_t1;
    select * from @t;
go

set BABELFISH_SHOWPLAN_ALL ON;
go

declare @a int = 5, @b int = 5;
declare @c int;
execute babel_2903_outer_proc @a, @b;
select @a, @b;
go

set BABELFISH_SHOWPLAN_ALL Off;
go

select * from babel_2903_t1;
go

drop procedure if exists babel_2903_outer_proc;
go
drop procedure if exists babel_2903_inner_proc;
go
drop table if exists babel_2903_t1;
go
