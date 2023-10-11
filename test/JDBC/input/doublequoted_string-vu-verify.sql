-- BABEL-2442: Handle embedded double quotes in a double-quoted string
-- BABEL-4387: Support double-quoted strings containing single-quote
-- This also exercises parts of the ANTLR parse tree rewriting

set quoted_identifier off
go
create procedure dubquote_p @p varchar(20) = "ab'cd" , @p2 varchar(20)='xyz'
as select @p
go
create procedure dubquote_p2 @p varchar(20) = "ab""cd"
as select @p
go

set quoted_identifier off
go
select "aBc"
go
exec dubquote_p
go
exec dubquote_p2
go
exec dubquote_p "aBc"
go
exec dubquote_p 'aBc'
go
exec dubquote_p aBc
go

set quoted_identifier on
go
select "aBc"
go
exec dubquote_p
go
exec dubquote_p2
go
exec dubquote_p "aBc"
go
exec dubquote_p 'aBc'
go
exec dubquote_p aBc
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
exec dubquote_p
go
exec dubquote_p "xx'yy"
go
exec dubquote_p 'xx"yy'
go
exec dubquote_p """"
go
exec dubquote_p ''''
go
exec dubquote_p '"'
go
exec dubquote_p '""'
go
exec dubquote_p "'"
go
exec dubquote_p "''"
go
exec dubquote_p """'""'"""
go

-- same as above but with named notation
exec dubquote_p @p="xx'yy"  , @p2='x"y'
go
exec dubquote_p @p='xx"yy'  , @p2="x""y"
go
exec dubquote_p @p=""""     , @p2="x'y"
go
exec dubquote_p @p=''''     , @p2="x''y"
go
exec dubquote_p @p='"'      , @p2="x''y"
go
exec dubquote_p @p='""'     , @p2="x''y"
go
exec dubquote_p @p="'"      , @p2="x''y"
go
exec dubquote_p @p="''"     , @p2="x''y"
go
exec dubquote_p @p="""'""'""" , @p2="x''y"
go

-- using N'...' notation:
exec dubquote_p N'xx"yy'
go
exec dubquote_p N''''
go
exec dubquote_p N'"'
go
exec dubquote_p N'""'
go
exec dubquote_p @p=N'xx"yy'
go
exec dubquote_p @p=N''''
go
exec dubquote_p @p=N'"'
go
exec dubquote_p @p=N'""'
go

-- functions
set quoted_identifier off
go
create function dubquote_f1(@p varchar(20) = "ab'cd") returns varchar(20) as begin return @p end
go
create function dubquote_f2(@p varchar(20) = "ab""cd") returns varchar(20) as begin return @p end
go
create function dubquote_f3(@p varchar(20) = aBcd) returns varchar(20) as begin return @p end
go
declare @v varchar(20)
exec @v = dubquote_f1
select @v
go
declare @v varchar(20)
exec @v = dubquote_f2
select @v
go
declare @v varchar(20)
exec @v = dubquote_f3
select @v
go

select dbo.dubquote_f1("ab'cd")
go
select dbo.dubquote_f1('ab"cd')
go
select dbo.dubquote_f1(N'ab"cd')
go
select dbo.dubquote_f1("ab""cd")
go

set quoted_identifier on
go
select dbo.dubquote_f1("ab'cd")
go
select dbo.dubquote_f1('ab"cd')
go
select dbo.dubquote_f1(N'ab"cd')
go
select dbo.dubquote_f1("ab""cd")
go

set quoted_identifier off
go
create procedure dubquote_p2a @p varchar(20) ="aBc" as select @p
go
exec dubquote_p2a
go
create procedure dubquote_p3 @p varchar(20) ="'aBc'" as select @p
go
exec dubquote_p3
go
declare @v varchar(40) set @v = "It's almost ""weekend""!" select @v
go

select 'aBc'
go
select "aBc"
go
select "a'b""c''''''''''d"
go
select "a'b""c'd"
go
select "'aBc'",'xyz' 
go

declare @v varchar(20) = 'aBc' select @v
go
declare @v varchar(20) = "aBc" select @v
go
declare @v varchar(20) = "'a""bc'" select @v
go
declare @v varchar(20) select @v = "aBc" select @v
go
declare @v varchar(20) = 'x' select @v += "aBc" select @v
go
declare @v varchar(20) select @v = "'a""bc'" select @v
go
declare @v varchar(20) = 'x' select @v += "'a""bc'" select @v
go
declare @v varchar(20) set @v = "'a""bc'" select @v
go
declare @v varchar(20) = 'x' set @v += "'a""bc'" select @v
go

declare @v varchar(20) ="aBc" , @v2 varchar(10) = 'xyz' select @v
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

-- bracketed identifiers containing double-quoted strings should not be affected by double-quoted string replacement
-- this SELECT should return 0 rows and no error
create table dubquote_t1([x"a'b"y] int, c varchar(20))
go
select [x"a'b"y] from dubquote_t1 where c = "a'b"
go

set quoted_identifier off
go
-- the JDBC test cases do not capture PRINT output, but including them here for when it will
print "aBc"
go
print "'aBc'"  
go
print "a""b'c"  
go
print "a""b'c," + session_user +  ",d""e'f," + system_user
go
     /*test*/ print     "aBc" 
go
   /*hello*/    print /*hello*/ "aBc" 
go
print    /*hello*/  "a""b'c," +    /*hello*/     
session_user +     /*hello*/    
",d""e'f," +    /*hello*/     system_user
go
RAISERROR("Message from RAISERROR", 16,1)
go
RAISERROR("'Message from RAISERROR'", 16,1)
go
RAISERROR("""Message from ""'RAISERROR'""", 16,1)
go
      /*test*/RAISERROR( /*hello*/"Message from 'RAISERROR'", 16,1)
go

-- RAISERROR arguments are not yet rewritten. this should raise an error
RAISERROR ('%s %s',  10, 1, 'aBc', "def");
go


declare @v varchar(20) = "a""b'c"
if @v = 'a"b''c' select 'correct' 
else select 'wrong'
go

declare @v varchar(20) = "a""b'c"
while @v = 'a"b''c' 
begin 
select 'correct' 
break 
end 
go

declare @v varchar(20) = system_user
if @v = system_user select 'correct' 
else select 'wrong'
go

declare @v varchar(20) = system_user
while @v = system_user
begin 
select 'correct' 
break 
end 
go

set quoted_identifier on
go
print "aBc"
go
RAISERROR("Message from RAISERROR", 16,1)
go

set quoted_identifier off
go
create procedure dubquote_p4 @p varchar(20) ="a'bc" as select @p,@p
go
exec dubquote_p4
go
exec dubquote_p4 "aBc" 
go
exec dubquote_p4 "ab""cd" 
go
exec dubquote_p4 "ab'cd" 
go
select "ab'cd" 
go
create function dubquote_f4 (@p varchar(20) = "'aBc'") returns varchar(50) as begin return  ((("function's return" +( " string value:" ))) +"'" + @p + "'")  end 
go
select dbo.dubquote_f4("x")
go

create function dubquote_f5 () returns varchar(50) as begin return "a""b'c" end 
go
select dbo.dubquote_f5()
go

create function dubquote_f6 () returns varchar(50) as begin return "a""b'c," + session_user +  ",d""e'f," + system_user end 
go
select dbo.dubquote_f6()
go

CREATE function dubquote_f7() returns varchar(30) as begin return system_user end
go
select dbo.dubquote_f7(), system_user
go

create procedure dubquote_p5 @p varchar(10) as select @p
go
exec dubquote_p5 'xyz' exec dubquote_p5 aBc
go
exec dubquote_p5 aBcd
go
exec dubquote_p5 [aBcd]
go
exec dubquote_p5 @p=aBcde
go
declare @v varchar(20) exec dubquote_p5 @v
go
declare @v varchar(20) = 'efg' exec dubquote_p5 @v
go
declare @v varchar(20) exec dubquote_p5 @p=@v
go
declare @v varchar(20) = 'hij' exec dubquote_p5 @p=@v
go

declare @v varchar(20) = session_user select @v, session_user
go
declare @v varchar(20) = 'aBc' + session_user select @v, session_user
go
declare @v varchar(20) = "aBc" + session_user select @v, session_user
go
declare @v varchar(20) = "ab""c'd" + session_user select @v, session_user
go

declare @v varchar(20) = system_user select @v, system_user
go
declare @v varchar(20) = 'aBc' + system_user select @v, system_user
go
declare @v varchar(20) = "aBc" + system_user select @v, system_user
go
declare @v varchar(20) = "ab""c'd" + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = 'aBc' + system_user select @v, system_user
go
declare @v varchar(20) = '' set @v = "aBc" + system_user select @v, system_user
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
declare @v1 varchar(20) = 'aBc' + session_user select @v1
declare @v2 varchar(20) = "ab""c'd" + session_user select @v2
declare @v3 varchar(20) ="a""bc" , @v4 varchar(20) = 'x''z' select @v3,@v4
declare @v5 varchar(20) ="a""bc" , @v6 varchar(20) = 'x''z' , @v7 varchar(20) = "x""y'z'z" select @v5, @v6, @v7
go

declare @v varchar(20) = session_user, @v2 varchar(20)= system_user select @v, @v2, session_user, system_user
go
declare @v varchar(20) = 'aBcd'  + session_user, @v2 varchar(20) = 'xy' + session_user select @v, @v2, session_user  
go
declare @v varchar(20) = 'aBcd'  + upper('x'), @v2 varchar(20) = 'xy' + upper('y') select @v, @v2  
go
declare @v varchar(20) = session_user, @v2 varchar(20)= system_user select @v,@v2,session_user, system_user
go
declare @v varchar(20) = "x'y" + session_user, @v2 varchar(20)= "a'b" + system_user select @v,@v2,session_user, system_user
go
declare @v varchar(20) = "x'y" + session_user, @v2 varchar(20)= "a'b" + system_user + "x''""" select @v,@v2,session_user, system_user
go
declare @v varchar(20) = session_user select @v 
go

create sequence dubquote_myseq
go
create sequence dubquote_myseq2
go
create sequence dubquote_myseq3
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
create procedure dubquote_p6 @p varchar(20) ="aBc" as select @p
go
exec dubquote_p6
go
create procedure dubquote_p7 @p varchar(20) ="'aBc'" as select @p
go
exec dubquote_p7
go
declare @v varchar(20) = 'aBc' select @v
go

set quoted_identifier off
go
create procedure dubquote_p8 @p varchar(20) as select @p
go
execute dubquote_p8 "x'Y""z"
go
exec dubquote_p8 "x'Y""z"
go
execute[dubquote_p8]"x'Y""z"
go
exec[dubquote_p8]"x'Y""z"
go
exec ..[dubquote_p8]"x'Y""z"
go
dubquote_p8 "x'Y""z"
go
dbo.dubquote_p8 "x'Y""z"
go
.dubquote_p8 "x'Y""z"
go
..dubquote_p8 "x'Y""z"
go
[dubquote_p8]"x'Y""z"
go
/*test*/execute dubquote_p8 "x'Y""z" 
go
/*test*/exec dubquote_p8 "x'Y""z"
go
/*test*/execute[dubquote_p8]"x'Y""z"
go
/*test*/exec[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/dubquote_p8 "x'Y""z"
go
/*test*/dubquote_p8 "x'Y""z"
go
/*test*/.dubquote_p8 "x'Y""z"
go
/*test*/..dubquote_p8 "x'Y""z"
go
/*test*/[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/.[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/..[dubquote_p8]/*test*/"x'Y""z"
execute dubquote_p8 "a'B""C"
go

set quoted_identifier on
go
execute dubquote_p8 "x'Y""z"
go
exec dubquote_p8 "x'Y""z"
go
execute[dubquote_p8]"x'Y""z"
go
exec[dubquote_p8]"x'Y""z"
go
exec ..[dubquote_p8]"x'Y""z"
go
dubquote_p8 "x'Y""z"
go
dbo.dubquote_p8 "x'Y""z"
go
.dubquote_p8 "x'Y""z"
go
..dubquote_p8 "x'Y""z"
go
[dubquote_p8]"x'Y""z"
go
/*test*/execute dubquote_p8 "x'Y""z" 
go
/*test*/exec dubquote_p8 "x'Y""z"
go
/*test*/execute[dubquote_p8]"x'Y""z"
go
/*test*/exec[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/dubquote_p8 "x'Y""z"
go
/*test*/.dubquote_p8 "x'Y""z"
go
/*test*/..dubquote_p8 "x'Y""z"
go
/*test*/[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/.[dubquote_p8]/*test*/"x'Y""z"
go
/*test*/..[dubquote_p8]/*test*/"x'Y""z"
go
"dubquote_p8" "x'Y""z"
go
/*test*/"dubquote_p8"/*test*/"x'Y""z"
go
/*test*/"dubquote_p8"/*test*/"x'Y""z"
execute dubquote_p8 "a'B""C"
go

set quoted_identifier on
go
-- negative tests
declare @v varchar(20) = "aBc" select @v
go
declare @v varchar(20) = "'aBc'" select @v
go


--cleanup
drop procedure dubquote_p
go
drop procedure dubquote_p2
go
drop function dubquote_f1
go
drop function dubquote_f2
go
drop function dubquote_f3
go
drop procedure dubquote_p2a
go
drop procedure dubquote_p3
go
drop procedure dubquote_p4
go
drop function dubquote_f4
go
drop function dubquote_f5
go
drop function dubquote_f6
go
drop function dubquote_f7
go
drop procedure dubquote_p5
go
drop sequence dubquote_myseq
go
drop sequence dubquote_myseq2
go
drop sequence dubquote_myseq3
go
drop sequence dubquote_myseq4
go
drop procedure dubquote_p6
go
drop procedure dubquote_p7
go
drop procedure dubquote_p8
go
drop table dubquote_t1
go
