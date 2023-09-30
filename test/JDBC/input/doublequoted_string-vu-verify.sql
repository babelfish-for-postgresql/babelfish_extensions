create procedure dubquote_p @p varchar(20) = "ab'cd" , @p2 varchar(20)='xyz'
as select @p
go
create procedure dubquote_p2 @p varchar(20) = "ab""cd"
as select @p
go

set quoted_identifier off
go
select "abc"
go
exec dubquote_p
go
exec dubquote_p2
go
exec dubquote_p "abc"
go
exec dubquote_p 'abc'
go
exec dubquote_p abc
go
set quoted_identifier on
go
select "abc"
go
exec dubquote_p
go
exec dubquote_p2
go
exec dubquote_p "abc"
go
exec dubquote_p 'abc'
go
exec dubquote_p abc
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
create function dubquote_f3(@p varchar(20) = abcd) returns varchar(20) as begin return @p end
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
create procedure dubquote_p2a @p varchar(20) ="abc" as select @p
go
exec dubquote_p2a
go
create procedure dubquote_p3 @p varchar(20) ="'abc'" as select @p
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

-- the JDBC test cases do not capture PRINT output, but including them here for when it will
print "abc"
go
print "'abc'"  
go
print "a""b'c"  
go
print "a""b'c," + session_user +  ",d""e'f," + system_user
go
     /*test*/ print     "abc" 
go
   /*hello*/    print /*hello*/ "abc" 
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
create function dubquote_f4 (@p varchar(20) = "'abc'") returns varchar(50) as begin return  ((("function's return" +( " string value:" ))) +"'" + @p + "'")  end 
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

create procedure dubquote_p5 @p varchar(10) as select @p
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

create procedure dubquote_p6 @par1 varchar(10) = abc as select @par1
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
create procedure dubquote_p7 @p varchar(20) ="abc" as select @p
go
exec dubquote_p7
go
create procedure dubquote_p8 @p varchar(20) ="'abc'" as select @p
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

