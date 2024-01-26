if 1=@@max_precision select 'yes' else select 'no'
go
if 1<>@@max_precision select 'yes' else select 'no'
go
if 1< >@@max_precision select 'yes' else select 'no'
go
if 1!=@@max_precision select 'yes' else select 'no'
go
if 1! =@@max_precision select 'yes' else select 'no'
go
if 1>@@max_precision select 'yes' else select 'no'
go
if 1<@@max_precision select 'yes' else select 'no'
go
if 1>=@@max_precision select 'yes' else select 'no'
go
if 1> =@@max_precision select 'yes' else select 'no'
go
if 1<=@@max_precision select 'yes' else select 'no'
go
if 1< =@@max_precision select 'yes' else select 'no'
go
if 1!>@@max_precision select 'yes' else select 'no'
go
if 1! >@@max_precision select 'yes' else select 'no'
go
if 1! <@@max_precision select 'yes' else select 'no'
go
if 1!<@@max_precision select 'yes' else select 'no'
go
if case when 1! <@@max_precision then 1 else 0 end=@@max_precision select 'yes' else select 'no'
go
if case when 1>@@max_precision then 1 else 0 end>@@max_precision select 'yes' else select 'no'
go
if case when 1=@@max_precision then 1 else 0 end!=@@max_precision select 'yes' else select 'no'
go
execute('if case when 1=@@max_precision then 1 else 0 end > 0 select ''yes'' else select ''no''')
go
select 1 where 1<@@max_precision 
go
select 1 where 1!=@@max_precision 
go
select 1 where 1<>@@max_precision 
go
select 1 where 1< >@@max_precision 
go
select 1 where 1!>@@max_precision 
go
select 1 where 1! >@@max_precision 
go

if 1 = @@max_precision select 'yes' else select 'no'
go

declare @v int = 1 if 1=@v select 'yes' else select 'no'
go
declare @v int = 1 if 1<@v select 'yes' else select 'no'
go
declare @v int = 1 if 1>@v select 'yes' else select 'no'
go
declare @v int = 1 if 1<>@v select 'yes' else select 'no'
go
declare @v int = 1 if 1!=@v select 'yes' else select 'no'
go
declare @v int = 1 if 1 !=@v select 'yes' else select 'no'
go
declare @v int = 1 if 1 ! =@v select 'yes' else select 'no'
go
declare @v int = 1 if 1!>@v select 'yes' else select 'no'
go
declare @v int = 1 if 1!<@v select 'yes' else select 'no'
go
declare @v int = 1 if 1=@v select 'yes' else select 'no'
go
declare @v int = 1 if 1<@v select 'yes' else select 'no'
go
declare @v int = 1 if 1>@v select 'yes' else select 'no'
go
declare @v int = 1 if 1< >@v select 'yes' else select 'no'
go
declare @v int = 1 if 1! =@v select 'yes' else select 'no'
go
declare @v int = 1 if 1! >@v select 'yes' else select 'no'
go
declare @v int = 1 if 1! <@v select 'yes' else select 'no'
go

select c=@@max_precision where 0< >@@max_precision
go

select * from v1_operator_atatvar where 0! <@@max_precision
go

select * from v1_operator_atatvar where case when 1!=@@max_precision then 1 else @@max_precision end=@@max_precision
go

select * from v2_operator_atatvar where 0!<@@max_precision
go

select * from v2_operator_atatvar where case when 1!=@@max_precision then 1 else @@max_precision end=@@max_precision
go

declare @v int
set @v=1
set @v+=@v
select @v=@v+1
select @v+=@v
select @v
go

execute p2_operator_atatvar
go

p2_operator_atatvar
go

execute p3_operator_atatvar @p=@@max_precision
go

p3_operator_atatvar @p=@@max_precision
go

execute('p3_operator_atatvar @p=@@max_precision')
go

execute('execute p3_operator_atatvar @p=@@max_precision')
go

select dbo.f1_operator_atatvar(@@spid)
go

select dbo.f1_operator_atatvar(@@spid-1)
go

select * from dbo.f2_operator_atatvar(@@max_precision)
go

select * from dbo.f2_operator_atatvar(@@max_precision-1)
go