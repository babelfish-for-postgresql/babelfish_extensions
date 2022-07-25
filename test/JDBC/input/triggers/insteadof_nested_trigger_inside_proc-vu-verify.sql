-- For INSTEAD OF keyword --

-- with INSERT
exec insteadof_nested_trigger_inside_proc_vu_prepare_p11;
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t11
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t22
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t33
go

-- with update
exec insteadof_nested_trigger_inside_proc_vu_prepare_p011;
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t11
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t22
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t33
go
-- with delete
exec insteadof_nested_trigger_inside_proc_vu_prepare_p0011;
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t11
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t22
go

select * from insteadof_nested_trigger_inside_proc_vu_prepare_t33
go
