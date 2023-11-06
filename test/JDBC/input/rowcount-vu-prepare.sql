create table rowcount_vu_prepare_testing1 (a int);
GO

create table rowcount_vu_prepare_testing2 (a int);
go


-- procedures to test "SET ROWCOUNT value"
create procedure rowcount_vu_prepare_insert_proc as
begin
    set rowcount 1;
    insert into rowcount_vu_prepare_testing1 values (1);
    insert into rowcount_vu_prepare_testing1 values (1);
    insert into rowcount_vu_prepare_testing1 select a + 1 from rowcount_vu_prepare_testing1;
    insert into rowcount_vu_prepare_testing1 select a + 1 from rowcount_vu_prepare_testing1;
    set rowcount 0;
    set rowcount 5;
    insert into rowcount_vu_prepare_testing1 select a from rowcount_vu_prepare_testing1;
    insert into rowcount_vu_prepare_testing1 select a from rowcount_vu_prepare_testing1;
    set rowcount 0;
end
GO

create procedure rowcount_vu_prepare_select_proc as
begin
    set rowcount 1;
    select count(*) from rowcount_vu_prepare_testing1;
    select * from rowcount_vu_prepare_testing1;
    set rowcount 0;
end
GO

create procedure rowcount_vu_prepare_update_proc as
begin
    set rowcount 1;
    select count(*) from rowcount_vu_prepare_testing1;
    update rowcount_vu_prepare_testing1 set a = 10;
    select count(*) from rowcount_vu_prepare_testing1 where a = 10;
    set rowcount 0;
end
GO

create procedure rowcount_vu_prepare_delete_proc as
begin
    set rowcount 1;
    select count(*) from rowcount_vu_prepare_testing1 where a = 1;
    delete from rowcount_vu_prepare_testing1 where a = 1;
    select count(*) from rowcount_vu_prepare_testing1 where a = 1;
    set rowcount 0;
end
GO

-- procedures to test "SET ROWCOUNT @variable"
create procedure rowcount_vu_prepare_insert_proc_var as
begin
    declare @v int = 1;
    set rowcount @v;
    insert into rowcount_vu_prepare_testing2 values (1);
    insert into rowcount_vu_prepare_testing2 values (1);
    insert into rowcount_vu_prepare_testing2 select a + 1 from rowcount_vu_prepare_testing2;
    insert into rowcount_vu_prepare_testing2 select a + 1 from rowcount_vu_prepare_testing2;
    declare @x int = 0;
    set rowcount @x;
    set @x = 5;
    set rowcount @x;
    insert into rowcount_vu_prepare_testing2 select a from rowcount_vu_prepare_testing2;
    insert into rowcount_vu_prepare_testing2 select a from rowcount_vu_prepare_testing2;
    set rowcount 0;
end
GO

create procedure rowcount_vu_prepare_select_proc_var as
begin
    declare @v smallint = 1;
    set rowcount @v;
    select count(*) from rowcount_vu_prepare_testing2;
    select * from rowcount_vu_prepare_testing2;
    declare @x int = 0;
    set rowcount @x;
end
GO

create procedure rowcount_vu_prepare_update_proc_var as
begin
    declare @v smallint = 1;
    set rowcount @v;
    select count(*) from rowcount_vu_prepare_testing2;
    update rowcount_vu_prepare_testing2 set a = 10;
    select count(*) from rowcount_vu_prepare_testing2 where a = 10;
    declare @x int = 0;
    set rowcount @x;
end
GO

create procedure rowcount_vu_prepare_delete_proc_var as
begin
    declare @v smallint = 1;
    set rowcount @v;
    select count(*) from rowcount_vu_prepare_testing2 where a = 1;
    delete from rowcount_vu_prepare_testing2 where a = 1;
    select count(*) from rowcount_vu_prepare_testing2 where a = 1;
    set rowcount 0;
end
GO

create procedure rowcount_vu_prepare_select as
begin
    select * from rowcount_vu_prepare_testing2;
end
go



create procedure rowcount_vu_prepare_select_nested_proc_var as
begin
    declare @v smallint = 1;
    set rowcount @v;
    select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
    exec rowcount_vu_prepare_select;
    declare @x int = 0;
    set rowcount @x;
    select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
    exec rowcount_vu_prepare_select;
end
GO