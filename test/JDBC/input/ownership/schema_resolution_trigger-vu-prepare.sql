create schema schema_resolution_trigger_s1
go

create table schema_resolution_trigger_t1(dbo_t1 int)
go

create table schema_resolution_trigger_s1.schema_resolution_trigger_t1(s1_t1 int, s1_t2 int)
go

create table schema_resolution_trigger_mytab(dbo_mytab int)
go

create table schema_resolution_trigger_s1.schema_resolution_trigger_mytab(s1_mytab int)
go

create trigger schema_resolution_trigger_tr1 on dbo.schema_resolution_trigger_mytab for insert as
select * from schema_resolution_trigger_t1
go

create trigger schema_resolution_trigger_tr2 on schema_resolution_trigger_s1.schema_resolution_trigger_mytab for insert as
select * from schema_resolution_trigger_t1
go

