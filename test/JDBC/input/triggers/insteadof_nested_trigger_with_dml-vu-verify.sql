-- For INSTEAD OF keyword --

-- with INSERT
insert into insteadof_nested_trigger_with_dml_vu_prepare_t11 values(2)
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t11
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t22
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t33
go

-- with update
update insteadof_nested_trigger_with_dml_vu_prepare_t11 set c1 = 3 where c1 = 1 ;
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t11
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t22
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t33
go
-- with delete
delete from insteadof_nested_trigger_with_dml_vu_prepare_t11 where c1 = 1 ;
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t11
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t22
go

select * from insteadof_nested_trigger_with_dml_vu_prepare_t33
go