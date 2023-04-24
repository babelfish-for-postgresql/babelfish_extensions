create table dbo.babel_3725(a int)
go

insert into babel_3725 values (1), (2), (NULL)
go

create procedure babel_3725_dml_top_proc as
begin
    update top(2) dbo.babel_3725 set a = 100;
    delete top(2) dbo.babel_3725;
end
go
