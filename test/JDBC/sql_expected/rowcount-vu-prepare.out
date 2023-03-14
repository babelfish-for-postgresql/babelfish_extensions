create table testing1 (a int);
GO

create procedure rowcountinsert as
begin
    set rowcount 1;
    insert into testing1 values (1);
    insert into testing1 values (1);
    insert into testing1 select a + 1 from testing1;
    insert into testing1 select a + 1 from testing1;
    set rowcount 0;
end
GO

create procedure rowcountselect as
begin
    set rowcount 1;
    select count(*) from testing1;
    select * from testing1;
    set rowcount 0;
end
GO

create procedure rowcountupdate as
begin
    set rowcount 1;
    select count(*) from testing1;
    update testing1 set a = 10;
    select count(*) from testing1 where a = 10;
    set rowcount 0;
end
GO

create procedure rowcountdelete as
begin
    set rowcount 1;
    select count(*) from testing1 where a = 1;
    delete from testing1 where a = 1;
    select count(*) from testing1 where a = 1;
    set rowcount 0;
end
GO
