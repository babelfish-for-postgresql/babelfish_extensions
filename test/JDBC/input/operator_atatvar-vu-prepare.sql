create view v1_operator_atatvar as
select c=@@max_precision where 0! =@@max_precision
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