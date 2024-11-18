create table t1_empty_dq_string(a int)
go
create table t2_empty_dq_string(a int)
go
create table t3_empty_dq_string(a int)
go
create table t4_empty_dq_string(a int)
go
create table t5_empty_dq_string(a int, b varchar(10))
insert t5_empty_dq_string values(1, 'test 1')
go
create table t6_empty_dq_string(a int, b varchar(10))
insert t6_empty_dq_string values(1, 'test 1')
go
create table t7_empty_dq_string(a int, b varchar(10))
insert t7_empty_dq_string values(1, 'test 1')
go

set quoted_identifier on
go
create table "t8_empty_dq_string"("a" int, "b" varchar(10))
insert "t8_empty_dq_string" values(1, 'test 1')
go
