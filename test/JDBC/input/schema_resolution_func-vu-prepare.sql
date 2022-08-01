create schema schema_resolution_func_vu_prepare_s1;
create schema schema_resolution_func_vu_prepare_s2;
go

create table schema_resolution_func_vu_prepare_t1(a int);
go

create table schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1(a int);
go

insert into schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_t1 values (1);
go

create table schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_t1(b int);
insert into schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_t1 values (1);
insert into schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_t1 values (1);
go

create function dbo.schema_resolution_func_vu_prepare_f1()
returns int
as
begin
	return (select count(*) from schema_resolution_func_vu_prepare_t1);
end
go

create function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f1()
returns int
as
begin
	return (select count(*) from schema_resolution_func_vu_prepare_t1);
end
go

create function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f2()
returns int
as
begin
	return (select count(*) from sys.checksum(0));
end
go

create function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f3()
returns int
as
begin
	return (select count(*) from schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_t1);
end
go

create function schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f4()
returns table
as
return
	select * from schema_resolution_func_vu_prepare_t1;
go

create view dbo.schema_resolution_func_vu_prepare_v1
as
select schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f3()
go

create proc schema_resolution_func_vu_prepare_s2.schema_resolution_func_vu_prepare_p1
as
select schema_resolution_func_vu_prepare_s1.schema_resolution_func_vu_prepare_f1();
select * from dbo.schema_resolution_func_vu_prepare_v1;
go

