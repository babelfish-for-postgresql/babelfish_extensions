--  For AFTER keyword --

create table nested_trigger_with_dml_t1(c1 int not null)
go

create table nested_trigger_with_dml_t2(c1 int not null)
go

create table nested_trigger_with_dml_t3(c1 int not null)
go

insert into nested_trigger_with_dml_t1 values(1)
go

insert into nested_trigger_with_dml_t2 values(1)
go

insert into nested_trigger_with_dml_t3 values(1)
go

-- with INSERT
create trigger nested_trigger_with_dml_trig1 on nested_trigger_with_dml_t1 AFTER insert as
select 'nest level 1'
insert into nested_trigger_with_dml_t2 values (2);
go

create trigger nested_trigger_with_dml_trig2 on nested_trigger_with_dml_t2 AFTER insert as
select 'nest level 2'
insert into nested_trigger_with_dml_t3 values (2);
go

create trigger nested_trigger_with_dml_trig3 on nested_trigger_with_dml_t3 AFTER insert as
select 'nest level 3'
go


-- with update

create trigger nested_trigger_with_dml_trig4 on nested_trigger_with_dml_t1 AFTER update as
select 'nest level 1'
update nested_trigger_with_dml_t2 set c1 = 3 where c1 = 2 ;
go

create trigger nested_trigger_with_dml_trig5 on nested_trigger_with_dml_t2 AFTER update as
select 'nest level 2'
update nested_trigger_with_dml_t3 set c1 = 3 where c1 = 2 ;
go

create trigger nested_trigger_with_dml_trig6 on nested_trigger_with_dml_t3 AFTER update as
select 'nest level 3'
go


-- with delete

create trigger nested_trigger_with_dml_trig7 on nested_trigger_with_dml_t1 AFTER delete as
select 'nest level 1'
delete from nested_trigger_with_dml_t2 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig8 on nested_trigger_with_dml_t2 AFTER delete as
select 'nest level 2'
delete from nested_trigger_with_dml_t3 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig9 on nested_trigger_with_dml_t3 AFTER delete as
select 'nest level 3'
go


-- For INSTEAD OF keyword --

create table nested_trigger_with_dml_t11(c1 int not null)
go

create table nested_trigger_with_dml_t22(c1 int not null)
go

create table nested_trigger_with_dml_t33(c1 int not null)
go

insert into nested_trigger_with_dml_t11 values(1)
go

insert into nested_trigger_with_dml_t22 values(1)
go

insert into nested_trigger_with_dml_t33 values(1)
go

-- with INSERT
create trigger nested_trigger_with_dml_trig11 on nested_trigger_with_dml_t11 INSTEAD OF insert as
select 'nest level 1'
insert into nested_trigger_with_dml_t22 values (2);
go

create trigger nested_trigger_with_dml_trig22 on nested_trigger_with_dml_t22 INSTEAD OF insert as
select 'nest level 2'
insert into nested_trigger_with_dml_t33 values (2);
go

create trigger nested_trigger_with_dml_trig33 on nested_trigger_with_dml_t33 INSTEAD OF insert as
select 'nest level 3'
go


-- with update

create trigger nested_trigger_with_dml_trig44 on nested_trigger_with_dml_t11 INSTEAD OF update as
select 'nest level 1'
update nested_trigger_with_dml_t22 set c1 = 3 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig55 on nested_trigger_with_dml_t22 INSTEAD OF update as
select 'nest level 2'
update nested_trigger_with_dml_t33 set c1 = 3 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig66 on nested_trigger_with_dml_t33 INSTEAD OF update as
select 'nest level 3'
go


-- with delete

create trigger nested_trigger_with_dml_trig77 on nested_trigger_with_dml_t11 INSTEAD OF delete as
select 'nest level 1'
delete from nested_trigger_with_dml_t22 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig88 on nested_trigger_with_dml_t22 INSTEAD OF delete as
select 'nest level 2'
delete from nested_trigger_with_dml_t33 where c1 = 1 ;
go

create trigger nested_trigger_with_dml_trig99 on nested_trigger_with_dml_t33 INSTEAD OF delete as
select 'nest level 3'
go
