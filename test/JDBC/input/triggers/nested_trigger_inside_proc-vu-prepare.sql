--  For AFTER keyword --

create table nested_trigger_inside_proc_t1(c1 int not null)
go

create table nested_trigger_inside_proc_t2(c1 int not null)
go

create table nested_trigger_inside_proc_t3(c1 int not null)
go

insert into nested_trigger_inside_proc_t1 values(1)
go

insert into nested_trigger_inside_proc_t2 values(1)
go

insert into nested_trigger_inside_proc_t3 values(1)
go

-- procedure to invoke
-- with INSERT
CREATE PROCEDURE nested_trigger_inside_proc_p1
AS
insert into nested_trigger_inside_proc_t1 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_p2
AS
insert into nested_trigger_inside_proc_t2 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_p3
AS
insert into nested_trigger_inside_proc_t3 values(2)
GO



create trigger nested_trigger_inside_proc_trig1 on nested_trigger_inside_proc_t1 AFTER insert as
select 'nest level 1'
exec nested_trigger_inside_proc_p2;
go

create trigger nested_trigger_inside_proc_trig2 on nested_trigger_inside_proc_t2 AFTER insert as
select 'nest level 2'
exec nested_trigger_inside_proc_p3
go

create trigger nested_trigger_inside_proc_trig3 on nested_trigger_inside_proc_t3 AFTER insert as
select 'nest level 3'
go


-- with update


CREATE PROCEDURE nested_trigger_inside_proc_p01
AS
update nested_trigger_inside_proc_t1 set c1 = 3 where c1 = 2 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p02
AS
update nested_trigger_inside_proc_t2 set c1 = 3 where c1 = 2 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p03
AS
update nested_trigger_inside_proc_t3 set c1 = 3 where c1 = 2 ;
GO

create trigger nested_trigger_inside_proc_trig4 on nested_trigger_inside_proc_t1 AFTER update as
select 'nest level 1'
exec nested_trigger_inside_proc_p02 ;
go

create trigger nested_trigger_inside_proc_trig5 on nested_trigger_inside_proc_t2 AFTER update as
select 'nest level 2'
exec nested_trigger_inside_proc_p03 ;
go

create trigger nested_trigger_inside_proc_trig6 on nested_trigger_inside_proc_t3 AFTER update as
select 'nest level 3'
go


-- with delete


CREATE PROCEDURE nested_trigger_inside_proc_p001
AS
delete from nested_trigger_inside_proc_t1 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p002
AS
delete from nested_trigger_inside_proc_t2 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p003
AS
delete from nested_trigger_inside_proc_t3 where c1 = 1 ;
GO

create trigger nested_trigger_inside_proc_trig7 on nested_trigger_inside_proc_t1 AFTER delete as
select 'nest level 1'
exec nested_trigger_inside_proc_p002;
go

create trigger nested_trigger_inside_proc_trig8 on nested_trigger_inside_proc_t2 AFTER delete as
select 'nest level 2'
exec nested_trigger_inside_proc_p003;
go

create trigger nested_trigger_inside_proc_trig9 on nested_trigger_inside_proc_t3 AFTER delete as
select 'nest level 3'
go


-- For INSTEAD OF keyword --

create table nested_trigger_inside_proc_t11(c1 int not null)
go

create table nested_trigger_inside_proc_t22(c1 int not null)
go

create table nested_trigger_inside_proc_t33(c1 int not null)
go

insert into nested_trigger_inside_proc_t11 values(1)
go

insert into nested_trigger_inside_proc_t22 values(1)
go

insert into nested_trigger_inside_proc_t33 values(1)
go

-- with INSERT
CREATE PROCEDURE nested_trigger_inside_proc_p11
AS
insert into nested_trigger_inside_proc_t11 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_p22
AS
insert into nested_trigger_inside_proc_t22 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_p33
AS
insert into nested_trigger_inside_proc_t33 values(2)
GO

create trigger nested_trigger_inside_proc_trig11 on nested_trigger_inside_proc_t11 INSTEAD OF insert as
select 'nest level 1'
exec nested_trigger_inside_proc_p22;
go

create trigger nested_trigger_inside_proc_trig22 on nested_trigger_inside_proc_t22 INSTEAD OF insert as
select 'nest level 2'
exec nested_trigger_inside_proc_p33;
go

create trigger nested_trigger_inside_proc_trig33 on nested_trigger_inside_proc_t33 INSTEAD OF insert as
select 'nest level 3'
go


-- with update

CREATE PROCEDURE nested_trigger_inside_proc_p011
AS
update nested_trigger_inside_proc_t11 set c1 = 3 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p022
AS
update nested_trigger_inside_proc_t22 set c1 = 3 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_p033
AS
update nested_trigger_inside_proc_t33 set c1 = 3 where c1 = 1 ;
GO

create trigger nested_trigger_inside_proc_trig44 on nested_trigger_inside_proc_t11 INSTEAD OF update as
select 'nest level 1'
exec nested_trigger_inside_proc_p022;
go

create trigger nested_trigger_inside_proc_trig55 on nested_trigger_inside_proc_t22 INSTEAD OF update as
select 'nest level 2'
exec nested_trigger_inside_proc_p033;
go

create trigger nested_trigger_inside_proc_trig66 on nested_trigger_inside_proc_t33 INSTEAD OF update as
select 'nest level 3'
go


-- with delete
CREATE PROCEDURE nested_trigger_inside_proc_p0011
AS
delete from nested_trigger_inside_proc_t11 where c1 = 1 ;

GO

CREATE PROCEDURE nested_trigger_inside_proc_p0022
AS
delete from nested_trigger_inside_proc_t22 where c1 = 1 ;

GO

CREATE PROCEDURE nested_trigger_inside_proc_p0033
AS
delete from nested_trigger_inside_proc_t33 where c1 = 1 ;
GO



create trigger nested_trigger_inside_proc_trig77 on nested_trigger_inside_proc_t11 INSTEAD OF delete as
select 'nest level 1'
exec nested_trigger_inside_proc_p0022;
go

create trigger nested_trigger_inside_proc_trig88 on nested_trigger_inside_proc_t22 INSTEAD OF delete as
select 'nest level 2'
exec nested_trigger_inside_proc_p0033;

go

create trigger nested_trigger_inside_proc_trig99 on nested_trigger_inside_proc_t33 INSTEAD OF delete as
select 'nest level 3'
go
