-- For AFTER keyword --

-- with INSERT
insert into nested_trigger_with_dml_vu_prepare_t1 values(2)
go

select * from nested_trigger_with_dml_vu_prepare_t1
go

select * from nested_trigger_with_dml_vu_prepare_t2
go

select * from nested_trigger_with_dml_vu_prepare_t3
go

-- with update
update nested_trigger_with_dml_vu_prepare_t1 set c1 = 3 where c1 = 2 ;
go

select * from nested_trigger_with_dml_vu_prepare_t1
go

select * from nested_trigger_with_dml_vu_prepare_t2
go

select * from nested_trigger_with_dml_vu_prepare_t3
go
-- with delete
delete from nested_trigger_with_dml_vu_prepare_t1 where c1 = 1 ;
go

select * from nested_trigger_with_dml_vu_prepare_t1
go

select * from nested_trigger_with_dml_vu_prepare_t2
go

select * from nested_trigger_with_dml_vu_prepare_t3
go
