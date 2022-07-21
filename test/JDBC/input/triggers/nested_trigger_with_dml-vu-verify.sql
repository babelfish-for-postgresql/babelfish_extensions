-- For AFTER keyword --

-- with INSERT
insert into nested_trigger_with_dml_t1 values(2)
go

select * from nested_trigger_with_dml_t1
go

select * from nested_trigger_with_dml_t2
go

select * from nested_trigger_with_dml_t3
go

-- with update
update nested_trigger_with_dml_t1 set c1 = 3 where c1 = 2 ;
go

select * from nested_trigger_with_dml_t1
go

select * from nested_trigger_with_dml_t2
go

select * from nested_trigger_with_dml_t3
go
-- with delete
delete from nested_trigger_with_dml_t1 where c1 = 1 ;
go

select * from nested_trigger_with_dml_t1
go

select * from nested_trigger_with_dml_t2
go

select * from nested_trigger_with_dml_t3
go

-- For INSTEAD OF keyword --

-- with INSERT
insert into nested_trigger_with_dml_t11 values(2)
go

select * from nested_trigger_with_dml_t11
go

select * from nested_trigger_with_dml_t22
go

select * from nested_trigger_with_dml_t33
go

-- with update
update nested_trigger_with_dml_t11 set c1 = 3 where c1 = 1 ;
go

select * from nested_trigger_with_dml_t11
go

select * from nested_trigger_with_dml_t22
go

select * from nested_trigger_with_dml_t33
go
-- with delete
delete from nested_trigger_with_dml_t11 where c1 = 1 ;
go

select * from nested_trigger_with_dml_t11
go

select * from nested_trigger_with_dml_t22
go

select * from nested_trigger_with_dml_t33
go