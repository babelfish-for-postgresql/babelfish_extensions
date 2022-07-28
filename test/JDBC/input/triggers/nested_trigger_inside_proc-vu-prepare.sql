--  For AFTER keyword --

create table nested_trigger_inside_proc_vu_prepare_t1(c1 int not null)
go

create table nested_trigger_inside_proc_vu_prepare_t2(c1 int not null)
go

create table nested_trigger_inside_proc_vu_prepare_t3(c1 int not null)
go

insert into nested_trigger_inside_proc_vu_prepare_t1 values(1)
go

insert into nested_trigger_inside_proc_vu_prepare_t2 values(1)
go

insert into nested_trigger_inside_proc_vu_prepare_t3 values(1)
go

-- procedure to invoke
-- with INSERT
CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p1
AS
insert into nested_trigger_inside_proc_vu_prepare_t1 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p2
AS
insert into nested_trigger_inside_proc_vu_prepare_t2 values(2)
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p3
AS
insert into nested_trigger_inside_proc_vu_prepare_t3 values(2)
GO



create trigger nested_trigger_inside_proc_vu_prepare_trig1 on nested_trigger_inside_proc_vu_prepare_t1 AFTER insert as
select 'nest level 1'
exec nested_trigger_inside_proc_vu_prepare_p2;
go

create trigger nested_trigger_inside_proc_vu_prepare_trig2 on nested_trigger_inside_proc_vu_prepare_t2 AFTER insert as
select 'nest level 2'
exec nested_trigger_inside_proc_vu_prepare_p3
go

create trigger nested_trigger_inside_proc_vu_prepare_trig3 on nested_trigger_inside_proc_vu_prepare_t3 AFTER insert as
select 'nest level 3'
go


-- with update


CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p01
AS
update nested_trigger_inside_proc_vu_prepare_t1 set c1 = 3 where c1 = 2 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p02
AS
update nested_trigger_inside_proc_vu_prepare_t2 set c1 = 3 where c1 = 2 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p03
AS
update nested_trigger_inside_proc_vu_prepare_t3 set c1 = 3 where c1 = 2 ;
GO

create trigger nested_trigger_inside_proc_vu_prepare_trig4 on nested_trigger_inside_proc_vu_prepare_t1 AFTER update as
select 'nest level 1'
exec nested_trigger_inside_proc_vu_prepare_p02 ;
go

create trigger nested_trigger_inside_proc_vu_prepare_trig5 on nested_trigger_inside_proc_vu_prepare_t2 AFTER update as
select 'nest level 2'
exec nested_trigger_inside_proc_vu_prepare_p03 ;
go

create trigger nested_trigger_inside_proc_vu_prepare_trig6 on nested_trigger_inside_proc_vu_prepare_t3 AFTER update as
select 'nest level 3'
go


-- with delete


CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p001
AS
delete from nested_trigger_inside_proc_vu_prepare_t1 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p002
AS
delete from nested_trigger_inside_proc_vu_prepare_t2 where c1 = 1 ;
GO

CREATE PROCEDURE nested_trigger_inside_proc_vu_prepare_p003
AS
delete from nested_trigger_inside_proc_vu_prepare_t3 where c1 = 1 ;
GO

create trigger nested_trigger_inside_proc_vu_prepare_trig7 on nested_trigger_inside_proc_vu_prepare_t1 AFTER delete as
select 'nest level 1'
exec nested_trigger_inside_proc_vu_prepare_p002;
go

create trigger nested_trigger_inside_proc_vu_prepare_trig8 on nested_trigger_inside_proc_vu_prepare_t2 AFTER delete as
select 'nest level 2'
exec nested_trigger_inside_proc_vu_prepare_p003;
go

create trigger nested_trigger_inside_proc_vu_prepare_trig9 on nested_trigger_inside_proc_vu_prepare_t3 AFTER delete as
select 'nest level 3'
go



