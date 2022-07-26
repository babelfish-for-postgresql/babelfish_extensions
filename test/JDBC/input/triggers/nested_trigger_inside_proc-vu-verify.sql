-- For AFTER keyword --

-- with INSERT
exec nested_trigger_inside_proc_vu_prepare_p1;
go

select * from nested_trigger_inside_proc_vu_prepare_t1
go

select * from nested_trigger_inside_proc_vu_prepare_t2
go

select * from nested_trigger_inside_proc_vu_prepare_t3
go

-- with update
exec nested_trigger_inside_proc_vu_prepare_p01;
go

select * from nested_trigger_inside_proc_vu_prepare_t1
go

select * from nested_trigger_inside_proc_vu_prepare_t2
go

select * from nested_trigger_inside_proc_vu_prepare_t3
go
-- with delete

exec nested_trigger_inside_proc_vu_prepare_p001;
go

select * from nested_trigger_inside_proc_vu_prepare_t1
go

select * from nested_trigger_inside_proc_vu_prepare_t2
go

select * from nested_trigger_inside_proc_vu_prepare_t3
go