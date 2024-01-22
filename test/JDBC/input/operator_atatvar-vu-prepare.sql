create view v1_operator_atatvar as
select c=@@max_precision where 0! =@@max_precision
go

create view v2_operator_atatvar as
select c=@@max_precision where 0=@@max_precision
go

create procedure p1_operator_atatvar
as
if 1=@@max_precision select 'yes' else select 'no'
if 1< >@@max_precision select 'yes' else select 'no'
if 1! =@@max_precision select 'yes' else select 'no'
if 1>@@max_precision select 'yes' else select 'no'
if 1<@@max_precision select 'yes' else select 'no'
if 1! >@@max_precision select 'yes' else select 'no'
if 1! <@@max_precision select 'yes' else select 'no'
if case when 1! <@@max_precision then 1 else 0 end > 0 select 'yes' else select 'no'
if case when 1>@@max_precision then 1 else 0 end > 0 select 'yes' else select 'no'
if case when 1=@@max_precision then 1 else 0 end > 0 select 'yes' else select 'no'
execute('if case when 1=@@max_precision then 1 else 0 end > 0 select ''yes'' else select ''no''')
select 1 where 1<@@max_precision 
select 1 where 1!>@@max_precision 
select * from v1_operator_atatvar where case when 1!=@@max_precision then 1 else @@max_precision end=@@max_precision
go

create procedure p2_operator_atatvar @p int=@@max_precision
as
select @p
go

create procedure p3_operator_atatvar @p int
as
select @p
go

create function f1_operator_atatvar(@p int) returns int
as
begin
	if @p=@@spid return 1
	else return 0
end
go

create function f2_operator_atatvar(@p int) returns table
as
	return select 1 as c where @p=@@max_precision
go
