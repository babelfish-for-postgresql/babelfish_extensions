-- For AFTER keyword --

-- with INSERT
exec nested_trigger_inside_proc_p1;
go

select * from nested_trigger_inside_proc_t1
go

select * from nested_trigger_inside_proc_t2
go

select * from nested_trigger_inside_proc_t3
go

-- with update
exec nested_trigger_inside_proc_p01;
go

select * from nested_trigger_inside_proc_t1
go

select * from nested_trigger_inside_proc_t2
go

select * from nested_trigger_inside_proc_t3
go
-- with delete

exec nested_trigger_inside_proc_p001;
go

select * from nested_trigger_inside_proc_t1
go

select * from nested_trigger_inside_proc_t2
go

select * from nested_trigger_inside_proc_t3
go