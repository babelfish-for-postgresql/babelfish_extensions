-- For INSTEAD OF keyword --

create table insteadof_nested_trigger_with_dml_vu_prepare_t11(c1 int not null)
go

create table insteadof_nested_trigger_with_dml_vu_prepare_t22(c1 int not null)
go

create table insteadof_nested_trigger_with_dml_vu_prepare_t33(c1 int not null)
go

insert into insteadof_nested_trigger_with_dml_vu_prepare_t11 values(1)
go

insert into insteadof_nested_trigger_with_dml_vu_prepare_t22 values(1)
go

insert into insteadof_nested_trigger_with_dml_vu_prepare_t33 values(1)
go

-- with INSERT
create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig11 on insteadof_nested_trigger_with_dml_vu_prepare_t11 INSTEAD OF insert as
select 'nest level 1'
insert into insteadof_nested_trigger_with_dml_vu_prepare_t22 values (2);
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig22 on insteadof_nested_trigger_with_dml_vu_prepare_t22 INSTEAD OF insert as
select 'nest level 2'
insert into insteadof_nested_trigger_with_dml_vu_prepare_t33 values (2);
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig33 on insteadof_nested_trigger_with_dml_vu_prepare_t33 INSTEAD OF insert as
select 'nest level 3'
go


-- with update

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig44 on insteadof_nested_trigger_with_dml_vu_prepare_t11 INSTEAD OF update as
select 'nest level 1'
update insteadof_nested_trigger_with_dml_vu_prepare_t22 set c1 = 3 where c1 = 1 ;
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig55 on insteadof_nested_trigger_with_dml_vu_prepare_t22 INSTEAD OF update as
select 'nest level 2'
update insteadof_nested_trigger_with_dml_vu_prepare_t33 set c1 = 3 where c1 = 1 ;
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig66 on insteadof_nested_trigger_with_dml_vu_prepare_t33 INSTEAD OF update as
select 'nest level 3'
go


-- with delete

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig77 on insteadof_nested_trigger_with_dml_vu_prepare_t11 INSTEAD OF delete as
select 'nest level 1'
delete from insteadof_nested_trigger_with_dml_vu_prepare_t22 where c1 = 1 ;
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig88 on insteadof_nested_trigger_with_dml_vu_prepare_t22 INSTEAD OF delete as
select 'nest level 2'
delete from insteadof_nested_trigger_with_dml_vu_prepare_t33 where c1 = 1 ;
go

create trigger insteadof_nested_trigger_with_dml_vu_prepare_trig99 on insteadof_nested_trigger_with_dml_vu_prepare_t33 INSTEAD OF delete as
select 'nest level 3'
go
