-- simple variables in T-SQL batch
set quoted_identifier off
go
declare @@v int = 2 select @@v
go
declare @#v int = 2 select @#v
go
declare @@@$$@@@@v int = 2 select @@@$$@@@@v
go
declare @@@$$@@@@v##### int = 2 select @@@$$@@@@v#####
go
declare @@@$$@@@@#####v int = 2 select @@@$$@@@@#####v
go
declare @#############v int = 2 select @#############v
go

-- 63 long
declare @@v63_7890123456789$123456789$123456789012345678901234567890123 int = 2 
select  @@v63_7890123456789$123456789$123456789012345678901234567890123
go
-- 64 long
declare @@v64_7890123456789$123456789$1234567890123456789012345678901234 int = 2 
select  @@v64_7890123456789$123456789$1234567890123456789012345678901234
go
-- maximum length in T-SQL is 128
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 2 
select  @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go

declare @#v63_7890123456789$123456789$123456789012345678901234567890123 int = 2 
select  @#v63_7890123456789$123456789$123456789012345678901234567890123
go
declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int = 2 
select  @#v64_7890123456789$123456789$1234567890123456789012345678901234
go
declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 2 
select  @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go
declare @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ int = 2 
select  @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@
go

-- referencing global @@variable, in T-SQL batch, procedure, trigger and function
declare @@v int
select 1
set @@v = @@rowcount
select @@v
go

declare @@@$$@@@@v int, @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int
select 1
set @@@$$@@@@v = @@rowcount
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@pgerror
select @@@$$@@@@v, @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go

declare @@v63_7890123456789$123456789$123456789012345678901234567890123 int 
set @@v63_7890123456789$123456789$123456789012345678901234567890123 = @@rowcount
select @@v63_7890123456789$123456789$123456789012345678901234567890123
go

declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int 
set @#v64_7890123456789$123456789$1234567890123456789012345678901234 = @@rowcount
select @#v64_7890123456789$123456789$1234567890123456789012345678901234
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@rowcount
select @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go

create procedure p1_atatuservar
as
declare @@v int
select 1
set @@v = @@rowcount
select @@v

declare @#v int
select 1
set @#v = @@rowcount
select @#v
go
exec p1_atatuservar
go

create procedure p2_atatuservar
as
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int, @@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int
select 1
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@rowcount
select @@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@pgerror
select @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678,  @@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678

declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int
select 1
set @#v64_7890123456789$123456789$1234567890123456789012345678901234 = @@rowcount
select @#v64_7890123456789$123456789$1234567890123456789012345678901234
go
exec p2_atatuservar
go

create trigger tr1_atatuservar on t1_trigger_atatuservar for insert
as
begin
select 'trigger tr1_atatuservar'	
declare @@v int
select 1
set @@v = @@rowcount
select @@v

declare @#v int
select 1
set @#v = @@rowcount
select @#v
end
go
insert t1_trigger_atatuservar values (123)
go

create trigger tr2_atatuservar on t2_trigger_atatuservar for insert
as
begin
select 'trigger tr2_atatuservar'	

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int
select 1
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@rowcount
select @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678

declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int
select 1
set @#v64_7890123456789$123456789$1234567890123456789012345678901234 = @@rowcount
select @#v64_7890123456789$123456789$1234567890123456789012345678901234
end
go
insert t2_trigger_atatuservar values (123)
go

create function f1_atatuservar() returns int
as
begin
declare @@v int, @@v2 int
select @@v2 = count(*) from t1_atatuservar
set @@v = @@rowcount

declare @#v int, @#v2 int
select @#v2 = count(*) from t1_atatuservar
set @#v = @@rowcount

return @@v * @#v
end
go
select dbo.f1_atatuservar()
go

create function f2_atatuservar() returns int
as
begin
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int, @#v64_7890123456789$123456789$1234567890123456789012345678901234 int
select @#v64_7890123456789$123456789$1234567890123456789012345678901234 = count(*) from t1_atatuservar
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@rowcount

return @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 * @#v64_7890123456789$123456789$1234567890123456789012345678901234
end
go
select dbo.f2_atatuservar()
go

create trigger tr3_atatuservar on t3_trigger_atatuservar for insert
as
begin
select 'trigger tr3_atatuservar'	
declare @@v int, @@v2 int
select @@v2 = count(*) from t1_atatuservar
set @@v = @@rowcount
select @@v

declare @#v int, @#v2 int
select @#v2 = count(*) from t1_atatuservar
set @#v = @@rowcount
select @#v
end
go
insert t3_trigger_atatuservar values (123)
go

-- assuming @@servername is BABELFISH
declare @v varchar(50)
set @v = @@servername
select @v
go

declare @v int
set @v = len(@@servername)
select @v
go

create procedure p3_atatuservar
as
declare @v varchar(50)
set @v = @@servername
select @v

declare @v2 int
set @v2 = len(@@servername)
select @v2
go
exec p3_atatuservar
go

create function f3_atatuservar(@#p1 varchar(30)) returns int
as
begin
declare @@v int
set @@v = len(@@servername)
return @@v * len(@#p1)
end
go
select dbo.f3_atatuservar(@@servername)
go

create trigger tr4_atatuservar on t4_trigger_atatuservar for insert
as
begin
select 'trigger tr4_atatuservar'	
declare @@v int
set @@v = len(@@servername)
select @@v
end
go
insert t4_trigger_atatuservar values (123)
go

-- procedure call with named/unnamed arguments, output parameters, return status, in T-SQL batch, procedure, trigger
create procedure p4_atatuservar @@p1 int
as select @@p1
return @@p1*-1
go
exec p4_atatuservar 123
go
exec p4_atatuservar @@p1=123
go
declare @@v int = 987
exec p4_atatuservar @@p1=@@v
go
declare @@v int
exec @@v = p4_atatuservar @@p1=123
select @@v
go

create procedure p19_atatuservar @#p19_atatuservar int
as select @#p19_atatuservar
return @#p19_atatuservar*-1
go
exec p19_atatuservar @@max_precision
go
exec p19_atatuservar @#p19_atatuservar=@@max_precision
go
declare @#v int = @@max_precision
exec p19_atatuservar @#p19_atatuservar=@#v
go
declare @#v int
exec @#v = p19_atatuservar @#p19_atatuservar=@@max_precision
select @#v
go

create procedure p5_atatuservar
as
declare @@v int
exec @@v = p4_atatuservar @@p1=123
select @@v

declare @#v int
exec @#v = p4_atatuservar @@p1=123
select @#v
go
exec p5_atatuservar
go

create procedure p6_atatuservar @@p4 int output
as
set @@p4 *= 2
select @@p4
return @@p4*-1
go
declare @#v1 int, @@v2 int = 123
exec @#v1 = p6_atatuservar @@v2
select @#v1, @@v2
go

declare @#v1 int, @@v2 int = 123
exec @#v1 = p6_atatuservar @@p4 = @@v2 out
select @#v1, @@v2
go

create procedure p7_atatuservar
as
declare @#v1 int, @@v2 int = 123
exec @#v1 = p6_atatuservar @@v2 output
select @#v1, @@v2
go

create procedure p8_atatuservar @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int output
as
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 *= 2
select @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
return @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678*-1
go
declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int, @@v63_7890123456789$123456789$123456789012345678901234567890123 int = 123
exec @#v64_7890123456789$123456789$1234567890123456789012345678901234 = p8_atatuservar @@v63_7890123456789$123456789$123456789012345678901234567890123
select @#v64_7890123456789$123456789$1234567890123456789012345678901234, @@v63_7890123456789$123456789$123456789012345678901234567890123
go

declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int, @@v63_7890123456789$123456789$123456789012345678901234567890123 int = 123
exec @#v64_7890123456789$123456789$1234567890123456789012345678901234 = p8_atatuservar @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = @@v63_7890123456789$123456789$123456789012345678901234567890123 out
select @#v64_7890123456789$123456789$1234567890123456789012345678901234, @@v63_7890123456789$123456789$123456789012345678901234567890123
go

create procedure p9_atatuservar
as
declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int, @@v63_7890123456789$123456789$123456789012345678901234567890123 int = 123
exec @#v64_7890123456789$123456789$1234567890123456789012345678901234 = p8_atatuservar @@v63_7890123456789$123456789$123456789012345678901234567890123 output
select @#v64_7890123456789$123456789$1234567890123456789012345678901234, @@v63_7890123456789$123456789$123456789012345678901234567890123
go

create trigger tr5_atatuservar on t5_trigger_atatuservar for insert
as
begin
select 'trigger tr5_atatuservar'		
declare @@v int
exec @@v = p4_atatuservar @@p1=123
select @@v

declare @#v int
exec @#v = p4_atatuservar @@p1=123
select @#v
end
go
insert t5_trigger_atatuservar values (123)
go

create trigger tr6_atatuservar on t6_trigger_atatuservar for insert
as
begin
select 'trigger tr6_atatuservar'		

declare @#v64_7890123456789$123456789$1234567890123456789012345678901234 int, @@v63_7890123456789$123456789$123456789012345678901234567890123 int = 123
exec @#v64_7890123456789$123456789$1234567890123456789012345678901234 = p8_atatuservar @@v63_7890123456789$123456789$123456789012345678901234567890123 output
select @#v64_7890123456789$123456789$1234567890123456789012345678901234, @@v63_7890123456789$123456789$123456789012345678901234567890123
end
go
insert t6_trigger_atatuservar values (123)
go

-- misc variable usage in expressions
declare @#v int = 3
set @#v *= -1
set @#v = @#v + 10*@#v
select @#v = @#v + 1
if @#v > 0 select 'positive' else select 'negative'
select @#v, @#V, '@#v'
print @#v -- PRINT output not captured by JDBC tests
go

declare @@v int = 3
set @@v *= -1
set @@v = @@v + 10*@@v
select @@v = @@v + 1
if @@v > 0 select 'positive' else select 'negative'
select @@v , @@V, '@@v'
print @@V -- PRINT output not captured by JDBC tests
go

create procedure p10_atatuservar
as
declare @#v int = 3
set @#v *= -1
set @#v = @#v + 10*@#v
select @#v = @#v + 1
if @#v > 0 select 'positive' else select 'negative'
select @#v, @#V, '@#v'
print @#v -- PRINT output not captured by JDBC tests

declare @@v int = 3
set @@v *= -1
set @@v = @@v + 10*@@v
select @@v = @@v + 1
if @@v > 0 select 'positive' else select 'negative'
select @@v , @@V, '@@v'
print @@V -- PRINT output not captured by JDBC tests
go
exec p10_atatuservar
go

declare @@c varchar(20)='abcd', @#v1 int=2, @v2@# int=1
select substring(@@c, @#v1, @v2@#)
go

declare @@v1 varchar(20)='row 1', @#v2 varchar(20)='row 3'
select * from t1_atatuservar where c in (@@v1,  @#v2) order by 1
go

declare @@v1 varchar(20)='1', @#v2 varchar(20)='3'
select * from t1_atatuservar where c like '%'+@@v1 or c like '%'+@#v2 order by 1
go

create procedure p11_atatuservar
as
declare @@c varchar(20)='abcd', @#v int=2, @v@# int=1
select substring(@@c, @#v, @v@#)

declare @@v1 varchar(20)='row 1', @#v1 varchar(20)='row 3'
select * from t1_atatuservar where c in (@@v1,  @#v1) order by 1

declare @@v2 varchar(20)='1', @#v2 varchar(20)='3'
select * from t1_atatuservar where c like '%'+@@v2 or c like '%'+@#v2 order by 1
go
exec p11_atatuservar
go

create function f4_atatuservar (@@p1 int, @#p2 int, @p5_atatuservar int)
returns table
as
return (select @@p1*@#p2*@p5_atatuservar as x where @@p1 = 123 or @#p2 = 10 or @p5_atatuservar = 1)
go
select * from dbo.f4_atatuservar(123, 20, 2)
go
select * from dbo.f4_atatuservar(345, 10, 2)
go
select * from dbo.f4_atatuservar(345, 20, 1)
go

declare @@c varchar(30), @#v int=1, @#v2 int=2
set @@c = case when @#v > 0 then '> zero' else '<- zero' end
select @@c
set @@c = case @#v when 0 then 'zero' else '<> zero' end
select @@c
set @@c = case @#v when 0 then 'zero' when @#v2 then 'case 2' else 'something else' end
select @@c
set @@c = case @#v+@#v when 0 then 'zero' when @#v2 then 'case 2' else 'something else' end
select @@c
go

create procedure p22_atatuservar
as
declare @@c varchar(30), @#v int=1, @#v2 int=2
set @@c = case when @#v > 0 then '> zero' else '<- zero' end
select @@c
set @@c = case @#v when 0 then 'zero' else '<> zero' end
select @@c
set @@c = case @#v when 0 then 'zero' when @#v2 then 'case 2' else 'something else' end
select @@c
set @@c = case @#v+@#v when 0 then 'zero' when @#v2 then 'case 2' else 'something else' end
select @@c
go
exec p22_atatuservar
go

create trigger tr7_atatuservar on t7_trigger_atatuservar for insert
as
begin
select 'trigger tr7_atatuservar'		

declare @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################ varchar(30), @#v64_7890123456789$123456789$1234567890123456789012345678901234 int=1, @#w64_7890123456789$123456789$1234567890123456789012345678901234 int=2
set @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################ = case when @#v64_7890123456789$123456789$1234567890123456789012345678901234 > 0 then '> zero' else '<- zero' end
select @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################
set @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################ = case @#v64_7890123456789$123456789$1234567890123456789012345678901234 when 0 then 'zero' else '<> zero' end
select @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################
set @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################ = case @#v64_7890123456789$123456789$1234567890123456789012345678901234 when 0 then 'zero' when @#w64_7890123456789$123456789$1234567890123456789012345678901234 then 'case 2' else 'something else' end
select @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################
set @@z128_@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@_____############################################################ = case @#v64_7890123456789$123456789$1234567890123456789012345678901234+@#v64_7890123456789$123456789$1234567890123456789012345678901234 when 0 then 'zero' when @#w64_7890123456789$123456789$1234567890123456789012345678901234 then 'case 2' else 'something else' end

declare @#x64_7890123456789$123456789$1234567890123456789012345678901234 int = 3
set @#x64_7890123456789$123456789$1234567890123456789012345678901234 *= -1
set @#x64_7890123456789$123456789$1234567890123456789012345678901234 = @#x64_7890123456789$123456789$1234567890123456789012345678901234 + 10*@#x64_7890123456789$123456789$1234567890123456789012345678901234
select @#x64_7890123456789$123456789$1234567890123456789012345678901234 = @#x64_7890123456789$123456789$1234567890123456789012345678901234 + 1
if @#x64_7890123456789$123456789$1234567890123456789012345678901234 > 0 select 'positive' else select 'negative'
select @#x64_7890123456789$123456789$1234567890123456789012345678901234, @#x64_7890123456789$123456789$1234567890123456789012345678901234, '@#x64_7890123456789$123456789$1234567890123456789012345678901234'
print @#x64_7890123456789$123456789$1234567890123456789012345678901234 -- PRINT output not captured by JDBC tests

declare @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ int = 3
set @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ *= -1
set @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ = @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ + 10*@@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@
select @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ = @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ + 1
if @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ > 0 select 'positive' else select 'negative'
select @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ , @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@, '@@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@'
print @@v128_@@@$$@@@@$$@########@@@$$@@@@$$@@@@$$@@@###__##@@@$$@@@@$$@@@@$$@@@@$$@@@______@@@$$@@@@$$@@@@$$@@@###########@@@$$@@@@@@ -- PRINT output not captured by JDBC tests

declare @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@ varchar(20)='abcd', @#p64_7890123456789$123456789$1234567890123456789012345678901234 int=2, @@#q64_890123456789$123456789$1234567890123456789012345678901234 int=1
select substring(@@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@, @#p64_7890123456789$123456789$1234567890123456789012345678901234, @@#q64_890123456789$123456789$1234567890123456789012345678901234)

declare @@q64_7890123456789$123456789$1234567890123456789012345678901234 varchar(20)='1', @#q4_7890123456789$123456789$1234567890123456789012345678901234 varchar(20)='3'
select * from t1_atatuservar where c like '%'+@@q64_7890123456789$123456789$1234567890123456789012345678901234 or c like '%'+@#q4_7890123456789$123456789$1234567890123456789012345678901234 order by 1
end
go
insert t7_trigger_atatuservar values (123)
go

-- table variables, in T-SQL batch, procedure and trigger (functions are below)
declare @@v table (a int)
insert @@v values (123)
select * from @@v
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table (a int)
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values (123)
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go

declare @#v table (a int)
insert @#v values (123)
insert @#v select * from @#v
select * from @#v
update @#v set a = a + 1
select * from @#v
set rowcount 1
delete @#v
set rowcount 0
select * from @#v
go

declare @@V table (a int)
insert @@v values (123)
insert @@v select * from @@v
select * from @@v
update @@v set a = a + 1
select * from @@v
set rowcount 1
delete @@v
set rowcount 0
select * from @@v
go

create procedure p12_atatuservar
as
declare @#v table (a int)
insert @#v values (123)
insert @#v select * from @#v
select * from @#v
update @#v set a = a + 1
select * from @#v
set rowcount 1
delete @#v
set rowcount 0
select * from @#v

declare @@V table (a int)
insert @@v values (123)
insert @@v select * from @@v
select * from @@v
update @@v set a = a + 1
select * from @@v
set rowcount 1
delete @@v
set rowcount 0
select * from @@v
go
exec p12_atatuservar
go

create procedure p13_atatuservar
as
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table (a int)
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values (123)
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
update @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 set a = a + 1
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
set rowcount 1
delete @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
set rowcount 0
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go
exec p13_atatuservar
go

create trigger tr8_atatuservar on t8_trigger_atatuservar for insert
as
begin
select 'trigger tr8_atatuservar'	

declare @#v table (a int)
insert @#v values (123)
insert @#v select * from @#v
select * from @#v
update @#v set a = a + 1
select * from @#v
set rowcount 1
delete @#v
set rowcount 0
select * from @#v

declare @@V table (a int)
insert @@v values (123)
insert @@v select * from @@v
select * from @@v
update @@v set a = a + 1
select * from @@v
set rowcount 1
delete @@v
set rowcount 0
select * from @@v
end
go
insert t8_trigger_atatuservar values (123)
go

create trigger tr9_atatuservar on t9_trigger_atatuservar for insert
as
begin
select 'trigger tr9_atatuservar'	

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table (a int)
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values (123)
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
update @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 set a = a + 1
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
set rowcount 1
delete @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
set rowcount 0
select * from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
end
go
insert t9_trigger_atatuservar values (123)
go

-- @@rowcount
declare @@V int = 1
set rowcount @@v
select * from t1_atatuservar order by 1
set @@v = 0
set rowcount @@v
select * from t1_atatuservar order by 1
go

declare @#V int = 1
set rowcount @#v
select * from t1_atatuservar order by 1
set @#v = 0
set rowcount @#v
select * from t1_atatuservar order by 1
go

create procedure p14_atatuservar
as
declare @@V int = 1
set rowcount @@v
select * from t1_atatuservar order by 1
set @@v = 0
set rowcount @@v
select * from t1_atatuservar order by 1

declare @#V int = 1
set rowcount @#v
select * from t1_atatuservar order by 1
set @#v = 0
set rowcount @#v
select * from t1_atatuservar order by 1
go
exec p14_atatuservar
go

create trigger tr10_atatuservar on t10_trigger_atatuservar for insert
as
begin
select 'trigger tr10_atatuservar'	

declare @@V int = 1
set rowcount @@v
select * from t1_atatuservar order by 1
set @@v = 0
set rowcount @@v
select * from t1_atatuservar order by 1

declare @#V int = 1
set rowcount @#v
select * from t1_atatuservar order by 1
set @#v = 0
set rowcount @#v
select * from t1_atatuservar order by 1
end
go
insert t10_trigger_atatuservar values (123)
go

create function f1_atatuservar_extra_long_name_here()
returns @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table (a int)
as
begin
insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
values (123)
return
end
go
select * from f1_atatuservar_extra_long_name_here()
go

create function f2_atatuservar_extra_long_name_here()
returns @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table (a int)
as
begin
insert @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
values (123)
return
end
go
select * from f2_atatuservar_extra_long_name_here()
go

-- in SET statements that support variable argument, procedure and trigger (functions are below)
declare @@v int = 4
set datefirst @@v
select datepart(dw, '2024-10-21')
go
set datefirst 7
go

declare @#v int = 5
set datefirst @#v
select datepart(dw, '2024-10-21')
go
set datefirst 7
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 5
set datefirst @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select datepart(dw, '2024-10-21')
go
set datefirst 7
go

-- SET DATEFORMAT currently ignores the argument and will always use 'mdy'
declare @@v varchar(10) = 'dmy'
set dateformat @@v
select cast('01/02/03' as datetime)
go
set dateformat mdy
go

-- SET DATEFORMAT currently silently ignores the argument and will always use 'mdy'
declare @#v varchar(10) = 'dmy'
set dateformat @#v
select cast('01/02/03' as datetime)
go
set dateformat mdy
go

-- SET DATEFORMAT currently silently ignores the argument and will always use 'mdy'
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'dmy'
set dateformat @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select cast('01/02/03' as datetime)
go
set dateformat mdy
go

-- SET LANGUAGE currently only supports english
declare @@v varchar(10) = 'dutch'
set language @@v
select @@language
go
set language us_english
go
declare @#v varchar(10) = 'french'
set language @#v
select @@language
go
set language us_english
go
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'french'
set language @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select @@language
go
set language us_english
go

create procedure p15_atatuservar
as
declare @@v1 int = 4
set datefirst @@v1
select datepart(dw, '2024-10-21')

declare @#v1 int = 5
set datefirst @#v1
select datepart(dw, '2024-10-21')

declare @@v2 varchar(10) = 'dmy'
set dateformat @@v2
select cast('01/02/03' as datetime)

declare @#v3 varchar(10) = 'dutch'
set language @#v3
select @@language
go

exec p15_atatuservar
go
set datefirst 7
set dateformat mdy
set language us_english
go
create procedure p16_atatuservar
as
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 4
set datefirst @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select datepart(dw, '2024-10-21')

declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 5
set datefirst @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select datepart(dw, '2024-10-21')

declare @@w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'dmy'
set dateformat @@w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select cast('01/02/03' as datetime)

declare @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'dutch'
set language @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select @@language
go
exec p15_atatuservar
go
set datefirst 7
set dateformat mdy
set language us_english
go

create trigger tr11_atatuservar on t11_trigger_atatuservar for insert
as
begin
select 'trigger tr11_atatuservar'	
	
declare @@v1 int = 4
set datefirst @@v1
select datepart(dw, '2024-10-21')

declare @#v1 int = 5
set datefirst @#v1
select datepart(dw, '2024-10-21')

declare @@v2 varchar(10) = 'dmy'
set dateformat @@v2
select cast('01/02/03' as datetime)

declare @#v3 varchar(10) = 'dutch'
set language @#v3
select @@language
end
go
insert t11_trigger_atatuservar values (123)
go
set datefirst 7
set dateformat mdy
set language us_english
go

create trigger tr12_atatuservar on t12_trigger_atatuservar for insert
as
begin
select 'trigger tr12_atatuservar'	
	
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 4
set datefirst @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select datepart(dw, '2024-10-21')

declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 5
set datefirst @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select datepart(dw, '2024-10-21')

declare @@w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'dmy'
set dateformat @@w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select cast('01/02/03' as datetime)

declare @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(10) = 'dutch'
set language @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select @@language
end
go
insert t12_trigger_atatuservar values (123)
go
set datefirst 7
set dateformat mdy
set language us_english
go

-- execute-immediate, procedure and trigger
declare @@V varchar(50) = 'select 123' execute(@@v)
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(50) = 'select 123' execute(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
go

declare @@V varchar(50) = 'declare @#v int =123 select @#v'
execute(@@v)
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(500) = 'declare @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int =123 select @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678'
execute(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
go

declare @@V varchar(50) = 'declare @#v int =123 select @#v'
execute('select 456 ' + @@v)
go

declare @#V varchar(50) = 'declare @@v int =123 select @@v'
execute(@#v)
go

declare @#V varchar(50) = 'declare @@v int =123 select @@v'
execute('select 456 ' + @#v)
go

declare @#V varchar(50) = 'select 123 '
execute(@#v + @#v)
go

declare @#V varchar(50) = 'select 123 ',  @@V varchar(50) = 'select 456 '
execute(@#v + @@v + @@v + @#v)
go

declare @@V varchar(50) = 'select "abc''def" '
execute(@@v + 'select "xy''z" ' + @@V)
go

create procedure p17_atatuservar
as
declare @#V1 varchar(50) = 'declare @@v int =123 select @@v'
execute('select 456 ' + @#v1)

declare @#V2 varchar(50) = 'select 123 '
execute(@#v2 + @#v2)

declare @#V3 varchar(50) = 'select 123 ',  @@V varchar(50) = 'select 456 '
execute(@#v3 + @@v + @@v + @#v3)

declare @@V4 varchar(50) = 'select "abc''def" '
execute(@@v4 + 'select "xy''z" ' + @@V4)
go
exec p17_atatuservar
go

create trigger tr13_atatuservar on t13_trigger_atatuservar for insert
as
begin
select 'trigger tr13_atatuservar'	

declare @#V1 varchar(50) = 'declare @@v int =123 select @@v'
execute('select 456 ' + @#v1)

declare @#V2 varchar(50) = 'select 123 '
execute(@#v2 + @#v2)

declare @#V3 varchar(50) = 'select 123 ',  @@V varchar(50) = 'select 456 '
execute(@#v3 + @@v + @@v + @#v3)

declare @@V4 varchar(50) = 'select "abc''def" '
execute(@@v4 + 'select "xy''z" ' + @@V4)
end
go
insert t13_trigger_atatuservar values (123)
go

create procedure p18_atatuservar
as
begin
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(500) = 'declare @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int =123 select @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678'
execute(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
end
go
exec p18_atatuservar
go

create trigger tr14_atatuservar on t14_trigger_atatuservar for insert
as
begin
select 'trigger tr14_atatuservar'	

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(500) = 'declare @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int =123 select @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678'
execute(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
end
go
insert t14_trigger_atatuservar values (123)
go

-- RAISERROR, procedure and trigger
declare @@v int=50001
raiserror(@@v,1,1)
go

declare @@v int=50001, @@v2 int=1
raiserror(@@v,@@v2,1)
go

declare @@v int=50001, @@v2 int=1, @#v3 int=1
raiserror(@@v,@@v2,@#v3)
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=50001, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=1, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@ int=1
raiserror(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@)
go

create procedure p1_raiserror_atatuservar
as
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=50001, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=1, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@ int=1
raiserror(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@)
go
exec p1_raiserror_atatuservar
go

create trigger tr15_atatuservar on t15_trigger_atatuservar for insert
as
begin
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=50001, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=1, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@ int=1
raiserror(@@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#w128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @@y128_############################################______@@@$$@@@@$$@@@@__###############@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@$$@@@@)
end
go
insert t15_trigger_atatuservar values (123)
go


-- sp_executesql with named/unnamed arguments, output parameters, in T-SQL batch, procedure, trigger
exec sp_executesql N'declare @@v int=123 select @@v'
go

exec sp_executesql N'SELECT @@v1, @#v2', N'@@v1 int, @#v2 varchar(20)', @#v2='Hello, World!', @@v1=123
go

declare @@sql nvarchar(50)=N'SELECT @@v1, @#v2'
exec sp_executesql @@sql, N'@@v1 int, @#v2 varchar(20)', @#v2='Hello, World!', @@v1=123
go

declare @@params nvarchar(50)=N'@@v1 int, @#v2 varchar(20)'
exec sp_executesql N'SELECT @@v1, @#v2', @@params, @#v2='Hello, World!', @@v1=123
go

declare @@sql nvarchar(50)=N'SELECT @@v1, @#v2'
declare @@params nvarchar(50)=N'@@v1 int, @#v2 varchar(20)'
exec sp_executesql @@sql, @@params, @#v2='Hello, World!', @@v1=123
go

declare @@sql nvarchar(50)=N'SELECT @@v1, @#v2', @@params nvarchar(50)=N'@@v1 int, @#v2 varchar(20)', @@v3 int=123, @#v4 varchar(20)='Hello, World!'
exec sp_executesql @@sql, @@params, @#v2=@#v4, @@v1=@@v3
go

declare @@SQLString1 NVARCHAR(100);
declare @#SQLString2 NVARCHAR(max);
declare @@ParamDef NVARCHAR(100);
SET @@SQLString1 = N'SET @#a = @@b + @@b';
SET @#SQLString2 = N'EXEC sp_executesql N''SET @#a = @@b + @@b'', N''@#a INT OUT, @@b INT'', @#a OUTPUT, @@b;';
SET @@ParamDef = N'@#a INT OUTPUT, @@b INT';
declare @@p INT;
declare @#a INT;
EXEC sp_executesql @@SQLString1, @@ParamDef, @#a = @@p OUT, @@b = 10;
EXEC sp_executesql @#SQLString2, @@ParamDef, @#a = @#a OUT, @@b = 11;
SELECT @@p, @#a;
go

create procedure p1_spexec_atatuservar
as
declare @@sql nvarchar(50)=N'SELECT @@v1, @#v2', @@params nvarchar(50)=N'@@v1 int, @#v2 varchar(20)', @@v3 int=123, @#v4 varchar(20)='Hello, World!'
exec sp_executesql @@sql, @@params, @#v2=@#v4, @@v1=@@v3
declare @@SQLString1 NVARCHAR(100)
declare @#SQLString2 NVARCHAR(max)
declare @@ParamDef NVARCHAR(100)
SET @@SQLString1 = N'SET @#a = @@b + @@b'
SET @#SQLString2 = N'EXEC sp_executesql N''SET @#a = @@b + @@b'', N''@#a INT OUT, @@b INT'', @#a OUT, @@b'
SET @@ParamDef = N'@#a INT OUTPUT, @@b INT'
declare @@p INT
declare @#a INT
EXEC sp_executesql @@SQLString1, @@ParamDef, @#a = @@p OUT, @@b = 10
EXEC sp_executesql @#SQLString2, @@ParamDef, @#a = @#a OUT, @@b = 11
SELECT @@p, @#a
go
exec p1_spexec_atatuservar
go

create trigger tr16_atatuservar on t16_trigger_atatuservar for insert
as
begin
select 'trigger tr16_atatuservar'	

declare @@sql nvarchar(50)=N'SELECT @@v1, @#v2', @@params nvarchar(50)=N'@@v1 int, @#v2 varchar(20)', @@v3 int=123, @#v4 varchar(20)='Hello, World!'
exec sp_executesql @@sql, @@params, @#v2=@#v4, @@v1=@@v3
declare @@SQLString1 NVARCHAR(100)
declare @#SQLString2 NVARCHAR(max)
declare @@ParamDef NVARCHAR(100)
SET @@SQLString1 = N'SET @#a = @@b + @@b'
SET @#SQLString2 = N'EXEC sp_executesql N''SET @#a = @@b + @@b'', N''@#a INT OUT, @@b INT'', @#a OUT, @@b'
SET @@ParamDef = N'@#a INT OUTPUT, @@b INT'
declare @@p INT
declare @#a INT
EXEC sp_executesql @@SQLString1, @@ParamDef, @#a = @@p OUT, @@b = 10
EXEC sp_executesql @#SQLString2, @@ParamDef, @#a = @#a OUT, @@b = 11
SELECT @@p, @#a	
end
go
insert t16_trigger_atatuservar values (123)
go

declare @@v63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
declare @#w63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(max);
declare @@x63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
SET @@v63_7890123456789$123456789$123456789012345678901234567890123 = N'SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123';
SET @#w63_7890123456789$123456789$123456789012345678901234567890123 = N'EXEC sp_executesql N''SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123'', N''@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT'', @@z63_7890123456789$123456789$123456789012345678901234567890123 OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123;';
SET @@x63_7890123456789$123456789$123456789012345678901234567890123 = N'@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT';
declare @#y63_7890123456789$123456789$123456789012345678901234567890123 INT;
declare @@z63_7890123456789$123456789$123456789012345678901234567890123 INT;
EXEC sp_executesql @@v63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @#y63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 10;
EXEC sp_executesql @#w63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@z63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 11;
SELECT @#y63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123;
go

create procedure p2_spexec_atatuservar
as
declare @@v63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
declare @#w63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(max);
declare @@x63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
SET @@v63_7890123456789$123456789$123456789012345678901234567890123 = N'SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123';
SET @#w63_7890123456789$123456789$123456789012345678901234567890123 = N'EXEC sp_executesql N''SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123'', N''@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT'', @@z63_7890123456789$123456789$123456789012345678901234567890123 OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123;';
SET @@x63_7890123456789$123456789$123456789012345678901234567890123 = N'@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT';
declare @#y63_7890123456789$123456789$123456789012345678901234567890123 INT;
declare @@z63_7890123456789$123456789$123456789012345678901234567890123 INT;
EXEC sp_executesql @@v63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @#y63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 10;
EXEC sp_executesql @#w63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@z63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 11;
SELECT @#y63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123;
go
exec p2_spexec_atatuservar
go


create trigger tr17_atatuservar on t17_trigger_atatuservar for insert
as
begin
select 'trigger tr17_atatuservar'	

declare @@v63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
declare @#w63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(max);
declare @@x63_7890123456789$123456789$123456789012345678901234567890123 NVARCHAR(1000);
SET @@v63_7890123456789$123456789$123456789012345678901234567890123 = N'SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123';
SET @#w63_7890123456789$123456789$123456789012345678901234567890123 = N'EXEC sp_executesql N''SET @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@p63_7890123456789$123456789$123456789012345678901234567890123 + @@p63_7890123456789$123456789$123456789012345678901234567890123'', N''@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT'', @@z63_7890123456789$123456789$123456789012345678901234567890123 OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123;';
SET @@x63_7890123456789$123456789$123456789012345678901234567890123 = N'@@z63_7890123456789$123456789$123456789012345678901234567890123 INT OUTPUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 INT';
declare @#y63_7890123456789$123456789$123456789012345678901234567890123 INT;
declare @@z63_7890123456789$123456789$123456789012345678901234567890123 INT;
EXEC sp_executesql @@v63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @#y63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 10;
EXEC sp_executesql @#w63_7890123456789$123456789$123456789012345678901234567890123, @@x63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123 = @@z63_7890123456789$123456789$123456789012345678901234567890123 OUT, @@p63_7890123456789$123456789$123456789012345678901234567890123 = 11;
SELECT @#y63_7890123456789$123456789$123456789012345678901234567890123, @@z63_7890123456789$123456789$123456789012345678901234567890123;
end
go
insert t17_trigger_atatuservar values (123)
go

-- table variables in different types of functions
create function f1_ins_atatuservar(@@p1 int)
returns int
as
begin
	declare @@tv table(a int)
    insert @@tv values(@@p1)
    return (select sum(a) from @@tv)
end
go
select dbo. f1_ins_atatuservar(123)
go

create function f1_upd_atatuservar(@@p1 int)
returns int
as
begin
	declare @@tv table(a int)
    insert @@tv values(@@p1)
    update @@tv set a = a + 1
    return (select sum(a) from @@tv)
end
go
select dbo. f1_upd_atatuservar(123)
go

create function f1_del_atatuservar(@@p1 int)
returns int
as
begin
	declare @@tv table(a int)
    insert @@tv values(@@p1)
    update @@tv set a = a + 1
    insert @@tv values(@@p1)
    update @@tv set a = a + 1
    delete @@tv where a = 124
    return (select sum(a) from @@tv)
end
go
select dbo. f1_del_atatuservar(123)
go

-- INSERT/UPDATE/DELETE on table variable in function
create function f3_atatuservar_upd(@@p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@@p1)
    update t set a = t.a + 1 from @@tv as t
    return
end
go
select * from dbo. f3_atatuservar_upd(123) order by 1
go

create function f3_atatuservar_del(@@p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@@p1)
    update @@tv set a = a + 1
    insert @@tv values(@@p1)
    delete t from @@tv as t where a = 124
    return
end
go
select * from dbo. f3_atatuservar_del(123) order by 1
go

create function f3_upd_atatuservar(@@p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@@p1)
    update t set a = t.a + 1 from t2_atatuservar, @@tv as t where t2_atatuservar.a = t.a
    return
end
go
select * from dbo. f3_upd_atatuservar(123) order by 1
go

create function f3_del_atatuservar(@@p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@@p1)
    update @@tv set a = a + 1
    insert @@tv values(@@p1)
    delete t from t2_atatuservar join @@tv as t on t2_atatuservar.a = t.a
    return
end
go
select * from dbo. f3_del_atatuservar(123) order by 1
go

create function f4_ins_atatuservar(@#p1 int)
returns int
as
begin
	declare @#tv table(a int)
    insert @#tv values(@#p1)
    return (select sum(a) from @#tv)
end
go
select dbo. f4_ins_atatuservar(123)
go

create function f4_upd_atatuservar(@#p1 int)
returns int
as
begin
	declare @#tv table(a int)
    insert @#tv values(@#p1)
    update @#tv set a = a + 1
    return (select sum(a) from @#tv)
end
go
select dbo. f4_upd_atatuservar(123)
go

create function f4_del_atatuservar(@#p1 int)
returns int
as
begin
	declare @#tv table(a int)
    insert @#tv values(@#p1)
    update @#tv set a = a + 1
    insert @#tv values(@#p1)
    update @#tv set a = a + 1
    delete @#tv where a = 124
    return (select sum(a) from @#tv)
end
go
select dbo. f4_del_atatuservar(123)
go

create function f5_upd_atatuservar(@#p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@#p1)
    update t set a = t.a + 1 from @#tv as t
    return
end
go
select * from dbo. f5_upd_atatuservar(123) order by 1
go

create function f5_del_atatuservar(@#p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@#p1)
    update @#tv set a = a + 1
    insert @#tv values(@#p1)
    delete t from @#tv as t where a = 124
    return
end
go
select * from dbo. f5_del_atatuservar(123) order by 1
go

create function f6_upd_atatuservar(@#p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@#p1)
    update t set a = t.a + 1 from t2_atatuservar, @#tv as t where t2_atatuservar.a = t.a
    return
end
go
select * from dbo. f6_upd_atatuservar(123) order by 1
go

create function f6_del_atatuservar(@#p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@#p1)
    update @#tv set a = a + 1
    insert @#tv values(@#p1)
    delete t from t2_atatuservar, @#tv as t where t2_atatuservar.a = t.a
    return
end
go
select * from dbo. f6_del_atatuservar(123) order by 1
go

create function f7_tabvar_udf_upd_atatuservar(@@p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@@p1)
    update t set a = t.a + 1 from t2_atatuservar, @#tv as t where t2_atatuservar.a = t.a
    return
end
go
select * from dbo. f7_tabvar_udf_upd_atatuservar(123) order by 1
go

create function f7a_tabvar_udf_upd_atatuservar(@@p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@@p1)
    update t set a = t.a + 1 from @#tv as tv, t2_atatuservar as t where tv.a = t.a
    return
end
go

create function f8_tabvar_udf_del_atatuservar(@@p1 int)
returns @#tv table(a int)
as
begin
    insert @#tv values(@@p1)
    update @#tv set a = a + 1
    insert @#tv values(@@p1)
    delete t from @#tv as tv, t2_atatuservar as t where tv.a = t.a
    return
end
go

create function f9_tabvar_udf_del_atatuservar(@p1 int)
returns @tv table(a int)
as
begin
    insert @tv values(@p1)
    update @tv set a = a + 1
    insert @tv values(@p1)
    delete t from @tv as t inner join t2_atatuservar as tv on tv.a = t.a
    return
end
go
select * from dbo.f9_tabvar_udf_del_atatuservar(123)
go

create function f10_tabvar_udf_del_atatuservar(@#p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@#p1)
    update @@tv set a = a + 1
    insert @@tv values(@#p1)
    delete t from t2_atatuservar as tv join @@tv as t on tv.a = t.a
    return
end
go
select * from dbo.f10_tabvar_udf_del_atatuservar(123)
go

create function f4_atatuservar_tabvar_in_function_upd(@#p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@#p1)
    update t set a = t.a + 1 from t2_atatuservar as t2_atatuservar left join t2_atatuservar as tv on tv.a = t2_atatuservar.a right join @@tv t on tv.a = t.a
    return
end
go
select * from dbo.f4_atatuservar_tabvar_in_function_upd(123)
go

create function f12_tabvar_udf_upd_atatuservar(@#p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@#p1)
    update t set a = t.a + 1 from @@tv as tv cross join t2_atatuservar as t
    return
end
go

create function f13_tabvar_udf_del_atatuservar(@#p1 int)
returns @@tv table(a int)
as
begin
    insert @@tv values(@#p1)
    update @@tv set a = a + 1
    insert @@tv values(@#p1)
    delete t from @@tv as t2_atatuservar right join t2_atatuservar as tv on tv.a = t2_atatuservar.a full outer join t2_atatuservar t on tv.a = t.a
    return
end
go

create function f14_del_atatuservar(@@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int)
returns int
as
begin
	declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table(a int)
    insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values(@@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
    update @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 set a = a + 1
    insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values(@@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
    update @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 set a = a + 1
    delete @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 where a = 124
    return (select sum(a) from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
end
go
select dbo. f14_del_atatuservar(123)
go

-- INSERT/UPDATE/DELETE on table variable in function
create function f15_upd_atatuservar(@@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int)
returns @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table(a int)
as
begin
    insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values(@@p128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
    update t set a = t.a + 1 from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 as t
    return
end
go
select * from dbo. f15_upd_atatuservar(123) order by 1
go

create function f16_tabvar_udf_del_atatuservar(@#q128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int)
returns @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 table(a int)
as
begin
    insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values(@#q128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
    update @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 set a = a + 1
    insert @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 values(@#q128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
    delete t from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 as t2_atatuservar right join t2_atatuservar as tv on tv.a = t2_atatuservar.a full outer join t2_atatuservar t on tv.a = t.a
    return
end
go

-- THROW
declare @@v int = 50001;
THROW @@v, 'Test message', 1;
go

declare @@v int = 50001, @@v2 varchar(30) = 'Test message';
THROW @@v, @@v2, 1
go

declare @@v int = 50001, @@v2 varchar(30) = 'Test message', @@v3 int=1;
THROW @@v, @@v2, @@v3
go

declare @#v int = 50001;
THROW @#v, 'Test message', 1;
go

declare @#v int = 50001, @#v2 varchar(30) = 'Test message';
THROW @#v, @#v2, 1
go

declare @#v int = 50001, @#v2 varchar(30) = 'Test message', @#v3 int=1;
THROW @#v, @#v2, @#v3
go

create procedure p20_atatuservar @@p int
as
if @@p > 0
begin
declare @@v int = 50001, @@v2 varchar(30) = 'Test message 1', @@v3 int=1;
THROW @@v, @@v2, @@v3
end

declare @#v int = 50001, @#v2 varchar(30) = 'Test message 2', @#v3 int=1;
THROW @#v, @#v2, @#v3
go
exec p20_atatuservar 1
go
exec p20_atatuservar 0
go

create trigger tr18_atatuservar on t18_trigger_atatuservar for insert
as
begin
select 'trigger tr18_atatuservar'	

declare @#v int = 50001, @#v2 varchar(30) = 'Test message 2', @#v3 int=1;
THROW @#v, @#v2, @#v3
end
go
insert t18_trigger_atatuservar values (123)
go

declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 50001, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782 varchar(30) = 'Test message', @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783 int=1;
THROW @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783
go

create procedure p21_atatuservar
as
declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 50001, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782 varchar(30) = 'Test message', @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783 int=1;
THROW @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783
go
exec p21_atatuservar 
go

create trigger tr19_atatuservar on t19_trigger_atatuservar for insert
as
begin
select 'trigger tr19_atatuservar'	

declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int = 50001, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782 varchar(30) = 'Test message', @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783 int=1;
THROW @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456782, @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$123456789012345678901234567890123456783
end
go
insert t19_trigger_atatuservar values (123)
go

-- DBCC CHECKIDENT
declare @@TableName varchar(100)='mytab'
DBCC CHECKIDENT (@@TableName)
go
declare @@v int=2
DBCC CHECKIDENT ('mytab', RESEED, @@v)
go

create procedure p1_checkident_atatuservar @@TableName varchar(100), @@v int
as
DBCC CHECKIDENT (@@TableName, RESEED, @@v)
go

create trigger tr20_atatuservar on t20_trigger_atatuservar for insert
as
begin
select 'trigger tr20_atatuservar'	
declare @@TableName varchar(100)='mytab', @@v int=2
DBCC CHECKIDENT (@@TableName, RESEED, @@v)
end
go

declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=2
DBCC CHECKIDENT ('mytab', RESEED, @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
go

create procedure p2_checkident_atatuservar @@t128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(100), @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int
as
DBCC CHECKIDENT (@@t128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, RESEED, @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
go

create trigger tr21_atatuservar on t21_trigger_atatuservar for insert
as
begin
select 'trigger tr21_atatuservar'	
declare @@t128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(100)='mytab', @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 int=2
DBCC CHECKIDENT (@@t128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678, RESEED, @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678)
end
go

-- transaction name
declare @@V varchar(50) = 'myxact'
begin transaction @@v
insert t3_atatuservar values(234)
declare @#V varchar(50) = 'mysavept'
save transaction @#v
insert t3_atatuservar values(345)
set @#V  = 'mysavept'
rollback transaction @#v
insert t3_atatuservar values(567)
commit transaction @@v
go
select * from t3_atatuservar
go

create procedure p1_xactname_atatuservar
as
declare @@V varchar(50) = 'myxact'
delete t3_atatuservar where a > 123
begin transaction @@v
insert t3_atatuservar values(234)
declare @#V varchar(50) = 'mysavept'
save transaction @#v
insert t3_atatuservar values(345)
set @#V  = 'mysavept'
rollback transaction @#v
insert t3_atatuservar values(567)
commit transaction @@v
select * from t3_atatuservar
go
exec p1_xactname_atatuservar
go

delete t3_atatuservar where a > 123
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(50) = 'myxact'
begin transaction @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(234)
declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(50) = 'mysavept'
save transaction @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(345)
set @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678  = 'mysavept'
rollback transaction @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(567)
commit transaction @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go
select * from t3_atatuservar
go

create procedure p2_xactname_atatuservar
as
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(50) = 'myxact'
delete t3_atatuservar where a > 123
begin transaction @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(234)
declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(50) = 'mysavept'
save transaction @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(345)
set @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678  = 'mysavept'
rollback transaction @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
insert t3_atatuservar values(567)
commit transaction @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
select * from t3_atatuservar
go
exec p2_xactname_atatuservar
go

-- cursor variable in T-SQL batch, stored procedure, trigger
declare @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(20)
declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 cursor	  
set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = cursor for select a from t_checkident_atatuservar order by n
open @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
while 1=1
begin
	fetch from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 into @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	if @@fetch_status <> 0 break
	select @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
end
close @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
deallocate @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
go

create procedure p1_cursor_atatuservar
as
begin  
	declare @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(20)
	declare @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 cursor	  
	set @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = cursor for select a from t_checkident_atatuservar order by n
	open @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	while 1=1
	begin
		fetch from @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 into @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
		if @@fetch_status <> 0 break
		select @#v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	end
	close @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	deallocate @@v128_890123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
end
go
exec p1_cursor_atatuservar
go

create trigger tr22_atatuservar on t22_trigger_atatuservar for insert
as
begin
	select 'trigger tr22_atatuservar'	

	declare @@v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 varchar(20)
	declare @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 cursor	  
	set @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 = cursor for select a from t_checkident_atatuservar order by n
	open @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	while 1=1
	begin
		fetch from @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678 into @@v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
		if @@fetch_status <> 0 break
		select @@v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	end
	close @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
	deallocate @#v128_90123456789$123456789$1234567890123456789$123456789$1234567890123456789$123456789$12345678901234567890123456789012345678
end
go
insert t22_trigger_atatuservar values (123)
go
set quoted_identifier on
go

-- user-defined variables that were previously mapped to internal sys. functions, e.g. sys.rand()
declare @@xact_state int=123 select @@xact_state, xact_state()
go
declare @@error_line int=123 select @@error_line, error_line()
go
declare @@error_message int=123 select @@error_message, error_message()
go
declare @@error_number int=123 select @@error_number, error_number()
go
declare @@error_procedure int=123 select @@error_procedure, error_procedure()
go
declare @@error_severity int=123 select @@error_severity, error_severity()
go
declare @@error_state int=123 select @@error_state, error_state()
go
declare @@db_id int=123 select @@db_id, db_id('master')
go
declare @@db_name int=123 select @@db_name, db_name()
go
declare @@exp int=123 select @@exp, exp(1)
go
declare @@sign int=123 select @@sign, sign(1)
go
declare @@lock_timeout int=123 select @@lock_timeout, lock_timeout()
go
declare @@rand int=123 select @@rand, case when rand() <= 0 then 'too small, <= 0' when rand() >= 1 then ' too large, >= 1' else 'correct, >0 && <1' end
go
declare @@trigger_nestlevel int=123 select @@trigger_nestlevel, trigger_nestlevel()
go
declare @@atn2 int=123 select @@atn2, atn2(1,0)
go
declare @@datepart int=123 select @@datepart, datepart(yy, '2024-11-12')
go
declare @@datediff int=123 select @@datediff, datediff(dd, '2024-11-12', '2024-12-13')
go
declare @@datediff_big int=123 select @@datediff_big, datediff(dd, '2024-11-12', '2024-12-13')
go
declare @@dateadd int=123 select @@dateadd, datediff(dd, 3, '2024-11-12')
go
declare @@datename int=123 select @@datename, datename(dw, '2024-11-12')
go

create proc p1_sysfunctions_atatuservar
as
begin
declare @@xact_state int=123 select @@xact_state, xact_state()
declare @@error_line int=123 select @@error_line, error_line()
declare @@error_message int=123 select @@error_message, error_message()
declare @@error_number int=123 select @@error_number, error_number()
declare @@error_procedure int=123 select @@error_procedure, error_procedure()
declare @@error_state int=123 select @@error_state, error_state()
declare @@db_id int=123 select @@db_id, db_id('master')
declare @@db_name int=123 select @@db_name, db_name()
declare @@exp int=123 select @@exp, exp(1)
declare @@sign int=123 select @@sign, sign(1)
declare @@lock_timeout int=123 select @@lock_timeout, lock_timeout()
declare @@rand int=123 select @@rand, case when rand() <= 0 then 'too small, <= 0' when rand() >= 1 then ' too large, >= 1' else 'correct, >0 && <1' end
declare @@trigger_nestlevel int=123 select @@trigger_nestlevel, trigger_nestlevel()
declare @@atn2 int=123 select @@atn2, atn2(1,0)
declare @@datepart int=123 select @@datepart, datepart(yy, '2024-11-12')
declare @@datediff int=123 select @@datediff, datediff(dd, '2024-11-12', '2024-12-13')
declare @@datediff_big int=123 select @@datediff_big, datediff(dd, '2024-11-12', '2024-12-13')
declare @@dateadd int=123 select @@dateadd, datediff(dd, 3, '2024-11-12')
declare @@datename int=123 select @@datename, datename(dw, '2024-11-12')
end
go
exec p1_sysfunctions_atatuservar
go

create function f1_sysfunctions_atatuservar() returns int
as
begin
declare @@xact_state int=123 
declare @@error_line int=123 
declare @@error_message int=123 
declare @@error_number int=123 
declare @@error_procedure int=123 
declare @@error_state int=123 
declare @@db_id int=123 
declare @@db_name int=123 
declare @@exp int=123 
declare @@sign int=123 
declare @@lock_timeout int=123 
declare @@rand int=123 
declare @@trigger_nestlevel int=123 
declare @@atn2 int=123 
declare @@datepart int=123 
declare @@datediff int=123 
declare @@datediff_big int=123 
declare @@dateadd int=123 
declare @@datename int=123 
return @@xact_state + @@error_line + @@error_message + @@error_number + @@error_procedure + @@error_state + @@db_id + @@db_name + @@exp + @@sign + @@lock_timeout + @@rand + @@trigger_nestlevel + @@atn2 + @@datepart + @@datediff + @@datediff_big + @@dateadd + @@datename 
end
go
select dbo.f1_sysfunctions_atatuservar()
go

create trigger tr1_sysfunctions_atatuservar on t23_trigger_atatuservar for insert as
begin
declare @@xact_state int=123 select @@xact_state, xact_state()
declare @@error_line int=123 select @@error_line, error_line()
declare @@error_message int=123 select @@error_message, error_message()
declare @@error_number int=123 select @@error_number, error_number()
declare @@error_procedure int=123 select @@error_procedure, error_procedure()
declare @@error_state int=123 select @@error_state, error_state()
declare @@db_id int=123 select @@db_id, db_id('master')
declare @@db_name int=123 select @@db_name, db_name()
declare @@exp int=123 select @@exp, exp(1)
declare @@sign int=123 select @@sign, sign(1)
declare @@lock_timeout int=123 select @@lock_timeout, lock_timeout()
declare @@rand int=123 select @@rand, case when rand() <= 0 then 'too small, <= 0' when rand() >= 1 then ' too large, >= 1' else 'correct, >0 && <1' end
declare @@trigger_nestlevel int=123 select @@trigger_nestlevel, trigger_nestlevel()
declare @@atn2 int=123 select @@atn2, atn2(1,0)
declare @@datepart int=123 select @@datepart, datepart(yy, '2024-11-12')
declare @@datediff int=123 select @@datediff, datediff(dd, '2024-11-12', '2024-12-13')
declare @@datediff_big int=123 select @@datediff_big, datediff(dd, '2024-11-12', '2024-12-13')
declare @@dateadd int=123 select @@dateadd, datediff(dd, 3, '2024-11-12')
declare @@datename int=123 select @@datename, datename(dw, '2024-11-12')
end
go
insert t23_trigger_atatuservar values(1)
go
