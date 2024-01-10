-- bit AND/OR/XOR
select 99&-5
go
select 99&+5
go
select 99&~5
go
declare @v int = 99 set @v = 123&@v select @v
go

select 88|-~+2
go
select 88|+~+2
go
select 88|~~+2
go
declare @v int = 88 set @v = 123|@v select @v
go

select 77^-~+2
go
select 77^+~+2
go
select 77^~~+2
go
declare @v int = 77 set @v = 123^@v select @v
go
declare @v int = 10&+2 set @v = @v|-9 select @v
go
select * from v1_bitop
go
execute p1_bitop
go
print 99&+2 
go
print 99&~1
go


-- bit NOT
select ~+2
go
select +~+2
go
select -~+2
go
select ~-2
go
select +~-2
go
select -~-2
go
select +~2
go
select -~2
go
select ~~2
go
select ~~~~~2
go
select ~~~~~+2
go
select +~~~~~+2
go
select -~~~~~+2
go
select ~~~~~+2
go
select +~~~~~-2
go
select -~~~~~-2
go
select ~@@max_precision
go
declare @v int = 2 set @v = ~@@max_precision select @v
go
declare @v int = 2 set @v = ~@v select @v
go
select * from v1_bitop_not
go
execute p1_bitop_not 
go
print ~+10
go
declare @v int = 10 print ~@v
go

-- modulo
select 10%-3
go
select 10%+3
go
select 100%@@max_precision
go
declare @v int select 99%@v
go
select * from v1_modulo_op
go
exec p1_modulo_op
go
declare @v int =10%+3 select @v
go
declare @v int =10%+~3 select @v
go
declare @v int =10%~+3 select @v
go
declare @v int = 10 set @v = 3%@v select @v
go

-- many expressions in one SELECT:
select 99&-5,99&+5,99&~5,99&-5,99&+5,99&~5,88|-~+2,88|+~+2,88|~~+2,77^-~+2,77^+~+2,77^~~+2,+~+2,~-2,+~-2-~-2,~~~~~2,+~~~~~-2,10%-3,10%+3,10%3,100%@@max_precision
go
select * from v1_bitop_all
go
execute p1_bitop_all
go

-- already supported before this fix
select 12|~+2
go
select 10%3
go
select 99&5
go
select ~2
go
select ~ 2
go
select ~ + 2
go
select ~ - 2
go
select ~ ~ ~ 2
go
declare @v int = 2 select @v = ~@v select @v
go
declare @v int =~2 select @v
go
declare @v int = 10 set @v %=3 select @v
go

-- invalid syntax in SQL Server
select 1~+2
go
-- invalid syntax in SQL Server
select 1 ~ 2
go
