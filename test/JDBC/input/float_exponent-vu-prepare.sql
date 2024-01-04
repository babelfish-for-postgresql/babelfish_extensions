create table t1_float_exponent(a int, b real, c float, d decimal(10,2))
go

create view v1_float_exponent as select 2e as c
go

create procedure p1_float_exponent @p float as select @p
go

create procedure p2_float_exponent as
insert t1_float_exponent values (2e+, 3.1e, -.4e-, 5.e-) 
go

create function f1_float_exponent (@p float) returns float as begin return @p end
go
