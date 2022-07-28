create schema schema_resolution_func_s1;
go

create table schema_resolution_func_t1(a int);
go

create table schema_resolution_func_s1.schema_resolution_func_t1(a int);
go

insert into schema_resolution_func_s1.schema_resolution_func_t1 values (1);
go

create function dbo.schema_resolution_func_f1()
returns int
as
begin
	return (select count(*) from schema_resolution_func_t1);
end
go

create function schema_resolution_func_s1.schema_resolution_func_f1()
returns int
as
begin
	return (select count(*) from schema_resolution_func_t1);
end
go

create function schema_resolution_func_s1.schema_resolution_func_f2()
returns int
as
begin
	return (select count(*) from sys.checksum(0));
end
go

create proc schema_resolution_func_s1.schema_resolution_func_p1
as
select dbo.schema_resolution_func_f1()
go