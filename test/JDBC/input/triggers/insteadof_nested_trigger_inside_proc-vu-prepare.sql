-- For INSTEAD OF keyword --

create table insteadof_nested_trigger_inside_proc_t11(c1 int not null)
go

create table insteadof_nested_trigger_inside_proc_t22(c1 int not null)
go

create table insteadof_nested_trigger_inside_proc_t33(c1 int not null)
go

insert into insteadof_nested_trigger_inside_proc_t11 values(1)
go

insert into insteadof_nested_trigger_inside_proc_t22 values(1)
go

insert into insteadof_nested_trigger_inside_proc_t33 values(1)
go

-- with INSERT
CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p11
AS
insert into insteadof_nested_trigger_inside_proc_t11 values(2)
GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p22
AS
insert into insteadof_nested_trigger_inside_proc_t22 values(2)
GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p33
AS
insert into insteadof_nested_trigger_inside_proc_t33 values(2)
GO

create trigger insteadof_nested_trigger_inside_proc_trig11 on insteadof_nested_trigger_inside_proc_t11 INSTEAD OF insert as
select 'nest level 1'
exec insteadof_nested_trigger_inside_proc_p22;
go

create trigger insteadof_nested_trigger_inside_proc_trig22 on insteadof_nested_trigger_inside_proc_t22 INSTEAD OF insert as
select 'nest level 2'
exec insteadof_nested_trigger_inside_proc_p33;
go

create trigger insteadof_nested_trigger_inside_proc_trig33 on insteadof_nested_trigger_inside_proc_t33 INSTEAD OF insert as
select 'nest level 3'
go


-- with update

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p011
AS
update insteadof_nested_trigger_inside_proc_t11 set c1 = 3 where c1 = 1 ;
GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p022
AS
update insteadof_nested_trigger_inside_proc_t22 set c1 = 3 where c1 = 1 ;
GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p033
AS
update insteadof_nested_trigger_inside_proc_t33 set c1 = 3 where c1 = 1 ;
GO

create trigger insteadof_nested_trigger_inside_proc_trig44 on insteadof_nested_trigger_inside_proc_t11 INSTEAD OF update as
select 'nest level 1'
exec insteadof_nested_trigger_inside_proc_p022;
go

create trigger insteadof_nested_trigger_inside_proc_trig55 on insteadof_nested_trigger_inside_proc_t22 INSTEAD OF update as
select 'nest level 2'
exec insteadof_nested_trigger_inside_proc_p033;
go

create trigger insteadof_nested_trigger_inside_proc_trig66 on insteadof_nested_trigger_inside_proc_t33 INSTEAD OF update as
select 'nest level 3'
go


-- with delete
CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p0011
AS
delete from insteadof_nested_trigger_inside_proc_t11 where c1 = 1 ;

GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p0022
AS
delete from insteadof_nested_trigger_inside_proc_t22 where c1 = 1 ;

GO

CREATE PROCEDURE insteadof_nested_trigger_inside_proc_p0033
AS
delete from insteadof_nested_trigger_inside_proc_t33 where c1 = 1 ;
GO



create trigger insteadof_nested_trigger_inside_proc_trig77 on insteadof_nested_trigger_inside_proc_t11 INSTEAD OF delete as
select 'nest level 1'
exec insteadof_nested_trigger_inside_proc_p0022;
go

create trigger insteadof_nested_trigger_inside_proc_trig88 on insteadof_nested_trigger_inside_proc_t22 INSTEAD OF delete as
select 'nest level 2'
exec insteadof_nested_trigger_inside_proc_p0033;

go

create trigger insteadof_nested_trigger_inside_proc_trig99 on insteadof_nested_trigger_inside_proc_t33 INSTEAD OF delete as
select 'nest level 3'
go

