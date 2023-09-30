create procedure proc_doublequote @p varchar(20) = "ab'cd" , @p2 varchar(20)='xyz'
as select @p
go
create proc proc_doublequote2 @p varchar(20) = "ab""cd"
as select @p
go

set quoted_identifier off
go
select "abc"
go
exec proc_doublequote
go
exec proc_doublequote2
go
exec proc_doublequote "abc"
go
exec proc_doublequote 'abc'
go
exec proc_doublequote abc
go
set quoted_identifier on
go
select "abc"
go
exec proc_doublequote
go
exec proc_doublequote2
go
exec proc_doublequote "abc"
go
exec proc_doublequote 'abc'
go
exec proc_doublequote abc
go

set quoted_identifier off
go
select "ab""cd"
go
select "de'fg"
go
select 'ab"cd'
go
select "ab'cd"
go
select 'ab"cd'
go
select 'ab"''"''"cd'
go
select """"
go
select ''''
go
select '"'
go
select '""'
go
select "'"
go
select "''"
go
select """'""'"""
go

set quoted_identifier on
go
exec proc_doublequote
go
exec proc_doublequote "xx'yy"
go
exec proc_doublequote 'xx"yy'
go
exec proc_doublequote """"
go
exec proc_doublequote ''''
go
exec proc_doublequote '"'
go
exec proc_doublequote '""'
go
exec proc_doublequote "'"
go
exec proc_doublequote "''"
go
exec proc_doublequote """'""'"""
go

-- same as above but with named notation
exec proc_doublequote @p="xx'yy"  , @p2='x"y'
go
exec proc_doublequote @p='xx"yy'  , @p2="x""y"
go
exec proc_doublequote @p=""""     , @p2="x'y"
go
exec proc_doublequote @p=''''     , @p2="x''y"
go
exec proc_doublequote @p='"'      , @p2="x''y"
go
exec proc_doublequote @p='""'     , @p2="x''y"
go
exec proc_doublequote @p="'"      , @p2="x''y"
go
exec proc_doublequote @p="''"     , @p2="x''y"
go
exec proc_doublequote @p="""'""'""" , @p2="x''y"
go

-- using N'...' notation:
exec proc_doublequote N'xx"yy'
go
exec proc_doublequote N''''
go
exec proc_doublequote N'"'
go
exec proc_doublequote N'""'
go
exec proc_doublequote @p=N'xx"yy'
go
exec proc_doublequote @p=N''''
go
exec proc_doublequote @p=N'"'
go
exec proc_doublequote @p=N'""'
go

-- functions
set quoted_identifier off
go
create function func_doublequote(@p varchar(20) = "ab'cd") returns varchar(20) as begin return @p end
go
create function func2_doublequote(@p varchar(20) = "ab""cd") returns varchar(20) as begin return @p end
go
create function func3_doublequote(@p varchar(20) = abcd) returns varchar(20) as begin return @p end
go
declare @v varchar(20)
exec @v = func_doublequote
select @v
go
declare @v varchar(20)
exec @v = func2_doublequote
select @v
go
declare @v varchar(20)
exec @v = func3_doublequote
select @v
go

select dbo.func_doublequote("ab'cd")
go
select dbo.func_doublequote('ab"cd')
go
select dbo.func_doublequote(N'ab"cd')
go
select dbo.func_doublequote("ab""cd")
go

set quoted_identifier on
go
select dbo.func_doublequote("ab'cd")
go
select dbo.func_doublequote('ab"cd')
go
select dbo.func_doublequote(N'ab"cd')
go
select dbo.func_doublequote("ab""cd")
go

set quoted_identifier off
go
drop proc if exists dubquote_p2
go
create proc dubquote_p2 @p varchar(20) ="abc" as print @p
go
exec dubquote_p2
go
drop proc if exists dubquote_p3
go
create proc dubquote_p3 @p varchar(20) ="'abc'" as print @p
go
exec dubquote_p3
go
declare @v varchar(40) set @v = "It's almost ""weekend""!" select @v
go

select 'abc'
go
select "abc"
go
select "a'b""c''''''''''d"
go
select "a'b""c'd"
go
select "'abc'",'xyz' 
go

declare @v varchar(20) = 'abc' select @v
go
declare @v varchar(20) = "abc" select @v
go
declare @v varchar(20) = "'a""bc'" select @v
go
declare @v varchar(20) select @v = "abc" select @v
go
declare @v varchar(20) = 'x' select @v += "abc" select @v
go
declare @v varchar(20) select @v = "'a""bc'" select @v
go
declare @v varchar(20) = 'x' select @v += "'a""bc'" select @v
go
declare @v varchar(20) set @v = "'a""bc'" select @v
go
declare @v varchar(20) = 'x' set @v += "'a""bc'" select @v
go

declare @v varchar(20) ="abc" , @v2 varchar(10) = 'xyz' select @v
go
declare @v varchar(20), @v2 varchar(20) select @v="a""b''c'd", @v2="x""y''z" select @v, @v2
go
declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ" select @v+="a""b''c'd", @v2+="x""y''z" select @v, @v2
go
declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ" set @v+="a""b''c'd" set @v2+="x""y''z" select @v, @v2
go
declare @v varchar(20) ="a""bc" , @v2 varchar(10) = 'x''z' select @v, @v2
go
declare @v varchar(20) ="a""bc" , @v2 varchar(10) = 'x''z' , @v3 varchar(10) = "x""y'z'z" select @v, @v2, @v3
go

print "abc"
go
print "'abc'"  
go
print "a""b'c"  
go
     /*test*/ print     "abc" 
go
   /*hello*/    print /*hello*/ "abc" 
go
RAISERROR("Message from RAISERROR", 16,1)
go
RAISERROR("'Message from RAISERROR'", 16,1)
go
RAISERROR("""Message from ""'RAISERROR'""", 16,1)
go
      /*test*/RAISERROR( /*hello*/"Message from 'RAISERROR'", 16,1)
go

drop procedure if exists dubquote_p4
go
create procedure dubquote_p4 @p varchar(20) ="a'bc" as select @p,@p
go
exec dubquote_p4
go
exec dubquote_p4 "abc" 
go
exec dubquote_p4 "ab""cd" 
go
exec dubquote_p4 "ab'cd" 
go
select "ab'cd" 
go
drop function if exists dubquote_f15 
go
create function dubquote_f15 (@p varchar(20) = "'abc'") returns varchar(50) as begin return  ((("function's return" +( " string value:" ))) +"'" + @p + "'")  end 
go
select dbo.dubquote_f15("x")
go

drop procedure if exists dubquote_p5 
go
create procedure dubquote_p5 @p varchar(10) as print @p
go
exec dubquote_p5 'xyz' exec dubquote_p5 abc
go
exec dubquote_p5 abcd
go
exec dubquote_p5 [abcd]
go
exec dubquote_p5 @p=abcde
go
declare @v varchar(20) exec dubquote_p5 @v
go
declare @v varchar(20) = 'efg' exec dubquote_p5 @v
go
declare @v varchar(20) exec dubquote_p5 @p=@v
go
declare @v varchar(20) = 'hij' exec dubquote_p5 @p=@v
go

drop proc if exists dubquote_p6
go
create proc dubquote_p6 @par1 varchar(10) = abc as print @par1
go
exec dubquote_p6
go


declare @v varchar(20) = session_user select @v, session_user
go
declare @v varchar(20) = 'abc' + session_user select @v, session_user
go
declare @v varchar(20) = "abc" + session_user select @v, session_user
go
declare @v varchar(20) = "ab""c'd" + session_user select @v, session_user
go

declare @v varchar(20) = system_user select @v, system_user
go
declare @v varchar(20) = 'abc' + system_user select @v, system_user
go
declare @v varchar(20) = "abc" + system_user select @v, system_user
go
declare @v varchar(20) = "ab""c'd" + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = 'abc' + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = "abc" + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v =  "ab""c'd" + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = "ab""c'd" + system_user select @v, system_user
go
declare @v varchar(20) = 'ab,' set @v += system_user select @v, system_user
go
declare @myvar varchar(20) = '' set @myvar += system_user select @myvar, system_user
go
/*hello*/declare @myvar varchar(50) = '' /*hello*/set /*hello*/@myvar/*hello*/ +=      
/*hello*/system_user/*hello*/ + 

/*hello*/",a""b'c," + /*hello*/system_user  
select @myvar, system_user
go
declare @v varchar(50) = system_user+"," set @v += "a""b'c," + system_user + ",a""b'c," + system_user select @v, system_user
go

-- all in one batch:
declare @v varchar(20) = session_user select @v 
declare @v1 varchar(20) = 'abc' + session_user select @v1
declare @v2 varchar(20) = "ab""c'd" + session_user select @v2
declare @v3 varchar(20) ="a""bc" , @v4 varchar(20) = 'x''z' select @v3,@v4
declare @v5 varchar(20) ="a""bc" , @v6 varchar(20) = 'x''z' , @v7 varchar(20) = "x""y'z'z" select @v5, @v6, @v7
go

declare @v varchar(20) = session_user, @v2 varchar(20)= system_user select @v, @v2, session_user, system_user
go
declare @v varchar(20) = 'abcd'  + session_user, @v2 varchar(20) = 'xy' + session_user select @v, @v2, session_user  
go
declare @v varchar(20) = 'abcd'  + upper('x'), @v2 varchar(20) = 'xy' + upper('y') select @v, @v2  
go
declare @v varchar(20) = session_user, @v2 varchar(20)= system_user select @v,@v2,session_user, system_user
go
declare @v varchar(20) = "x'y" + session_user, @v2 varchar(20)= "a'b" + system_user select @v,@v2,session_user, system_user
go
declare @v varchar(20) = "x'y" + session_user, @v2 varchar(20)= "a'b" + system_user + "x''""" select @v,@v2,session_user, system_user
go
declare @v varchar(20) = session_user select @v 
go

drop sequence if exists dubquote_myseq
go
create sequence dubquote_myseq
go
drop sequence if exists dubquote_myseq2
go
create sequence dubquote_myseq2
go
drop sequence if exists dubquote_myseq3
go
create sequence dubquote_myseq3
go
drop sequence if exists dubquote_myseq4
go
create sequence dubquote_myseq4
go
declare 
@v  varchar(20) = '123' + next value for dubquote_myseq, 
@v2 varchar(20) = next value for dubquote_myseq2,
@v3 varchar(20) = next value for dubquote_myseq3 + "000",
@v4 varchar(20) = "123" + next value for dubquote_myseq4 + "000"
select @v, @v2, @v3, @v4 
go
declare @v int = next value for dubquote_myseq select @v 
go
declare @v int = next value for dubquote_myseq select @v 
go
declare @v int = len("a'bc") + next value for dubquote_myseq + len(system_user) select @v
go
declare @v int = 0 set @v = next value for dubquote_myseq select @v
go
declare @v int = 0 set @v += len("a'bc") + next value for dubquote_myseq + len(system_user) select @v
go
declare @v int = 0 set @v -= len("a'bc") + next value for dubquote_myseq + len(system_user) select @v
go
declare @v int = 1 set @v *= len("a'bc") + next value for dubquote_myseq + len(system_user) select @v
go
declare @v int = 1 set @v /= len("a'bc") + next value for dubquote_myseq + len(system_user) select @v
go



set quoted_identifier on
go
drop proc if exists dubquote_p7
go
create proc dubquote_p7 @p varchar(20) ="abc" as print @p
go
exec dubquote_p7
go
drop proc if exists dubquote_p8
go
create proc dubquote_p8 @p varchar(20) ="'abc'" as print @p
go
exec dubquote_p8
go
declare @v varchar(20) = 'abc' select @v
go

-- negative tests
declare @v varchar(20) = "abc" select @v
go
declare @v varchar(20) = "'abc'" select @v
go

